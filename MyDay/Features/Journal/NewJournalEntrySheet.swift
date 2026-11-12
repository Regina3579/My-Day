import SwiftUI

/// Write a new journal page, or edit one: the same page as the journal's opening page, in a sheet.
struct NewJournalEntrySheet: View {
    private let entry: JournalEntry?
    private let date: Date

    /// A new page dated `date`.
    init(date: Date) {
        entry = nil
        self.date = date
    }

    /// Edit an existing page.
    init(entry: JournalEntry) {
        self.entry = entry
        date = entry.date
    }

    var body: some View {
        NavigationStack {
            JournalComposer(entry: entry, date: date, presentation: .sheet)
        }
        .presentationDragIndicator(.visible)
    }
}
