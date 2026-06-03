import SwiftUI

struct BlinkingCursor: View {
    var color: Color = .vAcc
    var height: CGFloat = 14

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.53)) { tl in
            let on = Int(tl.date.timeIntervalSinceReferenceDate / 0.53).isMultiple(of: 2)
            RoundedRectangle(cornerRadius: 1)
                .fill(color)
                .frame(width: max(height * 0.5, 5), height: height)
                .opacity(on ? 1 : 0)
        }
    }
}
