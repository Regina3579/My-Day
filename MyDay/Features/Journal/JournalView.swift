import SwiftUI
import SwiftData

/// "My Journal": opens on today's page, ready to write (or on the page already written today).
/// Every page is in `JournalPagesView`, from the ⋮ menu or the link under Save.
struct JournalView: View {
    @Environment(AppState.self) private var appState
    #if DEBUG
    @Environment(Router.self) private var router
    #endif
    @AppStorage(Prefs.journalLock) private var lockEnabled = false
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    var body: some View {
        Group {
            if lockEnabled && !appState.isJournalUnlocked {
                JournalLockView()
                    .tabBarSafeArea()
                    .background(DreamyBackground(theme: .journal))
                    .navigationTitle("My Journal")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                JournalComposer(entry: entries.first(where: { $0.date.isToday }), date: .now, presentation: .page)
            }
        }
        #if DEBUG
        .task {
            if DebugLaunchRoute.takeJournalPage(), let newest = entries.first {
                router.homePath.append(newest)
            } else if DebugLaunchRoute.takeJournalPages() {
                router.homePath.append(AppRoute.journalPages)
            }
        }
        #endif
    }
}

/// "My Journal Pages": every page, with search, favourites and little wins.
struct JournalPagesView: View {
    @Environment(AppState.self) private var appState
    @AppStorage(Prefs.journalLock) private var lockEnabled = false
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @State private var search = ""
    @State private var shelf: JournalShelf = .all
    @State private var isComposing = false

    var body: some View {
        Group {
            if lockEnabled && !appState.isJournalUnlocked {
                JournalLockView()
            } else {
                journal
            }
        }
        .tabBarSafeArea()
        .background(DreamyBackground(theme: .journal))
        .navigationTitle("My Journal Pages")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isComposing) {
            NewJournalEntrySheet(date: .now)
        }
    }

    // MARK: Content

    private var filtered: [JournalEntry] {
        let query = search.trimmed
        return entries.filter { entry in
            shelf.includes(entry) && (query.isEmpty || entry.matches(query))
        }
    }

    private var winCount: Int { entries.filter(\.hasLittleWin).count }

    private var months: [JournalMonth] {
        let groups = Dictionary(grouping: filtered) { $0.date.startOfMonth }
        return groups.keys.sorted(by: >).map { JournalMonth(month: $0, entries: groups[$0] ?? []) }
    }

    private var journal: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "My Pages", subtitle: "Every thought and beautiful moment",
                              symbol: "book.closed.fill", theme: .journal)

                Button {
                    isComposing = true
                } label: {
                    Label("Write a new page", systemImage: "pencil.and.scribble")
                }
                .buttonStyle(PillButtonStyle())

                MoodWeek(entries: entries, today: appState.today)

                Picker("Show", selection: $shelf) {
                    ForEach(JournalShelf.allCases, id: \.self) { shelf in
                        Text(shelf.label).tag(shelf)
                    }
                }
                .pickerStyle(.segmented)

                if shelf == .wins && winCount > 0 {
                    LittleWinsSummary(count: winCount)
                }

                if filtered.isEmpty {
                    emptyState
                }

                ForEach(months) { month in
                    Text(month.month.formatted(.dateTime.month(.wide).year()))
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(Palette.berry)
                        .padding(.top, 6)
                    ForEach(month.entries) { entry in
                        NavigationLink(value: entry) {
                            JournalEntryCard(entry: entry)
                        }
                        .buttonStyle(PressScaleStyle(scale: 0.98))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .searchable(text: $search, prompt: "Search your journal")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isComposing = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("New page")
            }
        }
    }
}

extension JournalPagesView {
    @ViewBuilder
    private var emptyState: some View {
        if !search.isEmpty {
            EmptyStateCard(title: "No pages found", message: "Try another word.")
        } else if shelf == .wins {
            EmptyStateCard(title: "No little wins yet",
                           message: "Add one line to any page: “🌟 My little win today…” 🏆")
        } else if shelf == .favorites {
            EmptyStateCard(title: "No favorites yet",
                           message: "Tap the heart on a page to keep it here. 💖")
        } else {
            EmptyStateCard(title: "Your journal is waiting",
                           message: "Write about your day, a happy moment or something you're grateful for. 🌸")
        }
    }
}

/// Which pages the journal list shows.
enum JournalShelf: CaseIterable {
    case all, favorites, wins

    var label: String {
        switch self {
        case .all: "All pages"
        case .favorites: "Favorites 💖"
        case .wins: "Little Wins 🏆"
        }
    }

    func includes(_ entry: JournalEntry) -> Bool {
        switch self {
        case .all: true
        case .favorites: entry.isFavorite
        case .wins: entry.hasLittleWin
        }
    }
}

private extension JournalEntry {
    /// Search looks in the title, the text, the little win, the other prompts, the place and the tags.
    func matches(_ query: String) -> Bool {
        [title, body, littleWin, gratitude, highlight, lookingForward, place, tagsText]
            .contains { $0.localizedCaseInsensitiveContains(query) }
    }
}

/// Shown above the Little Wins: how many there are so far.
struct LittleWinsSummary: View {
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("🏆")
                .font(.system(size: 30))
                .frame(width: 54, height: 54)
                .background(Circle().fill(Palette.cream))
                .overlay(Circle().strokeBorder(Palette.butter, lineWidth: 1.5))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(count == 1 ? "1 little win" : "\(count) little wins")
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(Palette.cocoa)
                    .contentTransition(.numericText(value: Double(count)))
                Text("Look how far you've come! 🌟")
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(Palette.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .cuteCard(tint: Palette.honey, padding: 14)
        .accessibilityElement(children: .combine)
    }
}

/// "🏆 Finished my workout." on a soft butter ribbon.
struct LittleWinLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("🏆")
                .accessibilityHidden(true)
            Text(text)
                .foregroundStyle(Palette.cocoa)
                .multilineTextAlignment(.leading)
        }
        .font(.rounded(.subheadline, weight: .semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.cream))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Palette.butter.opacity(0.7), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Little win: \(text)")
    }
}

struct JournalMonth: Identifiable {
    let month: Date
    let entries: [JournalEntry]
    var id: Date { month }
}

/// The last seven days, each with the mood of its latest page.
struct MoodWeek: View {
    let entries: [JournalEntry]
    let today: Date

    var body: some View {
        let days = (0..<7).reversed().map { today.adding(days: -$0) }
        VStack(alignment: .leading, spacing: 10) {
            Text("My week in moods")
                .font(.rounded(.subheadline, weight: .bold))
                .foregroundStyle(Palette.berry)
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    let mood = entries.first(where: { $0.date.isSameDay(as: day) })?.mood
                    VStack(spacing: 4) {
                        Text(mood?.emoji ?? "·")
                            .font(.system(size: 24))
                            .frame(height: 30)
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.rounded(.caption2, weight: .bold))
                            .foregroundStyle(day.isToday ? Palette.hotPink : Palette.inkSoft)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .cuteCard(tint: Palette.hotPink, padding: 14)
        .accessibilityElement(children: .combine)
    }
}

/// A journal page in the list.
struct JournalEntryCard: View {
    let entry: JournalEntry

    var body: some View {
        let photos = entry.sortedPhotos
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Text(entry.date.formatted(.dateTime.day()))
                    .font(.rounded(.title2, weight: .heavy))
                    .foregroundStyle(Palette.berry)
                Text(entry.date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.rounded(.caption, weight: .bold))
                    .foregroundStyle(Palette.hotPink)
            }
            .frame(width: 52, height: 60)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.blush))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(entry.mood.emoji)
                    Text(entry.displayTitle)
                        .font(.rounded(.headline, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if entry.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(Palette.hotPink)
                    }
                }
                if !entry.body.isEmpty {
                    Text(entry.body)
                        .font(.rounded(.subheadline))
                        .foregroundStyle(Palette.inkSoft)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                if entry.hasLittleWin {
                    LittleWinLine(text: entry.littleWin)
                        .lineLimit(2)
                }
                Text(entry.date.formatted(date: .omitted, time: .shortened))
                    .font(.rounded(.caption2, weight: .semibold))
                    .foregroundStyle(Color.secondary)
            }

            if let first = photos.first, let data = first.thumbnailData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(alignment: .bottomTrailing) {
                        if photos.count > 1 {
                            Text("+\(photos.count - 1)")
                                .font(.rounded(.caption2, weight: .heavy))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.black.opacity(0.45)))
                                .padding(4)
                        }
                    }
            }
        }
        .cuteCard(tint: Palette.hotPink, padding: 14)
    }
}
