import Foundation
import Observation

@Observable
final class AnalyticsViewModel {
    let engine: VaultEngine
    var range: DateRange = .last30

    init(engine: VaultEngine) {
        self.engine = engine
    }

    var baseCurrency: Currency { engine.baseCurrency }

    var transactionsInRange: [Transaction] {
        let lower = range.lowerBound()
        return engine.transactions.filter { tx in
            if let lower, tx.date < lower { return false }
            return true
        }
    }

    var totalExpenseBase: Double {
        transactionsInRange
            .filter { $0.kind == .expense }
            .reduce(0.0) { acc, tx in
                acc + (engine.convertToBase(tx.amount, from: tx.currency) ?? 0)
            }
    }

    var totalIncomeBase: Double {
        transactionsInRange
            .filter { $0.kind == .income }
            .reduce(0.0) { acc, tx in
                acc + (engine.convertToBase(tx.amount, from: tx.currency) ?? 0)
            }
    }

    var balanceBase: Double { totalIncomeBase - totalExpenseBase }

    // ─── Gasto por categoría ─────────────────────────────────────────────────

    struct CategorySlice: Identifiable {
        let id: UUID
        let name: String
        let glyph: String
        let colorHex: String
        let amount: Double
    }

    var expenseByCategory: [CategorySlice] {
        var bucket: [UUID: (Category?, Double)] = [:]
        let unknownId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

        for tx in transactionsInRange where tx.kind == .expense {
            let base = engine.convertToBase(tx.amount, from: tx.currency) ?? 0
            let key = tx.category?.id ?? unknownId
            let existing = bucket[key] ?? (tx.category, 0)
            bucket[key] = (existing.0, existing.1 + base)
        }

        return bucket.map { id, pair in
            let (cat, total) = pair
            return CategorySlice(
                id: id,
                name: cat?.name ?? "Sin categoría",
                glyph: cat?.glyph ?? "·",
                colorHex: cat?.colorHex ?? "5A7A6E",
                amount: total
            )
        }.sorted { $0.amount > $1.amount }
    }

    // ─── Top comercios ───────────────────────────────────────────────────────

    struct MerchantSlice: Identifiable {
        let id = UUID()
        let merchant: String
        let amount: Double
        let count: Int
    }

    var topMerchants: [MerchantSlice] {
        var bucket: [String: (Double, Int)] = [:]
        for tx in transactionsInRange where tx.kind == .expense {
            let base = engine.convertToBase(tx.amount, from: tx.currency) ?? 0
            let key = tx.merchant.isEmpty ? "(sin nombre)" : tx.merchant
            let existing = bucket[key] ?? (0, 0)
            bucket[key] = (existing.0 + base, existing.1 + 1)
        }
        return bucket.map { MerchantSlice(merchant: $0.key, amount: $0.value.0, count: $0.value.1) }
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map { $0 }
    }

    // ─── Tendencia 6 meses ───────────────────────────────────────────────────

    struct MonthBucket: Identifiable {
        let id: Date
        let label: String
        let expense: Double
        let income: Double
    }

    var trend6Months: [MonthBucket] {
        let cal = Calendar.current
        let now = Date.now
        guard let thisMonthStart = cal.dateInterval(of: .month, for: now)?.start else { return [] }

        var months: [Date] = []
        for offset in (0..<6).reversed() {
            if let d = cal.date(byAdding: .month, value: -offset, to: thisMonthStart) {
                months.append(d)
            }
        }

        let allTx = engine.transactions
        return months.map { start in
            let end = cal.date(byAdding: .month, value: 1, to: start) ?? start
            var expense = 0.0
            var income = 0.0
            for tx in allTx where tx.date >= start && tx.date < end {
                let base = engine.convertToBase(tx.amount, from: tx.currency) ?? 0
                if tx.kind == .expense { expense += base } else { income += base }
            }
            return MonthBucket(
                id: start,
                label: Self.monthFmt.string(from: start).uppercased(),
                expense: expense,
                income: income
            )
        }
    }

    private static let monthFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        f.locale = Locale(identifier: "es_ES")
        return f
    }()
}
