import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel

    init(engine: VaultEngine) {
        _viewModel = State(initialValue: DashboardViewModel(engine: engine))
    }

    var body: some View {
        @Bindable var vm = viewModel
        return ScrollView {
            LazyVStack(spacing: 10) {
                DashboardHeader(vm: viewModel)

                MonthSummaryCard(vm: viewModel)

                if !viewModel.missingRates.isEmpty {
                    MissingRatesWarning(missing: viewModel.missingRates, base: viewModel.baseCurrency)
                }

                AccountsSection(accounts: viewModel.accounts)

                if !viewModel.recentMovements.isEmpty {
                    RecentMovementsCard(transactions: viewModel.recentMovements)
                }

                NewOperationButton(action: viewModel.openNuevaOp)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background { VaultBackground() }
        .sheet(isPresented: $vm.showNuevaOpSheet) {
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
                    Text("[ ").foregroundStyle(Color.vTx3)
                    Text("VAULT").foregroundStyle(Color.vAcc)
                    Text(" ]").foregroundStyle(Color.vTx3)
                }
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .tracking(2)
                Spacer()
                Text(Self.dateFmt.string(from: .now).uppercased())
                    .vLabel(size: 9, color: .vTx3)
            }

            TerminalSeparator(style: .heavy).padding(.vertical, 11)

            HStack(alignment: .firstTextBaseline) {
                Text("PATRIMONIO TOTAL").vLabel()
                Spacer()
                Text(vm.baseCurrency.code).vLabel(color: .vAcc)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(vm.baseCurrency.symbol)
                    .font(.system(size: 30, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.vTx2)
                AnimatedCounter(
                    value: vm.totalNetWorth,
                    dec: vm.baseCurrency.defaultDecimals,
                    size: 42,
                    color: vm.totalNetWorth < 0 ? .vDanger : .vAcc
                )
            }
            .padding(.top, 6)

            HStack(spacing: 4) {
                Text("\(vm.accounts.count) CUENTAS").vLabel(size: 9, color: .vTx3)
                if !vm.missingRates.isEmpty {
                    Text("·").vLabel(size: 9, color: .vTx3)
                    Text("\(vm.missingRates.count) MONEDA(S) SIN TASA")
                        .vLabel(size: 9, color: .vAmber)
                }
            }
            .padding(.top, 6)
        }
        .padding(16)
        .glassCard()
    }

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM yyyy"
        f.locale = Locale(identifier: "es_ES")
        return f
    }()
}

struct MonthSummaryCard: View {
    let vm: DashboardViewModel

    var body: some View {
        let base = vm.baseCurrency

        VStack(spacing: 0) {
            HStack {
                Text("ESTE MES").vLabel(color: .vTx2)
                Spacer()
                Text(Self.monthFmt.string(from: .now).uppercased())
                    .vLabel(size: 9, color: .vTx3)
            }
            TerminalSeparator(style: .dashed).padding(.vertical, 9)

            HStack(spacing: 14) {
                MonthMetric(label: "INGRESOS", value: vm.monthIncome, currency: base, color: .vAcc)
                Rectangle().fill(Color.vLine).frame(width: 1)
                MonthMetric(label: "GASTOS", value: vm.monthExpense, currency: base, color: .vDanger)
                Rectangle().fill(Color.vLine).frame(width: 1)
                MonthMetric(
                    label: "BALANCE",
                    value: vm.monthBalance,
                    currency: base,
                    color: vm.monthBalance >= 0 ? .vAcc : .vDanger
                )
            }
        }
        .padding(14)
        .solidCard()
    }

    private static let monthFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        f.locale = Locale(identifier: "es_ES")
        return f
    }()
}

private struct MonthMetric: View {
    let label: String
    let value: Double
    let currency: Currency
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).vLabel(size: 9)
            BalanceBadge(amount: value, currency: currency, color: color, size: 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AccountsSection: View {
    let accounts: [Account]

    var body: some View {
        if accounts.isEmpty {
            EmptyAccountsCard()
        } else {
            ForEach(accounts) { account in
                AccountCardView(account: account)
            }
        }
    }
}

private struct EmptyAccountsCard: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("◌")
                .font(.system(size: 28, design: .monospaced))
                .foregroundStyle(Color.vTx3)
            Text("SIN CUENTAS").vLabel(color: .vTx2)
            Text("// AÑADE TU PRIMERA CUENTA").vLabel(size: 9, color: .vTx3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .solidCard()
    }
}

private struct RecentMovementsCard: View {
    let transactions: [Transaction]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ÚLTIMOS MOVIMIENTOS").vLabel(color: .vTx2)
                Spacer()
            }
            TerminalSeparator(style: .dashed).padding(.vertical, 9)
            ForEach(transactions) { tx in
                HStack(alignment: .center, spacing: 10) {
                    Text(tx.kind == .expense ? "▼" : "▲")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(tx.kind == .expense ? Color.vDanger : Color.vAcc)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(tx.merchant)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.vTx1)
                            .lineLimit(1)
                        Text("\(tx.account?.name ?? "—") · \(tx.displayDate)")
                            .vLabel(size: 9, color: .vTx3)
                    }
                    Spacer()
                    BalanceBadge(
                        amount: tx.amount,
                        currency: tx.currency,
                        color: tx.kind == .expense ? .vDanger : .vAcc,
                        size: 13
                    )
                }
                .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .solidCard()
    }
}

private struct MissingRatesWarning: View {
    let missing: [Currency]
    let base: Currency

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.vAmber)
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 3) {
                Text("TASAS PENDIENTES").vLabel(color: .vAmber)
                Text("Configura la tasa para \(missing.map(\.code).joined(separator: ", ")) en Config → Tasas para que el patrimonio total incluya esos saldos.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.vTx2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(12)
        .glassCard(border: Color.vAmber.opacity(0.35))
    }
}

struct NewOperationButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                Text("NUEVA OPERACIÓN")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(1)
            }
            .foregroundStyle(Color.vBg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.vAcc, in: RoundedRectangle(cornerRadius: 6))
        }
    }
}
