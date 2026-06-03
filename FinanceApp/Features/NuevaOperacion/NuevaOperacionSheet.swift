import SwiftUI

// Type chooser. Picks which kind of transaction to register, then routes
// to the matching form sheet.
enum NuevaOpKind: String, Identifiable, CaseIterable {
    case income      // USD income (salary)
    case usdtBuy     // USD → USDT
    case vesSale     // USDT → VES
    case gasto       // Gasto in VES

    var id: String { rawValue }
    var title: String {
        switch self {
        case .income:   "INGRESO USD"
        case .usdtBuy:  "USD → USDT"
        case .vesSale:  "USDT → VES"
        case .gasto:    "GASTO VES"
        }
    }
    var subtitle: String {
        switch self {
        case .income:   "Depósito en tu cuenta de banco USA"
        case .usdtBuy:  "Compra P2P de USDT con USD"
        case .vesSale:  "Venta P2P de USDT por bolívares"
        case .gasto:    "Pago realizado en VES"
        }
    }
    var glyph: String {
        switch self {
        case .income:   "↧"
        case .usdtBuy:  "◉ → ◈"
        case .vesSale:  "◈ → ▣"
        case .gasto:    "▣ ↧"
        }
    }
    var color: Color {
        switch self {
        case .income:   .vAcc
        case .usdtBuy:  .vInfo
        case .vesSale:  .vAmber
        case .gasto:    .vDanger
        }
    }
}

struct NuevaOperacionSheet: View {
    @Environment(VaultEngine.self) private var engine
    @Environment(\.dismiss)        private var dismiss

    @State private var selected: NuevaOpKind? = nil

    var body: some View {
        ZStack {
            VaultBackground()
            ScrollView {
                VStack(spacing: 14) {
                    FormHeader(title: "Nueva operación", subtitle: "ELIGE EL TIPO DE TRANSACCIÓN")
                        .padding(.bottom, 4)

                    ForEach(NuevaOpKind.allCases) { kind in
                        NuevaOpButton(kind: kind) { selected = kind }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.thinMaterial)
        .presentationDragIndicator(.visible)
        .sheet(item: $selected) { kind in
            switch kind {
            case .income:   AddUSDIncomeForm()
            case .usdtBuy:  AddUSDTLotForm()
            case .vesSale:  AddVESLotForm()
            case .gasto:    AddGastoForm()
            }
        }
    }
}

private struct NuevaOpButton: View {
    let kind: NuevaOpKind
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Text(kind.glyph)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(kind.color)
                    .frame(width: 60, alignment: .leading)
                VStack(alignment: .leading, spacing: 3) {
                    Text(kind.title)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.vTx1)
                        .tracking(1)
                    Text(kind.subtitle)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.vTx2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.vTx3)
            }
            .padding(14)
            .glassCard(border: kind.color.opacity(0.30))
        }
        .buttonStyle(.plain)
    }
}
