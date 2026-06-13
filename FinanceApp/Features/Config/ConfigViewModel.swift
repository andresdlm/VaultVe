import Foundation
import Observation

@Observable
final class ConfigViewModel {
    let engine: VaultEngine

    var showICloudReminder = false
    var showRateEditor: Currency? = nil
    var showCategoriesSheet = false

    init(engine: VaultEngine) {
        self.engine = engine
    }

    var baseCurrency: Currency {
        get { engine.baseCurrency }
        set { engine.setBaseCurrency(newValue) }
    }

    var faceIdEnabled: Bool {
        get { engine.faceIdEnabled }
        set { engine.faceIdEnabled = newValue; engine.persist() }
    }

    var iCloudSyncEnabled: Bool {
        get { engine.iCloudSyncEnabled }
        set {
            engine.iCloudSyncEnabled = newValue
            engine.persist()
            showICloudReminder = true
        }
    }

    var nonBaseCurrencies: [Currency] {
        Currency.allCases.filter { $0 != baseCurrency }
    }

    func rate(for currency: Currency) -> Double {
        engine.rate(for: currency)?.unitsPerBase ?? 0
    }

    func updateRate(_ currency: Currency, unitsPerBase: Double) {
        _ = try? engine.upsertRate(currency: currency, unitsPerBase: unitsPerBase)
    }
}
