import SwiftUI

struct ConfigView: View {
    @State private var viewModel: ConfigViewModel

    init(engine: VaultEngine) {
        _viewModel = State(initialValue: ConfigViewModel(engine: engine))
    }

    var body: some View {
        @Bindable var vm = viewModel
        return ScrollView {
            VStack(spacing: 8) {
                ScreenTitle(title: "Config", sub: "v1.0 · SYSTEM READY")
                    .padding(.bottom, 4)

                // ─── Security ────────────────────────────────────────────────
                VStack(spacing: 0) {
                    ConfigSectionHeader(label: "SEGURIDAD")
                    TerminalSeparator(style: .dashed)
                    ConfigToggleRow(label: "FACE ID", isOn: Binding(
                        get: { viewModel.faceIdEnabled },
                        set: { viewModel.faceIdEnabled = $0 }
                    ))
                    TerminalSeparator(style: .dashed)
                    ConfigRow(label: "MÉTODO BIOMÉTRICO", value: "FaceID / TouchID")
                }
                .padding(.horizontal, 14)
                .solidCard()

                // ─── Storage ─────────────────────────────────────────────────
                VStack(spacing: 0) {
                    ConfigSectionHeader(label: "ALMACENAMIENTO")
                    TerminalSeparator(style: .dashed)
                    ConfigRow(label: "MOTOR", value: "SwiftData (local)")
                    TerminalSeparator(style: .dashed)
                    ConfigToggleRow(label: "RESPALDO iCLOUD", isOn: Binding(
                        get: { viewModel.iCloudSyncEnabled },
                        set: { viewModel.iCloudSyncEnabled = $0 }
                    ))
                    if viewModel.showICloudReminder {
                        TerminalSeparator(style: .dashed)
                        HStack(spacing: 6) {
                            Text("⚠").foregroundStyle(Color.vAmber)
                            Text("// REINICIA LA APP PARA APLICAR EL CAMBIO").vLabel(size: 9, color: .vAmber)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 14)
                .solidCard()

                // ─── General ─────────────────────────────────────────────────
                VStack(spacing: 0) {
                    ConfigSectionHeader(label: "GENERAL")
                    TerminalSeparator(style: .dashed)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MONEDA BASE").vLabel()
                        Text("// USADA PARA EL PATRIMONIO TOTAL Y REPORTES")
                            .vLabel(size: 9, color: .vTx3)
                        CurrencyPicker(selected: Binding(
                            get: { viewModel.baseCurrency },
                            set: { viewModel.baseCurrency = $0 }
                        ), label: "")
                    }
                    .padding(.vertical, 12)
                }
                .padding(.horizontal, 14)
                .solidCard()

                // ─── Rates ───────────────────────────────────────────────────
                VStack(spacing: 0) {
                    ConfigSectionHeader(label: "TASAS DE CAMBIO")
                    TerminalSeparator(style: .dashed)
                    HStack(spacing: 6) {
                        Text("// 1 \(viewModel.baseCurrency.code) =")
                            .vLabel(size: 9, color: .vTx3)
                        Text("X \(viewModel.baseCurrency.code) · CONVERSIÓN A LA BASE")
                            .vLabel(size: 9, color: .vTx3)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    TerminalSeparator(style: .dashed)

                    ForEach(viewModel.nonBaseCurrencies) { c in
                        Button {
                            viewModel.showRateEditor = c
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            HStack {
                                Text(c.symbol)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.vTx2)
                                    .frame(width: 22)
                                Text(c.code).vLabel(color: .vTx1)
                                Text("· \(c.label)").vLabel(color: .vTx2)
                                Spacer()
                                let r = viewModel.rate(for: c)
                                if r > 0 {
                                    Text("\(vFmt(r, dec: 4)) \(c.code) / 1 \(viewModel.baseCurrency.code)")
                                        .vNum(size: 11, color: .vAmber)
                                } else {
                                    Text("SIN TASA").vLabel(size: 9, color: .vDanger)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.vTx3)
                            }
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        if c != viewModel.nonBaseCurrencies.last { TerminalSeparator(style: .dashed) }
                    }
                }
                .padding(.horizontal, 14)
                .solidCard()

                // ─── Categories ──────────────────────────────────────────────
                VStack(spacing: 0) {
                    ConfigSectionHeader(label: "CATEGORÍAS")
                    TerminalSeparator(style: .dashed)
                    Button {
                        viewModel.showCategoriesSheet = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack {
                            Text("GESTIONAR CATEGORÍAS").vLabel(color: .vAcc)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.vAcc)
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .solidCard()

                HStack(spacing: 4) {
                    Text("// VAULT · MVVM · SWIFTDATA · IOS 26").vLabel(size: 9, color: .vTx3)
                    BlinkingCursor(color: .vTx3, height: 9)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background { VaultBackground() }
        .sheet(item: $vm.showRateEditor) { currency in
            RateEditorSheet(
                currency: currency,
                baseCurrency: viewModel.baseCurrency,
                initialRate: viewModel.rate(for: currency)
            ) { rate in
                viewModel.updateRate(currency, unitsPerBase: rate)
            }
        }
        .sheet(isPresented: $vm.showCategoriesSheet) {
            CategoriesManagerSheet(engine: viewModel.engine)
        }
    }
}

struct RateEditorSheet: View {
    let currency: Currency
    let baseCurrency: Currency
    let initialRate: Double
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    private var rateValue: Double {
        Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    private var canSave: Bool { rateValue > 0 }

    var body: some View {
        ZStack {
            VaultBackground()
            ScrollView {
                VStack(spacing: 14) {
                    FormHeader(
                        title: "Tasa \(currency.code)",
                        subtitle: "CONVERSIÓN A \(baseCurrency.code)"
                    )
                    .padding(.bottom, 6)

                    VStack(spacing: 0) {
                        HStack(spacing: 5) {
                            Text("1").vNum(size: 14, color: .vAcc)
                            Text(baseCurrency.code).vLabel(color: .vTx2)
                            Text("=").vLabel(color: .vTx3)
                            Text("X").vNum(size: 14, color: .vAmber)
                            Text(currency.code).vLabel(color: .vTx2)
                        }
                        Text("// CUÁNTOS \(currency.code) EQUIVALEN A 1 \(baseCurrency.code)")
                            .vLabel(size: 9, color: .vTx3)
                            .padding(.top, 4)
                    }
                    .padding(12)
                    .glassCard()

                    VStack(spacing: 12) {
                        TerminalField(
                            label: "TASA",
                            placeholder: "0.0000",
                            text: $text,
                            keyboard: .decimalPad,
                            prefix: currency.symbol,
                            suffix: "/ 1 \(baseCurrency.code)"
                        )
                    }
                    .padding(14)
                    .solidCard()

                    TerminalActionButton(title: "GUARDAR TASA", color: .vAmber, disabled: !canSave) {
                        onSave(rateValue)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        dismiss()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(.thinMaterial)
        .presentationDragIndicator(.visible)
        .onAppear {
            text = initialRate > 0 ? String(format: "%.4f", initialRate) : ""
        }
    }
}

struct ConfigSectionHeader: View {
    let label: String
    var body: some View {
        HStack { Text(label).vLabel(color: .vTx2); Spacer() }
            .padding(.vertical, 10)
    }
}

struct ConfigRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).vLabel()
            Spacer()
            Text(value).vNum(size: 13)
        }
        .padding(.vertical, 12)
    }
}

struct ConfigToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label).vLabel()
            Spacer()
            Button {
                isOn.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Text("[\(isOn ? "■" : " ")] \(isOn ? "ON" : "OFF")")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(isOn ? Color.vAcc : Color.vTx3)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
    }
}
