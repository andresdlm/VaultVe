import SwiftUI

// Shared header for tab screens.
struct ScreenTitle: View {
    let title: String
    let sub: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("VAULT //").vLabel(size: 9, color: .vTx3)
            Text(title)
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundStyle(Color.vTx1)
                .tracking(0.5)
            Text(sub).vLabel(size: 9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Two-column key/value row used in summary cards and forms.
struct LoteDataRow: View {
    let key: String
    let value: String
    var valueColor: Color = .vTx1

    var body: some View {
        HStack {
            Text(key).vLabel()
            Spacer()
            Text(value).vNum(size: 13, color: valueColor)
        }
        .padding(.vertical, 3)
    }
}
