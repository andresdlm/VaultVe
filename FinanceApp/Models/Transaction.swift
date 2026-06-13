import Foundation
import SwiftData

// An expense or income against a single account.
// `amount` is always positive; sign is implied by `kind`.
@Model
final class Transaction {
    var id: UUID = UUID()
    var sequenceNumber: Int = 0
    var date: Date = Date()
    var kindRaw: String = TransactionKind.expense.rawValue
    var amount: Double = 0
    var currencyRaw: String = Currency.usd.rawValue
    var merchant: String = ""
    var note: String? = nil

    var account: Account? = nil
    var category: Category? = nil

    init(
        id: UUID = UUID(),
        sequenceNumber: Int = 0,
        date: Date = .now,
        kind: TransactionKind = .expense,
        amount: Double = 0,
        currency: Currency = .usd,
        merchant: String = "",
        note: String? = nil,
        account: Account? = nil,
        category: Category? = nil
    ) {
        self.id = id
        self.sequenceNumber = sequenceNumber
        self.date = date
        self.kindRaw = kind.rawValue
        self.amount = amount
        self.currencyRaw = currency.rawValue
        self.merchant = merchant
        self.note = note
        self.account = account
        self.category = category
    }

    var kind: TransactionKind { TransactionKind(rawValue: kindRaw) ?? .expense }
    var currency: Currency { Currency.from(raw: currencyRaw) }

    var displayId: String { String(format: "%04d", sequenceNumber) }
    var displayDate: String { Self.fmt.string(from: date) }

    static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
