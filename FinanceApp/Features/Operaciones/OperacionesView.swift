import SwiftUI

struct OperacionesView: View {
    @State private var viewModel: OperacionesViewModel

    init(engine: VaultEngine) {
        _viewModel = State(initialValue: OperacionesViewModel(engine: engine))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScreenTitle(title: "Operaciones", sub: "REGISTRO DE CONVERSIONES · \(viewModel.sortedLotes.count) LOTES")
                    .padding(.bottom, 12)

                if viewModel.sortedLotes.isEmpty {
                    EmptyOpsState()
                } else {
                    VStack(spacing: 0) {
                        ForEach(viewModel.sortedLotes) { item in
                            switch item {
                            case .usdt(let lot): USDTLoteCard(lot: lot)
                            case .ves(let lot):  VESLoteCard(lot: lot)
                            }
                        }
                        TerminalSeparator(style: .heavy).padding(.top, 2)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .solidCard()
                }

                HStack(spacing: 4) {
                    Text("// FIFO ACTIVO · COSTOS HEREDADOS DE CADA LOTE FUENTE").vLabel(size: 9, color: .vTx3)
                    BlinkingCursor(color: .vTx3, height: 9)
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background { VaultBackground() }
    }
}

private struct EmptyOpsState: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("◌").font(.system(size: 28, design: .monospaced)).foregroundStyle(Color.vTx3)
            Text("SIN OPERACIONES").vLabel(color: .vTx2)
            Text("// REGISTRA TU PRIMERA CONVERSIÓN").vLabel(size: 9, color: .vTx3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .solidCard()
    }
}

struct USDTLoteCard: View {
    let lot: USDTLot

    var body: some View {
        VStack(spacing: 0) {
            TerminalSeparator(style: .heavy)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("LOTE #\(lot.displayId)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.vTx1)
                Text("USD → USDT")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.vInfo)
                Spacer()
                Text(lot.displayDate).vLabel(size: 9, color: .vTx3)
            }
            .padding(.vertical, 9)

            TerminalSeparator(style: .dashed)
            LoteDataRow(key: "ORIGEN",   value: "$ \(vFmt(lot.usdSent)) USD")
            LoteDataRow(key: "RECIBIDO", value: "₮ \(vFmt(lot.usdtReceived)) USDT", valueColor: .vInfo)
            LoteDataRow(key: "TASA P2P", value: "$ \(vFmt(lot.costPerUsdt, dec: 4)) / ₮")
            LoteDataRow(key: "COMISIÓN", value: "$ \(vFmt(lot.feeUsd))  (\(vFmt(lot.feePercent, dec: 2))%)", valueColor: .vAmber)
            LoteDataRow(key: "COSTO/₮",  value: "$ \(vFmt(lot.costPerUsdt, dec: 4))", valueColor: .vAcc)
            LoteDataRow(key: "RESTANTE", value: "₮ \(vFmt(lot.usdtRemaining))", valueColor: lot.usdtRemaining > 0 ? .vInfo : .vTx3)
        }
        .padding(.bottom, 4)
    }
}

struct VESLoteCard: View {
    let lot: VESLot

    var body: some View {
        VStack(spacing: 0) {
            TerminalSeparator(style: .heavy)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("LOTE #\(lot.displayId)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.vTx1)
                Text("USDT → VES")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.vAmber)
                Spacer()
                Text(lot.displayDate).vLabel(size: 9, color: .vTx3)
            }
            .padding(.vertical, 9)

            TerminalSeparator(style: .dashed)
            LoteDataRow(key: "ORIGEN",   value: "₮ \(vFmt(lot.usdtSent)) USDT")
            LoteDataRow(key: "RECIBIDO", value: "Bs \(vFmt(lot.vesReceived)) VES", valueColor: .vAmber)
            LoteDataRow(key: "TASA P2P", value: "Bs \(vFmt(lot.p2pRate, dec: 2)) / ₮")
            HStack {
                Text("COSTO REAL").vLabel()
                Spacer()
                HStack(spacing: 6) {
                    Text("$ \(vFmt(lot.costPerVes, dec: 5)) / Bs").vNum(size: 13, color: .vAcc)
                    Text("← heredado").vLabel(size: 8, color: .vTx3)
                }
            }
            .padding(.vertical, 3)
            LoteDataRow(key: "RESTANTE", value: "Bs \(vFmt(lot.vesRemaining))", valueColor: lot.vesRemaining > 0 ? .vAmber : .vTx3)

            // Show which USDT lots fed this sale
            if let allocs = lot.allocations, !allocs.isEmpty {
                TerminalSeparator(style: .dashed).padding(.top, 4)
                VStack(alignment: .leading, spacing: 4) {
                    Text("DESDE INVENTARIO").vLabel(size: 9, color: .vAcc)
                    ForEach(allocs.sorted(by: { ($0.sourceLot?.date ?? .now) < ($1.sourceLot?.date ?? .now) })) { a in
                        HStack(spacing: 6) {
                            Text("↳").font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.vTx3)
                            if let s = a.sourceLot {
                                Text("LOTE #\(s.displayId)").vLabel(size: 9, color: .vTx1)
                            }
                            Text("₮ \(vFmt(a.usdtAmount))").vLabel(size: 9, color: .vInfo)
                            Text("·").vLabel(size: 9, color: .vTx3)
                            Text("$ \(vFmt(a.usdAmount))").vLabel(size: 9, color: .vAcc)
                            Spacer()
                        }
                    }
                }
                .padding(.top, 6)
            }
        }
        .padding(.bottom, 4)
    }
}

struct LoteDataRow: View {
    let key: String
    let value: String
    var valueColor: Color = .vTx1

    var body: some View {
        HStack {
            Text(key).vLabel()
            Spacer()
            Text(value).vNum(size: 13, color: valueColor)
        }
        .padding(.vertical, 3)
    }
}

struct ScreenTitle: View {
    let title: String
    let sub: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("VAULTVE //").vLabel(size: 9, color: .vTx3)
            Text(title)
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundStyle(Color.vTx1)
                .tracking(0.5)
            Text(sub).vLabel(size: 9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
