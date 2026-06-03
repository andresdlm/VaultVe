import SwiftUI
import Observation

@Observable
final class DashboardViewModel {
    private let engine: VaultEngine

    var isRefreshing       = false
    var showNuevaOpSheet   = false

    var patrimonioUsd:  Double { engine.patrimonioUsd }
    var patrimonioVes:  Double { engine.patrimonioVes }
    var usdAvail:       Double { engine.usdAvail }
    var usdtAvail:      Double { engine.usdtAvail }
    var usdtAvgCost:    Double { engine.usdtAvgCost }
    var vesBalance:     Double { engine.vesBalance }
    var vesCostPerBs:   Double { engine.vesCostPerBs }
    var vesInUsd:       Double { engine.vesInUsd }
    var spreadPct:      Double { engine.spreadPct }
    var rates:          ExchangeRates { engine.rates }
    var activeRateKey:  ActiveRate    { engine.activeRateKey }
    var layout:         DashboardLayout { engine.dashboardLayout }

    var usdtLots: [USDTLot] { engine.usdtLots }
    var vesLots:  [VESLot]  { engine.vesLots }

    init(engine: VaultEngine) {
        self.engine = engine
    }

    func refresh() async {
        isRefreshing = true
        try? await Task.sleep(for: .seconds(1.15))
        engine.refresh()
        isRefreshing = false
    }

    func openNuevaOp() {
        showNuevaOpSheet = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
