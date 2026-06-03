import SwiftUI

// VES expense entry. Allocates VES FIFO from current VES lot inventory and
// shows the real USD cost of the expense before confirming.
struct AddGastoForm: View {
    @Environment(VaultEngine.self) private var engine
    @Environment(\.dismiss)        private var dismiss

    @State private var date     = Date()
    @State private var merchant = ""
    @State private var category: GastoCategory = .mercado
    @State private var amount   = ""
    @State private var note     = ""
    @State private var errorMsg: String? = nil

    private var amountValue: Double { Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var available:   Double { engine.vesBalance }
    private var insufficient: Bool  { amountValue > available + 1e-9 }

    private var preview: [GastoAllocationPreview] {
        guard amountValue > 0, !insufficient else { return [] }
        return engine.previewGasto(vesAmount: amountValue)
    }
    private var previewUsdCost: Double { preview.reduce(0) { $0 + $1.usdAmount } }
    private var effRate: Double { previewUsdCost > 0 ? amountValue / previewUsdCost : 0 }

    private var paralela: Double { engine.rates.paralela }
    private var diffVsParalela: Double {
        paralela > 0 ? previewUsdCost - (amountValue / paralela) : 0
    }

    private var canSubmit: Bool {
        amountValue > 0 && !merchant.isEmpty && !insufficient
    }

    var body: some View {
        ZStack {
            VaultBackground()
            ScrollView {
                VStack(spacing: 14) {
                    FormHeader(title: "Gasto VES", subtitle: "PAGO REALIZADO EN BOLÍVARES")
                        .padding(.bottom, 6)

                    InventoryHint(
                        label: "VES DISPONIBLE",
                        glyph: "Bs",
                        available: available,
                        used: amountValue,
                        insufficient: insufficient,
                        availableColor: .vAmber
                    )

                    VStack(spacing: 12) {
                        TerminalDateField(label: "FECHA", date: $date)
                        TerminalField(
                            label: "COMERCIO",
                            placeholder: "Ej. Excelsior Gama",
                            text: $merchant
                        )
                        CategoryPicker(selected: $category)
                        TerminalField(
                            label: "MONTO PAGADO",
                            placeholder: "0.00",
                            text: $amount,
                            keyboard: .decimalPad,
                            prefix: "Bs", suffix: "VES",
                            error: insufficient ? "INSUFICIENTE" : nil
                        )
                        TerminalField(
                            label: "NOTA (OPCIONAL)",
                            placeholder: "—",
                            text: $note
                        )
                    }
                    .padding(14)
                    .solidCard()

                    if !preview.isEmpty {
                        FIFOPreviewCard(
                            tag: "ASIGNACIÓN DESDE INVENTARIO VES",
                            rows: preview.map { p in
                                FIFOPreviewCard.Row(
                                    title: "LOTE #\(p.sourceLot.displayId)",
                                    qty:   "Bs \(vFmt(p.vesAmount))",
                                    cost:  "$ \(vFmt(p.usdAmount))",
                                    sub:   "@ $\(vFmt(p.sourceLot.costPerVes, dec: 7))/Bs · \(p.sourceLot.displayDate.prefix(10))"
                                )
                            }
                        )

                        VStack(spacing: 0) {
                            HStack {
                                Text("COSTO REAL DE ESTE GASTO").vLabel(color: .vAcc)
                                Spacer()
                            }
                            TerminalSeparator(style: .heavy).padding(.vertical, 8)

                            HStack(alignment: .lastTextBaseline) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("PAGADO").vLabel(size: 9)
                                    Text("Bs \(vFmt(amountValue))").vNum(size: 17, color: .vAmber)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("COSTO REAL").vLabel(size: 9)
                                    Text("$ \(vFmt(previewUsdCost))").vNum(size: 17, color: .vAcc)
                                }
                            }
                            .padding(.bottom, 8)

                            LoteDataRow(key: "TASA EFECTIVA", value: "Bs \(vFmt(effRate)) / $")
                            LoteDataRow(key: "PARALELA HOY",  value: paralela > 0 ? "Bs \(vFmt(paralela)) / $" : "—", valueColor: .vAmber)
                            HStack {
                                Text("VS PARALELA").vLabel()
                                Spacer()
                                if paralela > 0 {
                                    let cheaper = diffVsParalela < 0
                                    Text("\(cheaper ? "▼ -" : "▲ +") $\(vFmt(abs(diffVsParalela)))")
                                        .vNum(size: 13, color: cheaper ? .vAcc : .vDanger)
                                } else {
                                    Text("—").vNum(size: 13, color: .vTx3)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                        .padding(14)
                        .glassCard(border: Color.vAcc.opacity(0.25))
                    }

                    if let err = errorMsg {
                        Text(err)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.vDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    TerminalActionButton(title: "REGISTRAR GASTO", color: .vDanger, disabled: !canSubmit) {
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
            _ = try engine.recordGasto(
                date: date,
                merchant: merchant.trimmingCharacters(in: .whitespaces),
                category: category.label,
                vesAmount: amountValue,
                note: note.isEmpty ? nil : note
            )
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            dismiss()
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

private struct CategoryPicker: View {
    @Binding var selected: GastoCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CATEGORÍA").vLabel()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(GastoCategory.allCases, id: \.self) { c in
                        let active = c == selected
                        Button {
                            selected = c
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            HStack(spacing: 5) {
                                Text(c.glyph).font(.system(size: 10, design: .monospaced))
                                Text(c.label).vLabel(size: 9, color: active ? .vAcc : .vTx2)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 7)
                            .background(active ? Color.vAcc.opacity(0.10) : Color.vBg.opacity(0.5),
                                        in: RoundedRectangle(cornerRadius: 5))
                            .overlay {
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(active ? Color.vAcc.opacity(0.45) : Color.vLine, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
