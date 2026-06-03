import SwiftUI

struct DashboardPipeline: View {
    let vm: DashboardViewModel

    var body: some View {
        let latestUsdt = vm.usdtLots.first
        let latestVes  = vm.vesLots.first

        DashboardHeaderCompact(vm: vm)

        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("⌗").font(.system(size: 11, design: .monospaced)).foregroundStyle(Color.vAcc)
                Text("CADENA DE CONVERSIÓN").vLabel(color: .vTx1)
                Spacer()
                Text("FLUJO ACTIVO").vLabel(size: 9, color: .vTx3)
            }
            TerminalSeparator(style: .heavy).padding(.vertical, 11)

            HStack(alignment: .center, spacing: 0) {
                PipelineNode(glyph: "◉", glyphColor: .vAcc,   ticker: "USD",  name: "BANCO",  amount: "$\(vFmt(vm.usdAvail, dec: 0))",   amtColor: .vTx1)
                PipelineArrow()
                PipelineNode(glyph: "◈", glyphColor: .vInfo,  ticker: "USDT", name: "WALLET", amount: "₮\(vFmt(vm.usdtAvail, dec: 0))",  amtColor: .vInfo)
                PipelineArrow()
                PipelineNode(glyph: "▣", glyphColor: .vAmber, ticker: "VES",  name: "CUENTA", amount: "Bs\(vFmt(vm.vesBalance, dec: 0))", amtColor: .vAmber)
            }

            HStack(alignment: .top, spacing: 10) {
                ConversionCaption(
                    tag: "ÚLT. CONVERSIÓN A",
                    rate: latestUsdt.map { "$\(vFmt($0.costPerUsdt, dec: 4))/₮" } ?? "—",
                    fee: latestUsdt.map { "\(vFmt($0.feePercent, dec: 2))%" } ?? "—",
                    cost: latestUsdt.map { "$\(vFmt($0.costPerUsdt, dec: 4))/₮" } ?? "—",
                    costColor: .vInfo
                )
                Color.vLine.frame(width: 1)
                ConversionCaption(
                    tag: "ÚLT. CONVERSIÓN B",
                    rate: latestVes.map { "Bs \(vFmt($0.p2pRate))/₮" } ?? "—",
                    fee: "0%",
                    cost: latestVes.map { "$\(vFmt($0.costPerVes, dec: 5))/Bs" } ?? "—",
                    costColor: .vAmber
                )
            }
            .padding(.top, 14)
        }
        .padding(14)
        .glassCard()

        VStack(spacing: 0) {
            HStack {
                Text("CUENTAS").vLabel(color: .vTx2)
                Spacer()
            }
            .padding(.bottom, 4)

            HStack(alignment: .center, spacing: 10) {
                Text("◉").font(.system(size: 12, design: .monospaced)).foregroundStyle(Color.vAcc)
                Text("USD").vLabel(color: .vTx1).frame(width: 36, alignment: .leading)
                Text("BANCO USA").vLabel()
                Spacer()
                Text("$ \(vFmt(vm.usdAvail))").vNum(size: 14)
            }
            .padding(.vertical, 9)

            TerminalSeparator(style: .dashed)

            HStack(alignment: .center, spacing: 10) {
                Text("◈").font(.system(size: 12, design: .monospaced)).foregroundStyle(Color.vInfo)
                Text("USDT").vLabel(color: .vTx1).frame(width: 36, alignment: .leading)
                Text("WALLET").vLabel()
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("₮ \(vFmt(vm.usdtAvail))").vNum(size: 14, color: .vInfo)
                    Text("$\(vFmt(vm.usdtAvgCost, dec: 4))/₮").vLabel(size: 8.5)
                }
            }
            .padding(.vertical, 9)

            TerminalSeparator(style: .dashed)

            HStack(alignment: .center, spacing: 10) {
                Text("▣").font(.system(size: 12, design: .monospaced)).foregroundStyle(Color.vAmber)
                Text("VES").vLabel(color: .vTx1).frame(width: 36, alignment: .leading)
                Text("MERCANTIL").vLabel()
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Bs \(vFmt(vm.vesBalance))").vNum(size: 14, color: .vAmber)
                    Text("≈ $\(vFmt(vm.vesInUsd)) USD").vLabel(size: 8.5)
                }
            }
            .padding(.vertical, 9)
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .solidCard()

        RatePanelSection(vm: vm)
        NewOperationButton(action: vm.openNuevaOp)
    }
}

struct PipelineNode: View {
    let glyph: String
    let glyphColor: Color
    let ticker: String
    let name: String
    let amount: String
    let amtColor: Color

    var body: some View {
        VStack(spacing: 0) {
            Text(glyph).font(.system(size: 15, design: .monospaced)).foregroundStyle(glyphColor)
            Text(ticker).vLabel(size: 9, color: .vTx1).padding(.top, 7)
            Text(name).vLabel(size: 8.5).padding(.top, 2)
            Text(amount).vNum(size: 14, color: amtColor).padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .glassCard(border: Color.white.opacity(0.16))
    }
}

struct PipelineArrow: View {
    var body: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 12, weight: .light))
            .foregroundStyle(Color.vTx2)
            .frame(width: 22)
    }
}

struct ConversionCaption: View {
    let tag: String
    let rate: String
    let fee: String
    let cost: String
    let costColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tag).vLabel(color: .vTx1)
            Text("Tasa \(rate)").vLabel()
            Text("Fee \(fee)").vLabel(color: .vAmber)
            HStack(spacing: 3) {
                Text("Acum.").vLabel(size: 9)
                Text(cost).vLabel(size: 9, color: costColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
