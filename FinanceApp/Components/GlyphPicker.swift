import SwiftUI

// Picker for a single-character ASCII / unicode glyph used as the account
// or category icon in the terminal-style UI.
struct GlyphPicker: View {
    static let defaultOptions: [String] = ["◉", "◈", "▣", "▢", "⬢", "⬣", "◆", "●", "✚", "✦", "◌", "◐"]

    let label: String
    let options: [String]
    @Binding var selected: String

    init(label: String, options: [String] = GlyphPicker.defaultOptions, selected: Binding<String>) {
        self.label = label
        self.options = options
        self._selected = selected
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).vLabel()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(options, id: \.self) { g in
                        let active = g == selected
                        Button {
                            selected = g
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(g)
                                .font(.system(size: 16, design: .monospaced))
                                .foregroundStyle(active ? Color.vAcc : Color.vTx1)
                                .frame(width: 36, height: 36)
                                .background(active ? Color.vAcc.opacity(0.10) : Color.vBg.opacity(0.5),
                                            in: RoundedRectangle(cornerRadius: 5))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5)
                                        .strokeBorder(active ? Color.vAcc.opacity(0.50) : Color.vLine, lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
