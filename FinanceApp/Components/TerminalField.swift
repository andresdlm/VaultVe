import SwiftUI

// Monospaced input matching the terminal aesthetic.
// Pairs a key label with either a free-text TextField or a decimal numeric input.
struct TerminalField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var prefix: String? = nil
    var suffix: String? = nil
    var error: String? = nil

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).vLabel()
                Spacer()
                if let err = error {
                    Text(err)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.vDanger)
                }
            }
            HStack(spacing: 6) {
                if let p = prefix {
                    Text(p)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(Color.vTx3)
                }
                TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Color.vTx3))
                    .focused($focused)
                    .keyboardType(keyboard)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.vTx1)
                    .tint(Color.vAcc)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(true)
                if let s = suffix {
                    Text(s)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.vTx2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Color.vBg.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        error != nil ? Color.vDanger.opacity(0.55)
                                     : focused ? Color.vAcc.opacity(0.55) : Color.vLine,
                        lineWidth: 1
                    )
            }
        }
    }
}

// Terminal-style date picker row.
struct TerminalDateField: View {
    let label: String
    @Binding var date: Date

    var body: some View {
        HStack {
            Text(label).vLabel()
            Spacer()
            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(Color.vAcc)
                .colorScheme(.dark)
                .environment(\.locale, Locale(identifier: "es_ES"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.vBg.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.vLine, lineWidth: 1)
        }
    }
}

// Bottom-of-form action button.
struct TerminalActionButton: View {
    let title: String
    var color: Color = .vAcc
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(1)
            }
            .foregroundStyle(disabled ? Color.vTx3 : Color.vBg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(disabled ? Color.vSurf : color, in: RoundedRectangle(cornerRadius: 6))
        }
        .disabled(disabled)
    }
}

// Title bar inside the sheet.
struct FormHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                Text("[ ").foregroundStyle(Color.vTx3)
                Text("VAULT").foregroundStyle(Color.vAcc)
                Text(" / NUEVA OP ]").foregroundStyle(Color.vTx3)
            }
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .tracking(2)
            Text(title)
                .font(.system(size: 22, weight: .black, design: .monospaced))
                .foregroundStyle(Color.vTx1)
                .tracking(0.5)
            Text(subtitle).vLabel(size: 9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
