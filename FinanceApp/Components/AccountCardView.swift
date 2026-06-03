import SwiftUI

struct AccountCardView<S: View>: View {
    let glyph: String
    let glyphColor: Color
    let ticker: String
    let name: String
    let balance: Double
    let balDec: Int
    let balPrefix: String
    let balColor: Color
    let badge: StatusBadge
    @ViewBuilder let sub: () -> S

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text(glyph)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(glyphColor)

                HStack(spacing: 5) {
                    Text(ticker)
                        .vLabel(color: .vTx1)
                    Text("·")
                        .vLabel(color: .vTx3)
                    Text(name)
                        .vLabel()
                }

                Spacer()
                badge
            }

            TerminalSeparator(style: .heavy)
                .padding(.vertical, 10)

            AnimatedCounter(value: balance, dec: balDec, prefix: balPrefix, size: 30, color: balColor)

            sub()
                .padding(.top, 8)
        }
        .padding(14)
        .glassCard()
    }
}
