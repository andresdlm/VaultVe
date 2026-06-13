import SwiftUI
import Observation

@Observable
final class DashboardViewModel {
    let engine: VaultEngine
    var showNuevaOpSheet = false

    init(engine: VaultEngine) {
        self.engine = engine
    }

    var baseCurrency: Currency { engine.baseCurrency }
    var totalNetWorth: Double  { engine.totalNetWorth }
    var monthIncome:  Double   { engine.monthIncomeBase }
    var monthExpense: Double   { engine.monthExpensesBase }
    var monthBalance: Double   { engine.monthBalanceBase }
    var accounts:     [Account] { engine.accounts }
    var missingRates: [Currency] { engine.currenciesMissingRate }
    var recentMovements: [Transaction] {
        Array(engine.transactions.prefix(3))
    }

    func openNuevaOp() {
        showNuevaOpSheet = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
