import SwiftUI
import SwiftData
import Charts

/// Progress at a glance: today, the week, the streak and moods.
struct InsightsView: View {
    @Environment(AppState.self) private var appState
    @Query private var tasks: [TaskItem]
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    var body: some View {
        let stats = InsightStats(tasks: tasks, entries: entries, today: appState.today)

        ScrollView {
            VStack(spacing: 16) {
                SectionHeader(title: "Insights", subtitle: "Look how far you've come", symbol: "chart.bar.fill",
                              theme: .garden)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                          spacing: 12) {
                    StatTile(value: "\(stats.todayDone)/\(stats.todayTotal)", label: "Done today",
                             symbol: "checkmark.circle.fill", tint: Palette.grape)
                    StatTile(value: "\(stats.streak)", label: stats.streak == 1 ? "Day streak" : "Days streak",
                             symbol: "flame.fill", tint: Palette.hotPink)
                    StatTile(value: "\(stats.weekDone)", label: "Done this week",
                             symbol: "sparkles", tint: Palette.honey)
                    StatTile(value: "\(stats.monthEntries)", label: "Journal pages this month",
                             symbol: "book.closed.fill", tint: Palette.bubblegum)
                }

                weekCard(stats)
                moodCard(stats)
                encouragement(stats)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .background(DreamyBackground(theme: .garden))
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func weekCard(_ stats: InsightStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("To-dos done this week", systemImage: "chart.bar.fill")
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(Palette.grape)

            Chart(stats.week) { day in
                BarMark(
                    x: .value("Day", day.day, unit: .day),
                    y: .value("Done", day.done)
                )
                .foregroundStyle(LinearGradient(colors: [Palette.lavender, Palette.grape],
                                                startPoint: .bottom, endPoint: .top))
                .cornerRadius(8)
                .annotation(position: .top) {
                    if day.done > 0 {
                        Text("\(day.done)")
                            .font(.rounded(.caption2, weight: .bold))
                            .foregroundStyle(Palette.grape)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 170)
        }
        .cuteCard(tint: Palette.grape)
    }

    private func moodCard(_ stats: InsightStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Moods · last 30 days", systemImage: "heart.text.square.fill")
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(Palette.hotPink)

            if stats.moods.isEmpty {
                Text("Write journal pages to watch your moods bloom 🌸")
                    .font(.rounded(.subheadline))
                    .foregroundStyle(Palette.inkSoft)
            } else {
                HStack(spacing: 18) {
                    Chart(stats.moods) { slice in
                        SectorMark(angle: .value("Pages", slice.count), innerRadius: .ratio(0.62), angularInset: 2)
                            .cornerRadius(4)
                            .foregroundStyle(slice.mood.color)
                    }
                    .frame(width: 140, height: 140)
                    .overlay {
                        if let top = stats.moods.max(by: { $0.count < $1.count }) {
                            VStack(spacing: 0) {
                                Text(top.mood.emoji).font(.system(size: 32))
                                Text(top.mood.label)
                                    .font(.rounded(.caption2, weight: .bold))
                                    .foregroundStyle(Palette.inkSoft)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(stats.moods) { slice in
                            HStack(spacing: 6) {
                                Circle().fill(slice.mood.color).frame(width: 9, height: 9)
                                Text("\(slice.mood.emoji) \(slice.mood.label)")
                                Spacer(minLength: 4)
                                Text("\(slice.count)").fontWeight(.heavy)
                            }
                            .font(.rounded(.caption, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                        }
                    }
                }
            }
        }
        .cuteCard(tint: Palette.hotPink)
    }

    private func encouragement(_ stats: InsightStats) -> some View {
        VStack(spacing: 12) {
            HeroBanner(height: 130)
            Text(stats.cheer)
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(Palette.berry)
                .multilineTextAlignment(.center)
            Text("\(stats.totalDone) to-dos done in total · \(stats.prioritiesDoneThisWeek) priorities this week")
                .font(.rounded(.caption, weight: .semibold))
                .foregroundStyle(Palette.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cuteCard()
    }
}

struct StatTile: View {
    let value: String
    let label: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint.gradient)
            Text(value)
                .font(.rounded(.title, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
            Text(label)
                .font(.rounded(.caption, weight: .semibold))
                .foregroundStyle(Palette.inkSoft)
                .lineLimit(2, reservesSpace: true)
        }
        .cuteCard(tint: tint, padding: 14)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Numbers

struct DayStat: Identifiable {
    let day: Date
    let done: Int
    var id: Date { day }
}

struct MoodSlice: Identifiable {
    let mood: Mood
    let count: Int
    var id: String { mood.rawValue }
}

struct InsightStats {
    let todayDone: Int
    let todayTotal: Int
    let week: [DayStat]
    let weekDone: Int
    let streak: Int
    let monthEntries: Int
    let moods: [MoodSlice]
    let totalDone: Int
    let prioritiesDoneThisWeek: Int

    init(tasks: [TaskItem], entries: [JournalEntry], today: Date) {
        let start = today.startOfDay
        let weekStart = start.adding(days: -6)

        let todays = tasks.filter { $0.day.isSameDay(as: start) }
        todayTotal = todays.count
        todayDone = todays.filter(\.isDone).count

        var doneByDay: [Date: Int] = [:]
        for task in tasks where task.isDone {
            doneByDay[(task.completedAt ?? task.day).startOfDay, default: 0] += 1
        }
        let lastSevenDays = (0..<7).reversed().map { offset -> DayStat in
            let day = start.adding(days: -offset)
            return DayStat(day: day, done: doneByDay[day] ?? 0)
        }
        week = lastSevenDays
        weekDone = lastSevenDays.reduce(0) { $0 + $1.done }

        // A day counts toward the streak when a to-do was finished or a page was written.
        let activeDays = Set(doneByDay.keys).union(entries.map { $0.date.startOfDay })
        var cursor = activeDays.contains(start) ? start : start.adding(days: -1)
        var run = 0
        while activeDays.contains(cursor) {
            run += 1
            cursor = cursor.adding(days: -1)
        }
        streak = run

        let monthStart = start.startOfMonth
        monthEntries = entries.filter { $0.date >= monthStart }.count

        let recent = entries.filter { $0.date >= start.adding(days: -29) }
        let counts = Dictionary(grouping: recent, by: \.mood).mapValues(\.count)
        moods = Mood.allCases.compactMap { mood in
            guard let count = counts[mood], count > 0 else { return nil }
            return MoodSlice(mood: mood, count: count)
        }

        totalDone = tasks.filter(\.isDone).count
        prioritiesDoneThisWeek = tasks.filter {
            $0.isPriority && $0.isDone && ($0.completedAt ?? $0.day) >= weekStart
        }.count
    }

    var cheer: String {
        switch streak {
        case 0: "Every journey starts with one small step. 🌱"
        case 1: "You showed up today — that's wonderful! 🌸"
        case 2...6: "\(streak) days in a row — you're blooming! 🌷"
        default: "\(streak)-day streak! You're a superstar! ⭐"
        }
    }
}
