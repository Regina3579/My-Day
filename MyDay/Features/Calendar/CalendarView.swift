import SwiftData
import SwiftUI

/// "Calendar — Every day is a new page": the illustrated header with a Today button, the
/// month card with markers for to-dos, priorities and journal pages, and the selected day's
/// Priorities, To-Dos and Journal.
struct CalendarView: View {
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @AppStorage(Prefs.journalLock) private var lockEnabled = false
    @Query(sort: \TaskItem.sortOrder) private var tasks: [TaskItem]
    @Query(sort: \Priority.order) private var priorities: [Priority]
    @Query(filter: #Predicate<JournalEntry> { $0.deletedAt == nil }, sort: \JournalEntry.date)
    private var entries: [JournalEntry]
    @State private var month = Date.now.startOfMonth
    @State private var selected = Date.now.startOfDay

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    CalendarHeader(width: proxy.size.width, statusBar: proxy.safeAreaInsets.top,
                                   onToday: goToToday)
                    VStack(spacing: 14) {
                        MonthCard(month: $month, selected: $selected, today: appState.today, markers: markers)
                        agenda
                    }
                    .padding(.horizontal, 13)
                    .padding(.bottom, 16)
                }
            }
            .ignoresSafeArea(edges: .top)
            .tabBarSafeArea()
        }
        .background(CalendarBackdrop())
        .toolbar(.hidden, for: .navigationBar)
        #if DEBUG
        .task { openDebugDay() }
        #endif
    }

    private func goToToday() {
        withAnimation(.snappy) {
            month = appState.today.startOfMonth
            selected = appState.today
        }
        Haptics.tap()
    }

    #if DEBUG
    /// `calendar-tomorrow` selects tomorrow, which has nothing planned yet.
    private func openDebugDay() {
        let offset = DebugLaunchRoute.takeCalendarDayOffset()
        guard offset != 0 else { return }
        selected = appState.today.adding(days: offset)
        month = selected.startOfMonth
    }
    #endif

    // MARK: Data

    private var markers: [Date: DayMarker] {
        var result: [Date: DayMarker] = [:]
        for task in tasks {
            let key = task.date.startOfDay
            result[key, default: DayMarker()].tasks += 1
            if task.isCompleted { result[key, default: DayMarker()].done += 1 }
        }
        for priority in priorities {
            result[priority.date.startOfDay, default: DayMarker()].priorities += 1
        }
        for entry in entries {
            result[entry.date.startOfDay, default: DayMarker()].journal += 1
        }
        return result
    }

    private var isJournalLocked: Bool { lockEnabled && !appState.isJournalUnlocked }

    private var dayTasks: [TaskItem] { tasks.filter { $0.date.isSameDay(as: selected) } }
    private var dayPriorities: [Priority] { priorities.filter { $0.date.isSameDay(as: selected) } }
    private var dayEntries: [JournalEntry] { entries.filter { $0.date.isSameDay(as: selected) } }

    // MARK: Agenda

    /// "Tuesday, 29 September", a little chip saying which day it is, then the three rows.
    private var agenda: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text(selected.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.rounded(.title3, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 4)
                dayChip
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 12)

            prioritiesRow
            separator
            todosRow
            separator
            journalRow
        }
        .padding(.horizontal, 8)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(CalendarPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white, lineWidth: 1.5)
                )
                .shadow(color: CalendarPalette.pink.opacity(0.1), radius: 12, x: 0, y: 5)
        )
    }

    private var separator: some View {
        Rectangle()
            .fill(CalendarPalette.separator)
            .frame(height: 1)
            .padding(.horizontal, 4)
            .padding(.vertical, 7)
    }

    /// "☀️ Today", "Tomorrow", "In 3 days", "2 days ago"…
    private var dayChip: some View {
        let offset = Calendar.current.dateComponents([.day], from: appState.today, to: selected.startOfDay).day ?? 0
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        let words = formatter.localizedString(from: DateComponents(day: offset))
        let symbol = offset == 0 ? "sun.max.fill" : (offset > 0 ? "sunrise.fill" : "moon.stars.fill")
        return HStack(spacing: 6) {
            Image(systemName: symbol)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 17))
                .accessibilityHidden(true)
            Text(words.prefix(1).uppercased() + words.dropFirst())
                .font(.rounded(.subheadline, weight: .bold))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.white))
        .shadow(color: CalendarPalette.pink.opacity(0.12), radius: 5, x: 0, y: 2)
    }

    private func doneNote(_ done: Int, of total: Int) -> String {
        done == total ? "All \(total) done 🎉" : "\(done) of \(total) done"
    }

    private var prioritiesRow: some View {
        let items = dayPriorities
        return AgendaRow(style: .priorities,
                         note: items.isEmpty ? "No priorities for this day."
                                             : doneNote(items.filter(\.isCompleted).count, of: items.count),
                         addLabel: "Add a priority",
                         onAdd: { router.sheet = .newPriority(selected) }) {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(items) { priority in
                        CompactCheckRow(title: priority.title, isDone: priority.isCompleted, tint: Palette.honey) {
                            withAnimation(.snappy) { priority.toggleCompleted() }
                            if priority.isCompleted {
                                CompletionFeedback.completed(finishingAll: items.allSatisfy(\.isCompleted))
                            } else {
                                Haptics.tap()
                            }
                        }
                    }
                }
                .padding(.bottom, 6)
            }
        }
    }

    private var todosRow: some View {
        let items = dayTasks
        return AgendaRow(style: .todos,
                         note: items.isEmpty ? "No to-dos for this day yet."
                                             : doneNote(items.filter(\.isCompleted).count, of: items.count),
                         addLabel: "Add a to-do",
                         onAdd: { router.sheet = .newTask(selected) }) {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(items) { task in
                        CompactCheckRow(title: task.title, isDone: task.isCompleted, tint: task.choice.color) {
                            withAnimation(.snappy) { TaskActions.toggle(task, in: context) }
                        }
                    }
                    NavigationLink(value: AppRoute.todos(selected)) {
                        Label("Open this day", systemImage: "arrow.right.circle.fill")
                            .font(.rounded(.subheadline, weight: .bold))
                            .foregroundStyle(CalendarPalette.purple)
                            .padding(.vertical, 6)
                    }
                }
                .padding(.bottom, 4)
            }
        }
    }

    private var journalNote: String {
        if isJournalLocked { return "Locked with \(JournalLock.currentMethodName)." }
        switch dayEntries.count {
        case 0: return "No journal entry for this day."
        case 1: return "1 page"
        default: return "\(dayEntries.count) pages"
        }
    }

    private var journalRow: some View {
        AgendaRow(style: .journal,
                  note: journalNote,
                  addLabel: "Write a journal page",
                  onAdd: { router.sheet = .newJournal(selected.atTime(of: .now)) }) {
            if isJournalLocked {
                NavigationLink(value: AppRoute.journal) {
                    Label("Unlock your journal to see this day", systemImage: "lock.fill")
                        .font(.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(Palette.berry)
                        .padding(.vertical, 6)
                }
            } else if !dayEntries.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(dayEntries) { entry in
                        NavigationLink(value: entry) {
                            journalLine(entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 6)
            }
        }
    }

    private func journalLine(_ entry: JournalEntry) -> some View {
        HStack(spacing: 10) {
            Image(entry.mood.artName)
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 30)
                .accessibilityLabel(entry.mood.label)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayTitle)
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Text(entry.date.formatted(date: .omitted, time: .shortened))
                    .font(.rounded(.caption2, weight: .semibold))
                    .foregroundStyle(Color.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Palette.inkSoft.opacity(0.5))
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
