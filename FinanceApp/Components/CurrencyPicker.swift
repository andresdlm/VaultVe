import SwiftUI

// Horizontal scrolling chip picker for selecting a Currency.
struct CurrencyPicker: View {
    @Binding var selected: Currency
    var label: String = "MONEDA"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).vLabel()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Currency.allCases) { c in
                        let active = c == selected
                        Button {
                            selected = c
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            HStack(spacing: 5) {
                                Text(c.symbol)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(active ? Color.vAcc : Color.vTx2)
                                Text(c.code)
                                    .vLabel(size: 9, color: active ? .vAcc : .vTx2)
                            }
                            .padding(.horizontal, 10)
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
