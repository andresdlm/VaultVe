import SwiftUI

struct AddExpenseForm: View {
    @Environment(VaultEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TransactionForm(kind: .expense, engine: engine, onDismiss: { dismiss() })
    }
}

struct AddIncomeForm: View {
    @Environment(VaultEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TransactionForm(kind: .income, engine: engine, onDismiss: { dismiss() })
    }
}

struct EditTransactionForm: View {
    let transaction: Transaction
    @Environment(VaultEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TransactionForm(
            kind: transaction.kind,
            engine: engine,
            editing: transaction,
            onDismiss: { dismiss() }
        )
    }
}

private struct TransactionForm: View {
    let kind: TransactionKind
    let engine: VaultEngine
    var editing: Transaction? = nil
    let onDismiss: () -> Void

    @State private var date = Date()
    @State private var account: Account? = nil
    @State private var amount = ""
    @State private var merchant = ""
    @State private var category: Category? = nil
    @State private var note = ""
    @State private var errorMsg: String? = nil

    private var amountValue: Double {
        Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    private var canSubmit: Bool {
        amountValue > 0 && account != nil && !merchant.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        let accent: Color = kind == .expense ? .vDanger : .vAcc

        ZStack {
            VaultBackground()
            ScrollView {
                VStack(spacing: 14) {
                    FormHeader(
                        title: editing == nil ? (kind == .expense ? "Nuevo gasto" : "Nuevo ingreso")
                                              : (kind == .expense ? "Editar gasto" : "Editar ingreso"),
                        subtitle: kind == .expense ? "REGISTRA UN PAGO" : "REGISTRA UN INGRESO"
                    )
                    .padding(.bottom, 4)

                    VStack(spacing: 12) {
                        TerminalDateField(label: "FECHA", date: $date)

                        AccountPicker(
                            label: "CUENTA",
                            accounts: engine.accounts,
                            selected: $account
                        )

                        TerminalField(
                            label: "MONTO \(account.map { " · " + $0.currency.code } ?? "")",
                            placeholder: "0.00",
                            text: $amount,
                            keyboard: .decimalPad,
                            prefix: account?.currency.symbol ?? "$",
                            suffix: account?.currency.code
                        )

                        TerminalField(
                            label: kind == .expense ? "COMERCIO" : "ORIGEN",
                            placeholder: kind == .expense ? "Ej. Excelsior Gama" : "Ej. Salario, Cliente X",
                            text: $merchant
                        )

                        let visibleCategories = engine.categories(of: kind)
                        if !visibleCategories.isEmpty {
                            CategoryChipsRow(
                                label: "CATEGORÍA",
                                categories: visibleCategories,
                                selected: $category
                            )
                        }

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

                    if account == nil && engine.accounts.isEmpty {
                        EmptyAccountsHint()
                    }

                    TerminalActionButton(
                        title: editing == nil
                               ? (kind == .expense ? "REGISTRAR GASTO" : "REGISTRAR INGRESO")
                               : "GUARDAR CAMBIOS",
                        color: accent,
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
        if let tx = editing {
            date = tx.date
            account = tx.account
            amount = vFmt(tx.amount, dec: tx.currency.defaultDecimals)
                .replacingOccurrences(of: ",", with: "")
            merchant = tx.merchant
            category = tx.category
            note = tx.note ?? ""
        } else if account == nil {
            account = engine.accounts.first
            if let visible = engine.categories(of: kind).first {
                category = visible
            }
        }
    }

    private func submit() {
        guard let account else { return }
        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespaces)
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)
        do {
            if let tx = editing {
                try engine.updateTransaction(
                    tx, date: date, account: account, amount: amountValue,
                    merchant: trimmedMerchant, category: category,
                    note: trimmedNote.isEmpty ? nil : trimmedNote
                )
            } else if kind == .expense {
                _ = try engine.recordExpense(
                    date: date, account: account, amount: amountValue,
                    merchant: trimmedMerchant, category: category,
                    note: trimmedNote.isEmpty ? nil : trimmedNote
                )
            } else {
                _ = try engine.recordIncome(
                    date: date, account: account, amount: amountValue,
                    merchant: trimmedMerchant, category: category,
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

struct EmptyAccountsHint: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.vAmber)
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 3) {
                Text("SIN CUENTAS").vLabel(color: .vAmber)
                Text("Primero crea una cuenta desde la pestaña Cuentas para poder registrar movimientos.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.vTx2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(12)
        .glassCard(border: Color.vAmber.opacity(0.35))
    }
}
