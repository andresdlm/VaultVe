import SwiftUI
import LocalAuthentication

// Locks the app behind Face ID / Touch ID when enabled.
// Re-locks on background → foreground.
struct BiometricGate<Content: View>: View {
    @Environment(VaultEngine.self) private var engine
    @Environment(\.scenePhase)     private var scenePhase

    @State private var unlocked   = false
    @State private var attempting = false
    @State private var errorText: String? = nil

    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            if !engine.faceIdEnabled || unlocked {
                content()
            } else {
                LockScreen(
                    attempting: attempting,
                    errorText: errorText,
                    onUnlock: attempt
                )
                .task { attempt() }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Re-lock when returning from background. Keep unlocked across .inactive (control-center swipes, etc.).
            if phase == .background { unlocked = false }
        }
    }

    private func attempt() {
        let ctx = LAContext()
        ctx.localizedFallbackTitle = "Usar código"
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err) else {
            errorText = err?.localizedDescription ?? "Autenticación no disponible."
            return
        }
        attempting = true
        ctx.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Acceder a VaultVE"
        ) { ok, evalErr in
            DispatchQueue.main.async {
                attempting = false
                if ok {
                    withAnimation(.easeOut(duration: 0.25)) { unlocked = true }
                } else {
                    errorText = evalErr?.localizedDescription
                }
            }
        }
    }
}

private struct LockScreen: View {
    let attempting: Bool
    let errorText: String?
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            VaultBackground()

            VStack(spacing: 18) {
                Spacer()
                HStack(spacing: 0) {
                    Text("[").foregroundStyle(Color.vTx3)
                    Text(" VAULT").foregroundStyle(Color.vTx1)
                    Text("VE").foregroundStyle(Color.vAcc)
                    Text(" ]").foregroundStyle(Color.vTx3)
                }
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .tracking(3)

                Image(systemName: "faceid")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(Color.vAcc)
                    .padding(.top, 20)

                VStack(spacing: 6) {
                    Text("BLOQUEADO").vLabel(size: 11, color: .vAcc)
                    HStack(spacing: 4) {
                        Text(attempting ? "// AUTENTICANDO" : "// AUTENTICA PARA CONTINUAR")
                            .vLabel(size: 10, color: .vTx2)
                        if attempting { BlinkingCursor(color: .vAcc, height: 10) }
                    }
                }
                .padding(.top, 4)

                if let err = errorText {
                    Text(err)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.vDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                Button(action: onUnlock) {
                    HStack(spacing: 8) {
                        Image(systemName: "faceid").font(.system(size: 13, weight: .bold))
                        Text("DESBLOQUEAR")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .tracking(1)
                    }
                    .foregroundStyle(Color.vBg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.vAcc, in: RoundedRectangle(cornerRadius: 6))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .disabled(attempting)
            }
        }
    }
}
