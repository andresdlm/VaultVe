import SwiftUI

// Compact palette picker that returns a hex string. Stays inside the app's
// curated terminal palette so accounts/categories blend with the design.
struct AccentColorPicker: View {
    static let palette: [String] = [
        "00FF88", // vAcc green
        "00C8FF", // vInfo cyan
        "F0A500", // vAmber
        "FF3B30", // vDanger red
        "B47BFF", // soft purple
        "FF7AD9", // pink
        "E8F0ED", // off-white
        "5A7A6E", // muted teal
    ]

    let label: String
    @Binding var selected: String
    var options: [String] = AccentColorPicker.palette

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).vLabel()
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { hex in
                    let active = hex.uppercased() == selected.uppercased()
                    Button {
                        selected = hex
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(hex: hex))
                                .frame(width: 28, height: 28)
                            if active {
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(Color.vTx1, lineWidth: 2)
                                    .frame(width: 28, height: 28)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
    }
}
