import Foundation

/// UserDefaults keys used with `@AppStorage`.
enum Prefs {
    static let userName = "userName"
    static let carryOver = "carryOverUnfinishedTasks"
    static let showCompleted = "showCompletedTasks"
    /// Whether Today's Priority's Completed list is open.
    static let showCompletedPriorities = "showCompletedPriorities"
    /// Whether a template's Completed list is open (in Templates).
    static let showCompletedTemplateItems = "showCompletedTemplateItems"
    /// Set once the first-time "Add your task with your voice" tip has been shown on To-Dos.
    static let didShowVoiceTip = "didShowVoiceAddTip"
    /// Set once the first-time "A New Quote Every Day!" tip has been shown on To-Dos.
    static let didShowQuoteTip = "didShowTodosQuoteTip"
    /// Set once the first-time "Add photos to your tasks!" tip has been shown on To-Dos.
    static let didShowPhotoTip = "didShowTodosPhotoTip"
    /// Set once the first-time "There's a feeling for every kind of day!" tip has been shown on
    /// the journal's writing page.
    static let didShowMoodTip = "didShowJournalMoodTip"
    /// Set once the first-time "Not sure what to write?" tip has been shown on the journal's
    /// writing page, pointing at Get a Prompt.
    static let didShowPromptTip = "didShowJournalPromptTip"
    static let didShowJournalMenuTip = "didShowJournalMenuTip"
    static let didShowQuickAddTip = "didShowQuickAddTip"
    /// How many times the journal has opened, and the Journal Lock tip's state (see
    /// `JournalLockTipSchedule`).
    static let journalOpenings = "journalOpenings"
    static let journalLockTipDone = "journalLockTipDone"
    static let journalLockTipRemindAt = "journalLockTipRemindAt"
    static let didShowJournalThemeTip = "didShowJournalThemeTip"
    /// Set once the first-time "Task Reminders" tip has been shown on a to-do's Task Details,
    /// pointing at Reminder.
    static let didShowReminderTip = "didShowTaskReminderTip"
    /// Set once the first-time "Your memories are safe" tip has been shown on Settings,
    /// pointing at Sync with iCloud.
    static let didShowICloudTip = "didShowSettingsICloudTip"
    /// The "Enjoying My Day?" rating card (see `RatingPrompt`): the days My Day has been used,
    /// the last of them, how many times the card has asked, when it last asked, and whether
    /// "Rate Now" (or Settings → Rate My Day) was tapped.
    static let ratingActiveDays = "ratingActiveDays"
    static let ratingLastActiveDay = "ratingLastActiveDay"
    static let ratingAsks = "ratingAsks"
    static let ratingLastAsked = "ratingLastAsked"
    static let ratingDone = "ratingDone"
    static let haptics = "hapticsEnabled"
    /// Settings → iCloud → Sync with iCloud (on when unset; see `MyDayStore.syncsWithICloud`).
    static let iCloudSync = "iCloudSyncOn"
    /// Settings → Sounds & Haptics → Task Completion Sound.
    static let taskCompletionSound = "taskCompletionSoundOn"
    /// Settings → Sounds & Haptics → Mood Star Sound.
    static let moodStarSound = "moodStarSoundOn"
    /// Settings → Sounds & Haptics → Reminder Sound: the `ReminderSound` a to-do's reminder
    /// arrives with (Gentle Bloom when unset).
    static let reminderSound = "reminderSound"
    /// Whether My Day Pro was active when the App Store was last asked (see `MyDayPro`).
    static let proActive = "myDayProActive"
    /// Debug builds only: Settings → My Day Pro → Pretend Pro (on, off, or unset for the App Store's answer).
    static let debugPretendPro = "debugPretendPro"
    /// The sticker picker's tab last opened (a `StickerCategory` id).
    static let stickerCategory = "journalStickerCategory"
    /// Settings → Journal → Journal Theme: a `JournalTheme` raw value (Blush Blossom when unset).
    static let journalTheme = "journalTheme"
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
