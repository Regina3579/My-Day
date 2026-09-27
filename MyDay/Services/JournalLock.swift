import LocalAuthentication

/// Face ID / Touch ID (with passcode fallback) protection for the journal.
enum JournalLock {
    static var canAuthenticate: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    private static var biometry: LABiometryType {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType
    }

    static var methodName: String {
        switch biometry {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        default: "Passcode"
        }
    }

    static var symbolName: String {
        switch biometry {
        case .faceID: "faceid"
        case .touchID: "touchid"
        default: "lock.fill"
        }
    }

    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return false }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}
