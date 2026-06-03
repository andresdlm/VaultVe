import SwiftUI

enum BadgeKind {
    case green, amber, danger, info

    var color: Color {
        switch self {
        case .green:  return .vAcc
        case .amber:  return .vAmber
        case .danger: return .vDanger
        case .info:   return .vInfo
        }
    }
}

struct StatusBadge: View {
    let kind: BadgeKind
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(kind.color).frame(width: 5, height: 5)
            Text(text)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundStyle(kind.color)
                .textCase(.uppercase)
                .tracking(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(kind.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 4))
    }
}
