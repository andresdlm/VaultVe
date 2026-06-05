import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel: AnalyticsViewModel

    init(engine: VaultEngine) {
        _viewModel = State(initialValue: AnalyticsViewModel(engine: engine))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ScreenTitle(title: "Analytics", sub: "REPORTES · ÚLTIMOS 30 DÍAS")
                    .padding(.bottom, 4)

                RateChartCard()

                SalaryCard(vm: viewModel)

                SpendingDonutCard(slices: viewModel.categorySlices, totalUsd: viewModel.totalSpentUsd)

                AccountsCard(slices: viewModel.accountSlices, totalUsd: viewModel.totalAccountsUsd)

                MetricCard(
                    label:  "COSTO PROMEDIO USDT",
                    value:  "$\(vFmt(viewModel.usdtAvgCost, dec: 4))/₮",
                    sub:    "mejor $0.9985  ·  peor $1.0031",
                    accent: .vInfo
                )
                MetricCard(
                    label:  "TASA EFECTIVA PROMEDIO VES",
                    value:  "Bs 41.52/$",
                    sub:    "vs paralela Bs \(vFmt(viewModel.paralela))  ·  eficiencia 99.2%",
                    accent: .vAmber
                )
                MetricCard(
                    label:  "PÉRDIDA EN CONVERSIONES",
                    value:  "$ 4.83",
                    sub:    "este mes  ·  0.48% de tu flujo total",
                    accent: .vDanger
                )

                HStack(spacing: 4) {
                    Text("// MÁS REPORTES — EN CONSTRUCCIÓN").vLabel(size: 9, color: .vTx3)
                    BlinkingCursor(color: .vTx3, height: 9)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background { VaultBackground() }
    }
}

// MARK: - Salary usage

private struct SalaryCard: View {
    let vm: AnalyticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("SUELDO SIN GASTAR").vLabel()
                Spacer()
                Text("INGRESOS $\(vFmt(vm.totalIncomeUsd))").vLabel(size: 9, color: .vTx3)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("$").vNum(size: 20, color: .vTx2)
                Text(vFmt(vm.unspentUsd)).vNum(size: 30, color: .vAcc)
                Text("USD").vLabel(size: 9).padding(.bottom, 4)
                Spacer()
                Text("\(vFmt(vm.unspentFraction * 100, dec: 0))%")
                    .vNum(size: 16, color: .vAcc)
            }
            .padding(.top, 6)

            // Spent vs available bar
            GeometryReader { geo in
                let spentW = geo.size.width * CGFloat(vm.spentFraction)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.vAcc.opacity(0.18))
                    Capsule().fill(Color.vDanger.opacity(0.7))
                        .frame(width: max(0, spentW))
                }
            }
            .frame(height: 8)
            .padding(.top, 12)

            HStack(spacing: 6) {
                LegendDot(color: .vDanger)
                Text("GASTADO $\(vFmt(vm.totalSpentUsd))").vLabel(size: 9, color: .vTx2)
                Spacer()
                LegendDot(color: .vAcc)
                Text("DISPONIBLE $\(vFmt(vm.unspentUsd))").vLabel(size: 9, color: .vTx2)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard()
    }
}

// MARK: - Spending by category (donut)

private struct SpendingDonutCard: View {
    let slices: [CategorySlice]
    let totalUsd: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("EN QUÉ SE VA EL DINERO").vLabel()
            Text("GASTO POR CATEGORÍA · COSTO REAL USD").vLabel(size: 9, color: .vTx3)
                .padding(.top, 3)

            if slices.isEmpty {
                Text("// SIN GASTOS REGISTRADOS")
                    .vLabel(size: 9, color: .vTx3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            } else {
                HStack(alignment: .center, spacing: 16) {
                    DonutChart(slices: slices, totalUsd: totalUsd)
                        .frame(width: 116, height: 116)

                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(slices) { slice in
                            HStack(spacing: 7) {
                                LegendDot(color: slice.category.chartColor)
                                Text(slice.category.label.uppercased())
                                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Color.vTx1)
                                    .tracking(0.5)
                                Spacer(minLength: 4)
                                Text("\(vFmt(slice.fraction * 100, dec: 0))%")
                                    .vNum(size: 10, color: .vTx2)
                                Text("$\(vFmt(slice.usd))")
                                    .vNum(size: 10, color: slice.category.chartColor)
                                    .frame(width: 58, alignment: .trailing)
                            }
                        }
                    }
                }
                .padding(.top, 14)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard()
    }
}

private struct DonutChart: View {
    let slices: [CategorySlice]
    let totalUsd: Double

    var body: some View {
        ZStack {
            Canvas { ctx, size in
                let lineW = size.width * 0.17
                let radius = min(size.width, size.height) / 2 - lineW / 2
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let gap = 0.012 // small gap between segments (fraction of circle)

                var start = -0.25 // top, in turns (−90°)
                for slice in slices {
                    let sweep = slice.fraction - gap
                    guard sweep > 0 else { continue }
                    let startAngle = Angle(radians: start * 2 * .pi)
                    let endAngle   = Angle(radians: (start + sweep) * 2 * .pi)
                    var path = Path()
                    path.addArc(center: center, radius: radius,
                                startAngle: startAngle, endAngle: endAngle, clockwise: false)
                    ctx.stroke(
                        path,
                        with: .color(slice.category.chartColor),
                        style: StrokeStyle(lineWidth: lineW, lineCap: .butt)
                    )
                    start += slice.fraction
                }
            }
            VStack(spacing: 1) {
                Text("TOTAL").vLabel(size: 8, color: .vTx3)
                Text("$\(vFmt(totalUsd, dec: 0))").vNum(size: 16, color: .vTx1)
            }
        }
    }
}

// MARK: - Accounts (holdings)

private struct AccountsCard: View {
    let slices: [AccountSlice]
    let totalUsd: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("MIS CUENTAS").vLabel()
                Spacer()
                Text("PATRIMONIO $\(vFmt(totalUsd))").vLabel(size: 9, color: .vAcc)
            }
            Text("DISTRIBUCIÓN POR CUENTA · VALOR EN USD").vLabel(size: 9, color: .vTx3)
                .padding(.top, 3)

            VStack(spacing: 12) {
                ForEach(slices) { slice in
                    AccountBar(slice: slice)
                }
            }
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard()
    }
}

private struct AccountBar: View {
    let slice: AccountSlice

    private var color: Color { slice.kind.chartColor }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Text(slice.kind.glyph)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(color)
                Text(slice.kind.name)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.vTx1)
                    .tracking(0.5)
                Text(slice.kind.ticker).vLabel(size: 8, color: .vTx3)
                Spacer()
                Text(slice.nativeLabel).vNum(size: 11, color: .vTx2)
                Text("$\(vFmt(slice.usd))").vNum(size: 11, color: color)
                    .frame(width: 70, alignment: .trailing)
            }

            GeometryReader { geo in
                let w = geo.size.width * CGFloat(slice.fraction)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.vBg.opacity(0.6))
                    Capsule().fill(color.opacity(0.85))
                        .frame(width: max(2, w))
                }
            }
            .frame(height: 7)
        }
    }
}

// MARK: - Shared bits

private struct LegendDot: View {
    let color: Color
    var body: some View {
        Circle().fill(color).frame(width: 7, height: 7)
    }
}

extension GastoCategory {
    var chartColor: Color {
        switch self {
        case .mercado:      return .vAcc
        case .salud:        return .vInfo
        case .transporte:   return .vAmber
        case .restaurantes: return .vDanger
        case .servicios:    return Color(hex: "9B7BFF")
        case .ocio:         return Color(hex: "FF6FB5")
        case .otros:        return .vTx2
        }
    }
}

extension AccountKind {
    var chartColor: Color {
        switch self {
        case .usd:  return .vAcc
        case .usdt: return .vInfo
        case .ves:  return .vAmber
        }
    }
}

// MARK: - Existing cards

struct RateChartCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    Text("━").foregroundStyle(Color.vAcc)
                    Text("Tasa real").vLabel()
                }
                HStack(spacing: 4) {
                    Text("━").foregroundStyle(Color.vAmber)
                    Text("Paralela").vLabel()
                }
                Spacer()
            }
            .padding(.bottom, 10)

            Canvas { ctx, size in
                let amberPoints: [(CGFloat, CGFloat)] = [
                    (0,70),(45,62),(90,66),(135,55),(180,58),(225,48),(270,52),(320,44)
                ]
                let greenPoints: [(CGFloat, CGFloat)] = [
                    (0,78),(45,72),(90,69),(135,64),(180,67),(225,60),(270,58),(320,55)
                ]
                let sx = size.width / 320
                let sy = size.height / 110

                func polyline(_ pts: [(CGFloat, CGFloat)], color: Color) {
                    var path = Path()
                    for (i, pt) in pts.enumerated() {
                        let p = CGPoint(x: pt.0 * sx, y: pt.1 * sy)
                        i == 0 ? path.move(to: p) : path.addLine(to: p)
                    }
                    ctx.stroke(path, with: .color(color), lineWidth: 1.5)
                }

                for i in 0...4 {
                    let y = size.height * CGFloat(i) / 4
                    var grid = Path()
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(grid, with: .color(Color.vLine), lineWidth: 0.5)
                }
                polyline(amberPoints, color: .vAmber)
                polyline(greenPoints, color: .vAcc)
            }
            .frame(height: 120)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard()
    }
}

struct MetricCard: View {
    let label:  String
    let value:  String
    let sub:    String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).vLabel()
            Text(value).vNum(size: 22, color: accent).padding(.top, 6)
            Text(sub).vLabel(size: 9, color: .vTx3).padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .glassCard()
    }
}
