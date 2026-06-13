import SwiftUI

struct MovementCard: View {
    let item: MovementItem
    let expanded: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var confirmDelete = false

    var body: some View {
        Group {
            switch item {
            case .transaction(let tx):
                TransactionCard(tx: tx, expanded: expanded, onTap: onTap,
                                onEdit: onEdit, onDelete: { confirmDelete = true })
            case .transfer(let tr):
                TransferCard(tr: tr, expanded: expanded, onTap: onTap,
                             onEdit: onEdit, onDelete: { confirmDelete = true })
            }
        }
        .alert("Borrar movimiento", isPresented: $confirmDelete) {
            Button("Cancelar", role: .cancel) {}
            Button("Borrar", role: .destructive) { onDelete() }
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
    }
}

private struct TransactionCard: View {
    let tx: Transaction
    let expanded: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let accent: Color = tx.kind == .expense ? .vDanger : .vAcc
        let signedAmount = tx.kind == .expense ? -tx.amount : tx.amount

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Text(tx.kind == .expense ? "▼ GASTO" : "▲ INGRESO")
                        .vLabel(size: 10, color: accent)
                    Text("#\(tx.displayId)")
                        .vNum(size: 10, color: .vTx3)
                }
                Spacer()
                Text(tx.displayDate).vLabel(size: 9, color: .vTx3)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(tx.merchant.isEmpty ? "(sin nombre)" : tx.merchant)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.vTx1)
                Spacer()
                if let cat = tx.category {
                    HStack(spacing: 4) {
                        Text(cat.glyph)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color(hex: cat.colorHex))
                        Text(cat.name)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.vTx2)
                            .tracking(1)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.vBg.opacity(0.5), in: RoundedRectangle(cornerRadius: 3))
                    .overlay {
                        RoundedRectangle(cornerRadius: 3).strokeBorder(Color.vLine, lineWidth: 1)
                    }
                }
            }
            .padding(.vertical, 9)

            TerminalSeparator(style: .dashed)

            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tx.account?.name ?? "—").vLabel(size: 9)
                    Text(tx.kind == .expense ? "MONTO" : "INGRESO").vLabel(size: 9, color: .vTx3)
                }
                Spacer()
                HStack(spacing: 3) {
                    Text(signedAmount < 0 ? "−" : "+")
                        .vNum(size: 17, color: accent)
                    BalanceBadge(amount: abs(signedAmount), currency: tx.currency, color: accent, size: 17)
                }
            }
            .padding(.top, 9)

            if expanded {
                ExpandedActions(
                    note: tx.note,
                    onEdit: onEdit,
                    onDelete: onDelete
                )
                .padding(.top, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(13)
        .glassCard(border: accent.opacity(0.22))
        .onTapGesture(perform: onTap)
    }
}

private struct TransferCard: View {
    let tr: Transfer
    let expanded: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Text("⇄ TRANSFERENCIA").vLabel(size: 10, color: .vInfo)
                    Text("#\(tr.displayId)").vNum(size: 10, color: .vTx3)
                }
                Spacer()
                Text(tr.displayDate).vLabel(size: 9, color: .vTx3)
            }
            .padding(.bottom, 9)

            TerminalSeparator(style: .dashed)

            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("DE").vLabel(size: 9)
                    Text(tr.sourceAccount?.name ?? "—")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.vTx1)
                    BalanceBadge(amount: tr.sourceAmount, currency: tr.sourceCurrency, color: .vDanger, size: 13)
                }
                Spacer()
                Image(systemName: "arrow.right").font(.system(size: 12)).foregroundStyle(Color.vInfo)
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("A").vLabel(size: 9)
                    Text(tr.destAccount?.name ?? "—")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.vTx1)
                    BalanceBadge(amount: tr.destAmount, currency: tr.destCurrency, color: .vAcc, size: 13)
                }
            }
            .padding(.top, 10)

            if tr.crossCurrency {
                HStack {
                    Text("TASA").vLabel(size: 9, color: .vTx3)
                    Spacer()
                    Text("1 \(tr.sourceCurrency.code) = \(vFmt(tr.impliedRate, dec: 4)) \(tr.destCurrency.code)")
                        .vNum(size: 11, color: .vAmber)
                }
                .padding(.top, 8)
            }

            if expanded {
                ExpandedActions(
                    note: tr.note,
                    onEdit: onEdit,
                    onDelete: onDelete
                )
                .padding(.top, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(13)
        .glassCard(border: Color.vInfo.opacity(0.22))
        .onTapGesture(perform: onTap)
    }
}

private struct ExpandedActions: View {
    let note: String?
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TerminalSeparator(style: .heavy).padding(.bottom, 8)
            if let note, !note.isEmpty {
                Text("NOTA").vLabel(size: 9)
                Text(note)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.vTx2)
                    .padding(.top, 3)
                    .padding(.bottom, 8)
            }
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil").font(.system(size: 11, weight: .bold))
                        Text("EDITAR")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1)
                    }
                    .foregroundStyle(Color.vAcc)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.vAcc.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6).strokeBorder(Color.vAcc.opacity(0.35), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash").font(.system(size: 11, weight: .bold))
                        Text("BORRAR")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1)
                    }
                    .foregroundStyle(Color.vDanger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.vDanger.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6).strokeBorder(Color.vDanger.opacity(0.35), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
