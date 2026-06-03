import SwiftUI

struct VaultBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Color.vBg

                Circle()
                    .fill(Color.vAcc.opacity(0.05))
                    .frame(width: 500, height: 500)
                    .offset(x: w * 0.4, y: -h * 0.35)
                    .blur(radius: 100)

                Circle()
                    .fill(Color.vInfo.opacity(0.04))
                    .frame(width: 400, height: 400)
                    .offset(x: -w * 0.35, y: h * 0.55)
                    .blur(radius: 80)

                Canvas { ctx, size in
                    let spacing: CGFloat = 22
                    let color = Color.vTx2.opacity(0.10)
                    var x: CGFloat = spacing / 2
                    while x < size.width {
                        var y: CGFloat = spacing / 2
                        while y < size.height {
                            ctx.fill(Path(ellipseIn: CGRect(x: x - 0.5, y: y - 0.5, width: 1, height: 1)), with: .color(color))
                            y += spacing
                        }
                        x += spacing
                    }
                }
            }
            .clipped()
        }
        .ignoresSafeArea()
    }
}
