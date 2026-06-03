import SwiftUI

struct AnimatedCounter: View {
    let value: Double
    var dec: Int = 2
    var prefix: String = ""
    var suffix: String = ""
    var size: CGFloat = 16
    var color: Color = .vTx1
    var weight: Font.Weight = .bold

    @State private var display: Double = 0

    var body: some View {
        Text(prefix + vFmt(display, dec: dec) + suffix)
            .vNum(size: size, color: color, weight: weight)
            .contentTransition(.numericText(countsDown: false))
            .animation(.easeOut(duration: 0.65), value: display)
            .onAppear { display = value }
            .onChange(of: value) { _, new in display = new }
    }
}
