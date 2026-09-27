import Foundation

/// UserDefaults keys used with `@AppStorage`.
enum Prefs {
    static let userName = "userName"
    static let carryOver = "carryOverUnfinishedTasks"
    static let showCompleted = "showCompletedTasks"
    static let haptics = "hapticsEnabled"
    static let journalLock = "journalLockEnabled"
    static let morningOn = "morningReminderOn"
    static let morningTime = "morningReminderSeconds"
    static let eveningOn = "eveningReminderOn"
    static let eveningTime = "eveningReminderSeconds"
    static let didSeedWelcome = "didSeedWelcomeContent"
}
