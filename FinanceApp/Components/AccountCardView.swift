import SwiftUI

// Compact card that summarizes a single account.
struct AccountCardView: View {
    let account: Account

    var body: some View {
        let color = Color(hex: account.colorHex)
        let bal = account.balance
        let negative = bal < 0

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text(account.glyph)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(color)

                HStack(spacing: 5) {
                    Text(account.currency.code).vLabel(color: .vTx1)
                    Text("·").vLabel(color: .vTx3)
                    Text(account.name).vLabel()
                }

                Spacer()
                Text(account.kind.label.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.vTx2)
                    .tracking(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.vBg.opacity(0.5), in: RoundedRectangle(cornerRadius: 3))
                    .overlay {
                        RoundedRectangle(cornerRadius: 3).strokeBorder(Color.vLine, lineWidth: 1)
                    }
            }

            TerminalSeparator(style: .heavy)
                .padding(.vertical, 10)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(account.currency.symbol)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.vTx2)
                AnimatedCounter(
                    value: bal,
                    dec: account.currency.defaultDecimals,
                    size: 28,
                    color: negative ? .vDanger : color
                )
            }

            if account.initialBalance != 0 {
                Text("SALDO INICIAL · \(account.currency.symbol) \(vFmt(account.initialBalance, dec: account.currency.defaultDecimals))")
                    .vLabel(size: 9, color: .vTx3)
                    .padding(.top, 6)
            }
        }
        .padding(14)
        .glassCard(border: color.opacity(0.22))
    }
}
