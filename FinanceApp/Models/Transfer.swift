import Foundation
import SwiftData

// A movement between two accounts. When the accounts share a currency the
// `sourceAmount` and `destAmount` will typically match. When they differ,
// the implied exchange rate = destAmount / sourceAmount.
@Model
final class Transfer {
    var id: UUID = UUID()
    var sequenceNumber: Int = 0
    var date: Date = Date()

    var sourceAccount: Account? = nil
    var destAccount: Account? = nil

    var sourceAmount: Double = 0
    var destAmount: Double = 0
    var sourceCurrencyRaw: String = Currency.usd.rawValue
    var destCurrencyRaw: String = Currency.usd.rawValue

    var note: String? = nil

    init(
        id: UUID = UUID(),
        sequenceNumber: Int = 0,
        date: Date = .now,
        sourceAccount: Account? = nil,
        destAccount: Account? = nil,
        sourceAmount: Double = 0,
        destAmount: Double = 0,
        sourceCurrency: Currency = .usd,
        destCurrency: Currency = .usd,
        note: String? = nil
    ) {
        self.id = id
        self.sequenceNumber = sequenceNumber
        self.date = date
        self.sourceAccount = sourceAccount
        self.destAccount = destAccount
        self.sourceAmount = sourceAmount
        self.destAmount = destAmount
        self.sourceCurrencyRaw = sourceCurrency.rawValue
        self.destCurrencyRaw = destCurrency.rawValue
        self.note = note
    }

    var sourceCurrency: Currency { Currency.from(raw: sourceCurrencyRaw) }
    var destCurrency: Currency { Currency.from(raw: destCurrencyRaw) }

    var crossCurrency: Bool { sourceCurrencyRaw != destCurrencyRaw }
    var impliedRate: Double { sourceAmount > 0 ? destAmount / sourceAmount : 0 }

    var displayId: String { String(format: "%04d", sequenceNumber) }
    var displayDate: String { Transaction.fmt.string(from: date) }
}
