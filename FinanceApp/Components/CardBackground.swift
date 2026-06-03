import SwiftUI

struct GlassCardStyle: ViewModifier {
    var cornerRadius: CGFloat = vCardRadius
    var border: Color = Color.white.opacity(0.10)

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.vSurf.opacity(0.55))
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(border, lineWidth: 1)
            }
            .environment(\.colorScheme, .dark)
    }
}

struct SolidCardStyle: ViewModifier {
    var cornerRadius: CGFloat = vCardRadius

    func body(content: Content) -> some View {
        content
            .background(Color.vSurf, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.vLine, lineWidth: 1)
            }
    }
}

extension View {
    func glassCard(radius: CGFloat = vCardRadius, border: Color = Color.white.opacity(0.10)) -> some View {
        modifier(GlassCardStyle(cornerRadius: radius, border: border))
    }

    func solidCard(radius: CGFloat = vCardRadius) -> some View {
        modifier(SolidCardStyle(cornerRadius: radius))
    }
}
