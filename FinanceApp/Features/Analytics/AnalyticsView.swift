import SwiftUI

struct AnalyticsView: View {
    @State private var viewModel: AnalyticsViewModel

    init(engine: VaultEngine) {
        _viewModel = State(initialValue: AnalyticsViewModel(engine: engine))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ScreenTitle(title: "Analytics", sub: "REPORTES · ÚLTIMOS 30 DÍAS")
                    .padding(.bottom, 4)

                RateChartCard()

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
        .padding(13)
        .glassCard()
    }
}
