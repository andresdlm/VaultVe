import Foundation
import Observation

@Observable
final class MovementsViewModel {
    let engine: VaultEngine

    var searchText: String = ""
    var dateRange: DateRange = .all
    var typeFilter: MovementTypeFilter = .all
    var selectedCategory: Category? = nil
    var selectedAccount: Account? = nil

    var showAddSheet: Bool = false
    var expandedId: String? = nil
    var editingTransaction: Transaction? = nil
    var editingTransfer: Transfer? = nil

    init(engine: VaultEngine) {
        self.engine = engine
    }

    var accounts: [Account] { engine.accounts }
    var allCategories: [Category] { engine.categories }

    var items: [MovementItem] {
        let lower = dateRange.lowerBound()
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()

        var result: [MovementItem] = []

        if typeFilter == .all || typeFilter == .expense || typeFilter == .income {
            for tx in engine.transactions {
                if let lower, tx.date < lower { continue }
                if typeFilter == .expense && tx.kind != .expense { continue }
                if typeFilter == .income && tx.kind != .income { continue }
                if let cat = selectedCategory, tx.category?.id != cat.id { continue }
                if let acc = selectedAccount, tx.account?.id != acc.id { continue }
                if !query.isEmpty {
                    let haystack = "\(tx.merchant) \(tx.category?.name ?? "") \(tx.note ?? "")".lowercased()
                    if !haystack.contains(query) { continue }
                }
                result.append(.transaction(tx))
            }
        }

        if typeFilter == .all || typeFilter == .transfer {
            for tr in engine.transfers {
                if let lower, tr.date < lower { continue }
                if selectedCategory != nil { continue }
                if let acc = selectedAccount,
                   tr.sourceAccount?.id != acc.id, tr.destAccount?.id != acc.id { continue }
                if !query.isEmpty {
                    let haystack = "\(tr.sourceAccount?.name ?? "") \(tr.destAccount?.name ?? "") \(tr.note ?? "")".lowercased()
                    if !haystack.contains(query) { continue }
                }
                result.append(.transfer(tr))
            }
        }

        return result.sorted { $0.date > $1.date }
    }

    var visibleCount: Int { items.count }

    var hasActiveFilters: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
            || dateRange != .all
            || typeFilter != .all
            || selectedCategory != nil
            || selectedAccount != nil
    }

    func clearFilters() {
        searchText = ""
        dateRange = .all
        typeFilter = .all
        selectedCategory = nil
        selectedAccount = nil
    }

    func toggleExpand(_ id: String) {
        expandedId = expandedId == id ? nil : id
    }

    func deleteTransaction(_ tx: Transaction) {
        try? engine.deleteTransaction(tx)
    }

    func deleteTransfer(_ tr: Transfer) {
        try? engine.deleteTransfer(tr)
    }
}

enum MovementItem: Identifiable {
    case transaction(Transaction)
    case transfer(Transfer)

    var id: String {
        switch self {
        case .transaction(let t): "tx-\(t.id)"
        case .transfer(let t):    "tr-\(t.id)"
        }
    }

    var date: Date {
        switch self {
        case .transaction(let t): t.date
        case .transfer(let t):    t.date
        }
    }
}
