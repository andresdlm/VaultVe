import SwiftUI

struct GastosView: View {
    @State private var viewModel: GastosViewModel

    init(engine: VaultEngine) {
        _viewModel = State(initialValue: GastosViewModel(engine: engine))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ScreenTitle(title: "Gastos", sub: "TRAZABILIDAD POR GASTO · TOCA PARA EXPANDIR")
                    .padding(.bottom, 4)

                if viewModel.gastos.isEmpty {
                    EmptyGastosState()
                } else {
                    ForEach(viewModel.gastos) { gasto in
                        let trace = viewModel.trace(for: gasto)
                        GastoCard(
                            trace: trace,
                            expanded: viewModel.expandedGastoId == gasto.id
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.toggleExpand(gasto.id)
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background { VaultBackground() }
    }
}

private struct EmptyGastosState: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("◌").font(.system(size: 28, design: .monospaced)).foregroundStyle(Color.vTx3)
            Text("SIN GASTOS").vLabel(color: .vTx2)
            Text("// AÑADE TU PRIMER GASTO DESDE NUEVA OP").vLabel(size: 9, color: .vTx3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .solidCard()
    }
}

struct GastoCard: View {
    let trace: GastoTrace
    let expanded: Bool
    let onTap: () -> Void

    var body: some View {
        let cheaper = trace.diffVsParalela < 0

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("GASTO #\(trace.gasto.displayId)")
                    .vNum(size: 11).foregroundStyle(Color.vTx3)
                Spacer()
                Text(trace.gasto.displayDate).vLabel(size: 9, color: .vTx3)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(trace.gasto.merchant)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.vTx1)
                Spacer()
                Text(trace.gasto.category)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.vTx2)
                    .tracking(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.vBg.opacity(0.5), in: RoundedRectangle(cornerRadius: 3))
                    .overlay { RoundedRectangle(cornerRadius: 3).strokeBorder(Color.vLine, lineWidth: 1) }
            }
            .padding(.vertical, 9)

            TerminalSeparator(style: .dashed)

            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PAGADO").vLabel(size: 9)
                    Text("Bs \(vFmt(trace.gasto.vesAmount))").vNum(size: 17, color: .vAmber)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("COSTO REAL").vLabel(size: 9)
                    Text("$ \(vFmt(trace.totalUsdCost))").vNum(size: 17, color: .vAcc)
                }
            }
            .padding(.top, 9)

            if trace.paralela > 0 {
                StatusBadge(
                    kind: cheaper ? .green : .danger,
                    text: "\(cheaper ? "▼" : "▲") $\(vFmt(abs(trace.diffVsParalela))) vs paralela"
                )
                .padding(.top, 8)
            }

            if expanded {
                GastoTraceDetail(trace: trace)
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(13)
        .glassCard()
        .onTapGesture(perform: onTap)
    }
}

struct GastoTraceDetail: View {
    let trace: GastoTrace

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("COSTO REAL DE ESTE GASTO").vLabel(size: 9, color: .vAmber)
            TerminalSeparator(style: .heavy).padding(.vertical, 8)

            CostTraceNode(amount: "Bs \(vFmt(trace.gasto.vesAmount))", amtColor: .vAmber,
                          desc: "VES gastados", showArrow: true)

            ForEach(trace.vesLegs) { vleg in
                CostTraceNode(
                    amount: "LOTE #\(vleg.vesLot.displayId)",
                    amtColor: .vTx1,
                    desc: "Bs \(vFmt(vleg.vesAmount)) · tasa Bs \(vFmt(vleg.vesLot.p2pRate)) · \(vleg.vesLot.displayDate.prefix(10))",
                    showArrow: true
                )
                ForEach(vleg.usdtLegs) { uleg in
                    CostTraceNode(
                        amount: "₮ \(vFmt(uleg.usdtAmount))",
                        amtColor: .vInfo,
                        desc: "USDT usados ← LOTE #\(uleg.usdtLot.displayId) · tasa $\(vFmt(uleg.usdtLot.costPerUsdt, dec: 4)) · fee $\(vFmt(uleg.usdtLot.feeUsd))",
                        showArrow: true
                    )
                    CostTraceNode(
                        amount: "$ \(vFmt(uleg.usdAmount)) USD",
                        amtColor: .vAcc,
                        desc: "COSTO RAÍZ pagados originalmente desde el banco",
                        showArrow: false
                    )
                }
            }

            TerminalSeparator(style: .heavy).padding(.vertical, 8)
            Text("RESUMEN DE ESTE GASTO").vLabel(size: 9)
            TerminalSeparator(style: .dashed).padding(.vertical, 6)

            LoteDataRow(key: "PAGADO EN VES",    value: "Bs \(vFmt(trace.gasto.vesAmount))",   valueColor: .vAmber)
            LoteDataRow(key: "COSTO REAL USD",   value: "$ \(vFmt(trace.totalUsdCost))",       valueColor: .vAcc)
            LoteDataRow(key: "TASA EFECTIVA",    value: "Bs \(vFmt(trace.effRate)) / $")
            if trace.paralela > 0 {
                LoteDataRow(key: "PARALELA HOY",     value: "Bs \(vFmt(trace.paralela)) / $", valueColor: .vAmber)
                HStack {
                    Text("DIFERENCIA").vLabel()
                    Spacer()
                    Text("\(trace.diffVsParalela < 0 ? "-" : "+")\(vFmt(abs(trace.diffVsParalela))) vs paralela")
                        .vNum(size: 13, color: trace.diffVsParalela < 0 ? .vAcc : .vDanger)
                }
                .padding(.vertical, 3)
            }
        }
    }
}

struct CostTraceNode: View {
    let amount: String
    let amtColor: Color
    let desc: String
    let showArrow: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 0) {
                Circle().fill(amtColor).frame(width: 5, height: 5).padding(.top, 4)
                if showArrow {
                    Color.vLine.frame(width: 1).frame(height: 30)
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 5))
                        .foregroundStyle(Color.vLine)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(amount).vNum(size: 13, color: amtColor)
                Text(desc)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.vTx2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, showArrow ? 0 : 4)
    }
}
