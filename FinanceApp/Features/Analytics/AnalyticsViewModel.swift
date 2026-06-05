import Foundation
import Observation

// One expense category aggregated across all expenses.
struct CategorySlice: Identifiable {
    let category: GastoCategory
    let usd: Double      // real USD cost
    let ves: Double      // bolívares paid
    let fraction: Double // share of total spending (0...1)
    var id: String { category.rawValue }
}

// One holding account, valued in USD for comparison.
enum AccountKind: String, CaseIterable {
    case usd, usdt, ves

    var name: String {
        switch self {
        case .usd:  return "BANCO USA"
        case .usdt: return "BINANCE"
        case .ves:  return "MERCANTIL"
        }
    }
    var ticker: String {
        switch self {
        case .usd:  return "USD"
        case .usdt: return "USDT"
        case .ves:  return "VES"
        }
    }
    var glyph: String {
        switch self {
        case .usd:  return "◉"
        case .usdt: return "◈"
        case .ves:  return "▣"
        }
    }
}

struct AccountSlice: Identifiable {
    let kind: AccountKind
    let nativeLabel: String // e.g. "$ 950.00", "₮ 120.00", "Bs 4,170.00"
    let usd: Double
    let fraction: Double    // share of total holdings (0...1)
    var id: String { kind.rawValue }
}

@Observable
final class AnalyticsViewModel {
    private let engine: VaultEngine

    var usdtAvgCost: Double { engine.usdtAvgCost }
    var paralela:    Double { engine.rates.paralela }

    init(engine: VaultEngine) {
        self.engine = engine
    }

    // ─── Salary / spending ──────────────────────────────────────────────────

    var totalIncomeUsd: Double { engine.incomes.reduce(0) { $0 + $1.amount } }
    var totalSpentUsd:  Double { engine.gastos.reduce(0) { $0 + $1.totalUsdCost } }
    var unspentUsd:     Double { max(0, totalIncomeUsd - totalSpentUsd) }

    // Share of income already spent on expenses (0...1).
    var spentFraction: Double {
        totalIncomeUsd > 0 ? min(1, totalSpentUsd / totalIncomeUsd) : 0
    }
    var unspentFraction: Double { 1 - spentFraction }

    // ─── Spending by category (pie) ─────────────────────────────────────────

    var categorySlices: [CategorySlice] {
        let gastos = engine.gastos
        let total  = gastos.reduce(0) { $0 + $1.totalUsdCost }
        guard total > 0 else { return [] }

        var byCat: [GastoCategory: (usd: Double, ves: Double)] = [:]
        for g in gastos {
            let cat = GastoCategory.allCases.first { $0.label == g.category } ?? .otros
            var entry = byCat[cat] ?? (0, 0)
            entry.usd += g.totalUsdCost
            entry.ves += g.vesAmount
            byCat[cat] = entry
        }

        return byCat
            .map { CategorySlice(category: $0.key, usd: $0.value.usd, ves: $0.value.ves, fraction: $0.value.usd / total) }
            .sorted { $0.usd > $1.usd }
    }

    // ─── Accounts (holdings) ─────────────────────────────────────────────────

    var accountSlices: [AccountSlice] {
        let usd     = engine.usdAvail
        let usdtUsd = engine.usdtAvail * engine.usdtAvgCost
        let vesUsd  = engine.vesInUsd
        let total   = usd + usdtUsd + vesUsd

        let raw: [(AccountKind, Double, String)] = [
            (.usd,  usd,     "$ \(vFmt(usd))"),
            (.usdt, usdtUsd, "₮ \(vFmt(engine.usdtAvail))"),
            (.ves,  vesUsd,  "Bs \(vFmt(engine.vesBalance))")
        ]

        return raw.map {
            AccountSlice(
                kind: $0.0,
                nativeLabel: $0.2,
                usd: $0.1,
                fraction: total > 0 ? $0.1 / total : 0
            )
        }
    }

    var totalAccountsUsd: Double { engine.patrimonioUsd }
}
