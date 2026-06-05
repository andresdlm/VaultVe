import SwiftUI

struct GastosView: View {
    @State private var viewModel: GastosViewModel

    init(engine: VaultEngine) {
        _viewModel = State(initialValue: GastosViewModel(engine: engine))
    }

    var body: some View {
        @Bindable var vm = viewModel
        return ScrollView {
            VStack(spacing: 8) {
                HStack(alignment: .top) {
                    ScreenTitle(title: "Gastos", sub: "TRAZABILIDAD POR GASTO · TOCA PARA EXPANDIR")
                    AddGastoGlassButton { viewModel.showAddSheet = true }
                }
                .padding(.bottom, 4)

                GastoFilterBar(
                    searchText: $vm.searchText,
                    timeRange: $vm.timeRange,
                    selectedCategory: $vm.selectedCategory,
                    visibleCount: viewModel.gastos.count,
                    vesTotal: viewModel.filteredVesTotal,
                    hasActiveFilters: viewModel.hasActiveFilters,
                    onClear: { withAnimation(.easeInOut(duration: 0.2)) { viewModel.clearFilters() } }
                )
                .padding(.bottom, 4)

                if viewModel.gastos.isEmpty {
                    EmptyGastosState(
                        filtered: viewModel.hasActiveFilters && !viewModel.ledgerIsEmpty,
                        onAdd: { viewModel.showAddSheet = true },
                        onClear: { withAnimation(.easeInOut(duration: 0.2)) { viewModel.clearFilters() } }
                    )
                } else {
                    ForEach(viewModel.gastos) { gasto in
                        let trace = viewModel.trace(for: gasto)
                        GastoCard(
                            trace: trace,
                            expanded: viewModel.expandedGastoId == gasto.id
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.toggleExpand(gasto.id)
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background { VaultBackground() }
        .sheet(isPresented: $vm.showAddSheet) {
            AddGastoForm()
        }
    }
}

// Liquid-glass "+" affordance sitting next to the screen title.
private struct AddGastoGlassButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.vAcc)
                .frame(width: 40, height: 40)
                .glassCard(border: Color.vAcc.opacity(0.30))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Agregar gasto")
    }
}

// Search + time + category filters rendered in the terminal/liquid-glass style.
private struct GastoFilterBar: View {
    @Binding var searchText: String
    @Binding var timeRange: GastoTimeRange
    @Binding var selectedCategory: GastoCategory?
    let visibleCount: Int
    let vesTotal: Double
    let hasActiveFilters: Bool
    let onClear: () -> Void

    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            // Description search
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
                    Button {
                        searchText = ""
                    } label: {
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

            // Time range
            HStack(spacing: 6) {
                Text("RANGO").vLabel(size: 9, color: .vTx3)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(GastoTimeRange.allCases) { range in
                            FilterChip(
                                glyph: nil,
                                label: range.label,
                                active: timeRange == range
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) { timeRange = range }
                            }
                        }
                    }
                }
            }

            // Category
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    FilterChip(glyph: "∗", label: "Todas", active: selectedCategory == nil) {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = nil }
                    }
                    ForEach(GastoCategory.allCases, id: \.self) { c in
                        FilterChip(glyph: c.glyph, label: c.label, active: selectedCategory == c) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = selectedCategory == c ? nil : c
                            }
                        }
                    }
                }
            }

            TerminalSeparator(style: .dashed)

            // Result summary
            HStack(spacing: 6) {
                Text("\(visibleCount)").vNum(size: 12, color: .vAcc)
                Text(visibleCount == 1 ? "GASTO" : "GASTOS").vLabel(size: 9, color: .vTx2)
                Spacer()
                Text("TOTAL").vLabel(size: 9, color: .vTx3)
                Text("Bs \(vFmt(vesTotal))").vNum(size: 12, color: .vAmber)
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
}

private struct FilterChip: View {
    let glyph: String?
    let label: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 5) {
                if let glyph {
                    Text(glyph).font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(active ? Color.vAcc : Color.vTx2)
                }
                Text(label).vLabel(size: 9, color: active ? .vAcc : .vTx2)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(active ? Color.vAcc.opacity(0.10) : Color.vBg.opacity(0.5),
                        in: RoundedRectangle(cornerRadius: 5))
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(active ? Color.vAcc.opacity(0.45) : Color.vLine, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyGastosState: View {
    let filtered: Bool
    let onAdd: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(filtered ? "⦰" : "◌")
                .font(.system(size: 28, design: .monospaced))
                .foregroundStyle(Color.vTx3)
            Text(filtered ? "SIN COINCIDENCIAS" : "SIN GASTOS").vLabel(color: .vTx2)
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
                Text("// AÑADE TU PRIMER GASTO").vLabel(size: 9, color: .vTx3)
                Button(action: onAdd) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus").font(.system(size: 10, weight: .bold))
                        Text("NUEVO GASTO").vLabel(size: 9, color: .vAcc)
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

struct GastoCard: View {
    let trace: GastoTrace
    let expanded: Bool
    let onTap: () -> Void

    var body: some View {
        let cheaper = trace.diffVsParalela < 0

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("GASTO #\(trace.gasto.displayId)")
                    .vNum(size: 11).foregroundStyle(Color.vTx3)
                Spacer()
                Text(trace.gasto.displayDate).vLabel(size: 9, color: .vTx3)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(trace.gasto.merchant)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.vTx1)
                Spacer()
                Text(trace.gasto.category)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.vTx2)
                    .tracking(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.vBg.opacity(0.5), in: RoundedRectangle(cornerRadius: 3))
                    .overlay { RoundedRectangle(cornerRadius: 3).strokeBorder(Color.vLine, lineWidth: 1) }
            }
            .padding(.vertical, 9)

            TerminalSeparator(style: .dashed)

            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PAGADO").vLabel(size: 9)
                    Text("Bs \(vFmt(trace.gasto.vesAmount))").vNum(size: 17, color: .vAmber)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("COSTO REAL").vLabel(size: 9)
                    Text("$ \(vFmt(trace.totalUsdCost))").vNum(size: 17, color: .vAcc)
                }
            }
            .padding(.top, 9)

            if trace.paralela > 0 {
                StatusBadge(
                    kind: cheaper ? .green : .danger,
                    text: "\(cheaper ? "▼" : "▲") $\(vFmt(abs(trace.diffVsParalela))) vs paralela"
                )
                .padding(.top, 8)
            }

            if expanded {
                GastoTraceDetail(trace: trace)
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(13)
        .glassCard()
        .onTapGesture(perform: onTap)
    }
}

struct GastoTraceDetail: View {
    let trace: GastoTrace

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("COSTO REAL DE ESTE GASTO").vLabel(size: 9, color: .vAmber)
            TerminalSeparator(style: .heavy).padding(.vertical, 8)

            CostTraceNode(amount: "Bs \(vFmt(trace.gasto.vesAmount))", amtColor: .vAmber,
                          desc: "VES gastados", showArrow: true)

            ForEach(trace.vesLegs) { vleg in
                CostTraceNode(
                    amount: "LOTE #\(vleg.vesLot.displayId)",
                    amtColor: .vTx1,
                    desc: "Bs \(vFmt(vleg.vesAmount)) · tasa Bs \(vFmt(vleg.vesLot.p2pRate)) · \(vleg.vesLot.displayDate.prefix(10))",
                    showArrow: true
                )
                ForEach(vleg.usdtLegs) { uleg in
                    CostTraceNode(
                        amount: "₮ \(vFmt(uleg.usdtAmount))",
                        amtColor: .vInfo,
                        desc: "USDT usados ← LOTE #\(uleg.usdtLot.displayId) · tasa $\(vFmt(uleg.usdtLot.costPerUsdt, dec: 4)) · fee $\(vFmt(uleg.usdtLot.feeUsd))",
                        showArrow: true
                    )
                    CostTraceNode(
                        amount: "$ \(vFmt(uleg.usdAmount)) USD",
                        amtColor: .vAcc,
                        desc: "COSTO RAÍZ pagados originalmente desde el banco",
                        showArrow: false
                    )
                }
            }

            TerminalSeparator(style: .heavy).padding(.vertical, 8)
            Text("RESUMEN DE ESTE GASTO").vLabel(size: 9)
            TerminalSeparator(style: .dashed).padding(.vertical, 6)

            LoteDataRow(key: "PAGADO EN VES",    value: "Bs \(vFmt(trace.gasto.vesAmount))",   valueColor: .vAmber)
            LoteDataRow(key: "COSTO REAL USD",   value: "$ \(vFmt(trace.totalUsdCost))",       valueColor: .vAcc)
            LoteDataRow(key: "TASA EFECTIVA",    value: "Bs \(vFmt(trace.effRate)) / $")
            if trace.paralela > 0 {
                LoteDataRow(key: "PARALELA HOY",     value: "Bs \(vFmt(trace.paralela)) / $", valueColor: .vAmber)
                HStack {
                    Text("DIFERENCIA").vLabel()
                    Spacer()
                    Text("\(trace.diffVsParalela < 0 ? "-" : "+")\(vFmt(abs(trace.diffVsParalela))) vs paralela")
                        .vNum(size: 13, color: trace.diffVsParalela < 0 ? .vAcc : .vDanger)
                }
                .padding(.vertical, 3)
            }
        }
    }
}

struct CostTraceNode: View {
    let amount: String
    let amtColor: Color
    let desc: String
    let showArrow: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 0) {
                Circle().fill(amtColor).frame(width: 5, height: 5).padding(.top, 4)
                if showArrow {
                    Color.vLine.frame(width: 1).frame(height: 30)
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 5))
                        .foregroundStyle(Color.vLine)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(amount).vNum(size: 13, color: amtColor)
                Text(desc)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.vTx2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, showArrow ? 0 : 4)
    }
}
