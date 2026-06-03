import Foundation
import Observation
import SwiftData
import SwiftUI

// App-level @Observable façade over VaultRepository.
// Views observe this object — never the repository directly.
// `dirtyTick` is bumped after every mutation to force SwiftUI re-reads of
// derived totals that depend on relationship traversal (SwiftData doesn't
// always re-fire @Observable for nested @Relationship changes).
@Observable
final class VaultEngine {
    let repository: VaultRepository

    var activeRateKey:     ActiveRate = .paralela
    var dashboardLayout:   DashboardLayout = .stack
    var iCloudSyncEnabled: Bool = false
    var faceIdEnabled:     Bool = true

    // Internal bump that any view can observe to invalidate cached derived state.
    private(set) var dirtyTick: Int = 0

    init(context: ModelContext) {
        self.repository = VaultRepository(context: context)
        loadPreferences()
        bootstrapIfEmpty()
    }

    // ─── Preferences in UserDefaults ────────────────────────────────────────

    private static let kActiveRate    = "vault.activeRate"
    private static let kLayout        = "vault.dashboardLayout"
    private static let kFaceId        = "vault.faceIdEnabled"
    private static let kICloud        = "vault.iCloudSyncEnabled"
    static let kICloudPersisted       = "vault.iCloudSyncEnabled"   // public for app launch

    private func loadPreferences() {
        let d = UserDefaults.standard
        if let raw = d.string(forKey: Self.kActiveRate), let v = ActiveRate(rawValue: raw) {
            activeRateKey = v
        }
        if let raw = d.string(forKey: Self.kLayout), let v = DashboardLayout(rawValue: raw) {
            dashboardLayout = v
        }
        if d.object(forKey: Self.kFaceId) != nil {
            faceIdEnabled = d.bool(forKey: Self.kFaceId)
        }
        iCloudSyncEnabled = d.bool(forKey: Self.kICloud)
    }

    func persist() {
        let d = UserDefaults.standard
        d.set(activeRateKey.rawValue, forKey: Self.kActiveRate)
        d.set(dashboardLayout.rawValue, forKey: Self.kLayout)
        d.set(faceIdEnabled, forKey: Self.kFaceId)
        d.set(iCloudSyncEnabled, forKey: Self.kICloud)
    }

    // ─── First-launch seed ──────────────────────────────────────────────────

    private func bootstrapIfEmpty() {
        let hasData =
            !repository.allUSDTLots().isEmpty ||
            !repository.allIncome().isEmpty ||
            !repository.allGastos().isEmpty
        if hasData { return }

        // Seed a plausible starting state so the app isn't empty on first launch.
        _ = try? repository.updateRate(bcv: 40.20, paralela: 41.85)
        _ = try? repository.addUSDIncome(date: .now.addingTimeInterval(-86400 * 14), amount: 1500, source: "Salario", note: nil)

        if let u1 = try? repository.addUSDTLot(date: .now.addingTimeInterval(-86400 * 12), usdSent: 150, usdtReceived: 149.78, feeUsd: 0.22, note: nil),
           let u2 = try? repository.addUSDTLot(date: .now.addingTimeInterval(-86400 * 6), usdSent: 200, usdtReceived: 199.62, feeUsd: 0.38, note: nil),
           let u3 = try? repository.addUSDTLot(date: .now.addingTimeInterval(-86400 * 2), usdSent: 100, usdtReceived: 99.87, feeUsd: 0.13, note: nil) {
            _ = (u1, u2, u3)
        }
        if let v1 = try? repository.addVESLot(date: .now.addingTimeInterval(-86400 * 11), usdtSent: 120, vesReceived: 4980, note: nil),
           let v2 = try? repository.addVESLot(date: .now.addingTimeInterval(-86400 * 5), usdtSent: 80, vesReceived: 3320.80, note: nil),
           let v3 = try? repository.addVESLot(date: .now.addingTimeInterval(-86400 * 1), usdtSent: 50, vesReceived: 2085, note: nil) {
            _ = (v1, v2, v3)
        }
        _ = try? repository.addGasto(date: .now.addingTimeInterval(-86400 * 10), merchant: "Gasolina PDV La Trinidad", category: GastoCategory.transporte.label, vesAmount: 2490, note: nil)
        _ = try? repository.addGasto(date: .now.addingTimeInterval(-86400 * 5),  merchant: "Panadería La Esquina",     category: GastoCategory.restaurantes.label, vesAmount: 830.20, note: nil)
        _ = try? repository.addGasto(date: .now.addingTimeInterval(-86400 * 4),  merchant: "Farmatodo C.C. Sambil",    category: GastoCategory.salud.label, vesAmount: 1660.40, note: nil)
        _ = try? repository.addGasto(date: .now.addingTimeInterval(-86400 * 1),  merchant: "Supermercado Excelsior Gama", category: GastoCategory.mercado.label, vesAmount: 4170, note: nil)

        dirtyTick += 1
    }

    // ─── Read-through accessors ─────────────────────────────────────────────

    var usdAvail:    Double { _ = dirtyTick; return repository.usdAvail }
    var usdtAvail:   Double { _ = dirtyTick; return repository.usdtAvail }
    var vesBalance:  Double { _ = dirtyTick; return repository.vesBalance }
    var usdtAvgCost: Double { _ = dirtyTick; return repository.usdtAvgCost }
    var vesCostPerBs: Double { _ = dirtyTick; return repository.vesCostPerBs }
    var vesInUsd:    Double { _ = dirtyTick; return repository.vesInUsd }
    var patrimonioUsd: Double { _ = dirtyTick; return repository.patrimonioUsd }
    var patrimonioVes: Double { _ = dirtyTick; return repository.patrimonioVes(rate: activeRateKey) }
    var spreadPct:   Double  { _ = dirtyTick; return repository.spreadPct }
    var activeRate:  Double {
        guard let r = repository.latestRateSnapshot() else { return 0 }
        return activeRateKey == .bcv ? r.bcv : r.paralela
    }
    var rates: ExchangeRates {
        guard let r = repository.latestRateSnapshot() else { return .placeholder }
        return ExchangeRates(
            bcv: r.bcv,
            paralela: r.paralela,
            paralelaPrev: r.paralelaPrev,
            spreadPrevPct: r.spreadPrevPct,
            date: Self.shortDateFmt.string(from: r.capturedAt)
        )
    }

    var usdtLots: [USDTLot] { _ = dirtyTick; return repository.allUSDTLots().reversed() }
    var vesLots:  [VESLot]  { _ = dirtyTick; return repository.allVESLots().reversed() }
    var gastos:   [Gasto]   { _ = dirtyTick; return repository.allGastos() }
    var incomes:  [USDIncome] { _ = dirtyTick; return repository.allIncome().reversed() }

    // ─── Mutations (the views call into these via their VMs) ────────────────

    @discardableResult
    func recordIncome(date: Date, amount: Double, source: String, note: String?) throws -> USDIncome {
        let i = try repository.addUSDIncome(date: date, amount: amount, source: source, note: note)
        dirtyTick &+= 1
        return i
    }

    @discardableResult
    func recordUSDTPurchase(date: Date, usdSent: Double, usdtReceived: Double, feeUsd: Double, note: String?) throws -> USDTLot {
        let l = try repository.addUSDTLot(date: date, usdSent: usdSent, usdtReceived: usdtReceived, feeUsd: feeUsd, note: note)
        dirtyTick &+= 1
        return l
    }

    @discardableResult
    func recordVESSale(date: Date, usdtSent: Double, vesReceived: Double, note: String?) throws -> VESLot {
        let l = try repository.addVESLot(date: date, usdtSent: usdtSent, vesReceived: vesReceived, note: note)
        dirtyTick &+= 1
        return l
    }

    @discardableResult
    func recordGasto(date: Date, merchant: String, category: String, vesAmount: Double, note: String?) throws -> Gasto {
        let g = try repository.addGasto(date: date, merchant: merchant, category: category, vesAmount: vesAmount, note: note)
        dirtyTick &+= 1
        return g
    }

    func updateRates(bcv: Double, paralela: Double) {
        try? repository.updateRate(bcv: bcv, paralela: paralela)
        dirtyTick &+= 1
    }

    func refresh() {
        repository.jitterRates()
        dirtyTick &+= 1
    }

    // ─── Trace + previews ───────────────────────────────────────────────────

    func trace(_ gasto: Gasto) -> GastoTrace {
        repository.traceGasto(gasto)
    }

    func previewVES(usdtSent: Double) -> [VESLotAllocationPreview] {
        repository.previewVESLot(usdtSent: usdtSent)
    }

    func previewGasto(vesAmount: Double) -> [GastoAllocationPreview] {
        repository.previewGasto(vesAmount: vesAmount)
    }

    private static let shortDateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd/yyyy"
        return f
    }()
}
