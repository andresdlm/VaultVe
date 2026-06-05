import SwiftUI
import LocalAuthentication

// Locks the app behind Face ID / Touch ID when enabled.
// Re-locks on background → foreground.
struct BiometricGate<Content: View>: View {
    @Environment(VaultEngine.self) private var engine
    @Environment(\.scenePhase)     private var scenePhase

    @State private var unlocked   = false
    @State private var attempting = false
    @State private var feedback: AuthFeedback? = nil

    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            if !engine.faceIdEnabled || unlocked {
                content()
            } else {
                LockScreen(
                    attempting: attempting,
                    feedback: feedback,
                    onUnlock: attempt
                )
                .task { attempt() }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Re-lock when returning from background. Keep unlocked across .inactive (control-center swipes, etc.).
            if phase == .background {
                unlocked = false
                feedback = nil
            }
        }
    }

    private func attempt() {
        guard !attempting else { return }

        let ctx = LAContext()
        ctx.localizedFallbackTitle = "Usar código"

        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err) else {
            feedback = AuthFeedback(error: err)
            return
        }

        // Clear any stale message before a fresh attempt.
        withAnimation(.easeInOut(duration: 0.2)) { feedback = nil }
        attempting = true

        ctx.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Acceder a VaultVE"
        ) { ok, evalErr in
            DispatchQueue.main.async {
                attempting = false
                if ok {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation(.easeOut(duration: 0.25)) { unlocked = true }
                } else {
                    let fb = AuthFeedback(error: evalErr)
                    if fb?.tone == .error {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
                    withAnimation(.easeInOut(duration: 0.2)) { feedback = fb }
                }
            }
        }
    }
}

// User-facing translation of an authentication failure. Distinguishes real
// errors from benign cancellations so we don't alarm the user when they simply
// dismissed the Face ID prompt.
struct AuthFeedback {
    enum Tone { case error, neutral }

    let tone: Tone
    let icon: String
    let title: String
    let message: String

    // Returns nil when there is nothing worth surfacing.
    init?(error: Error?) {
        guard let error else { return nil }

        let nsError = error as NSError

        // Anything outside the LocalAuthentication domain gets a generic message.
        guard nsError.domain == LAErrorDomain,
              let code = LAError.Code(rawValue: nsError.code) else {
            tone = .error
            icon = "exclamationmark.triangle.fill"
            title = "No se pudo autenticar"
            message = "Ocurrió un problema al verificar tu identidad. Vuelve a intentarlo."
            return
        }

        switch code {
        case .userCancel, .systemCancel, .appCancel:
            tone = .neutral
            icon = "faceid"
            title = "Autenticación cancelada"
            message = "Toca «Desbloquear» para intentarlo de nuevo."

        case .userFallback:
            tone = .neutral
            icon = "key.fill"
            title = "Usar código"
            message = "Introduce tu código para acceder a VaultVE."

        case .authenticationFailed:
            tone = .error
            icon = "exclamationmark.shield.fill"
            title = "No te reconocimos"
            message = "Face ID no pudo verificar tu identidad. Vuelve a intentarlo."

        case .biometryLockout:
            tone = .error
            icon = "lock.trianglebadge.exclamationmark.fill"
            title = "Face ID bloqueado"
            message = "Demasiados intentos fallidos. Usa tu código para desbloquear Face ID."

        case .biometryNotEnrolled:
            tone = .error
            icon = "faceid"
            title = "Face ID no configurado"
            message = "Configura Face ID en Ajustes o usa tu código de acceso."

        case .biometryNotAvailable:
            tone = .error
            icon = "faceid"
            title = "Face ID no disponible"
            message = "Tu dispositivo no tiene Face ID activo. Usa tu código de acceso."

        case .passcodeNotSet:
            tone = .error
            icon = "lock.slash.fill"
            title = "Sin código de acceso"
            message = "Activa un código en Ajustes para proteger VaultVE."

        default:
            tone = .error
            icon = "exclamationmark.triangle.fill"
            title = "No se pudo autenticar"
            message = "Ocurrió un problema al verificar tu identidad. Vuelve a intentarlo."
        }
    }
}

private struct LockScreen: View {
    let attempting: Bool
    let feedback: AuthFeedback?
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
                    .foregroundStyle(attempting ? Color.vAcc : (feedback?.tone == .error ? Color.vDanger : Color.vAcc))
                    .padding(.top, 20)
                    .animation(.easeInOut(duration: 0.2), value: feedback?.tone)

                VStack(spacing: 6) {
                    Text("BLOQUEADO").vLabel(size: 11, color: .vAcc)
                    HStack(spacing: 4) {
                        Text(attempting ? "// AUTENTICANDO" : "// AUTENTICA PARA CONTINUAR")
                            .vLabel(size: 10, color: .vTx2)
                        if attempting { BlinkingCursor(color: .vAcc, height: 10) }
                    }
                }
                .padding(.top, 4)

                if let feedback, !attempting {
                    AuthFeedbackCard(feedback: feedback)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                Button(action: onUnlock) {
                    HStack(spacing: 8) {
                        Image(systemName: "faceid").font(.system(size: 13, weight: .bold))
                        Text(feedback == nil ? "DESBLOQUEAR" : "REINTENTAR")
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

// Styled error/notice surfaced on the lock screen, matching the app's
// terminal / liquid-glass aesthetic instead of raw red text.
private struct AuthFeedbackCard: View {
    let feedback: AuthFeedback

    private var accent: Color { feedback.tone == .error ? .vDanger : .vAmber }

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: feedback.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(feedback.title)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(accent)
                    .textCase(.uppercase)
                    .tracking(1)
                Text(feedback.message)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.vTx2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .glassCard(border: accent.opacity(0.35))
    }
}
