import Foundation

/// UserDefaults keys used with `@AppStorage`.
enum Prefs {
    static let userName = "userName"
    static let carryOver = "carryOverUnfinishedTasks"
    static let showCompleted = "showCompletedTasks"
    /// Whether Today's Priority's Completed list is open.
    static let showCompletedPriorities = "showCompletedPriorities"
    /// Set once the first-time "Add your task with your voice" tip has been shown on To-Dos.
    static let didShowVoiceTip = "didShowVoiceAddTip"
    /// Set once the first-time "A New Quote Every Day!" tip has been shown on To-Dos.
    static let didShowQuoteTip = "didShowTodosQuoteTip"
    static let haptics = "hapticsEnabled"
    /// Settings → Sounds & Haptics → Task Completion Sound.
    static let taskCompletionSound = "taskCompletionSoundOn"
    static let journalLock = "journalLockEnabled"
    /// How the journal is unlocked: a `JournalLockMethod` raw value (Face ID when unset).
    static let journalLockMethod = "journalLockMethod"
    /// The number of digits in the journal passcode (4 or 6).
    static let journalPasscodeLength = "journalPasscodeLength"
    /// Wrong pattern or passcode tries in a row, and when the next try is allowed after too
    /// many (seconds since 1970).
    static let journalLockFailures = "journalLockFailures"
    static let journalLockWaitUntil = "journalLockWaitUntil"
    static let morningOn = "morningReminderOn"
    static let morningTime = "morningReminderSeconds"
    static let eveningOn = "eveningReminderOn"
    static let eveningTime = "eveningReminderSeconds"
    /// Set by earlier versions, which added example to-dos, a priority and a journal page.
    static let didSeedWelcome = "didSeedWelcomeContent"
    /// Set once the starter templates have been added to the store (see `TemplateLibrary`).
    static let didSeedTemplates = "didSeedStarterTemplates"
    /// Set once those examples have been removed (see `SampleContent`).
    static let didRemoveSamples = "didRemoveSampleContent"
}
