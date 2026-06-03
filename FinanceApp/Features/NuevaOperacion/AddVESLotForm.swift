import SwiftUI

// USDT → VES P2P sale.
// Shows a live FIFO preview: which USDT lots will be drawn and at what cost.
// This is the screen where cost traceability begins to lock in.
struct AddVESLotForm: View {
    @Environment(VaultEngine.self) private var engine
    @Environment(\.dismiss)        private var dismiss

    @State private var date        = Date()
    @State private var usdtSent    = ""
    @State private var vesReceived = ""
    @State private var note        = ""
    @State private var errorMsg: String? = nil

    private var usdtValue: Double { Double(usdtSent.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var vesValue:  Double { Double(vesReceived.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    private var available: Double { engine.usdtAvail }
    private var insufficient: Bool { usdtValue > available + 1e-9 }

    private var p2pRate: Double { usdtValue > 0 ? vesValue / usdtValue : 0 }

    private var preview: [VESLotAllocationPreview] {
        guard usdtValue > 0, !insufficient else { return [] }
        return engine.previewVES(usdtSent: usdtValue)
    }
    private var previewUsdCost: Double { preview.reduce(0) { $0 + $1.usdAmount } }
    private var previewCostPerVes: Double { vesValue > 0 ? previewUsdCost / vesValue : 0 }

    private var canSubmit: Bool {
        usdtValue > 0 && vesValue > 0 && !insufficient
    }

    var body: some View {
        ZStack {
            VaultBackground()
            ScrollView {
                VStack(spacing: 14) {
                    FormHeader(title: "USDT → VES", subtitle: "VENTA P2P · ASIGNACIÓN FIFO")
                        .padding(.bottom, 6)

                    InventoryHint(
                        label: "USDT DISPONIBLE",
                        glyph: "₮",
                        available: available,
                        used: usdtValue,
                        insufficient: insufficient,
                        availableColor: .vInfo
                    )

                    VStack(spacing: 12) {
                        TerminalDateField(label: "FECHA", date: $date)
                        TerminalField(
                            label: "USDT VENDIDOS",
                            placeholder: "0.00",
                            text: $usdtSent,
                            keyboard: .decimalPad,
                            prefix: "₮", suffix: "USDT",
                            error: insufficient ? "INSUFICIENTE" : nil
                        )
                        TerminalField(
                            label: "VES RECIBIDOS",
                            placeholder: "0.00",
                            text: $vesReceived,
                            keyboard: .decimalPad,
                            prefix: "Bs", suffix: "VES"
                        )
                        TerminalField(
                            label: "NOTA (OPCIONAL)",
                            placeholder: "Comprador, banco, etc.",
                            text: $note
                        )
                    }
                    .padding(14)
                    .solidCard()

                    if !preview.isEmpty {
                        FIFOPreviewCard(
                            tag: "ASIGNACIÓN DESDE INVENTARIO USDT",
                            rows: preview.map { p in
                                FIFOPreviewCard.Row(
                                    title: "LOTE #\(p.sourceLot.displayId)",
                                    qty:   "₮ \(vFmt(p.usdtAmount))",
                                    cost:  "$ \(vFmt(p.usdAmount))",
                                    sub:   "@ $\(vFmt(p.sourceLot.costPerUsdt, dec: 5))/₮ · \(p.sourceLot.displayDate.prefix(10))"
                                )
                            }
                        )

                        DerivedSummaryCard(rows: [
                            ("TASA P2P", "Bs \(vFmt(p2pRate)) / ₮", Color.vAmber),
                            ("COSTO REAL TOTAL", "$ \(vFmt(previewUsdCost))", Color.vAcc),
                            ("COSTO POR BS", "$ \(vFmt(previewCostPerVes, dec: 7)) / Bs", Color.vAcc)
                        ])
                    }

                    if let err = errorMsg {
                        Text(err)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.vDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    TerminalActionButton(title: "CONFIRMAR VENTA", color: .vAmber, disabled: !canSubmit) {
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
            _ = try engine.recordVESSale(
                date: date,
                usdtSent: usdtValue,
                vesReceived: vesValue,
                note: note.isEmpty ? nil : note
            )
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            dismiss()
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

// Shared inventory hint card (used by VES + Gasto forms).
struct InventoryHint: View {
    let label: String
    let glyph: String
    let available: Double
    let used: Double
    let insufficient: Bool
    let availableColor: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(label).vLabel(size: 9)
                Text("\(glyph) \(vFmt(available))").vNum(size: 17, color: insufficient ? .vDanger : availableColor)
            }
            Spacer()
            if used > 0 {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("RESTANTE").vLabel(size: 9)
                    Text("\(glyph) \(vFmt(max(0, available - used)))")
                        .vNum(size: 13, color: insufficient ? .vDanger : .vTx2)
                }
            }
        }
        .padding(12)
        .glassCard(border: (insufficient ? Color.vDanger : availableColor).opacity(0.25))
    }
}

// Shows the FIFO plan breakdown the user is about to commit to.
struct FIFOPreviewCard: View {
    struct Row: Identifiable {
        let id = UUID()
        let title: String
        let qty: String
        let cost: String
        let sub: String
    }
    let tag: String
    let rows: [Row]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(tag).vLabel(color: .vAcc)
                Spacer()
                Text("FIFO").vLabel(size: 9, color: .vTx3)
            }
            TerminalSeparator(style: .heavy).padding(.vertical, 8)

            ForEach(rows.indices, id: \.self) { i in
                let row = rows[i]
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.title)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.vTx1)
                        Spacer()
                        Text(row.qty).vNum(size: 13, color: .vInfo)
                    }
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.sub)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.vTx2)
                        Spacer()
                        Text(row.cost).vNum(size: 12, color: .vAcc)
                    }
                }
                .padding(.vertical, 8)
                if i < rows.count - 1 { TerminalSeparator(style: .dashed) }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassCard(border: Color.vAcc.opacity(0.25))
    }
}
