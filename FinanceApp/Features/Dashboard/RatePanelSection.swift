import SwiftUI

struct RatePanelSection: View {
    let vm: DashboardViewModel

    var body: some View {
        let r = vm.rates
        let spreadUp = r.paralela >= r.paralelaPrev

        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Text("≣")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color.vAmber)
                    Text("TASAS").vLabel(color: .vAmber)
                }
                Spacer()
                Text("HOY · \(r.date)").vLabel(size: 9, color: .vTx3)
            }

            Color.vAmber.opacity(0.25).frame(height: 1).padding(.vertical, 10)

            RateRow(label: "BCV", value: "Bs \(vFmt(r.bcv)) / $")
            RateRow(label: "PARALELA", value: "Bs \(vFmt(r.paralela)) / $", active: true) {
                StatusBadge(kind: .amber, text: "ACTIVA")
            }

            TerminalSeparator(style: .dashed).padding(.vertical, 8)

            HStack(alignment: .firstTextBaseline) {
                Text("SPREAD").vLabel()
                Spacer()
                Text("+\(vFmt(vm.spreadPct))%").vNum(size: 14, color: .vTx1)
                HStack(spacing: 3) {
                    Text(spreadUp ? "▲" : "▼")
                    Text("\(vFmt(abs(r.spreadPrevPct), dec: 1))% hoy")
                }
                .vLabel(size: 9, color: spreadUp ? .vAmber : .vAcc)
            }
            .padding(.vertical, 5)

            RateRow(label: "TU ÚLTIMA", value: "Bs \(vFmt(r.paralelaPrev)) / $") {
                Text("(AYER)").vLabel(size: 9, color: .vTx3)
            }
        }
        .padding(14)
        .glassCard(border: Color.vAmber.opacity(0.22))
    }
}

struct RateRow<N: View>: View {
    let label: String
    let value: String
    var active: Bool = false
    @ViewBuilder let note: () -> N

    init(label: String, value: String, active: Bool = false, @ViewBuilder note: @escaping () -> N) {
        self.label = label
        self.value = value
        self.active = active
        self.note = note
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).vLabel(color: active ? .vAmber : .vTx2)
            Spacer()
            HStack(spacing: 8) {
                Text(value).vNum(size: 14, color: active ? .vAmber : .vTx1)
                note()
            }
        }
        .padding(.vertical, 5)
    }
}

extension RateRow where N == EmptyView {
    init(label: String, value: String, active: Bool = false) {
        self.init(label: label, value: value, active: active) { EmptyView() }
    }
}
