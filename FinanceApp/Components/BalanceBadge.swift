import SwiftUI

// Small monospaced pill showing a value formatted in a given currency.
struct BalanceBadge: View {
    let amount: Double
    let currency: Currency
    var dec: Int? = nil
    var color: Color = .vTx1
    var size: CGFloat = 12

    var body: some View {
        let d = dec ?? currency.defaultDecimals
        HStack(spacing: 4) {
            Text(currency.symbol)
                .font(.system(size: size - 1, design: .monospaced))
                .foregroundStyle(Color.vTx2)
            Text(vFmt(amount, dec: d))
                .vNum(size: size, color: color)
        }
    }
}
