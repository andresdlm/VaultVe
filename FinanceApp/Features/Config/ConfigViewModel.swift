import Foundation
import Observation

@Observable
final class ConfigViewModel {
    private let engine: VaultEngine

    var showICloudReminder = false
    var showRateEditor     = false

    var faceIdEnabled: Bool {
        get { engine.faceIdEnabled }
        set {
            engine.faceIdEnabled = newValue
            engine.persist()
        }
    }

    var iCloudSyncEnabled: Bool {
        get { engine.iCloudSyncEnabled }
        set {
            engine.iCloudSyncEnabled = newValue
            engine.persist()
            showICloudReminder = true   // takes effect on next launch
        }
    }

    var selectedLayout: DashboardLayout {
        get { engine.dashboardLayout }
        set { engine.dashboardLayout = newValue; engine.persist() }
    }

    var selectedRate: ActiveRate {
        get { engine.activeRateKey }
        set { engine.activeRateKey = newValue; engine.persist() }
    }

    var currentRates: ExchangeRates { engine.rates }

    func updateRates(bcv: Double, paralela: Double) {
        engine.updateRates(bcv: bcv, paralela: paralela)
    }

    init(engine: VaultEngine) {
        self.engine = engine
    }
}
