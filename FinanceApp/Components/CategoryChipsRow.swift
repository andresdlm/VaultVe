import SwiftUI

// Horizontal scrolling chip picker for selecting a Category.
struct CategoryChipsRow: View {
    let label: String
    let categories: [Category]
    @Binding var selected: Category?
    var includeNone: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).vLabel()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if includeNone {
                        ChipButton(
                            glyph: "∗",
                            label: "Ninguna",
                            color: .vTx2,
                            active: selected == nil
                        ) {
                            selected = nil
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                    ForEach(categories) { c in
                        ChipButton(
                            glyph: c.glyph,
                            label: c.name,
                            color: Color(hex: c.colorHex),
                            active: selected?.id == c.id
                        ) {
                            selected = c
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
        }
    }
}

struct ChipButton: View {
    let glyph: String
    let label: String
    let color: Color
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(glyph)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(active ? color : .vTx2)
                Text(label)
                    .vLabel(size: 9, color: active ? color : .vTx2)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(active ? color.opacity(0.12) : Color.vBg.opacity(0.5),
                        in: RoundedRectangle(cornerRadius: 5))
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(active ? color.opacity(0.50) : Color.vLine, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
