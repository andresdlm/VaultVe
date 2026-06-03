import SwiftUI

struct DashboardLedger: View {
    let vm: DashboardViewModel

    var body: some View {
        let r = vm.rates

        VStack(spacing: 0) {
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
                if vm.isRefreshing {
                    HStack(spacing: 4) {
                        Text("SYNC").vLabel(color: .vAcc)
                        BlinkingCursor(color: .vAcc, height: 10)
                    }
                } else {
                    Text("● LIVE").vLabel()
                }
            }

            TerminalSeparator(style: .heavy).padding(.vertical, 10)

            HStack(alignment: .firstTextBaseline) {
                Text("▸ PATRIMONIO").vLabel()
                Spacer()
                AnimatedCounter(value: vm.patrimonioUsd, dec: 2, prefix: "$ ", size: 26, color: .vAcc)
                Text("USD").vLabel().padding(.bottom, 4)
            }
            HStack(alignment: .firstTextBaseline) {
                Text("≈ a \(vm.activeRateKey.label)").vLabel(size: 9, color: .vTx3)
                Spacer()
                AnimatedCounter(value: vm.patrimonioVes, dec: 2, prefix: "Bs ", size: 12, color: .vTx2, weight: .medium)
            }
            .padding(.top, 3)
        }
        .padding(12)
        .glassCard()

        VStack(spacing: 0) {
            HStack { Text("CUENTAS · CADENA").vLabel(color: .vTx2); Spacer() }
            TerminalSeparator(style: .dashed).padding(.vertical, 9)
            LedgerRow(index: "01") {
                HStack(spacing: 6) {
                    Text("◉").foregroundStyle(Color.vAcc)
                    Text("USD").vLabel(color: .vTx1)
                    Text("· BANCO USA").vLabel()
                }
                Text("$ \(vFmt(vm.usdAvail))").vNum(size: 14)
            }
            LedgerRow(index: "02") {
                HStack(spacing: 6) {
                    Text("◈").foregroundStyle(Color.vInfo)
                    Text("USDT").vLabel(color: .vTx1)
                    Text("· @$\(vFmt(vm.usdtAvgCost, dec: 4))").vLabel()
                }
                Text("₮ \(vFmt(vm.usdtAvail))").vNum(size: 14, color: .vInfo)
            }
            LedgerRow(index: "03") {
                HStack(spacing: 6) {
                    Text("▣").foregroundStyle(Color.vAmber)
                    Text("VES").vLabel(color: .vTx1)
                    Text("· $\(vFmt(vm.vesCostPerBs, dec: 5))/Bs").vLabel()
                }
                Text("Bs \(vFmt(vm.vesBalance))").vNum(size: 14, color: .vAmber)
            }
            TerminalSeparator(style: .dashed).padding(.vertical, 9)
            LedgerRow(index: "≡") {
                Text("VES EN USD REAL").vLabel()
                Text("$ \(vFmt(vm.vesInUsd))").vNum(size: 13, color: .vAcc)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .solidCard()

        VStack(spacing: 0) {
            HStack {
                Text("TASAS").vLabel(color: .vAmber)
                Spacer()
                Text(r.date).vLabel(size: 9, color: .vTx3)
            }
            TerminalSeparator(style: .dashed).padding(.vertical, 9)
            LedgerRow(index: "$") {
                Text("BCV").vLabel()
                Text("Bs \(vFmt(r.bcv))").vNum(size: 13)
            }
            LedgerRow(index: "$") {
                Text("PARALELA ◂ ACTIVA").vLabel(color: .vAmber)
                Text("Bs \(vFmt(r.paralela))").vNum(size: 13, color: .vAmber)
            }
            LedgerRow(index: "%") {
                Text("SPREAD").vLabel()
                Text("+\(vFmt(vm.spreadPct))%").vNum(size: 13)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .solidCard()
        .overlay { RoundedRectangle(cornerRadius: vCardRadius).strokeBorder(Color.vAmber.opacity(0.20), lineWidth: 1) }

        VStack(spacing: 0) {
            HStack { Text("ÚLTIMOS LOTES").vLabel(color: .vTx2); Spacer() }
            TerminalSeparator(style: .dashed).padding(.vertical, 9)
            ForEach(Array(vm.vesLots.prefix(2))) { lot in
                LedgerRow(index: "#\(lot.displayId)") {
                    Text("USDT→VES · \(lot.displayDate.prefix(10).suffix(5))").vLabel()
                    Text("Bs \(vFmt(lot.vesReceived))").vNum(size: 12, color: .vTx2)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .solidCard()

        NewOperationButton(action: vm.openNuevaOp)
    }
}

struct LedgerRow<C: View>: View {
    let index: String
    @ViewBuilder let content: () -> C

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(index).vLabel(size: 9, color: .vTx3).frame(width: 24, alignment: .leading)
            content()
        }
        .padding(.vertical, 3)
    }
}
