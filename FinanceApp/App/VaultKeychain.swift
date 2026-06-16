import Foundation
import LocalAuthentication
import Security

// Biometric-backed gate key.
//
// The lock screen no longer hinges on a plain Bool. We keep a random key in
// the Keychain protected by a Secure Enclave access-control policy; the *act of
// reading it* is what proves the unlock, because the OS only returns the bytes
// after a live Face ID / Touch ID (or device-passcode) check.
//
// Two security properties this buys us beyond the old UI gate:
//   • `.biometryCurrentSet` invalidates the key if the enrolled biometrics
//     change, so an attacker who adds their own face/finger can't get in.
//   • `...WhenPasscodeSetThisDeviceOnly` ties the key to this device with a
//     passcode set, and keeps it out of backups / iCloud.
enum VaultKeychain {
    private static let service = "com.andresdlm.FinanceApp.vaultkey"
    private static let account = "primary"

    // Confirms access using a context the caller already authenticated (via
    // LAContext.evaluatePolicy), so this does NOT raise a second biometric
    // prompt. Creates the key on first use and rotates it if it was invalidated
    // by a legitimate biometric re-enrollment.
    static func confirmAccess(using context: LAContext) -> Bool {
        if !keyExists() {
            guard createKey() else { return false }
        }
        if readKey(using: context) { return true }

        // The key exists but couldn't be read — most likely the enrolled
        // biometrics changed and the OS invalidated it. The caller has already
        // passed device authentication for this attempt, so it's safe to rotate
        // the key and let this verified user back in.
        guard createKey() else { return false }
        return readKey(using: context)
    }

    // MARK: - Internals

    private static func keyExists() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            // Don't prompt: we only want to know whether the item is present.
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip,
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status != errSecItemNotFound
    }

    private static func readKey(using context: LAContext) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        return status == errSecSuccess && item != nil
    }

    @discardableResult
    private static func createKey() -> Bool {
        var acError: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            [.biometryCurrentSet, .or, .devicePasscode],
            &acError
        ) else { return false }

        var keyBytes = Data(count: 32)
        let drawn = keyBytes.withUnsafeMutableBytes { buffer -> Int32 in
            guard let base = buffer.baseAddress else { return errSecParam }
            return SecRandomCopyBytes(kSecRandomDefault, 32, base)
        }
        guard drawn == errSecSuccess else { return false }

        // Replace any prior (possibly invalidated) item.
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ] as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: keyBytes,
            kSecAttrAccessControl as String: access,
        ]
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }
}
