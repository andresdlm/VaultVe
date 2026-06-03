import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel

    init(engine: VaultEngine) {
        _viewModel = State(initialValue: DashboardViewModel(engine: engine))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                switch viewModel.layout {
                case .stack:    DashboardConsoleStack(vm: viewModel)
                case .pipeline: DashboardPipeline(vm: viewModel)
                case .ledger:   DashboardLedger(vm: viewModel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .background { VaultBackground() }
        .sheet(isPresented: $viewModel.showNuevaOpSheet) {
            NuevaOperacionSheet()
        }
    }
}

struct DashboardHeader: View {
    let vm: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 0) {
                    Text("[").foregroundStyle(Color.vTx3)
                    Text(" VAULT").foregroundStyle(Color.vTx1)
                    Text("VE").foregroundStyle(Color.vAcc)
                    Text(" ]").foregroundStyle(Color.vTx3)
                }
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .tracking(2)
                Spacer()
                HStack(spacing: 14) {
                    Image(systemName: "gearshape")
                    Image(systemName: "person.circle")
                }
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Color.vTx2)
            }

            TerminalSeparator(style: .heavy).padding(.vertical, 11)

            HStack(alignment: .firstTextBaseline) {
                Text("PATRIMONIO TOTAL").vLabel()
                Spacer()
                if vm.isRefreshing {
                    HStack(spacing: 4) {
                        Text("SINCRONIZANDO").vLabel(color: .vAcc)
                        BlinkingCursor(color: .vAcc, height: 10)
                    }
                } else {
                    Text("LIVE").vLabel(color: .vAcc)
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("$")
                    .font(.system(size: 36, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.vTx2)
                AnimatedCounter(value: vm.patrimonioUsd, dec: 2, size: 46, color: .vAcc)
                Text("USD").vLabel().padding(.bottom, 7)
            }
            .padding(.top, 6)

            HStack(spacing: 5) {
                Text("≈").vLabel(color: .vTx3)
                AnimatedCounter(value: vm.patrimonioVes, dec: 2, prefix: "Bs ", size: 13, color: .vTx2, weight: .medium)
                Text("a tasa \(vm.activeRateKey.label)").vLabel(size: 9)
            }
            .padding(.top, 5)
        }
        .padding(16)
        .glassCard()
    }
}

struct DashboardHeaderCompact: View {
    let vm: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 0) {
                    Text("[").foregroundStyle(Color.vTx3)
                    Text(" VAULT").foregroundStyle(Color.vTx1)
                    Text("VE").foregroundStyle(Color.vAcc)
                    Text(" ]").foregroundStyle(Color.vTx3)
                }
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .tracking(2)
                Spacer()
                HStack(spacing: 14) {
                    Image(systemName: "gearshape")
                    Image(systemName: "person.circle")
                }
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Color.vTx2)
            }

            TerminalSeparator(style: .heavy).padding(.vertical, 9)

            HStack(alignment: .firstTextBaseline) {
                Text("PATRIMONIO TOTAL").vLabel()
                Spacer()
                if vm.isRefreshing {
                    HStack(spacing: 4) {
                        Text("SINCRONIZANDO").vLabel(color: .vAcc)
                        BlinkingCursor(color: .vAcc, height: 10)
                    }
                } else {
                    Text("LIVE").vLabel(color: .vAcc)
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("$")
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.vTx2)
                AnimatedCounter(value: vm.patrimonioUsd, dec: 2, size: 30, color: .vAcc)
                Text("USD").vLabel().padding(.bottom, 4)
            }
            .padding(.top, 4)

            HStack(spacing: 5) {
                Text("≈").vLabel(color: .vTx3)
                AnimatedCounter(value: vm.patrimonioVes, dec: 2, prefix: "Bs ", size: 12, color: .vTx2, weight: .medium)
                Text("a tasa \(vm.activeRateKey.label)").vLabel(size: 9)
            }
            .padding(.top, 4)
        }
        .padding(13)
        .glassCard()
    }
}
