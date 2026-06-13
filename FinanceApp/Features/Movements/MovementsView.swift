import SwiftUI

struct MovementsView: View {
    @State private var viewModel: MovementsViewModel

    init(engine: VaultEngine) {
        _viewModel = State(initialValue: MovementsViewModel(engine: engine))
    }

    var body: some View {
        @Bindable var vm = viewModel
        return ScrollView {
            VStack(spacing: 8) {
                HStack(alignment: .top) {
                    ScreenTitle(
                        title: "Movimientos",
                        sub: "TOCA UN MOVIMIENTO PARA ACCIONES"
                    )
                    AddGlassButton(label: "Nueva operación") {
                        viewModel.showAddSheet = true
                    }
                }
                .padding(.bottom, 4)

                MovementFilterBar(
                    searchText: $vm.searchText,
                    timeRange: $vm.dateRange,
                    typeFilter: $vm.typeFilter,
                    selectedAccount: $vm.selectedAccount,
                    selectedCategory: $vm.selectedCategory,
                    accounts: viewModel.accounts,
                    categories: viewModel.allCategories.filter {
                        viewModel.typeFilter == .income ? $0.kind == .income : $0.kind == .expense
                    },
                    visibleCount: viewModel.visibleCount,
                    hasActiveFilters: viewModel.hasActiveFilters,
                    onClear: {
                        withAnimation(.easeInOut(duration: 0.2)) { viewModel.clearFilters() }
                    }
                )
                .padding(.bottom, 4)

                if viewModel.items.isEmpty {
                    EmptyMovementsState(
                        filtered: viewModel.hasActiveFilters,
                        onAdd: { viewModel.showAddSheet = true },
                        onClear: {
                            withAnimation(.easeInOut(duration: 0.2)) { viewModel.clearFilters() }
                        }
                    )
                } else {
                    ForEach(viewModel.items) { item in
                        MovementCard(
                            item: item,
                            expanded: viewModel.expandedId == item.id,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.toggleExpand(item.id)
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            },
                            onEdit: {
                                switch item {
                                case .transaction(let tx): viewModel.editingTransaction = tx
                                case .transfer(let tr):    viewModel.editingTransfer = tr
                                }
                            },
                            onDelete: {
                                switch item {
                                case .transaction(let tx): viewModel.deleteTransaction(tx)
                                case .transfer(let tr):    viewModel.deleteTransfer(tr)
                                }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background { VaultBackground() }
        .sheet(isPresented: $vm.showAddSheet) {
            NuevaOperacionSheet()
        }
        .sheet(item: $vm.editingTransaction) { tx in
            EditTransactionForm(transaction: tx)
        }
        .sheet(item: $vm.editingTransfer) { tr in
            EditTransferForm(transfer: tr)
        }
    }
}

private struct MovementFilterBar: View {
    @Binding var searchText: String
    @Binding var timeRange: DateRange
    @Binding var typeFilter: MovementTypeFilter
    @Binding var selectedAccount: Account?
    @Binding var selectedCategory: Category?
    let accounts: [Account]
    let categories: [Category]
    let visibleCount: Int
    let hasActiveFilters: Bool
    let onClear: () -> Void

    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(searchFocused ? Color.vAcc : Color.vTx2)
                TextField(
                    "",
                    text: $searchText,
                    prompt: Text("BUSCAR COMERCIO · NOTA")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.vTx3)
                )
                .focused($searchFocused)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.vTx1)
                .tint(Color.vAcc)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.vTx2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.vBg.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(searchFocused ? Color.vAcc.opacity(0.55) : Color.vLine, lineWidth: 1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(MovementTypeFilter.allCases) { t in
                        ChipButton(
                            glyph: glyphFor(t),
                            label: t.label,
                            color: colorFor(t),
                            active: typeFilter == t
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) { typeFilter = t }
                        }
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Text("RANGO").vLabel(size: 9, color: .vTx3)
                    ForEach(DateRange.allCases) { r in
                        ChipButton(
                            glyph: nil,
                            label: r.label,
                            color: .vAcc,
                            active: timeRange == r
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) { timeRange = r }
                        }
                    }
                }
            }

            if !accounts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ChipButton(glyph: "∗", label: "Todas", color: .vTx2,
                                   active: selectedAccount == nil) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedAccount = nil }
                        }
                        ForEach(accounts) { a in
                            ChipButton(
                                glyph: a.glyph,
                                label: a.name,
                                color: Color(hex: a.colorHex),
                                active: selectedAccount?.id == a.id
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedAccount = selectedAccount?.id == a.id ? nil : a
                                }
                            }
                        }
                    }
                }
            }

            if typeFilter != .transfer && !categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ChipButton(glyph: "∗", label: "Todas", color: .vTx2,
                                   active: selectedCategory == nil) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = nil }
                        }
                        ForEach(categories) { c in
                            ChipButton(
                                glyph: c.glyph,
                                label: c.name,
                                color: Color(hex: c.colorHex),
                                active: selectedCategory?.id == c.id
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = selectedCategory?.id == c.id ? nil : c
                                }
                            }
                        }
                    }
                }
            }

            TerminalSeparator(style: .dashed)

            HStack(spacing: 6) {
                Text("\(visibleCount)").vNum(size: 12, color: .vAcc)
                Text(visibleCount == 1 ? "MOVIMIENTO" : "MOVIMIENTOS").vLabel(size: 9, color: .vTx2)
                Spacer()
                if hasActiveFilters {
                    Button(action: onClear) {
                        HStack(spacing: 3) {
                            Image(systemName: "xmark").font(.system(size: 8, weight: .bold))
                            Text("LIMPIAR").vLabel(size: 8, color: .vDanger)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.vDanger.opacity(0.10), in: RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .glassCard()
    }

    private func colorFor(_ t: MovementTypeFilter) -> Color {
        switch t {
        case .all:      .vAcc
        case .expense:  .vDanger
        case .income:   .vAcc
        case .transfer: .vInfo
        }
    }

    private func glyphFor(_ t: MovementTypeFilter) -> String? {
        switch t {
        case .all:      "∗"
        case .expense:  "▼"
        case .income:   "▲"
        case .transfer: "⇄"
        }
    }
}

private struct EmptyMovementsState: View {
    let filtered: Bool
    let onAdd: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(filtered ? "⦰" : "◌")
                .font(.system(size: 28, design: .monospaced))
                .foregroundStyle(Color.vTx3)
            Text(filtered ? "SIN COINCIDENCIAS" : "SIN MOVIMIENTOS").vLabel(color: .vTx2)
            if filtered {
                Text("// AJUSTA O LIMPIA LOS FILTROS").vLabel(size: 9, color: .vTx3)
                Button(action: onClear) {
                    Text("LIMPIAR FILTROS").vLabel(size: 9, color: .vAcc)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .overlay {
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(Color.vAcc.opacity(0.45), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            } else {
                Text("// AGREGA TU PRIMER MOVIMIENTO").vLabel(size: 9, color: .vTx3)
                Button(action: onAdd) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus").font(.system(size: 10, weight: .bold))
                        Text("NUEVO MOVIMIENTO").vLabel(size: 9, color: .vAcc)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(Color.vAcc.opacity(0.45), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .solidCard()
    }
}
