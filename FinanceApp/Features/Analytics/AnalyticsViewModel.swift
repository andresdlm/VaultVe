import Foundation
import Observation

@Observable
final class AnalyticsViewModel {
    private let engine: VaultEngine

    var usdtAvgCost:   Double { engine.usdtAvgCost }
    var paralela:      Double { engine.rates.paralela }

    init(engine: VaultEngine) {
        self.engine = engine
    }
}
