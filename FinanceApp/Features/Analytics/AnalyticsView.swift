import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel: AnalyticsViewModel

    init(engine: VaultEngine) {
        _viewModel = State(initialValue: AnalyticsViewModel(engine: engine))
    }

    var body: some View {
        @Bindable var vm = viewModel
        return ScrollView {
            VStack(spacing: 8) {
                ScreenTitle(title: "Stats", sub: "REPORTES SOBRE TU ACTIVIDAD")
                    .padding(.bottom, 4)

                RangeSelector(range: $vm.range)

                SummaryCard(vm: viewModel)

                if viewModel.expenseByCategory.isEmpty && viewModel.totalIncomeBase == 0 {
                    EmptyStatsState()
                } else {
                    CategoryBreakdownCard(vm: viewModel)
                    TrendCard(vm: viewModel)
                    if !viewModel.topMerchants.isEmpty {
                        TopMerchantsCard(vm: viewModel)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background { VaultBackground() }
    }
}

private struct RangeSelector: View {
    @Binding var range: DateRange

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(DateRange.allCases) { r in
                    ChipButton(glyph: nil, label: r.label, color: .vAcc, active: range == r) {
                        withAnimation(.easeInOut(duration: 0.2)) { range = r }
                    }
                }
            }
        }
    }
}

private struct SummaryCard: View {
    let vm: AnalyticsViewModel

    var body: some View {
        let base = vm.baseCurrency
        let balance = vm.balanceBase

        VStack(spacing: 0) {
            HStack {
                Text("RESUMEN").vLabel(color: .vTx2)
                Spacer()
                Text(vm.range.label).vLabel(size: 9, color: .vTx3)
            }
            TerminalSeparator(style: .dashed).padding(.vertical, 9)

            LoteDataRow(
                key: "INGRESOS",
                value: "\(base.symbol) \(vFmt(vm.totalIncomeBase, dec: base.defaultDecimals))",
                valueColor: .vAcc
            )
            LoteDataRow(
                key: "GASTOS",
                value: "\(base.symbol) \(vFmt(vm.totalExpenseBase, dec: base.defaultDecimals))",
                valueColor: .vDanger
            )
            TerminalSeparator(style: .dashed).padding(.vertical, 6)
            LoteDataRow(
                key: "BALANCE",
                value: "\(balance < 0 ? "−" : "+")\(base.symbol) \(vFmt(abs(balance), dec: base.defaultDecimals))",
                valueColor: balance < 0 ? .vDanger : .vAcc
            )
        }
        .padding(14)
        .solidCard()
    }
}

private struct CategoryBreakdownCard: View {
    let vm: AnalyticsViewModel

    var body: some View {
        let base = vm.baseCurrency
        let slices = vm.expenseByCategory
        let total = slices.reduce(0) { $0 + $1.amount }

        VStack(spacing: 0) {
            HStack {
                Text("GASTO POR CATEGORÍA").vLabel(color: .vTx2)
                Spacer()
                Text("\(slices.count)").vLabel(size: 9, color: .vTx3)
            }
            TerminalSeparator(style: .dashed).padding(.vertical, 9)

            if slices.isEmpty || total <= 0 {
                Text("// SIN GASTOS EN ESTE RANGO")
                    .vLabel(size: 9, color: .vTx3)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(slices) { slice in
                    let pct = total > 0 ? slice.amount / total : 0
                    CategoryBar(
                        glyph: slice.glyph,
                        name: slice.name,
                        amount: slice.amount,
                        pct: pct,
                        color: Color(hex: slice.colorHex),
                        currency: base
                    )
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(14)
        .solidCard()
    }
}

private struct CategoryBar: View {
    let glyph: String
    let name: String
    let amount: Double
    let pct: Double
    let color: Color
    let currency: Currency

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Text(glyph).font(.system(size: 11, design: .monospaced)).foregroundStyle(color)
                Text(name)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.vTx1)
                Spacer()
                Text("\(vFmt(pct * 100, dec: 0))%").vLabel(size: 9, color: .vTx3)
                BalanceBadge(amount: amount, currency: currency, color: color, size: 12)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.vLine)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.85))
                        .frame(width: proxy.size.width * pct)
                }
            }
            .frame(height: 5)
        }
    }
}

private struct TrendCard: View {
    let vm: AnalyticsViewModel

    var body: some View {
        let buckets = vm.trend6Months
        let maxVal = buckets.flatMap { [$0.expense, $0.income] }.max() ?? 0

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    Text("━").foregroundStyle(Color.vAcc)
                    Text("Ingresos").vLabel()
                }
                HStack(spacing: 4) {
                    Text("━").foregroundStyle(Color.vDanger)
                    Text("Gastos").vLabel()
                }
                Spacer()
                Text("6 MESES").vLabel(size: 9, color: .vTx3)
            }
            .padding(.bottom, 10)

            if maxVal <= 0 {
                Text("// SIN DATA HISTÓRICA TODAVÍA")
                    .vLabel(size: 9, color: .vTx3)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
            } else {
                GeometryReader { proxy in
                    let h = proxy.size.height
                    let cols = buckets.count
                    let colW = proxy.size.width / CGFloat(cols)
                    let barW = max(4, colW * 0.30)

                    HStack(spacing: 0) {
                        ForEach(buckets) { b in
                            VStack(spacing: 4) {
                                ZStack(alignment: .bottom) {
                                    HStack(spacing: 4) {
                                        Bar(value: b.income, max: maxVal, h: h - 22, color: .vAcc, width: barW)
                                        Bar(value: b.expense, max: maxVal, h: h - 22, color: .vDanger, width: barW)
                                    }
                                }
                                Text(b.label).vLabel(size: 8, color: .vTx3)
                            }
                            .frame(width: colW)
                        }
                    }
                }
                .frame(height: 130)
            }
        }
        .padding(14)
        .glassCard()
    }
}

private struct Bar: View {
    let value: Double
    let max: Double
    let h: CGFloat
    let color: Color
    let width: CGFloat

    var body: some View {
        let pct = max > 0 ? value / max : 0
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.85))
                .frame(width: width, height: CGFloat(pct) * h)
        }
        .frame(height: h)
    }
}

private struct TopMerchantsCard: View {
    let vm: AnalyticsViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("TOP COMERCIOS").vLabel(color: .vTx2)
                Spacer()
            }
            TerminalSeparator(style: .dashed).padding(.vertical, 9)
            ForEach(Array(vm.topMerchants.enumerated()), id: \.element.id) { idx, m in
                HStack(spacing: 10) {
                    Text(String(format: "%02d", idx + 1))
                        .vNum(size: 11, color: .vTx3)
                        .frame(width: 24, alignment: .leading)
                    Text(m.merchant)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.vTx1)
                        .lineLimit(1)
                    Spacer()
                    Text("\(m.count)x").vLabel(size: 9, color: .vTx3)
                    BalanceBadge(amount: m.amount, currency: vm.baseCurrency, color: .vDanger, size: 12)
                }
                .padding(.vertical, 5)
            }
        }
        .padding(14)
        .solidCard()
    }
}

private struct EmptyStatsState: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("◌").font(.system(size: 28, design: .monospaced)).foregroundStyle(Color.vTx3)
            Text("SIN DATOS").vLabel(color: .vTx2)
            Text("// REGISTRA MOVIMIENTOS PARA VER REPORTES").vLabel(size: 9, color: .vTx3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .solidCard()
    }
}
