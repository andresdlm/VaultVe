import SwiftUI

struct TerminalSeparator: View {
    enum Style { case heavy, dashed, solid }
    var style: Style = .heavy

    var body: some View {
        switch style {
        case .heavy:
            Canvas { ctx, size in
                let count = max(1, Int(size.width / 7) + 2)
                let t = Text(String(repeating: "━", count: count))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.vLine)
                ctx.draw(t, at: CGPoint(x: 0, y: size.height / 2), anchor: .leading)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 14)
        case .solid:
            Color.vLine.frame(height: 1)
        case .dashed:
            Canvas { ctx, size in
                var x: CGFloat = 0
                while x < size.width {
                    let w = min(6, size.width - x)
                    ctx.fill(Path(CGRect(x: x, y: 0, width: w, height: 1)), with: .color(Color.vLine))
                    x += 10
                }
            }
            .frame(height: 1)
        }
    }
}
