import SwiftUI
import StoreKit

/// When the "Enjoying My Day?" card asks for a rating. As Apple's Human Interface Guidelines
/// advise, it asks only once people have used My Day for a while, right after a happy moment,
/// rarely, and never again once they have rated:
///
/// - First: once My Day has been used on 7 different days, right after a happy moment (every
///   to-do or every priority of the day done, or a new journal page that makes 5 pages or a
///   3-day writing streak).
/// - "Maybe Later" (or ✕): not again for 30 days; after a second ask, not for 60 more days.
///   It asks 3 times at most.
/// - "Rate Now", or Settings → Rate My Day: never again.
///
/// The stars on the card are only a picture: the rating itself is given on Apple's own page.
@MainActor @Observable
final class RatingPrompt {
    /// The card is on screen.
    private(set) var isShowing = false
    /// The card is only a preview (Settings in a build run from Xcode, or a screenshot): its
    /// buttons change nothing.
    private(set) var isPreview = false

    static let activeDaysBeforeFirstAsk = 7
    /// Days to wait after the first ask and after the second.
    static let daysBetweenAsks = [30, 60]
    static let maxAsks = 3
    /// After a happy moment, the card waits for the celebration (the confetti, or "Saved").
    static let delayAfterHappyMoment: Duration = .seconds(2.6)

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var pending: Task<Void, Never>?
    /// Whether nothing is in the way of the card (a sheet, the side menu). Set by `RootView`.
    @ObservationIgnored var isScreenFree: @MainActor () -> Bool = { true }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: What is saved

    var activeDays: Int { defaults.integer(forKey: Prefs.ratingActiveDays) }
    var asks: Int { defaults.integer(forKey: Prefs.ratingAsks) }
    var hasRated: Bool { defaults.bool(forKey: Prefs.ratingDone) }
    var lastAsked: Date? { defaults.object(forKey: Prefs.ratingLastAsked) as? Date }

    /// My Day came to the front: each day it is used counts once.
    func noteActive(on date: Date = .now) {
        if let last = defaults.object(forKey: Prefs.ratingLastActiveDay) as? Date,
           Calendar.current.isDate(last, inSameDayAs: date) {
            return
        }
        defaults.set(date.startOfDay, forKey: Prefs.ratingLastActiveDay)
        defaults.set(activeDays + 1, forKey: Prefs.ratingActiveDays)
    }

    /// Whether a happy moment now may bring the card.
    func isDue(now: Date = .now) -> Bool {
        guard !hasRated, asks < Self.maxAsks else { return false }
        guard asks > 0, let lastAsked else { return activeDays >= Self.activeDaysBeforeFirstAsk }
        let wait = Self.daysBetweenAsks[min(asks, Self.daysBetweenAsks.count) - 1]
        guard let next = Calendar.current.date(byAdding: .day, value: wait, to: lastAsked) else { return false }
        return now >= next
    }

    /// A new journal page is a happy moment once there are 5 pages, or pages on 3 days in a
    /// row up to today.
    static func isJournalMilestone(pageDates: [Date], today: Date = .now) -> Bool {
        if pageDates.count >= 5 { return true }
        let days = Set(pageDates.map(\.startOfDay))
        var day = today.startOfDay
        var streak = 0
        while days.contains(day) {
            streak += 1
            day = day.adding(days: -1)
        }
        return streak >= 3
    }

    // MARK: Asking

    /// A happy moment: the day's to-dos or priorities all done, or a journaling milestone.
    /// When it is time to ask, the card comes once the celebration is over.
    func happyMoment() {
        guard pending == nil, !isShowing, isDue() else { return }
        pending = Task { [weak self] in
            try? await Task.sleep(for: RatingPrompt.delayAfterHappyMoment)
            guard let self else { return }
            self.pending = nil
            guard !self.isShowing, self.isDue(), self.isScreenFree() else { return }
            self.defaults.set(self.asks + 1, forKey: Prefs.ratingAsks)
            self.defaults.set(Date.now, forKey: Prefs.ratingLastAsked)
            self.present(preview: false)
        }
    }

    /// Shows the card without counting it as an ask.
    func preview() {
        present(preview: true)
    }

    /// "Rate Now", or Settings → Rate My Day: the card never comes again.
    func rated() {
        if !isPreview {
            defaults.set(true, forKey: Prefs.ratingDone)
        }
        close()
    }

    /// "Maybe Later" or ✕: the card waits (30 days, then 60) for another happy moment.
    func later() {
        close()
    }

    private func present(preview: Bool) {
        isPreview = preview
        withAnimation(.easeOut(duration: 0.25)) { isShowing = true }
    }

    private func close() {
        withAnimation(.easeInOut(duration: 0.25)) { isShowing = false }
        isPreview = false
    }
}

/// Apple's ways to rate My Day.
enum AppReview {
    /// My Day's App Store ID (the number in its App Store link), from `MyDayAppStoreID` in
    /// Info.plist. It is empty until My Day is in App Store Connect.
    static var appStoreID: String? {
        let id = (Bundle.main.object(forInfoDictionaryKey: "MyDayAppStoreID") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !id.isEmpty && id.allSatisfy(\.isNumber) ? id : nil
    }

    /// The App Store's Write a Review page for My Day: Apple's way to rate from a button.
    static var writeReviewURL: URL? {
        appStoreID.flatMap { URL(string: "https://apps.apple.com/app/id\($0)?action=write-review") }
    }

    /// Opens the App Store's Write a Review page. Until My Day has an App Store ID, Apple's
    /// in-app rating sheet comes instead: it always shows in a build run from Xcode, never in
    /// TestFlight, and in the App Store at most 3 times a year.
    static func open(openURL: OpenURLAction, requestReview: RequestReviewAction) {
        if let url = writeReviewURL {
            openURL(url)
        } else {
            requestReview()
        }
    }
}
