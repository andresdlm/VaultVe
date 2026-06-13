import SwiftUI

struct AccountDetailView: View {
    let account: Account
    let engine: VaultEngine

    @Environment(\.dismiss) private var dismiss

    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var showArchiveConfirm = false

    private var movements: [Movement] {
        var items: [Movement] = []
        for tx in account.transactions ?? [] {
            items.append(.transaction(tx))
        }
        for tr in account.transfersOut ?? [] {
            items.append(.transferOut(tr))
        }
        for tr in account.transfersIn ?? [] {
            items.append(.transferIn(tr))
        }
        return items.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            VaultBackground()
            ScrollView {
                VStack(spacing: 14) {
                    AccountCardView(account: account)
                        .padding(.top, 8)

                    HStack(spacing: 8) {
                        DetailActionButton(label: "EDITAR", color: .vAcc, glyph: "pencil") {
                            showEdit = true
                        }
                        DetailActionButton(
                            label: account.archived ? "DESARCHIVAR" : "ARCHIVAR",
                            color: .vAmber,
                            glyph: "tray.full"
                        ) {
                            showArchiveConfirm = true
                        }
                        DetailActionButton(label: "BORRAR", color: .vDanger, glyph: "trash") {
                            showDeleteConfirm = true
                        }
                    }

                    if movements.isEmpty {
                        EmptyMovementsCard()
                    } else {
                        VStack(spacing: 0) {
                            HStack {
                                Text("MOVIMIENTOS").vLabel(color: .vTx2)
                                Spacer()
                                Text("\(movements.count)").vNum(size: 12, color: .vAcc)
                            }
                            TerminalSeparator(style: .dashed).padding(.vertical, 9)

                            ForEach(movements) { m in
                                MovementRow(movement: m, account: account)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .solidCard()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.large])
        .presentationBackground(.thinMaterial)
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showEdit) {
            EditAccountForm(account: account)
        }
        .alert("Borrar cuenta", isPresented: $showDeleteConfirm) {
            Button("Cancelar", role: .cancel) {}
            Button("Borrar", role: .destructive) {
                try? engine.deleteAccount(account)
                dismiss()
            }
        } message: {
            Text("Esto borrará la cuenta y todos sus movimientos. No se puede deshacer.")
        }
        .alert(account.archived ? "Desarchivar cuenta" : "Archivar cuenta", isPresented: $showArchiveConfirm) {
            Button("Cancelar", role: .cancel) {}
            Button(account.archived ? "Desarchivar" : "Archivar") {
                try? engine.setArchived(account, archived: !account.archived)
                dismiss()
            }
        } message: {
            Text(account.archived
                 ? "La cuenta volverá a aparecer en pickers y listas."
                 : "La cuenta no aparecerá en pickers ni en el resumen, pero sus movimientos se conservan.")
        }
    }
}

private struct DetailActionButton: View {
    let label: String
    let color: Color
    let glyph: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: glyph)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6).strokeBorder(color.opacity(0.35), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyMovementsCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("◌").font(.system(size: 24, design: .monospaced)).foregroundStyle(Color.vTx3)
            Text("SIN MOVIMIENTOS").vLabel(color: .vTx2)
            Text("// AÚN NO HAY ACTIVIDAD EN ESTA CUENTA").vLabel(size: 9, color: .vTx3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .solidCard()
    }
}

private enum Movement: Identifiable {
    case transaction(Transaction)
    case transferOut(Transfer)
    case transferIn(Transfer)

    var id: String {
        switch self {
        case .transaction(let t): "t\(t.id)"
        case .transferOut(let t): "o\(t.id)"
        case .transferIn(let t):  "i\(t.id)"
        }
    }

    var date: Date {
        switch self {
        case .transaction(let t): t.date
        case .transferOut(let t): t.date
        case .transferIn(let t):  t.date
        }
    }
}

private struct MovementRow: View {
    let movement: Movement
    let account: Account

    var body: some View {
        switch movement {
        case .transaction(let tx):
            Row(
                glyph: tx.kind == .expense ? "▼" : "▲",
                glyphColor: tx.kind == .expense ? .vDanger : .vAcc,
                title: tx.merchant.isEmpty ? "(sin nombre)" : tx.merchant,
                sub: "\(tx.category?.name ?? "Sin categoría") · \(tx.displayDate)",
                amount: tx.amount,
                amountSign: tx.kind == .expense ? -1 : 1,
                currency: tx.currency,
                amountColor: tx.kind == .expense ? .vDanger : .vAcc
            )
        case .transferOut(let tr):
            Row(
                glyph: "→",
                glyphColor: .vInfo,
                title: "A \(tr.destAccount?.name ?? "—")",
                sub: "Transferencia · \(tr.displayDate)",
                amount: tr.sourceAmount,
                amountSign: -1,
                currency: tr.sourceCurrency,
                amountColor: .vDanger
            )
        case .transferIn(let tr):
            Row(
                glyph: "←",
                glyphColor: .vInfo,
                title: "De \(tr.sourceAccount?.name ?? "—")",
                sub: "Transferencia · \(tr.displayDate)",
                amount: tr.destAmount,
                amountSign: 1,
                currency: tr.destCurrency,
                amountColor: .vAcc
            )
        }
    }
}

private struct Row: View {
    let glyph: String
    let glyphColor: Color
    let title: String
    let sub: String
    let amount: Double
    let amountSign: Int
    let currency: Currency
    let amountColor: Color

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(glyph)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(glyphColor)
                .frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.vTx1)
                    .lineLimit(1)
                Text(sub).vLabel(size: 9, color: .vTx3)
            }
            Spacer()
            HStack(spacing: 2) {
                Text(amountSign < 0 ? "−" : "+")
                    .vNum(size: 12, color: amountColor)
                BalanceBadge(amount: amount, currency: currency, color: amountColor, size: 13)
            }
        }
        .padding(.vertical, 6)
    }
}
