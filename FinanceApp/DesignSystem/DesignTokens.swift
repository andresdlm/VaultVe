import SwiftUI

let vCardRadius:  CGFloat = 8
let vModalRadius: CGFloat = 16

extension Color {
    static let vBg     = Color(hex: "080C0E")
    static let vSurf   = Color(hex: "0D1417")
    static let vAcc    = Color(hex: "00FF88")
    static let vAmber  = Color(hex: "F0A500")
    static let vDanger = Color(hex: "FF3B30")
    static let vInfo   = Color(hex: "00C8FF")
    static let vTx1    = Color(hex: "E8F0ED")
    static let vTx2    = Color(hex: "5A7A6E")
    static let vTx3    = Color(hex: "2A3D35")
    static let vLine   = Color(hex: "1A2E25")

    init(hex: String) {
        let s = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var n: UInt64 = 0
        Scanner(string: s).scanHexInt64(&n)
        let r, g, b: UInt64
        switch s.count {
        case 3: (r, g, b) = ((n >> 8)*17, (n >> 4 & 0xF)*17, (n & 0xF)*17)
        case 6: (r, g, b) = (n >> 16, n >> 8 & 0xFF, n & 0xFF)
        default: (r, g, b) = (255, 255, 255)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
    }
}

func vFmt(_ n: Double, dec: Int = 2) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.minimumFractionDigits = dec
    f.maximumFractionDigits = dec
    f.usesGroupingSeparator = true
    return f.string(from: n as NSNumber) ?? String(format: "%.\(dec)f", n)
}

extension View {
    func vLabel(size: CGFloat = 10, color: Color = .vTx2) -> some View {
        self
            .font(.system(size: size, weight: .medium, design: .monospaced))
            .foregroundStyle(color)
            .textCase(.uppercase)
            .tracking(1.2)
    }

    func vNum(size: CGFloat, color: Color = .vTx1, weight: Font.Weight = .bold) -> some View {
        self
            .font(.system(size: size, weight: weight, design: .monospaced))
            .foregroundStyle(color)
            .monospacedDigit()
    }
}
