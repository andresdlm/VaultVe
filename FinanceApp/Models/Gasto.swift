import Foundation
import SwiftData

// A VES expense. May be paid from multiple VES lots (FIFO).
@Model
final class Gasto {
    var id: UUID = UUID()
    var date: Date = Date()
    var sequenceNumber: Int = 0

    var merchant: String = ""
    var category: String = "Otros"
    var vesAmount: Double = 0
    var note: String? = nil

    @Relationship(deleteRule: .cascade, inverse: \VESAllocation.gasto)
    var allocations: [VESAllocation]? = []

    init(
        id: UUID = UUID(),
        date: Date = .now,
        sequenceNumber: Int,
        merchant: String,
        category: String = "Otros",
        vesAmount: Double,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.sequenceNumber = sequenceNumber
        self.merchant = merchant
        self.category = category
        self.vesAmount = vesAmount
        self.note = note
    }

    var totalUsdCost: Double { (allocations ?? []).reduce(0) { $0 + $1.usdAmount } }
    var effRate:      Double { totalUsdCost > 0 ? vesAmount / totalUsdCost : 0 }

    var displayId: String { String(format: "%04d", sequenceNumber) }
    var displayDate: String { Gasto.dayFmt.string(from: date) }

    static let dayFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

// One slice of VES taken from a VESLot to pay for a Gasto.
// usdAmount is captured at allocation time = vesAmount * sourceLot.costPerVes.
@Model
final class VESAllocation {
    var id: UUID = UUID()
    var vesAmount: Double = 0
    var usdAmount: Double = 0

    var sourceLot: VESLot? = nil
    var gasto: Gasto? = nil

    init(
        id: UUID = UUID(),
        vesAmount: Double,
        usdAmount: Double,
        sourceLot: VESLot,
        gasto: Gasto
    ) {
        self.id = id
        self.vesAmount = vesAmount
        self.usdAmount = usdAmount
        self.sourceLot = sourceLot
        self.gasto = gasto
    }
}
