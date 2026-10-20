import Foundation

/// When a first-time tip may show, so the tips come gently and are really read, not tapped
/// away in a row:
///
/// - **Look around first.** No tip in the first minute of the very first use, and each screen's
///   tip waits a few seconds after the screen opens (`settle`).
/// - **One at a time.** A screen shows at most one tip per visit, its most useful one first;
///   the next comes on a later visit.
/// - **Room to try it.** After a tip, the next waits at least 3 minutes, so there is time to go
///   and use what it showed. A tip for something just tapped (Quick Add, the ⋮ menu's Journal
///   Theme) needs only 30 seconds, since it explains what is on screen right then.
/// - **Not too many.** At most 3 tips a day; the rest wait for the following days.
///
/// Tips with their own timing (the Journal Lock tip on the journal's second opening, and 7
/// days after Maybe Later) follow it too.
enum TipPacer {
    /// How long a screen is open before its tip shows.
    static let settle: Duration = .seconds(2.5)
    static let firstUseQuiet: TimeInterval = 60
    static let gap: TimeInterval = 3 * 60
    static let contextualGap: TimeInterval = 30
    static let perDay = 3

    /// Whether a tip may show now. `contextual`: it explains something just tapped.
    static func mayShow(contextual: Bool = false, now: Date = .now) -> Bool {
        #if DEBUG
        // Screenshot runs show each tip on its own route straight away.
        if DebugLaunchRoute.isScreenshotRun { return true }
        #endif
        let defaults = UserDefaults.standard
        let time = now.timeIntervalSince1970
        var firstUse = defaults.double(forKey: Prefs.tipFirstUse)
        if firstUse == 0 {
            firstUse = time
            defaults.set(time, forKey: Prefs.tipFirstUse)
        }
        if !contextual, time - firstUse < firstUseQuiet { return false }
        let last = defaults.double(forKey: Prefs.tipLastShown)
        if last > 0, time - last < (contextual ? contextualGap : gap) { return false }
        return shownToday(now: now) < perDay
    }

    /// Call when a tip appears.
    static func shown(now: Date = .now) {
        let defaults = UserDefaults.standard
        let count = shownToday(now: now)
        defaults.set(dayKey(now), forKey: Prefs.tipDay)
        defaults.set(count + 1, forKey: Prefs.tipsToday)
        defaults.set(now.timeIntervalSince1970, forKey: Prefs.tipLastShown)
    }

    /// Settings → Show tips again: they may come again from the next screen opened (still one at
    /// a time, with the same gaps).
    static func reset() {
        let defaults = UserDefaults.standard
        for key in [Prefs.tipLastShown, Prefs.tipsToday] { defaults.removeObject(forKey: key) }
        defaults.set(1, forKey: Prefs.tipFirstUse)
    }

    private static func shownToday(now: Date) -> Int {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: Prefs.tipDay) == dayKey(now) ? defaults.integer(forKey: Prefs.tipsToday) : 0
    }

    private static func dayKey(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }
}
