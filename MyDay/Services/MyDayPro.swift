import Foundation
import Observation
import StoreKit

/// My Day Pro: an auto-renewable subscription (monthly or yearly) that unlocks the Pro features
/// (`ProFeature`). The to-dos and the journal's writing stay free for everyone.
///
/// Nothing is ever deleted when a subscription ends: photos, voice notes, stickers, moods and
/// reflections already on a to-do or a page stay there to see and play, and can be removed.
/// Only adding or changing Pro things waits for Pro again, and everything unlocks by itself
/// as soon as the App Store says the subscription is active.
@MainActor
@Observable
final class MyDayPro {
    /// The subscriptions, as set up in App Store Connect (one subscription group, "My Day Pro").
    static let productIDs = ["com.regina3579.myday.pro.yearly", "com.regina3579.myday.pro.monthly"]

    /// Whether My Day Pro is active. It starts from the last check, so Pro screens don't flicker
    /// at launch, and is then confirmed with the App Store.
    private(set) var isActive: Bool

    /// The App Store's transactions as they come (a renewal, a purchase on another device, a
    /// refund, Ask to Buy approved), for as long as My Day runs.
    @ObservationIgnored private var updates: Task<Void, Never>?

    init() {
        isActive = UserDefaults.standard.bool(forKey: Prefs.proActive)
        #if DEBUG
        if let pretend = DebugLaunchRoute.proOverride { isActive = pretend }
        #endif
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
                await self?.refresh()
            }
        }
        Task { await refresh() }
    }

    /// Whether My Day Pro was active at the last check, for code that runs away from the screen
    /// (like scheduling a reminder's sound).
    nonisolated static var wasActive: Bool {
        UserDefaults.standard.bool(forKey: Prefs.proActive)
    }

    /// Asks the App Store: Pro is active while a verified My Day Pro subscription is current
    /// (not expired, refunded or revoked).
    func refresh() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  Self.productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil
            else { continue }
            if let expiry = transaction.expirationDate, expiry < .now { continue }
            active = true
        }
        #if DEBUG
        if let pretend = DebugLaunchRoute.proOverride { active = pretend }
        #endif
        set(active)
    }

    /// A purchase from the subscription sheet: finish it and unlock at once.
    func purchased(_ verification: VerificationResult<Transaction>) async {
        if case .verified(let transaction) = verification {
            await transaction.finish()
        }
        await refresh()
    }

    /// Settings → Restore Purchases: syncs with the App Store (it may ask to sign in), then checks.
    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }

    private func set(_ active: Bool) {
        if isActive != active { isActive = active }
        if UserDefaults.standard.object(forKey: Prefs.proActive) as? Bool != active {
            UserDefaults.standard.set(active, forKey: Prefs.proActive)
        }
    }
}

/// What My Day Pro unlocks, each with the words of its "Unlock …" pop-up.
enum ProFeature: String, Identifiable {
    case reminderSounds, taskPhotos, moreMoods, prompts, journalPhotos, voiceNotes, stickers, reflections, themes
    case unlimitedWriting

    var id: String { rawValue }

    /// The pop-up's title, like "Unlock Daily Reflections".
    var title: String {
        switch self {
        case .reminderSounds: "Unlock Reminder Sounds"
        case .taskPhotos: "Unlock Task Photos"
        case .moreMoods: "Unlock All 30 Moods"
        case .prompts: "Unlock Journal Prompts"
        case .journalPhotos: "Unlock Journal Photos"
        case .voiceNotes: "Unlock Voice Notes"
        case .stickers: "Unlock All Stickers"
        case .reflections: "Unlock Daily Reflections"
        case .themes: "Unlock Journal Themes"
        case .unlimitedWriting: "Unlock Unlimited Writing"
        }
    }

    /// A line or two on what it brings.
    var message: String {
        switch self {
        case .reminderSounds:
            "Hear your to-dos with beautiful melodies: sparkling bells, gentle flutes, a harp, wind chimes and more."
        case .taskPhotos:
            "Add photos to your to-dos, so every task has a little picture to remember it by."
        case .moreMoods:
            "Find the perfect feeling for every kind of day, with 24 more moods to choose from."
        case .prompts:
            "Never face a blank page: get a gentle prompt whenever you're not sure what to write."
        case .journalPhotos:
            "Keep your favorite moments close with up to 6 photos on every journal page."
        case .voiceNotes:
            "Save your thoughts in your own voice and keep them with your journal pages."
        case .stickers:
            "Decorate your pages with every sticker collection: hearts, nature, food, cute animals and more."
        case .reflections:
            "Make your journal even more meaningful with gratitude, highlights, little wins, and hopes for tomorrow."
        case .unlimitedWriting:
            "A free page holds 1,000 characters. With My Day Pro, write as much as your heart wants, every single day."
        case .themes:
            "Dress your journal in Heavenly Angel Wishes 👼, Enchanted Fairy Garden 🧚, Rainbow Glow Unicorn 🦄, Rose Gold Elegance 🌹, Cozy Rainy Day ☔, Candy Cloud Kingdom 🍭 and every new theme as it arrives."
        }
    }
}
