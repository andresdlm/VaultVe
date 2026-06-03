import Foundation
import SwiftData

// USD income deposited in the US bank account (e.g., salary).
// The available USD balance = total income − total USD spent on USDT lots.
@Model
final class USDIncome {
    var id: UUID = UUID()
    var date: Date = Date()
    var sequenceNumber: Int = 0

    var amount: Double = 0
    var source: String = "Salario"
    var note: String? = nil

    init(
        id: UUID = UUID(),
        date: Date = .now,
        sequenceNumber: Int,
        amount: Double,
        source: String = "Salario",
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.sequenceNumber = sequenceNumber
        self.amount = amount
        self.source = source
        self.note = note
    }

    var displayId: String { String(format: "%04d", sequenceNumber) }
    var displayDate: String { USDTLot.fmt.string(from: date) }
}
