import Foundation
import Observation

// Time window used to filter the expense ledger.
enum GastoTimeRange: String, CaseIterable, Identifiable {
    case all, last7, last30, month, year

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:    return "Todo"
        case .last7:  return "7D"
        case .last30: return "30D"
        case .month:  return "Mes"
        case .year:   return "Año"
        }
    }

    // Lower bound for the range, or nil when no time filter applies.
    func lowerBound(now: Date = .now, calendar: Calendar = .current) -> Date? {
        switch self {
        case .all:
            return nil
        case .last7:
            return calendar.date(byAdding: .day, value: -7, to: now)
        case .last30:
            return calendar.date(byAdding: .day, value: -30, to: now)
        case .month:
            return calendar.dateInterval(of: .month, for: now)?.start
        case .year:
            return calendar.dateInterval(of: .year, for: now)?.start
        }
    }
}

@Observable
final class GastosViewModel {
    private let engine: VaultEngine

    var expandedGastoId: UUID? = nil
    var showAddSheet = false

    // ─── Filters ────────────────────────────────────────────────────────────
    var searchText = ""
    var timeRange: GastoTimeRange = .all
    var selectedCategory: GastoCategory? = nil

    init(engine: VaultEngine) {
        self.engine = engine
    }

    private var allGastos: [Gasto] { engine.gastos }

    var gastos: [Gasto] {
        let lowerBound = timeRange.lowerBound()
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()

        return allGastos.filter { gasto in
            // Time range
            if let lowerBound, gasto.date < lowerBound { return false }

            // Category
            if let selectedCategory, gasto.category != selectedCategory.label { return false }

            // Description / merchant / note
            if !query.isEmpty {
                let haystack = "\(gasto.merchant) \(gasto.category) \(gasto.note ?? "")".lowercased()
                if !haystack.contains(query) { return false }
            }

            return true
        }
    }

    // True when any filter narrows the full ledger.
    var hasActiveFilters: Bool {
        timeRange != .all
            || selectedCategory != nil
            || !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // True when the underlying ledger has no expenses at all.
    var ledgerIsEmpty: Bool { allGastos.isEmpty }

    // Sum of VES paid across the currently visible expenses.
    var filteredVesTotal: Double { gastos.reduce(0) { $0 + $1.vesAmount } }

    func clearFilters() {
        searchText = ""
        timeRange = .all
        selectedCategory = nil
    }

    func trace(for gasto: Gasto) -> GastoTrace {
        engine.trace(gasto)
    }

    func toggleExpand(_ id: UUID) {
        expandedGastoId = expandedGastoId == id ? nil : id
    }
}
