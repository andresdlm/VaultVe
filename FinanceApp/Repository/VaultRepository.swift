import Foundation
import SwiftData

// Pure data store. CRUD over accounts, categories, transactions, transfers,
// and exchange rates plus the derived aggregates the UI consumes.
// No SwiftUI imports, no observable state.
final class VaultRepository {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // ─── Queries ────────────────────────────────────────────────────────────

    func allAccounts(includingArchived: Bool = false) -> [Account] {
        let descriptor = FetchDescriptor<Account>(
            sortBy: [SortDescriptor(\.sortIndex), SortDescriptor(\.createdAt)]
        )
        let rows = (try? context.fetch(descriptor)) ?? []
        return includingArchived ? rows : rows.filter { !$0.archived }
    }

    func allCategories(includingArchived: Bool = false) -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.sortIndex), SortDescriptor(\.name)]
        )
        let rows = (try? context.fetch(descriptor)) ?? []
        return includingArchived ? rows : rows.filter { !$0.archived }
    }

    func categories(kind: TransactionKind) -> [Category] {
        allCategories().filter { $0.kind == kind }
    }

    func allTransactions() -> [Transaction] {
        (try? context.fetch(FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        ))) ?? []
    }

    func allTransfers() -> [Transfer] {
        (try? context.fetch(FetchDescriptor<Transfer>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        ))) ?? []
    }

    func allRates() -> [ExchangeRate] {
        (try? context.fetch(FetchDescriptor<ExchangeRate>())) ?? []
    }

    func rate(for currency: Currency) -> ExchangeRate? {
        allRates().first { $0.currency == currency }
    }

    // ─── Mutations: Account ─────────────────────────────────────────────────

    @discardableResult
    func createAccount(
        name: String,
        currency: Currency,
        kind: AccountKind,
        glyph: String,
        colorHex: String,
        initialBalance: Double,
        note: String?
    ) throws -> Account {
        let nextSort = (allAccounts(includingArchived: true).map(\.sortIndex).max() ?? -1) + 1
        let account = Account(
            name: name,
            currency: currency,
            kind: kind,
            glyph: glyph,
            colorHex: colorHex,
            initialBalance: initialBalance,
            note: note,
            sortIndex: nextSort
        )
        context.insert(account)
        try context.save()
        return account
    }

    func updateAccount(
        _ account: Account,
        name: String,
        kind: AccountKind,
        glyph: String,
        colorHex: String,
        initialBalance: Double,
        note: String?
    ) throws {
        // currency is intentionally NOT mutable: changing it would invalidate
        // every existing transaction's currencyRaw snapshot.
        account.name = name
        account.kindRaw = kind.rawValue
        account.glyph = glyph
        account.colorHex = colorHex
        account.initialBalance = initialBalance
        account.note = note
        try context.save()
    }

    func setArchived(_ account: Account, archived: Bool) throws {
        account.archived = archived
        try context.save()
    }

    func deleteAccount(_ account: Account) throws {
        context.delete(account)
        try context.save()
    }

    // ─── Mutations: Category ────────────────────────────────────────────────

    @discardableResult
    func createCategory(
        name: String,
        glyph: String,
        colorHex: String,
        kind: TransactionKind
    ) throws -> Category {
        let nextSort = (allCategories(includingArchived: true).map(\.sortIndex).max() ?? -1) + 1
        let category = Category(
            name: name,
            glyph: glyph,
            colorHex: colorHex,
            kind: kind,
            isDefault: false,
            sortIndex: nextSort
        )
        context.insert(category)
        try context.save()
        return category
    }

    func updateCategory(_ category: Category, name: String, glyph: String, colorHex: String) throws {
        category.name = name
        category.glyph = glyph
        category.colorHex = colorHex
        try context.save()
    }

    func setArchived(_ category: Category, archived: Bool) throws {
        category.archived = archived
        try context.save()
    }

    func deleteCategory(_ category: Category) throws {
        guard !category.isDefault else { throw VaultError.cannotDeleteDefault }
        context.delete(category)
        try context.save()
    }

    // ─── Mutations: Transaction ─────────────────────────────────────────────

    @discardableResult
    func recordTransaction(
        kind: TransactionKind,
        date: Date,
        account: Account,
        amount: Double,
        merchant: String,
        category: Category?,
        note: String?
    ) throws -> Transaction {
        precondition(amount > 0, "transaction amount must be positive")
        let seq = nextSeq(for: Transaction.self, key: \.sequenceNumber)
        let tx = Transaction(
            sequenceNumber: seq,
            date: date,
            kind: kind,
            amount: amount,
            currency: account.currency,
            merchant: merchant,
            note: note,
            account: account,
            category: category
        )
        context.insert(tx)
        try context.save()
        return tx
    }

    func updateTransaction(
        _ tx: Transaction,
        date: Date,
        account: Account,
        amount: Double,
        merchant: String,
        category: Category?,
        note: String?
    ) throws {
        precondition(amount > 0, "transaction amount must be positive")
        tx.date = date
        tx.account = account
        tx.amount = amount
        // Currency follows the (possibly new) account, since changing accounts
        // can cross currency boundaries.
        tx.currencyRaw = account.currencyRaw
        tx.merchant = merchant
        tx.category = category
        tx.note = note
        try context.save()
    }

    func deleteTransaction(_ tx: Transaction) throws {
        context.delete(tx)
        try context.save()
    }

    // ─── Mutations: Transfer ────────────────────────────────────────────────

    @discardableResult
    func recordTransfer(
        date: Date,
        source: Account,
        dest: Account,
        sourceAmount: Double,
        destAmount: Double,
        note: String?
    ) throws -> Transfer {
        precondition(sourceAmount > 0 && destAmount > 0, "transfer amounts must be positive")
        guard source.id != dest.id else { throw VaultError.transferSameAccount }
        let seq = nextSeq(for: Transfer.self, key: \.sequenceNumber)
        let transfer = Transfer(
            sequenceNumber: seq,
            date: date,
            sourceAccount: source,
            destAccount: dest,
            sourceAmount: sourceAmount,
            destAmount: destAmount,
            sourceCurrency: source.currency,
            destCurrency: dest.currency,
            note: note
        )
        context.insert(transfer)
        try context.save()
        return transfer
    }

    func updateTransfer(
        _ transfer: Transfer,
        date: Date,
        source: Account,
        dest: Account,
        sourceAmount: Double,
        destAmount: Double,
        note: String?
    ) throws {
        precondition(sourceAmount > 0 && destAmount > 0, "transfer amounts must be positive")
        guard source.id != dest.id else { throw VaultError.transferSameAccount }
        transfer.date = date
        transfer.sourceAccount = source
        transfer.destAccount = dest
        transfer.sourceAmount = sourceAmount
        transfer.destAmount = destAmount
        transfer.sourceCurrencyRaw = source.currencyRaw
        transfer.destCurrencyRaw = dest.currencyRaw
        transfer.note = note
        try context.save()
    }

    func deleteTransfer(_ transfer: Transfer) throws {
        context.delete(transfer)
        try context.save()
    }

    // ─── Mutations: ExchangeRate ────────────────────────────────────────────

    @discardableResult
    func upsertRate(currency: Currency, unitsPerBase: Double) throws -> ExchangeRate {
        if let existing = rate(for: currency) {
            existing.unitsPerBase = unitsPerBase
            existing.updatedAt = .now
            try context.save()
            return existing
        } else {
            let new = ExchangeRate(currency: currency, unitsPerBase: unitsPerBase, updatedAt: .now)
            context.insert(new)
            try context.save()
            return new
        }
    }

    // ─── Bootstrap (idempotent) ─────────────────────────────────────────────

    func seedDefaultsIfEmpty(baseCurrency: Currency) {
        if allCategories(includingArchived: true).isEmpty {
            seedDefaultCategories()
        }
        if allRates().isEmpty {
            seedRateSkeleton(baseCurrency: baseCurrency)
        }
    }

    private func seedDefaultCategories() {
        let expense: [(String, String, String)] = [
            ("Mercado",      "▣", "00FF88"),
            ("Restaurantes", "◆", "F0A500"),
            ("Transporte",   "▶", "00C8FF"),
            ("Salud",        "✚", "FF3B30"),
            ("Servicios",    "≣", "5A7A6E"),
            ("Hogar",        "⌂", "F0A500"),
            ("Ocio",         "◉", "00C8FF"),
            ("Educación",    "✦", "00FF88"),
            ("Otros",        "·", "5A7A6E"),
        ]
        let income: [(String, String, String)] = [
            ("Salario",   "↧", "00FF88"),
            ("Freelance", "◈", "00C8FF"),
            ("Reembolso", "↺", "F0A500"),
            ("Otros",     "·", "5A7A6E"),
        ]
        for (i, c) in expense.enumerated() {
            context.insert(Category(
                name: c.0, glyph: c.1, colorHex: c.2,
                kind: .expense, isDefault: true, sortIndex: i
            ))
        }
        for (i, c) in income.enumerated() {
            context.insert(Category(
                name: c.0, glyph: c.1, colorHex: c.2,
                kind: .income, isDefault: true, sortIndex: expense.count + i
            ))
        }
        try? context.save()
    }

    private func seedRateSkeleton(baseCurrency: Currency) {
        for c in Currency.allCases {
            let rate = ExchangeRate(
                currency: c,
                unitsPerBase: c == baseCurrency ? 1 : 0,
                updatedAt: .now
            )
            context.insert(rate)
        }
        try? context.save()
    }

    // Re-ensure the base currency has unitsPerBase = 1 (called when base changes).
    func reanchorBase(_ newBase: Currency) throws {
        for r in allRates() {
            if r.currency == newBase {
                r.unitsPerBase = 1
                r.updatedAt = .now
            }
        }
        // Insert a row for new base if it didn't exist for some reason.
        if rate(for: newBase) == nil {
            context.insert(ExchangeRate(currency: newBase, unitsPerBase: 1, updatedAt: .now))
        }
        try context.save()
    }

    // ─── Helpers ────────────────────────────────────────────────────────────

    private func nextSeq<T: PersistentModel>(
        for _: T.Type,
        key: KeyPath<T, Int>
    ) -> Int {
        guard let rows = try? context.fetch(FetchDescriptor<T>()) else { return 1 }
        return (rows.map { $0[keyPath: key] }.max() ?? 0) + 1
    }
}

enum VaultError: LocalizedError {
    case transferSameAccount
    case cannotDeleteDefault

    var errorDescription: String? {
        switch self {
        case .transferSameAccount: "La cuenta origen y destino no pueden ser la misma."
        case .cannotDeleteDefault: "No se puede borrar una categoría predeterminada. Archívala."
        }
    }
}
