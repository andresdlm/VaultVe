import Foundation
import SwiftData

// USD → USDT lot. One row per P2P purchase of USDT with USD from the bank.
@Model
final class USDTLot {
    var id: UUID = UUID()
    var date: Date = Date()
    var sequenceNumber: Int = 0      // display "LOTE #0034"

    var usdSent: Double = 0          // USD debited from the bank
    var usdtReceived: Double = 0     // USDT credited to the wallet
    var feeUsd: Double = 0           // fee captured in USD (informational)
    var note: String? = nil

    // Outgoing allocations: this lot has fed N VES lots.
    @Relationship(deleteRule: .cascade, inverse: \USDTAllocation.sourceLot)
    var allocations: [USDTAllocation]? = []

    init(
        id: UUID = UUID(),
        date: Date = .now,
        sequenceNumber: Int,
        usdSent: Double,
        usdtReceived: Double,
        feeUsd: Double = 0,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.sequenceNumber = sequenceNumber
        self.usdSent = usdSent
        self.usdtReceived = usdtReceived
        self.feeUsd = feeUsd
        self.note = note
    }

    var costPerUsdt: Double { usdtReceived > 0 ? usdSent / usdtReceived : 0 }
    var feePercent:  Double { usdSent > 0 ? feeUsd / usdSent * 100 : 0 }

    var usdtConsumed:  Double { (allocations ?? []).reduce(0) { $0 + $1.usdtAmount } }
    var usdtRemaining: Double { max(0, usdtReceived - usdtConsumed) }

    var displayId: String { String(format: "%04d", sequenceNumber) }
    var displayDate: String { Self.fmt.string(from: date) }

    static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()
}

// USDT → VES lot. One row per P2P sale of USDT to receive VES.
// A single sale may pull USDT from multiple USDTLots (FIFO).
@Model
final class VESLot {
    var id: UUID = UUID()
    var date: Date = Date()
    var sequenceNumber: Int = 0

    var usdtSent: Double = 0       // total USDT taken from inventory for this sale
    var vesReceived: Double = 0    // VES received from the buyer
    var note: String? = nil

    // Incoming: which USDT lots fed this sale.
    @Relationship(deleteRule: .cascade, inverse: \USDTAllocation.vesLot)
    var allocations: [USDTAllocation]? = []

    // Outgoing: VES from this sale has been spent on N gastos.
    @Relationship(deleteRule: .cascade, inverse: \VESAllocation.sourceLot)
    var consumptions: [VESAllocation]? = []

    init(
        id: UUID = UUID(),
        date: Date = .now,
        sequenceNumber: Int,
        usdtSent: Double,
        vesReceived: Double,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.sequenceNumber = sequenceNumber
        self.usdtSent = usdtSent
        self.vesReceived = vesReceived
        self.note = note
    }

    var p2pRate: Double { usdtSent > 0 ? vesReceived / usdtSent : 0 }

    // True USD cost = sum of USD captured at each allocation moment.
    var totalUsdCost: Double { (allocations ?? []).reduce(0) { $0 + $1.usdAmount } }
    var costPerVes:   Double { vesReceived > 0 ? totalUsdCost / vesReceived : 0 }

    var vesConsumed:  Double { (consumptions ?? []).reduce(0) { $0 + $1.vesAmount } }
    var vesRemaining: Double { max(0, vesReceived - vesConsumed) }

    var displayId: String { String(format: "%04d", sequenceNumber) }
    var displayDate: String { USDTLot.fmt.string(from: date) }
}

// One slice of USDT taken from a USDTLot to feed a VESLot.
// The USD amount is captured at the moment of allocation — that's what makes
// the traceability immutable even if later USDT lots have different rates.
@Model
final class USDTAllocation {
    var id: UUID = UUID()
    var usdtAmount: Double = 0
    var usdAmount: Double = 0     // = usdtAmount * sourceLot.costPerUsdt at allocation time

    var sourceLot: USDTLot? = nil
    var vesLot: VESLot? = nil

    init(
        id: UUID = UUID(),
        usdtAmount: Double,
        usdAmount: Double,
        sourceLot: USDTLot,
        vesLot: VESLot
    ) {
        self.id = id
        self.usdtAmount = usdtAmount
        self.usdAmount = usdAmount
        self.sourceLot = sourceLot
        self.vesLot = vesLot
    }
}
