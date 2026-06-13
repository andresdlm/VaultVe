import SwiftUI

struct AddAccountForm: View {
    @Environment(VaultEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AccountForm(engine: engine, onDismiss: { dismiss() })
    }
}

struct EditAccountForm: View {
    let account: Account

    @Environment(VaultEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AccountForm(engine: engine, editing: account, onDismiss: { dismiss() })
    }
}

private struct AccountForm: View {
    let engine: VaultEngine
    var editing: Account? = nil
    let onDismiss: () -> Void

    @State private var name = ""
    @State private var currency: Currency = .usd
    @State private var kind: AccountKind = .bank
    @State private var glyph = "◉"
    @State private var colorHex = "00FF88"
    @State private var initialBalance = "0"
    @State private var note = ""
    @State private var errorMsg: String? = nil

    private var initialValue: Double {
        Double(initialBalance.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            VaultBackground()
            ScrollView {
                VStack(spacing: 14) {
                    FormHeader(
                        title: editing == nil ? "Nueva cuenta" : "Editar cuenta",
                        subtitle: "CONFIGURA LA CUENTA"
                    )
                    .padding(.bottom, 4)

                    VStack(spacing: 12) {
                        TerminalField(
                            label: "NOMBRE",
                            placeholder: "Ej. Banco Mercantil, Efectivo",
                            text: $name
                        )

                        AccountKindPicker(selected: $kind, onSelect: applyKindGlyph)

                        if editing == nil {
                            CurrencyPicker(selected: $currency, label: "MONEDA")
                        } else {
                            HStack {
                                Text("MONEDA").vLabel()
                                Spacer()
                                Text("\(currency.symbol)  \(currency.code) · \(currency.label)")
                                    .vNum(size: 13)
                            }
                            .padding(.vertical, 4)
                            Text("// LA MONEDA NO SE PUEDE CAMBIAR DESPUÉS DE CREAR")
                                .vLabel(size: 9, color: .vTx3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        TerminalField(
                            label: "SALDO INICIAL",
                            placeholder: "0.00",
                            text: $initialBalance,
                            keyboard: .decimalPad,
                            prefix: currency.symbol,
                            suffix: currency.code
                        )

                        GlyphPicker(label: "GLYPH", selected: $glyph)
                        AccentColorPicker(label: "COLOR", selected: $colorHex)

                        TerminalField(
                            label: "NOTA (OPCIONAL)",
                            placeholder: "—",
                            text: $note
                        )
                    }
                    .padding(14)
                    .solidCard()

                    if let err = errorMsg {
                        Text(err)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.vDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    TerminalActionButton(
                        title: editing == nil ? "CREAR CUENTA" : "GUARDAR CAMBIOS",
                        color: .vAcc,
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
        if let a = editing {
            name = a.name
            currency = a.currency
            kind = a.kind
            glyph = a.glyph
            colorHex = a.colorHex
            initialBalance = vFmt(a.initialBalance, dec: a.currency.defaultDecimals)
                .replacingOccurrences(of: ",", with: "")
            note = a.note ?? ""
        }
    }

    private func applyKindGlyph(_ k: AccountKind) {
        // Only auto-update the glyph if it still matches one of the defaults.
        if AccountKind.allCases.map(\.glyph).contains(glyph) {
            glyph = k.glyph
        }
    }

    private func submit() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)
        do {
            if let existing = editing {
                try engine.updateAccount(
                    existing, name: trimmedName, kind: kind, glyph: glyph,
                    colorHex: colorHex, initialBalance: initialValue,
                    note: trimmedNote.isEmpty ? nil : trimmedNote
                )
            } else {
                _ = try engine.createAccount(
                    name: trimmedName, currency: currency, kind: kind,
                    glyph: glyph, colorHex: colorHex,
                    initialBalance: initialValue,
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

private struct AccountKindPicker: View {
    @Binding var selected: AccountKind
    let onSelect: (AccountKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TIPO").vLabel()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(AccountKind.allCases) { k in
                        ChipButton(
                            glyph: k.glyph,
                            label: k.label,
                            color: .vAcc,
                            active: selected == k
                        ) {
                            selected = k
                            onSelect(k)
                        }
                    }
                }
            }
        }
    }
}
