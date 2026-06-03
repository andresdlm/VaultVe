import Foundation
import SwiftData

// Pure data store + cost-traceability engine.
// Everything that runs deterministic math on persisted data lives here.
// No UI state, no SwiftUI imports.
//
// FIFO model
// ──────────
// • USDT lots are consumed by VES lots in date order. Older lots first.
// • VES lots are consumed by Gastos in date order. Older lots first.
// • At each allocation we *capture* the USD cost of that slice. Once captured
//   the cost is frozen — later changes to inventory cannot retroactively
//   alter the cost of past expenses.
final class VaultRepository {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // ─── Queries ────────────────────────────────────────────────────────────

    func allUSDTLots() -> [USDTLot] {
        (try? context.fetch(FetchDescriptor<USDTLot>(sortBy: [SortDescriptor(\.date)]))) ?? []
    }
    func allVESLots() -> [VESLot] {
        (try? context.fetch(FetchDescriptor<VESLot>(sortBy: [SortDescriptor(\.date)]))) ?? []
    }
    func allGastos() -> [Gasto] {
        (try? context.fetch(FetchDescriptor<Gasto>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
    }
    func allIncome() -> [USDIncome] {
        (try? context.fetch(FetchDescriptor<USDIncome>(sortBy: [SortDescriptor(\.date)]))) ?? []
    }

    func latestRateSnapshot() -> RateSnapshot? {
        var d = FetchDescriptor<RateSnapshot>(sortBy: [SortDescriptor(\.capturedAt, order: .reverse)])
        d.fetchLimit = 1
        return (try? context.fetch(d))?.first
    }

    // ─── Aggregates ─────────────────────────────────────────────────────────

    var totalUsdIncome:  Double { allIncome().reduce(0) { $0 + $1.amount } }
    var totalUsdSpent:   Double { allUSDTLots().reduce(0) { $0 + $1.usdSent } }
    var usdAvail:        Double { max(0, totalUsdIncome - totalUsdSpent) }

    var usdtAvail:       Double { allUSDTLots().reduce(0) { $0 + $1.usdtRemaining } }
    var vesBalance:      Double { allVESLots().reduce(0) { $0 + $1.vesRemaining } }

    /// Weighted average USD/USDT for the USDT currently on hand (remaining slices only).
    var usdtAvgCost: Double {
        let lots = allUSDTLots().filter { $0.usdtRemaining > 0 }
        let usd  = lots.reduce(0.0) { $0 + $1.costPerUsdt * $1.usdtRemaining }
        let qty  = lots.reduce(0.0) { $0 + $1.usdtRemaining }
        return qty > 0 ? usd / qty : 0
    }

    /// Weighted average USD per Bs for the VES currently on hand.
    var vesCostPerBs: Double {
        let lots = allVESLots().filter { $0.vesRemaining > 0 }
        let usd  = lots.reduce(0.0) { $0 + $1.costPerVes * $1.vesRemaining }
        let bs   = lots.reduce(0.0) { $0 + $1.vesRemaining }
        return bs > 0 ? usd / bs : 0
    }

    var vesInUsd:      Double { vesBalance * vesCostPerBs }
    var patrimonioUsd: Double { usdAvail + usdtAvail * usdtAvgCost + vesInUsd }

    func patrimonioVes(rate: ActiveRate) -> Double {
        let r = latestRateSnapshot()
        let v = r.map { rate == .bcv ? $0.bcv : $0.paralela } ?? 0
        return patrimonioUsd * v
    }

    var spreadPct: Double {
        guard let r = latestRateSnapshot(), r.bcv > 0 else { return 0 }
        return (r.paralela - r.bcv) / r.bcv * 100
    }

    // ─── Mutations: USD income ──────────────────────────────────────────────

    @discardableResult
    func addUSDIncome(date: Date, amount: Double, source: String, note: String?) throws -> USDIncome {
        let seq = nextSeq(for: USDIncome.self, key: \.sequenceNumber)
        let inc = USDIncome(date: date, sequenceNumber: seq, amount: amount, source: source, note: note)
        context.insert(inc)
        try context.save()
        return inc
    }

    // ─── Mutations: USD → USDT ──────────────────────────────────────────────

    @discardableResult
    func addUSDTLot(date: Date, usdSent: Double, usdtReceived: Double, feeUsd: Double, note: String?) throws -> USDTLot {
        precondition(usdSent > 0 && usdtReceived > 0, "lot needs positive amounts")
        let seq = nextSeq(for: USDTLot.self, key: \.sequenceNumber)
        let lot = USDTLot(
            date: date, sequenceNumber: seq,
            usdSent: usdSent, usdtReceived: usdtReceived,
            feeUsd: feeUsd, note: note
        )
        context.insert(lot)
        try context.save()
        return lot
    }

    // ─── Mutations: USDT → VES (FIFO allocate) ──────────────────────────────

    /// Inserts a new VES lot, drawing the requested USDT FIFO from available USDT lots.
    /// Throws if not enough USDT is available.
    @discardableResult
    func addVESLot(date: Date, usdtSent: Double, vesReceived: Double, note: String?) throws -> VESLot {
        precondition(usdtSent > 0 && vesReceived > 0, "ves lot needs positive amounts")
        guard usdtAvail + 1e-9 >= usdtSent else {
            throw VaultError.insufficientUsdt(needed: usdtSent, available: usdtAvail)
        }

        let seq = nextSeq(for: VESLot.self, key: \.sequenceNumber)
        let ves = VESLot(date: date, sequenceNumber: seq, usdtSent: usdtSent, vesReceived: vesReceived, note: note)
        context.insert(ves)

        var remaining = usdtSent
        for source in allUSDTLots() where source.usdtRemaining > 0 && remaining > 1e-9 {
            let take = min(source.usdtRemaining, remaining)
            let usd  = take * source.costPerUsdt
            let alloc = USDTAllocation(usdtAmount: take, usdAmount: usd, sourceLot: source, vesLot: ves)
            context.insert(alloc)
            remaining -= take
        }

        try context.save()
        return ves
    }

    /// Preview how a hypothetical USDT→VES allocation would draw from available lots.
    /// Returns the per-source plan without persisting anything.
    func previewVESLot(usdtSent: Double) -> [VESLotAllocationPreview] {
        var plan: [VESLotAllocationPreview] = []
        var remaining = usdtSent
        for source in allUSDTLots() where source.usdtRemaining > 0 && remaining > 1e-9 {
            let take = min(source.usdtRemaining, remaining)
            plan.append(.init(
                sourceLot: source,
                usdtAmount: take,
                usdAmount: take * source.costPerUsdt
            ))
            remaining -= take
        }
        return plan
    }

    // ─── Mutations: Gasto (FIFO allocate VES) ───────────────────────────────

    @discardableResult
    func addGasto(date: Date, merchant: String, category: String, vesAmount: Double, note: String?) throws -> Gasto {
        precondition(vesAmount > 0, "gasto needs positive ves amount")
        guard vesBalance + 1e-9 >= vesAmount else {
            throw VaultError.insufficientVes(needed: vesAmount, available: vesBalance)
        }

        let seq = nextSeq(for: Gasto.self, key: \.sequenceNumber)
        let gasto = Gasto(
            date: date, sequenceNumber: seq,
            merchant: merchant, category: category, vesAmount: vesAmount, note: note
        )
        context.insert(gasto)

        var remaining = vesAmount
        for source in allVESLots() where source.vesRemaining > 0 && remaining > 1e-9 {
            let take = min(source.vesRemaining, remaining)
            let usd  = take * source.costPerVes
            let alloc = VESAllocation(vesAmount: take, usdAmount: usd, sourceLot: source, gasto: gasto)
            context.insert(alloc)
            remaining -= take
        }

        try context.save()
        return gasto
    }

    func previewGasto(vesAmount: Double) -> [GastoAllocationPreview] {
        var plan: [GastoAllocationPreview] = []
        var remaining = vesAmount
        for source in allVESLots() where source.vesRemaining > 0 && remaining > 1e-9 {
            let take = min(source.vesRemaining, remaining)
            plan.append(.init(
                sourceLot: source,
                vesAmount: take,
                usdAmount: take * source.costPerVes
            ))
            remaining -= take
        }
        return plan
    }

    // ─── Trace one expense back to USD ──────────────────────────────────────

    func traceGasto(_ gasto: Gasto) -> GastoTrace {
        let allocs = gasto.allocations ?? []
        let vesLegs: [GastoTrace.VESLeg] = allocs.compactMap { va in
            guard let src = va.sourceLot else { return nil }
            // Prorate the VES leg back into the USDT lots that fed this VES lot.
            let shareOfVesLot = src.vesReceived > 0 ? va.vesAmount / src.vesReceived : 0
            let usdtAllocs    = src.allocations ?? []
            let usdtLegs: [GastoTrace.USDTLeg] = usdtAllocs.compactMap { ua in
                guard let usrc = ua.sourceLot else { return nil }
                return .init(
                    id: ua.id,
                    usdtLot: usrc,
                    usdtAmount: ua.usdtAmount * shareOfVesLot,
                    usdAmount:  ua.usdAmount  * shareOfVesLot
                )
            }
            return .init(
                id: va.id,
                vesLot: src,
                vesAmount: va.vesAmount,
                usdCost: va.usdAmount,
                usdtLegs: usdtLegs
            )
        }

        let totalUsd  = gasto.totalUsdCost
        let eff       = totalUsd > 0 ? gasto.vesAmount / totalUsd : 0
        let paralela  = latestRateSnapshot()?.paralela ?? 0
        let diff      = paralela > 0 ? totalUsd - (gasto.vesAmount / paralela) : 0

        return GastoTrace(
            gasto: gasto,
            vesLegs: vesLegs,
            totalUsdCost: totalUsd,
            effRate: eff,
            paralela: paralela,
            diffVsParalela: diff
        )
    }

    // ─── Rate snapshot ──────────────────────────────────────────────────────

    func updateRate(bcv: Double, paralela: Double) throws {
        let prev = latestRateSnapshot()?.paralela ?? paralela
        let prevPct: Double = {
            guard prev > 0 else { return 0 }
            return (paralela - prev) / prev * 100
        }()
        let snap = RateSnapshot(
            capturedAt: .now,
            bcv: bcv, paralela: paralela,
            paralelaPrev: prev, spreadPrevPct: prevPct
        )
        context.insert(snap)
        try context.save()
    }

    func jitterRates() {
        guard let r = latestRateSnapshot() else { return }
        let cur = r.paralela
        let jitter = Double.random(in: -0.007...0.007) * cur
        try? updateRate(bcv: r.bcv, paralela: ((cur + jitter) * 100).rounded() / 100)
    }

    // ─── Helpers ────────────────────────────────────────────────────────────

    private func nextSeq<T: PersistentModel>(
        for _: T.Type,
        key: KeyPath<T, Int>
    ) -> Int {
        guard let rows = try? context.fetch(FetchDescriptor<T>()) else { return 1 }
        let maxVal = rows.map { $0[keyPath: key] }.max() ?? 0
        return maxVal + 1
    }
}

// ─── Allocation preview structs (transient, not persisted) ─────────────────

struct VESLotAllocationPreview: Identifiable {
    let sourceLot: USDTLot
    let usdtAmount: Double
    let usdAmount: Double
    var id: UUID { sourceLot.id }
}

struct GastoAllocationPreview: Identifiable {
    let sourceLot: VESLot
    let vesAmount: Double
    let usdAmount: Double
    var id: UUID { sourceLot.id }
}

enum VaultError: LocalizedError {
    case insufficientUsdt(needed: Double, available: Double)
    case insufficientVes(needed: Double, available: Double)

    var errorDescription: String? {
        switch self {
        case .insufficientUsdt(let n, let a):
            return "USDT insuficiente. Necesitas ₮ \(vFmt(n)) pero solo tienes ₮ \(vFmt(a))."
        case .insufficientVes(let n, let a):
            return "VES insuficiente. Necesitas Bs \(vFmt(n)) pero solo tienes Bs \(vFmt(a))."
        }
    }
}
