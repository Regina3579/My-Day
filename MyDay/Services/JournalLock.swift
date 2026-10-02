import CryptoKit
import Foundation
import LocalAuthentication
import Security

/// How the journal is unlocked, chosen in Settings → Journal.
enum JournalLockMethod: String, CaseIterable, Identifiable {
    /// Face ID or Touch ID, with the iPhone passcode as a fallback.
    case biometrics
    /// A shape drawn by joining at least four of nine dots.
    case pattern
    /// A 4- or 6-digit number.
    case passcode

    var id: String { rawValue }

    /// "Face ID", "Pattern" or "Number Passcode".
    var title: String {
        switch self {
        case .biometrics: JournalLock.methodName
        case .pattern: "Pattern"
        case .passcode: "Number Passcode"
        }
    }

    /// What is asked for, in a sentence: "Your journal asks for your pattern…".
    var askedFor: String {
        switch self {
        case .biometrics: JournalLock.methodName
        case .pattern: "your pattern"
        case .passcode: "your passcode"
        }
    }

    var detail: String {
        switch self {
        case .biometrics: "Unlock with your face, just like your iPhone."
        case .pattern: "Draw a shape by joining the dots."
        case .passcode: "Type a 4- or 6-digit number."
        }
    }

    var symbol: String {
        switch self {
        case .biometrics: JournalLock.symbolName
        case .pattern: "circle.grid.3x3.fill"
        case .passcode: "123.rectangle.fill"
        }
    }

    /// A pattern or passcode is kept for it (Face ID uses the iPhone's own).
    var usesSecret: Bool { self != .biometrics }

    /// The chosen method (Face ID until another is chosen).
    static var current: JournalLockMethod {
        JournalLockMethod(rawValue: UserDefaults.standard.string(forKey: Prefs.journalLockMethod) ?? "") ?? .biometrics
    }
}

/// The journal lock: Face ID / Touch ID (with the passcode as a fallback), or a pattern or
/// number passcode of your own.
enum JournalLock {
    /// Wrong tries allowed before a wait.
    static let freeTries = 5

    enum Attempt: Equatable {
        case success
        /// Wrong; how many tries are left before a wait.
        case wrong(triesLeft: Int)
        /// Too many wrong tries: the next try is allowed at this time.
        case waiting(until: Date)
    }

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
        default: "iPhone Passcode"
        }
    }

    static var symbolName: String {
        switch biometry {
        case .faceID: "faceid"
        case .touchID: "touchid"
        default: "lock.fill"
        }
    }

    /// The chosen method's name, as the Calendar shows it ("Locked with Pattern.").
    static var currentMethodName: String { JournalLockMethod.current.title }

    /// Face ID, Touch ID or the iPhone passcode.
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

    // MARK: Pattern and passcode

    /// The digits in the passcode (4 or 6).
    static var passcodeLength: Int {
        UserDefaults.standard.integer(forKey: Prefs.journalPasscodeLength) == 6 ? 6 : 4
    }

    /// When the next try is allowed, while waiting after too many wrong tries.
    static var waitUntil: Date? {
        let time = UserDefaults.standard.double(forKey: Prefs.journalLockWaitUntil)
        return time > Date().timeIntervalSince1970 ? Date(timeIntervalSince1970: time) : nil
    }

    /// Checks a pattern ("0-4-8") or passcode. After `freeTries` wrong tries each one more
    /// means a wait: 30 seconds, then a minute more each time, up to 5 minutes.
    static func attempt(_ secret: String, for method: JournalLockMethod) -> Attempt {
        let defaults = UserDefaults.standard
        if let waitUntil { return .waiting(until: waitUntil) }
        if JournalSecretStore.matches(secret, for: method) {
            resetTries()
            return .success
        }
        let failures = defaults.integer(forKey: Prefs.journalLockFailures) + 1
        defaults.set(failures, forKey: Prefs.journalLockFailures)
        guard failures >= freeTries else { return .wrong(triesLeft: freeTries - failures) }
        let seconds = min(300, 30 + 60 * Double(failures - freeTries))
        let until = Date().addingTimeInterval(seconds)
        defaults.set(until.timeIntervalSince1970, forKey: Prefs.journalLockWaitUntil)
        return .waiting(until: until)
    }

    static func resetTries() {
        UserDefaults.standard.removeObject(forKey: Prefs.journalLockFailures)
        UserDefaults.standard.removeObject(forKey: Prefs.journalLockWaitUntil)
    }

    /// Turns the lock on with `method`, keeping `secret` for a pattern or passcode and
    /// forgetting any other. Returns false, changing nothing, when the pattern or passcode
    /// couldn't be kept.
    @discardableResult
    static func enable(_ method: JournalLockMethod, secret: String? = nil) -> Bool {
        let defaults = UserDefaults.standard
        if method.usesSecret {
            guard let secret, JournalSecretStore.save(secret, for: method) else { return false }
            if method == .passcode {
                defaults.set(secret.count, forKey: Prefs.journalPasscodeLength)
            }
        }
        for other in JournalLockMethod.allCases where other.usesSecret && other != method {
            JournalSecretStore.remove(for: other)
        }
        defaults.set(method.rawValue, forKey: Prefs.journalLockMethod)
        defaults.set(true, forKey: Prefs.journalLock)
        resetTries()
        return true
    }

    /// Turns the lock off and forgets the pattern and passcode.
    static func disable() {
        for method in JournalLockMethod.allCases where method.usesSecret {
            JournalSecretStore.remove(for: method)
        }
        UserDefaults.standard.set(false, forKey: Prefs.journalLock)
        resetTries()
    }

    /// The method the lock screen asks for: the chosen one, or Face ID / the iPhone passcode
    /// when a pattern or passcode was chosen but is missing (after a restore to a new iPhone,
    /// which doesn't bring it along).
    static var effectiveMethod: JournalLockMethod {
        let method = JournalLockMethod.current
        return method.usesSecret && !JournalSecretStore.hasSecret(for: method) ? .biometrics : method
    }
}

/// Keeps the pattern and passcode in the Keychain, on this iPhone only, as a salted and
/// stretched SHA-256 hash: the pattern or number itself is never stored.
enum JournalSecretStore {
    private static let service = "com.regina3579.myday.journal-lock"
    private static let saltLength = 16
    private static let rounds = 20_000

    static func hasSecret(for method: JournalLockMethod) -> Bool {
        read(account: method.rawValue) != nil
    }

    #if DEBUG
    /// Screenshot runs only: CI builds the app unsigned, and an unsigned app has no Keychain
    /// in the simulator, so the demo pattern and passcode are kept in memory there.
    private static var screenshotRecords: [String: Data] = [:]
    #endif

    @discardableResult
    static func save(_ secret: String, for method: JournalLockMethod) -> Bool {
        let salt = Data((0..<saltLength).map { _ in UInt8.random(in: .min ... .max) })
        let record = salt + digest(secret, salt: salt)
        remove(for: method)
        var item = query(account: method.rawValue)
        item[kSecValueData as String] = record
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let status = SecItemAdd(item as CFDictionary, nil)
        #if DEBUG
        if status == errSecMissingEntitlement && DebugLaunchRoute.isScreenshotRun {
            screenshotRecords[method.rawValue] = record
            return true
        }
        #endif
        return status == errSecSuccess
    }

    static func matches(_ secret: String, for method: JournalLockMethod) -> Bool {
        guard let record = read(account: method.rawValue), record.count > saltLength else { return false }
        let salt = record.prefix(saltLength)
        let stored = record.dropFirst(saltLength)
        let given = digest(secret, salt: Data(salt))
        // Compare every byte, so the time taken doesn't hint at how much matched.
        guard given.count == stored.count else { return false }
        return zip(given, stored).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }

    static func remove(for method: JournalLockMethod) {
        SecItemDelete(query(account: method.rawValue) as CFDictionary)
        #if DEBUG
        screenshotRecords[method.rawValue] = nil
        #endif
    }

    private static func digest(_ secret: String, salt: Data) -> Data {
        var hash = Data(SHA256.hash(data: salt + Data(secret.utf8)))
        for _ in 0..<rounds {
            hash = Data(SHA256.hash(data: salt + hash))
        }
        return hash
    }

    private static func query(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    private static func read(account: String) -> Data? {
        #if DEBUG
        if let record = screenshotRecords[account] { return record }
        #endif
        var item = query(account: account)
        item[kSecReturnData as String] = true
        item[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(item as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }
}
