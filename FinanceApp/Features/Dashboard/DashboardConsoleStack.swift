import SwiftUI

struct DashboardConsoleStack: View {
    let vm: DashboardViewModel

    var body: some View {
        DashboardHeader(vm: vm)

        AccountCardView(
            glyph: "◉", glyphColor: .vAcc,
            ticker: "USD", name: "BANCO USA",
            balance: vm.usdAvail, balDec: 2, balPrefix: "$ ",
            balColor: .vTx1,
            badge: StatusBadge(kind: .green, text: "ORIGEN ↓")
        ) {
            Text("DISPONIBLE").vLabel()
        }

        AccountCardView(
            glyph: "◈", glyphColor: .vInfo,
            ticker: "USDT", name: "WALLET",
            balance: vm.usdtAvail, balDec: 2, balPrefix: "₮ ",
            balColor: .vInfo,
            badge: StatusBadge(kind: .info, text: "EN TRÁNSITO ⇄")
        ) {
            Text("COSTO PROMEDIO: $\(vFmt(vm.usdtAvgCost, dec: 4))/₮")
                .vLabel()
        }

        AccountCardView(
            glyph: "▣", glyphColor: .vAmber,
            ticker: "VES", name: "MERCANTIL",
            balance: vm.vesBalance, balDec: 2, balPrefix: "Bs ",
            balColor: .vAmber,
            badge: StatusBadge(kind: .amber, text: "DESTINO")
        ) {
            VStack(alignment: .leading, spacing: 3) {
                Text("COSTO REAL: $\(vFmt(vm.vesCostPerBs, dec: 7))/Bs").vLabel()
                HStack(spacing: 4) {
                    Text("≈").vLabel(color: .vTx3)
                    AnimatedCounter(value: vm.vesInUsd, dec: 2, prefix: "$ ", suffix: " USD", size: 13, color: .vAcc, weight: .medium)
                }
            }
        }

        RatePanelSection(vm: vm)
        NewOperationButton(action: vm.openNuevaOp)
    }
}

struct NewOperationButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
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
