import Foundation
import Observation
import SwiftData
import SwiftUI

// App-level @Observable façade over VaultRepository.
// Views observe this object via .environment(engine). Mutations bump dirtyTick
// so derived totals re-read after SwiftData relationship changes.
@Observable
final class VaultEngine {
    let repository: VaultRepository

    var baseCurrencyRaw: String = Currency.usd.rawValue
    var iCloudSyncEnabled: Bool = false
    var faceIdEnabled: Bool = true

    private(set) var dirtyTick: Int = 0

    init(context: ModelContext) {
        self.repository = VaultRepository(context: context)
        loadPreferences()
        repository.seedDefaultsIfEmpty(baseCurrency: baseCurrency)
    }

    // ─── Preferences ────────────────────────────────────────────────────────

    private static let kBaseCurrency = "vault.baseCurrency"
    private static let kFaceId       = "vault.faceIdEnabled"
    private static let kICloud       = "vault.iCloudSyncEnabled"
    static let kICloudPersisted      = "vault.iCloudSyncEnabled"
    static let kSchemaVersion        = "vault.schemaVersion"
    static let currentSchemaVersion  = "v2"

    private func loadPreferences() {
        let d = UserDefaults.standard
        if let raw = d.string(forKey: Self.kBaseCurrency),
           let _ = Currency(rawValue: raw) {
            baseCurrencyRaw = raw
        }
        if d.object(forKey: Self.kFaceId) != nil {
            faceIdEnabled = d.bool(forKey: Self.kFaceId)
        }
        iCloudSyncEnabled = d.bool(forKey: Self.kICloud)
    }

    func persist() {
        let d = UserDefaults.standard
        d.set(baseCurrencyRaw, forKey: Self.kBaseCurrency)
        d.set(faceIdEnabled, forKey: Self.kFaceId)
        d.set(iCloudSyncEnabled, forKey: Self.kICloud)
    }

    // ─── Read-through accessors ─────────────────────────────────────────────

    var baseCurrency: Currency { Currency.from(raw: baseCurrencyRaw) }

    var accounts:     [Account]     { _ = dirtyTick; return repository.allAccounts() }
    var allAccounts:  [Account]     { _ = dirtyTick; return repository.allAccounts(includingArchived: true) }
    var categories:   [Category]    { _ = dirtyTick; return repository.allCategories() }
    var transactions: [Transaction] { _ = dirtyTick; return repository.allTransactions() }
    var transfers:    [Transfer]    { _ = dirtyTick; return repository.allTransfers() }
    var rates:        [ExchangeRate]{ _ = dirtyTick; return repository.allRates() }

    func categories(of kind: TransactionKind) -> [Category] {
        _ = dirtyTick
        return repository.categories(kind: kind)
    }

    func rate(for currency: Currency) -> ExchangeRate? {
        _ = dirtyTick
        return repository.rate(for: currency)
    }

    // Convert an amount in `from` to the base currency.
    // Falls back to `nil` if the rate is missing or 0 (non-base).
    func convertToBase(_ amount: Double, from currency: Currency) -> Double? {
        if currency == baseCurrency { return amount }
        guard let r = repository.rate(for: currency), r.unitsPerBase > 0 else { return nil }
        return amount / r.unitsPerBase
    }

    // Convert from base into any currency. Returns nil when no rate yet.
    func convertFromBase(_ amount: Double, to currency: Currency) -> Double? {
        if currency == baseCurrency { return amount }
        guard let r = repository.rate(for: currency), r.unitsPerBase > 0 else { return nil }
        return amount * r.unitsPerBase
    }

    // ─── Aggregates ─────────────────────────────────────────────────────────

    // Sum of every account's balance converted to base. Accounts whose rate
    // is missing contribute 0 — surfaced separately via `accountsMissingRate`.
    var totalNetWorth: Double {
        _ = dirtyTick
        return accounts.reduce(0.0) { acc, a in
            acc + (convertToBase(a.balance, from: a.currency) ?? 0)
        }
    }

    // Returns currencies in use that have no rate set (excluding base).
    var currenciesMissingRate: [Currency] {
        let used = Set(accounts.map(\.currency)).subtracting([baseCurrency])
        return used.filter { c in
            let r = repository.rate(for: c)
            return r == nil || r!.unitsPerBase <= 0
        }.sorted { $0.code < $1.code }
    }

    var monthExpensesBase: Double { monthAggregate(.expense) }
    var monthIncomeBase:   Double { monthAggregate(.income) }
    var monthBalanceBase:  Double { monthIncomeBase - monthExpensesBase }

    private func monthAggregate(_ kind: TransactionKind) -> Double {
        guard let lower = Calendar.current.dateInterval(of: .month, for: .now)?.start else { return 0 }
        return transactions
            .filter { $0.kind == kind && $0.date >= lower }
            .reduce(0.0) { acc, tx in
                acc + (convertToBase(tx.amount, from: tx.currency) ?? 0)
            }
    }

    // ─── Mutations ──────────────────────────────────────────────────────────

    @discardableResult
    func createAccount(
        name: String, currency: Currency, kind: AccountKind,
        glyph: String, colorHex: String, initialBalance: Double, note: String?
    ) throws -> Account {
        let a = try repository.createAccount(
            name: name, currency: currency, kind: kind,
            glyph: glyph, colorHex: colorHex,
            initialBalance: initialBalance, note: note
        )
        bump()
        return a
    }

    func updateAccount(
        _ account: Account,
        name: String, kind: AccountKind, glyph: String,
        colorHex: String, initialBalance: Double, note: String?
    ) throws {
        try repository.updateAccount(
            account, name: name, kind: kind, glyph: glyph,
            colorHex: colorHex, initialBalance: initialBalance, note: note
        )
        bump()
    }

    func setArchived(_ account: Account, archived: Bool) throws {
        try repository.setArchived(account, archived: archived)
        bump()
    }

    func deleteAccount(_ account: Account) throws {
        try repository.deleteAccount(account)
        bump()
    }

    @discardableResult
    func createCategory(name: String, glyph: String, colorHex: String, kind: TransactionKind) throws -> Category {
        let c = try repository.createCategory(name: name, glyph: glyph, colorHex: colorHex, kind: kind)
        bump()
        return c
    }

    func updateCategory(_ category: Category, name: String, glyph: String, colorHex: String) throws {
        try repository.updateCategory(category, name: name, glyph: glyph, colorHex: colorHex)
        bump()
    }

    func setArchived(_ category: Category, archived: Bool) throws {
        try repository.setArchived(category, archived: archived)
        bump()
    }

    func deleteCategory(_ category: Category) throws {
        try repository.deleteCategory(category)
        bump()
    }

    @discardableResult
    func recordExpense(date: Date, account: Account, amount: Double, merchant: String, category: Category?, note: String?) throws -> Transaction {
        let tx = try repository.recordTransaction(
            kind: .expense, date: date, account: account,
            amount: amount, merchant: merchant, category: category, note: note
        )
        bump()
        return tx
    }

    @discardableResult
    func recordIncome(date: Date, account: Account, amount: Double, merchant: String, category: Category?, note: String?) throws -> Transaction {
        let tx = try repository.recordTransaction(
            kind: .income, date: date, account: account,
            amount: amount, merchant: merchant, category: category, note: note
        )
        bump()
        return tx
    }

    func updateTransaction(_ tx: Transaction, date: Date, account: Account, amount: Double, merchant: String, category: Category?, note: String?) throws {
        try repository.updateTransaction(
            tx, date: date, account: account, amount: amount,
            merchant: merchant, category: category, note: note
        )
        bump()
    }

    func deleteTransaction(_ tx: Transaction) throws {
        try repository.deleteTransaction(tx)
        bump()
    }

    @discardableResult
    func recordTransfer(date: Date, source: Account, dest: Account, sourceAmount: Double, destAmount: Double, note: String?) throws -> Transfer {
        let t = try repository.recordTransfer(
            date: date, source: source, dest: dest,
            sourceAmount: sourceAmount, destAmount: destAmount, note: note
        )
        bump()
        return t
    }

    func updateTransfer(_ transfer: Transfer, date: Date, source: Account, dest: Account, sourceAmount: Double, destAmount: Double, note: String?) throws {
        try repository.updateTransfer(
            transfer, date: date, source: source, dest: dest,
            sourceAmount: sourceAmount, destAmount: destAmount, note: note
        )
        bump()
    }

    func deleteTransfer(_ transfer: Transfer) throws {
        try repository.deleteTransfer(transfer)
        bump()
    }

    @discardableResult
    func upsertRate(currency: Currency, unitsPerBase: Double) throws -> ExchangeRate {
        let r = try repository.upsertRate(currency: currency, unitsPerBase: unitsPerBase)
        bump()
        return r
    }

    func setBaseCurrency(_ currency: Currency) {
        guard currency != baseCurrency else { return }
        baseCurrencyRaw = currency.rawValue
        persist()
        try? repository.reanchorBase(currency)
        bump()
    }

    private func bump() { dirtyTick &+= 1 }
}
