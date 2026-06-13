import SwiftUI
import SwiftData

@main
struct FinanceAppApp: App {
    @State private var engine: VaultEngine
    private let container: ModelContainer

    init() {
        Self.wipeLegacyStoreIfNeeded()

        let schema = Schema([
            Account.self,
            Category.self,
            Transaction.self,
            Transfer.self,
            ExchangeRate.self,
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
            // CloudKit can fail to attach without the entitlement; fall back to local.
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

    // Drops the old VaultVE schema (USDTLot / VESLot / Gasto / etc.) on first
    // launch after upgrading to the simplified account-based model. The old
    // store only ever held dummy seed data so a clean wipe is acceptable.
    private static func wipeLegacyStoreIfNeeded() {
        let d = UserDefaults.standard
        let stored = d.string(forKey: VaultEngine.kSchemaVersion)
        guard stored != VaultEngine.currentSchemaVersion else { return }

        if let appSupport = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: false
        ) {
            for suffix in ["default.store", "default.store-shm", "default.store-wal"] {
                let url = appSupport.appendingPathComponent(suffix)
                try? FileManager.default.removeItem(at: url)
            }
        }
        d.set(VaultEngine.currentSchemaVersion, forKey: VaultEngine.kSchemaVersion)
    }
}
