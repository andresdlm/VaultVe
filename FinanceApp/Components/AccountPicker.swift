import SwiftUI

// Vertical list of selectable account rows (used in expense/income/transfer forms).
struct AccountPicker: View {
    let label: String
    let accounts: [Account]
    @Binding var selected: Account?
    var excludeAccount: Account? = nil
    var emptyMessage: String = "// PRIMERO CREA UNA CUENTA"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).vLabel()

            let visible = accounts.filter { excludeAccount == nil || $0.id != excludeAccount?.id }

            if visible.isEmpty {
                Text(emptyMessage)
                    .vLabel(size: 9, color: .vTx3)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.vBg.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6).strokeBorder(Color.vLine, lineWidth: 1)
                    }
            } else {
                VStack(spacing: 6) {
                    ForEach(visible) { account in
                        AccountPickerRow(
                            account: account,
                            active: selected?.id == account.id
                        ) {
                            selected = account
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
        }
    }
}

private struct AccountPickerRow: View {
    let account: Account
    let active: Bool
    let onTap: () -> Void

    var body: some View {
        let color = Color(hex: account.colorHex)
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text(account.glyph)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(color)
                VStack(alignment: .leading, spacing: 1) {
                    Text(account.name)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.vTx1)
                    Text("\(account.currency.code) · \(account.kind.label)")
                        .vLabel(size: 9, color: .vTx3)
                }
                Spacer()
                BalanceBadge(
                    amount: account.balance,
                    currency: account.currency,
                    color: account.balance < 0 ? .vDanger : .vTx1,
                    size: 13
                )
                if active {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.vAcc)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(active ? Color.vAcc.opacity(0.08) : Color.vBg.opacity(0.5),
                        in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(active ? Color.vAcc.opacity(0.50) : Color.vLine, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
