import SwiftUI

// Records a USD deposit (e.g., salary) into the US bank account.
struct AddUSDIncomeForm: View {
    @Environment(VaultEngine.self) private var engine
    @Environment(\.dismiss)        private var dismiss

    @State private var date    = Date()
    @State private var amount  = ""
    @State private var source  = "Salario"
    @State private var note    = ""
    @State private var errorMsg: String? = nil

    private var amountValue: Double { Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var canSubmit: Bool { amountValue > 0 && !source.isEmpty }

    var body: some View {
        ZStack {
            VaultBackground()
            ScrollView {
                VStack(spacing: 14) {
                    FormHeader(title: "Ingreso USD", subtitle: "DEPÓSITO EN CUENTA BANCARIA")
                        .padding(.bottom, 6)

                    VStack(spacing: 12) {
                        TerminalDateField(label: "FECHA", date: $date)
                        TerminalField(
                            label: "MONTO",
                            placeholder: "0.00",
                            text: $amount,
                            keyboard: .decimalPad,
                            prefix: "$",
                            suffix: "USD"
                        )
                        TerminalField(
                            label: "ORIGEN",
                            placeholder: "Salario, Cliente X, etc.",
                            text: $source
                        )
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

                    TerminalActionButton(title: "REGISTRAR INGRESO", color: .vAcc, disabled: !canSubmit) {
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
            _ = try engine.recordIncome(
                date: date,
                amount: amountValue,
                source: source.trimmingCharacters(in: .whitespaces),
                note: note.isEmpty ? nil : note
            )
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            dismiss()
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}
