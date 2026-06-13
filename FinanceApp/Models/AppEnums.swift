import Foundation

enum TransactionKind: String, CaseIterable, Codable, Identifiable, Hashable {
    case expense, income

    var id: String { rawValue }

    var label: String {
        switch self {
        case .expense: "Gasto"
        case .income:  "Ingreso"
        }
    }

    var pluralLabel: String {
        switch self {
        case .expense: "Gastos"
        case .income:  "Ingresos"
        }
    }
}

enum AccountKind: String, CaseIterable, Codable, Identifiable, Hashable {
    case bank, cash, wallet, card, savings, investment

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bank:       "Banco"
        case .cash:       "Efectivo"
        case .wallet:     "Wallet"
        case .card:       "Tarjeta"
        case .savings:    "Ahorro"
        case .investment: "Inversión"
        }
    }

    var glyph: String {
        switch self {
        case .bank:       "◉"
        case .cash:       "▣"
        case .wallet:     "◈"
        case .card:       "▢"
        case .savings:    "⬢"
        case .investment: "◆"
        }
    }
}

// Time window used to filter the movement ledger and analytics.
enum DateRange: String, CaseIterable, Identifiable, Codable {
    case all, last7, last30, month, year

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:    "Todo"
        case .last7:  "7D"
        case .last30: "30D"
        case .month:  "Mes"
        case .year:   "Año"
        }
    }

    func lowerBound(now: Date = .now, calendar: Calendar = .current) -> Date? {
        switch self {
        case .all:    nil
        case .last7:  calendar.date(byAdding: .day, value: -7, to: now)
        case .last30: calendar.date(byAdding: .day, value: -30, to: now)
        case .month:  calendar.dateInterval(of: .month, for: now)?.start
        case .year:   calendar.dateInterval(of: .year, for: now)?.start
        }
    }
}

// Picker on the movements screen.
enum MovementTypeFilter: String, CaseIterable, Identifiable, Codable {
    case all, expense, income, transfer

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:      "Todos"
        case .expense:  "Gastos"
        case .income:   "Ingresos"
        case .transfer: "Transferencias"
        }
    }
}
