import UIKit

@MainActor
enum Haptics {
    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Prefs.haptics) as? Bool ?? true
    }

    static func tap() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Kept ready, so a tick is felt at once.
    private static let softGenerator = UIImpactFeedbackGenerator(style: .soft)

    /// A very light tap, for ticking a to-do or priority off.
    static func softTap() {
        guard isEnabled else { return }
        softGenerator.impactOccurred(intensity: 0.6)
        softGenerator.prepare()
    }

    static func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// A light click, as a dragged card moves to a new place.
    static func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// A wrong pattern or passcode.
    static func error() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
