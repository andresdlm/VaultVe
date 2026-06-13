import SwiftUI

struct AddTransferForm: View {
    @Environment(VaultEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TransferForm(engine: engine, onDismiss: { dismiss() })
    }
}

struct EditTransferForm: View {
    let transfer: Transfer
    @Environment(VaultEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TransferForm(engine: engine, editing: transfer, onDismiss: { dismiss() })
    }
}

private struct TransferForm: View {
    let engine: VaultEngine
    var editing: Transfer? = nil
    let onDismiss: () -> Void

    @State private var date = Date()
    @State private var source: Account? = nil
    @State private var dest: Account? = nil
    @State private var sourceAmount = ""
    @State private var destAmount = ""
    @State private var note = ""
    @State private var errorMsg: String? = nil
    @State private var hasManuallyEditedDest = false

    private var sourceValue: Double { Double(sourceAmount.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var destValue:   Double { Double(destAmount.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var crossCurrency: Bool {
        guard let s = source, let d = dest else { return false }
        return s.currency != d.currency
    }
    private var impliedRate: Double { sourceValue > 0 ? destValue / sourceValue : 0 }

    private var canSubmit: Bool {
        guard let source, let dest else { return false }
        return source.id != dest.id && sourceValue > 0 && destValue > 0
    }

    var body: some View {
        ZStack {
            VaultBackground()
            ScrollView {
                VStack(spacing: 14) {
                    FormHeader(
                        title: editing == nil ? "Nueva transferencia" : "Editar transferencia",
                        subtitle: "MOVIMIENTO ENTRE TUS CUENTAS"
                    )
                    .padding(.bottom, 4)

                    VStack(spacing: 12) {
                        TerminalDateField(label: "FECHA", date: $date)

                        AccountPicker(
                            label: "ORIGEN",
                            accounts: engine.accounts,
                            selected: $source,
                            excludeAccount: dest
                        )

                        AccountPicker(
                            label: "DESTINO",
                            accounts: engine.accounts,
                            selected: $dest,
                            excludeAccount: source
                        )

                        TerminalField(
                            label: "MONTO ENVIADO\(source.map { " · " + $0.currency.code } ?? "")",
                            placeholder: "0.00",
                            text: $sourceAmount,
                            keyboard: .decimalPad,
                            prefix: source?.currency.symbol ?? "$",
                            suffix: source?.currency.code
                        )
                        .onChange(of: sourceAmount) { _, _ in autofillDest() }

                        TerminalField(
                            label: "MONTO RECIBIDO\(dest.map { " · " + $0.currency.code } ?? "")",
                            placeholder: "0.00",
                            text: $destAmount,
                            keyboard: .decimalPad,
                            prefix: dest?.currency.symbol ?? "$",
                            suffix: dest?.currency.code
                        )
                        .onChange(of: destAmount) { _, _ in
                            hasManuallyEditedDest = true
                        }

                        TerminalField(
                            label: "NOTA (OPCIONAL)",
                            placeholder: "Comprobante, comentario, etc.",
                            text: $note
                        )
                    }
                    .padding(14)
                    .solidCard()

                    if crossCurrency, let s = source, let d = dest, impliedRate > 0 {
                        ImpliedRateCard(
                            source: s.currency,
                            dest: d.currency,
                            rate: impliedRate
                        )
                    }

                    if let err = errorMsg {
                        Text(err)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.vDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if engine.accounts.count < 2 {
                        EmptyAccountsHint()
                    }

                    TerminalActionButton(
                        title: editing == nil ? "REGISTRAR TRANSFERENCIA" : "GUARDAR CAMBIOS",
                        color: .vInfo,
                        disabled: !canSubmit
                    ) {
                        submit()
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.large])
        .presentationBackground(.thinMaterial)
        .presentationDragIndicator(.visible)
        .onAppear { hydrate() }
    }

    private func hydrate() {
        if let tr = editing {
            date = tr.date
            source = tr.sourceAccount
            dest = tr.destAccount
            sourceAmount = vFmt(tr.sourceAmount, dec: tr.sourceCurrency.defaultDecimals)
                .replacingOccurrences(of: ",", with: "")
            destAmount = vFmt(tr.destAmount, dec: tr.destCurrency.defaultDecimals)
                .replacingOccurrences(of: ",", with: "")
            note = tr.note ?? ""
            hasManuallyEditedDest = true
        } else {
            let accs = engine.accounts
            source = accs.first
            dest = accs.dropFirst().first
        }
    }

    // When source amount changes and the user hasn't overridden dest, autofill
    // based on the configured per-currency rates (via engine).
    private func autofillDest() {
        guard !hasManuallyEditedDest else { return }
        guard let s = source, let d = dest else { return }
        guard sourceValue > 0 else { return }
        if s.currency == d.currency {
            destAmount = sourceAmount
            return
        }
        if let asBase = engine.convertToBase(sourceValue, from: s.currency),
           let toDest = engine.convertFromBase(asBase, to: d.currency) {
            destAmount = vFmt(toDest, dec: d.currency.defaultDecimals)
                .replacingOccurrences(of: ",", with: "")
        }
    }

    private func submit() {
        guard let source, let dest else { return }
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)
        do {
            if let tr = editing {
                try engine.updateTransfer(
                    tr, date: date, source: source, dest: dest,
                    sourceAmount: sourceValue, destAmount: destValue,
                    note: trimmedNote.isEmpty ? nil : trimmedNote
                )
            } else {
                _ = try engine.recordTransfer(
                    date: date, source: source, dest: dest,
                    sourceAmount: sourceValue, destAmount: destValue,
                    note: trimmedNote.isEmpty ? nil : trimmedNote
                )
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onDismiss()
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

private struct ImpliedRateCard: View {
    let source: Currency
    let dest: Currency
    let rate: Double

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("TASA IMPLÍCITA").vLabel(color: .vAmber)
                Spacer()
                Text("DERIVADA").vLabel(size: 9, color: .vTx3)
            }
            TerminalSeparator(style: .dashed).padding(.vertical, 8)

            HStack(spacing: 5) {
                Text("1").vNum(size: 14, color: .vAcc)
                Text(source.code).vLabel(color: .vTx2)
                Text("=").vLabel(color: .vTx3)
                Text(vFmt(rate, dec: 4)).vNum(size: 14, color: .vAmber)
                Text(dest.code).vLabel(color: .vTx2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .padding(14)
        .glassCard(border: Color.vAmber.opacity(0.30))
    }
}
