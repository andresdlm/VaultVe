import SwiftUI

enum NuevaOpKind: String, Identifiable, CaseIterable {
    case expense, income, transfer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expense:  "GASTO"
        case .income:   "INGRESO"
        case .transfer: "TRANSFERENCIA"
        }
    }

    var subtitle: String {
        switch self {
        case .expense:  "Registra un pago"
        case .income:   "Registra un depósito o ingreso"
        case .transfer: "Mueve dinero entre cuentas"
        }
    }

    var glyph: String {
        switch self {
        case .expense:  "▼"
        case .income:   "▲"
        case .transfer: "⇄"
        }
    }

    var color: Color {
        switch self {
        case .expense:  .vDanger
        case .income:   .vAcc
        case .transfer: .vInfo
        }
    }
}

struct NuevaOperacionSheet: View {
    @Environment(VaultEngine.self) private var engine
    @State private var selected: NuevaOpKind? = nil

    var body: some View {
        ZStack {
            VaultBackground()
            ScrollView {
                VStack(spacing: 14) {
                    FormHeader(title: "Nueva operación", subtitle: "ELIGE EL TIPO DE MOVIMIENTO")
                        .padding(.bottom, 4)

                    ForEach(NuevaOpKind.allCases) { kind in
                        NuevaOpButton(kind: kind) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            selected = kind
                        }
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
            case .expense:  AddExpenseForm()
            case .income:   AddIncomeForm()
            case .transfer: AddTransferForm()
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
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(kind.color)
                    .frame(width: 40, alignment: .leading)
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
