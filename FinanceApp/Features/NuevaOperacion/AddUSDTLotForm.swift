import SwiftUI

// USD → USDT P2P conversion.
// Captures: USD sent, USDT received, optional fee in USD.
// Derives: implicit P2P rate ($ per USDT).
struct AddUSDTLotForm: View {
    @Environment(VaultEngine.self) private var engine
    @Environment(\.dismiss)        private var dismiss

    @State private var date         = Date()
    @State private var usdSent      = ""
    @State private var usdtReceived = ""
    @State private var feeUsd       = "0"
    @State private var note         = ""
    @State private var errorMsg: String? = nil

    private var usdValue:  Double { Double(usdSent.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var usdtValue: Double { Double(usdtReceived.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var feeValue:  Double { Double(feeUsd.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    private var availableUSD: Double { engine.usdAvail }
    private var insufficientUsd: Bool { usdValue > availableUSD + 1e-9 }

    private var costPerUsdt: Double { usdtValue > 0 ? usdValue / usdtValue : 0 }
    private var feePercent:  Double { usdValue > 0 ? feeValue / usdValue * 100 : 0 }

    private var canSubmit: Bool {
        usdValue > 0 && usdtValue > 0 && !insufficientUsd
    }

    var body: some View {
        ZStack {
            VaultBackground()
            ScrollView {
                VStack(spacing: 14) {
                    FormHeader(title: "USD → USDT", subtitle: "P2P · BANCO USA HACIA WALLET")
                        .padding(.bottom, 6)

                    USDInventoryHint(available: availableUSD, used: usdValue, insufficient: insufficientUsd)

                    VStack(spacing: 12) {
                        TerminalDateField(label: "FECHA", date: $date)

                        TerminalField(
                            label: "USD ENVIADOS",
                            placeholder: "0.00",
                            text: $usdSent,
                            keyboard: .decimalPad,
                            prefix: "$", suffix: "USD",
                            error: insufficientUsd ? "INSUFICIENTE" : nil
                        )
                        TerminalField(
                            label: "USDT RECIBIDOS",
                            placeholder: "0.00",
                            text: $usdtReceived,
                            keyboard: .decimalPad,
                            prefix: "₮", suffix: "USDT"
                        )
                        TerminalField(
                            label: "COMISIÓN EN USD",
                            placeholder: "0.00",
                            text: $feeUsd,
                            keyboard: .decimalPad,
                            prefix: "$", suffix: "USD"
                        )
                        TerminalField(
                            label: "NOTA (OPCIONAL)",
                            placeholder: "Vendedor, banco, etc.",
                            text: $note
                        )
                    }
                    .padding(14)
                    .solidCard()

                    if usdtValue > 0 && usdValue > 0 {
                        DerivedSummaryCard(rows: [
                            ("TASA IMPLÍCITA", "$ \(vFmt(costPerUsdt, dec: 5)) / ₮", Color.vInfo),
                            ("COMISIÓN EFECTIVA", "\(vFmt(feePercent, dec: 2))%", Color.vAmber),
                            ("COSTO REAL POR USDT", "$ \(vFmt(costPerUsdt, dec: 5))", Color.vAcc)
                        ])
                    }

                    if let err = errorMsg {
                        Text(err)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.vDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    TerminalActionButton(title: "CONFIRMAR LOTE", color: .vInfo, disabled: !canSubmit) {
                        submit()
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
        }
        .presentationDetents([.large])
        .presentationBackground(.thinMaterial)
        .presentationDragIndicator(.visible)
    }

    private func submit() {
        do {
            _ = try engine.recordUSDTPurchase(
                date: date,
                usdSent: usdValue,
                usdtReceived: usdtValue,
                feeUsd: feeValue,
                note: note.isEmpty ? nil : note
            )
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            dismiss()
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

private struct USDInventoryHint: View {
    let available: Double
    let used: Double
    let insufficient: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text("USD DISPONIBLE").vLabel(size: 9)
                Text("$ \(vFmt(available))").vNum(size: 17, color: insufficient ? .vDanger : .vAcc)
            }
            Spacer()
            if used > 0 {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("DESPUÉS DE ESTA OP").vLabel(size: 9)
                    Text("$ \(vFmt(max(0, available - used)))")
                        .vNum(size: 13, color: insufficient ? .vDanger : .vTx2)
                }
            }
        }
        .padding(12)
        .glassCard(border: (insufficient ? Color.vDanger : Color.vAcc).opacity(0.25))
    }
}

struct DerivedSummaryCard: View {
    let rows: [(String, String, Color)]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("DERIVADO DEL LOTE").vLabel(color: .vTx2)
                Spacer()
            }
            TerminalSeparator(style: .dashed).padding(.vertical, 8)
            ForEach(rows.indices, id: \.self) { i in
                let row = rows[i]
                LoteDataRow(key: row.0, value: row.1, valueColor: row.2)
                if i < rows.count - 1 { TerminalSeparator(style: .dashed) }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .solidCard()
    }
}
