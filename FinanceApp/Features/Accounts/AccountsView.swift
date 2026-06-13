import SwiftUI

struct AccountsView: View {
    @State private var viewModel: AccountsViewModel

    init(engine: VaultEngine) {
        _viewModel = State(initialValue: AccountsViewModel(engine: engine))
    }

    var body: some View {
        @Bindable var vm = viewModel
        return ScrollView {
            VStack(spacing: 8) {
                HStack(alignment: .top) {
                    ScreenTitle(
                        title: "Cuentas",
                        sub: "\(viewModel.accounts.count) CUENTA(S) · TOCA PARA DETALLE"
                    )
                    AddGlassButton(label: "Agregar cuenta") {
                        viewModel.showAddAccount = true
                    }
                }
                .padding(.bottom, 4)

                HStack {
                    Text("MOSTRAR ARCHIVADAS").vLabel(size: 9, color: .vTx3)
                    Spacer()
                    Button {
                        viewModel.showArchived.toggle()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text("[\(viewModel.showArchived ? "■" : " ")] \(viewModel.showArchived ? "ON" : "OFF")")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(viewModel.showArchived ? Color.vAcc : Color.vTx3)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 6)

                if viewModel.accounts.isEmpty {
                    EmptyAccountsState(onAdd: { viewModel.showAddAccount = true })
                } else {
                    ForEach(viewModel.accounts) { account in
                        NavigationButton {
                            viewModel.editingAccount = account
                        } content: {
                            AccountCardView(account: account)
                                .opacity(account.archived ? 0.55 : 1)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background { VaultBackground() }
        .sheet(isPresented: $vm.showAddAccount) {
            AddAccountForm()
        }
        .sheet(item: $vm.editingAccount) { account in
            AccountDetailView(account: account, engine: viewModel.engine)
        }
    }
}

struct AddGlassButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.vAcc)
                .frame(width: 40, height: 40)
                .glassCard(border: Color.vAcc.opacity(0.30))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct NavigationButton<C: View>: View {
    let action: () -> Void
    @ViewBuilder let content: () -> C

    var body: some View {
        Button(action: action) {
            content()
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyAccountsState: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("◌")
                .font(.system(size: 28, design: .monospaced))
                .foregroundStyle(Color.vTx3)
            Text("SIN CUENTAS").vLabel(color: .vTx2)
            Text("// AÑADE TU PRIMERA CUENTA").vLabel(size: 9, color: .vTx3)
            Button(action: onAdd) {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 10, weight: .bold))
                    Text("NUEVA CUENTA").vLabel(size: 9, color: .vAcc)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(Color.vAcc.opacity(0.45), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .solidCard()
    }
}
