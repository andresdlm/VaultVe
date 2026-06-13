import Foundation
import SwiftData

// Conversion factor from a currency to the configured base currency.
// `unitsPerBase` = "units of this currency that equal 1 unit of base".
// Example: base = USD, this currency = VES, unitsPerBase = 41.85 → 41.85 Bs = 1 USD.
@Model
final class ExchangeRate {
    var id: UUID = UUID()
    var currencyRaw: String = Currency.usd.rawValue
    var unitsPerBase: Double = 0
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        currency: Currency = .usd,
        unitsPerBase: Double = 0,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.currencyRaw = currency.rawValue
        self.unitsPerBase = unitsPerBase
        self.updatedAt = updatedAt
    }

    var currency: Currency { Currency.from(raw: currencyRaw) }
}
