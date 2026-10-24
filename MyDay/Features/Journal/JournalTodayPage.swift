import SwiftUI
import SwiftData

// A journal is one page a day: writing on a day that already has a page carries on with that
// page, instead of starting another.

extension JournalEntry {
    /// The page written on `day`, if there is one (the latest, where an older version of the app
    /// wrote several that day), leaving out pages in Trash.
    static func page(on day: Date, in context: ModelContext) -> JournalEntry? {
        let start = Calendar.current.startOfDay(for: day)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return nil }
        var descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.date >= start && $0.date < end && $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    /// The same, from pages a screen already has.
    static func page(on day: Date, among pages: [JournalEntry]) -> JournalEntry? {
        pages
            .filter { $0.deletedAt == nil && Calendar.current.isDate($0.date, inSameDayAs: day) }
            .max { $0.date < $1.date }
    }
}

extension Router {
    /// Writing in the journal on `day` from outside it (Quick Add, the Calendar's ＋): that day's
    /// page when there is one, or a new page. While the journal is locked, it opens instead of
    /// an existing page, so the page is not shown until the journal is unlocked.
    func writeInJournal(on day: Date, context: ModelContext, isUnlocked: Bool) {
        guard let page = JournalEntry.page(on: day, in: context) else {
            sheet = .newJournal(day)
            return
        }
        if UserDefaults.standard.bool(forKey: Prefs.journalLock) && !isUnlocked {
            open(.journal)
        } else {
            sheet = .editJournal(page)
        }
    }
}
