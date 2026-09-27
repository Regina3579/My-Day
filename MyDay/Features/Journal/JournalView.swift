import SwiftUI
import SwiftData

/// "My Journal — Capture your thoughts and beautiful moments".
struct JournalView: View {
    @Environment(AppState.self) private var appState
    @AppStorage(Prefs.journalLock) private var lockEnabled = false
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @State private var search = ""
    @State private var favoritesOnly = false
    @State private var isComposing = false

    var body: some View {
        Group {
            if lockEnabled && !appState.isJournalUnlocked {
                JournalLockView()
            } else {
                journal
            }
        }
        .background(DreamyBackground(theme: .journal))
        .navigationTitle("My Journal")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isComposing) {
            NewJournalEntrySheet(date: .now)
        }
    }

    // MARK: Content

    private var filtered: [JournalEntry] {
        let query = search.trimmed
        return entries.filter { entry in
            (!favoritesOnly || entry.isFavorite)
                && (query.isEmpty
                    || entry.title.localizedCaseInsensitiveContains(query)
                    || entry.body.localizedCaseInsensitiveContains(query))
        }
    }

    private var months: [JournalMonth] {
        let groups = Dictionary(grouping: filtered) { $0.date.startOfMonth }
        return groups.keys.sorted(by: >).map { JournalMonth(month: $0, entries: groups[$0] ?? []) }
    }

    private var journal: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "My Journal", subtitle: "Capture your thoughts and beautiful moments",
                              symbol: "book.closed.fill", theme: .journal)

                Button {
                    isComposing = true
                } label: {
                    Label("Write today's page", systemImage: "pencil.and.scribble")
                }
                .buttonStyle(PillButtonStyle())

                MoodWeek(entries: entries, today: appState.today)

                Picker("Show", selection: $favoritesOnly) {
                    Text("All pages").tag(false)
                    Text("Favorites 💖").tag(true)
                }
                .pickerStyle(.segmented)

                if filtered.isEmpty {
                    EmptyStateCard(
                        title: search.isEmpty ? "Your journal is waiting" : "No pages found",
                        message: search.isEmpty
                            ? "Write about your day, a happy moment or something you're grateful for. 🌸"
                            : "Try another word."
                    )
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
