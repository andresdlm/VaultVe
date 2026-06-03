import SwiftUI

struct ConfigView: View {
    @State private var viewModel: ConfigViewModel

    init(engine: VaultEngine) {
        _viewModel = State(initialValue: ConfigViewModel(engine: engine))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ScreenTitle(title: "Config", sub: "v1.0 · SYSTEM READY")
                    .padding(.bottom, 4)

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

                VStack(spacing: 0) {
                    ConfigSectionHeader(label: "DASHBOARD")
                    TerminalSeparator(style: .dashed)
                    ConfigSegmentRow(
                        label: "LAYOUT",
                        options: DashboardLayout.allCases.map(\.label),
                        selectedIndex: DashboardLayout.allCases.firstIndex(of: viewModel.selectedLayout) ?? 0
                    ) { idx in viewModel.selectedLayout = DashboardLayout.allCases[idx] }

                    TerminalSeparator(style: .dashed)
                    ConfigSegmentRow(
                        label: "TASA ACTIVA",
                        options: ["Paralela", "BCV"],
                        selectedIndex: viewModel.selectedRate == .paralela ? 0 : 1
                    ) { idx in viewModel.selectedRate = idx == 0 ? .paralela : .bcv }
                }
                .padding(.horizontal, 14)
                .solidCard()

                VStack(spacing: 0) {
                    ConfigSectionHeader(label: "TASAS")
                    TerminalSeparator(style: .dashed)
                    ConfigRow(label: "BCV", value: "Bs \(vFmt(viewModel.currentRates.bcv))")
                    TerminalSeparator(style: .dashed)
                    ConfigRow(label: "PARALELA", value: "Bs \(vFmt(viewModel.currentRates.paralela))")
                    TerminalSeparator(style: .dashed)
                    Button {
                        viewModel.showRateEditor = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack {
                            Text("ACTUALIZAR TASAS").vLabel(color: .vAcc)
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
                    Text("// VAULTVE · MVVM · SWIFTDATA · IOS 26").vLabel(size: 9, color: .vTx3)
                    BlinkingCursor(color: .vTx3, height: 9)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background { VaultBackground() }
        .sheet(isPresented: $viewModel.showRateEditor) {
            RateEditorSheet(
                initialBcv: viewModel.currentRates.bcv,
                initialParalela: viewModel.currentRates.paralela
            ) { bcv, paralela in
                viewModel.updateRates(bcv: bcv, paralela: paralela)
            }
        }
    }
}

struct RateEditorSheet: View {
    let initialBcv: Double
    let initialParalela: Double
    let onSave: (Double, Double) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var bcv: String = ""
    @State private var paralela: String = ""

    private var bcvValue: Double { Double(bcv.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var paralelaValue: Double { Double(paralela.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var canSave: Bool { bcvValue > 0 && paralelaValue > 0 }

    var body: some View {
        ZStack {
            VaultBackground()
            ScrollView {
                VStack(spacing: 14) {
                    FormHeader(title: "Tasas BCV / Paralela", subtitle: "ACTUALIZA LAS TASAS DE REFERENCIA")
                        .padding(.bottom, 6)

                    VStack(spacing: 12) {
                        TerminalField(
                            label: "BCV",
                            placeholder: "0.00",
                            text: $bcv,
                            keyboard: .decimalPad,
                            prefix: "Bs", suffix: "/ $"
                        )
                        TerminalField(
                            label: "PARALELA",
                            placeholder: "0.00",
                            text: $paralela,
                            keyboard: .decimalPad,
                            prefix: "Bs", suffix: "/ $"
                        )
                    }
                    .padding(14)
                    .solidCard()

                    TerminalActionButton(title: "GUARDAR TASAS", color: .vAmber, disabled: !canSave) {
                        onSave(bcvValue, paralelaValue)
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
            bcv      = initialBcv > 0      ? String(format: "%.2f", initialBcv) : ""
            paralela = initialParalela > 0 ? String(format: "%.2f", initialParalela) : ""
        }
    }
}

struct ConfigSectionHeader: View {
    let label: String
    var body: some View {
        HStack {
            Text(label).vLabel(color: .vTx2)
            Spacer()
        }
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

struct ConfigSegmentRow: View {
    let label: String
    let options: [String]
    let selectedIndex: Int
    let onChange: (Int) -> Void

    var body: some View {
        HStack {
            Text(label).vLabel()
            Spacer()
            HStack(spacing: 5) {
                ForEach(options.indices, id: \.self) { i in
                    let active = i == selectedIndex
                    Button {
                        onChange(i)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text(options[i])
                            .vLabel(size: 9, color: active ? .vAcc : .vTx3)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(active ? Color.vAcc.opacity(0.10) : .clear,
                                        in: RoundedRectangle(cornerRadius: 4))
                            .overlay {
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(active ? Color.vAcc.opacity(0.40) : .clear, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 12)
    }
}
