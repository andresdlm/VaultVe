import Foundation
import SwiftData

// User-defined account holding a balance in a specific currency.
// Balance is derived: initialBalance + sum(income) - sum(expense)
//                    - sum(transfersOut.sourceAmount) + sum(transfersIn.destAmount)
@Model
final class Account {
    var id: UUID = UUID()
    var name: String = ""
    var currencyRaw: String = Currency.usd.rawValue
    var kindRaw: String = AccountKind.bank.rawValue
    var glyph: String = "◉"
    var colorHex: String = "00FF88"
    var initialBalance: Double = 0
    var note: String? = nil
    var archived: Bool = false
    var createdAt: Date = Date()
    var sortIndex: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction]? = []

    @Relationship(deleteRule: .cascade, inverse: \Transfer.sourceAccount)
    var transfersOut: [Transfer]? = []

    @Relationship(deleteRule: .cascade, inverse: \Transfer.destAccount)
    var transfersIn: [Transfer]? = []

    init(
        id: UUID = UUID(),
        name: String = "",
        currency: Currency = .usd,
        kind: AccountKind = .bank,
        glyph: String = "◉",
        colorHex: String = "00FF88",
        initialBalance: Double = 0,
        note: String? = nil,
        archived: Bool = false,
        createdAt: Date = .now,
        sortIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.currencyRaw = currency.rawValue
        self.kindRaw = kind.rawValue
        self.glyph = glyph
        self.colorHex = colorHex
        self.initialBalance = initialBalance
        self.note = note
        self.archived = archived
        self.createdAt = createdAt
        self.sortIndex = sortIndex
    }

    var currency: Currency { Currency.from(raw: currencyRaw) }
    var kind: AccountKind { AccountKind(rawValue: kindRaw) ?? .bank }

    // Current balance in this account's native currency.
    var balance: Double {
        let txs = transactions ?? []
        let income = txs.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount }
        let expense = txs.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
        let out = (transfersOut ?? []).reduce(0) { $0 + $1.sourceAmount }
        let inn = (transfersIn ?? []).reduce(0) { $0 + $1.destAmount }
        return initialBalance + income - expense - out + inn
    }
}
