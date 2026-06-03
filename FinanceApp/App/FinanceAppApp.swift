import SwiftUI
import SwiftData

@main
struct FinanceAppApp: App {
    @State private var engine: VaultEngine
    private let container: ModelContainer

    init() {
        let schema = Schema([
            USDTLot.self, VESLot.self, USDTAllocation.self,
            Gasto.self, VESAllocation.self,
            USDIncome.self, RateSnapshot.self,
        ])
        let cloud = UserDefaults.standard.bool(forKey: VaultEngine.kICloudPersisted)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: cloud ? .automatic : .none
        )
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // CloudKit can fail to attach if the user toggled it without the
            // capability/entitlement. Fall back to local-only so the app launches.
            let fallback = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            container = try! ModelContainer(for: schema, configurations: [fallback])
        }
        _engine = State(initialValue: VaultEngine(context: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            BiometricGate {
                ContentView()
            }
            .environment(engine)
            .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
