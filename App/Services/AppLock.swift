import Foundation
import LocalAuthentication

/// Optional Face ID or passcode lock, so reflections stay private when someone else picks up the phone.
@MainActor
final class AppLock: ObservableObject {
    @Published private(set) var isLocked = false
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.key) }
    }

    private static let key = "appLockEnabled"
    private var isAuthenticating = false

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.key)
        isLocked = isEnabled
    }

    /// "Face ID", "Touch ID", "Optic ID" or "passcode", for labels.
    var methodName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "passcode"
        }
    }

    var isAvailable: Bool { LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) }

    func lockIfEnabled() {
        if isEnabled { isLocked = true }
    }

    func unlock() {
        guard isLocked, !isAuthenticating else { return }
        isAuthenticating = true
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock your Ikigai Atlas") { success, _ in
            Task { @MainActor in
                self.isAuthenticating = false
                if success { self.isLocked = false }
            }
        }
    }

    /// Turning the lock on asks for authentication first, so nobody locks themselves out by accident.
    func setEnabled(_ on: Bool) {
        guard on else { isEnabled = false; return }
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Turn on the lock for your Ikigai Atlas") { success, _ in
            Task { @MainActor in self.isEnabled = success }
        }
    }
}
