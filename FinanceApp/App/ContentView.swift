import SwiftUI

enum AppTab: Hashable {
    case dashboard, accounts, movements, analytics, config
}

struct ContentView: View {
    @Environment(VaultEngine.self) private var engine
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Panel", systemImage: "rectangle.3.group", value: AppTab.dashboard) {
                DashboardView(engine: engine)
            }
            Tab("Cuentas", systemImage: "creditcard", value: AppTab.accounts) {
                AccountsView(engine: engine)
            }
            Tab("Movimientos", systemImage: "list.bullet.rectangle", value: AppTab.movements) {
                MovementsView(engine: engine)
            }
            Tab("Stats", systemImage: "chart.xyaxis.line", value: AppTab.analytics) {
                AnalyticsView(engine: engine)
            }
            Tab("Config", systemImage: "gearshape", value: AppTab.config) {
                ConfigView(engine: engine)
            }
        }
        .tint(Color.vAcc)
    }
}
