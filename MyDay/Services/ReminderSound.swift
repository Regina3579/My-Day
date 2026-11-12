import Foundation

/// The sounds a to-do's reminder can arrive with, chosen in Settings → Sounds & Haptics →
/// Reminder Sound (Gentle Bloom until another is chosen). Each is a WAV in Resources/Sounds made
/// by `scripts/make_sounds.py`, as loud to the ear as Gentle Bloom (the soft ones a little
/// quieter). Apple's rules for a notification sound: Linear PCM in a WAV (or AIFF, CAF), under
/// 30 seconds, in the main bundle or in the app's Library/Sounds folder.
enum ReminderSound: String, CaseIterable, Identifiable {
    case gentleBloom = "gentle_bloom"
    case sparklingSunrise = "sparkling_sunrise"
    case sparklingSunriseSoft = "sparkling_sunrise_soft"
    case gentleFlute = "gentle_flute"
    case softMelodicFlute = "soft_melodic_flute"
    case softTing = "soft_ting"
    case morningHarp = "morning_harp"
    case windChimes = "wind_chimes"
    case happyMarimba = "happy_marimba"

    var id: String { rawValue }

    /// The one chosen in Settings (an unknown name, say from a later version, means Gentle Bloom).
    static var chosen: ReminderSound {
        UserDefaults.standard.string(forKey: Prefs.reminderSound).flatMap(ReminderSound.init) ?? .gentleBloom
    }

    /// The sound reminders arrive with: the one chosen, or Gentle Bloom while a Pro sound waits
    /// for My Day Pro (the choice is kept for when Pro is back).
    static var current: ReminderSound {
        chosen.applying(pro: MyDayPro.wasActive)
    }

    /// Every sound but Gentle Bloom comes with My Day Pro.
    var isPro: Bool { self != .gentleBloom }

    /// This sound, or Gentle Bloom if it needs My Day Pro and `pro` is off.
    func applying(pro: Bool) -> ReminderSound {
        isPro && !pro ? .gentleBloom : self
    }

    var title: String {
        switch self {
        case .gentleBloom: "Gentle Bloom"
        case .sparklingSunrise: "Sparkling Sunrise"
        case .sparklingSunriseSoft: "Sparkling Sunrise – Soft Version"
        case .gentleFlute: "My Day – Gentle Flute"
        case .softMelodicFlute: "My Day – Soft Melodic Flute"
        case .softTing: "Soft Ting"
        case .morningHarp: "Morning Harp"
        case .windChimes: "Wind Chimes"
        case .happyMarimba: "Happy Marimba"
        }
    }

    /// What it sounds like, in a few words.
    var kind: String {
        switch self {
        case .gentleBloom: "Little music box"
        case .sparklingSunrise: "Bright musical bells"
        case .sparklingSunriseSoft: "Gentle musical bells"
        case .gentleFlute: "Soft, peaceful flute melody"
        case .softMelodicFlute: "Peaceful flute melody"
        case .softTing: "One gentle crystal ting"
        case .morningHarp: "Rising harp notes"
        case .windChimes: "Breezy tuned chimes"
        case .happyMarimba: "Cheerful wooden notes"
        }
    }

    /// The file's length, as `make_sounds.py` makes it.
    var seconds: Double {
        switch self {
        case .gentleBloom: 3
        case .sparklingSunrise, .sparklingSunriseSoft, .windChimes: 4
        case .gentleFlute: 4.4
        case .softMelodicFlute: 4.5
        case .softTing: 1.5
        case .morningHarp: 3.5
        case .happyMarimba: 2.5
        }
    }

    /// "Bright musical bells · 4 seconds".
    var detail: String { "\(kind) · \(seconds.formatted()) seconds" }

    var fileName: String { rawValue + ".wav" }

    /// The file in the app: at the bundle's top level, or in a Sounds folder.
    var bundleURL: URL? {
        Bundle.main.url(forResource: rawValue, withExtension: "wav")
            ?? Bundle.main.url(forResource: rawValue, withExtension: "wav", subdirectory: "Sounds")
    }
}
