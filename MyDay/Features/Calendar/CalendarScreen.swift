import SwiftUI
import SwiftData

/// Month view with little markers for to-dos, priorities and journal pages,
/// plus the agenda of the selected day.
struct CalendarScreen: View {
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @AppStorage(Prefs.journalLock) private var lockEnabled = false
    @Query(sort: \TaskItem.sortIndex) private var tasks: [TaskItem]
    @Query(sort: \JournalEntry.date) private var entries: [JournalEntry]
    @State private var month = Date.now.startOfMonth
    @State private var selected = Date.now.startOfDay

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SectionHeader(title: "Calendar", subtitle: "Every day is a new page", symbol: "calendar", theme: .garden)
                MonthGrid(month: $month, selected: $selected, today: appState.today, markers: markers)
                agenda
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .background(DreamyBackground(theme: .garden))
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Today") {
                    withAnimation(.snappy) {
                        month = appState.today.startOfMonth
                        selected = appState.today
                    }
                }
                .fontWeight(.semibold)
            }
        }
    }

    // MARK: Data

    private var markers: [Date: DayMarker] {
        var result: [Date: DayMarker] = [:]
        for task in tasks {
            let key = task.day.startOfDay
            result[key, default: DayMarker()].tasks += 1
            if task.isDone { result[key, default: DayMarker()].done += 1 }
            if task.isPriority { result[key, default: DayMarker()].hasPriority = true }
        }
        for entry in entries {
            result[entry.date.startOfDay, default: DayMarker()].journal += 1
        }
        return result
    }

    private var isJournalLocked: Bool { lockEnabled && !appState.isJournalUnlocked }

    // MARK: Agenda

    private var agenda: some View {
        let dayTasks = tasks.filter { $0.day.isSameDay(as: selected) }
        let dayEntries = entries.filter { $0.date.isSameDay(as: selected) }

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(selected.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.rounded(.title3, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                Spacer()
                if selected.isToday {
                    Text("Today")
                        .font(.rounded(.caption, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Palette.hotPink.gradient))
                }
            }

            agendaHeader("To-Dos", icon: "checklist", tint: Palette.grape) {
                router.sheet = .newTask(day: selected, priority: false)
            }
            if dayTasks.isEmpty {
                Text("No to-dos for this day yet.")
                    .font(.rounded(.subheadline))
                    .foregroundStyle(Color.secondary)
            } else {
                ForEach(dayTasks) { task in
                    CompactTaskRow(task: task) { toggle(task) }
                }
                NavigationLink(value: AppRoute.todos(selected)) {
                    Label("Open this day", systemImage: "arrow.right.circle.fill")
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(Palette.grape)
                }
            }

            Divider()

            agendaHeader("Journal", icon: "book.closed.fill", tint: Palette.hotPink) {
                router.sheet = .newJournal(selected.atTime(of: .now))
            }
            if isJournalLocked {
                NavigationLink(value: AppRoute.journal) {
                    Label("Unlock your journal to see this day", systemImage: "lock.fill")
                        .font(.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(Palette.berry)
                }
            } else if dayEntries.isEmpty {
                Text("No journal pages for this day.")
                    .font(.rounded(.subheadline))
                    .foregroundStyle(Color.secondary)
            } else {
                ForEach(dayEntries) { entry in
                    NavigationLink(value: entry) {
                        HStack(spacing: 10) {
                            Text(entry.mood.emoji).font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.displayTitle)
                                    .font(.rounded(.subheadline, weight: .bold))
                                    .foregroundStyle(Palette.ink)
                                    .lineLimit(1)
                                Text(entry.date.formatted(date: .omitted, time: .shortened))
                                    .font(.rounded(.caption2, weight: .semibold))
                                    .foregroundStyle(Color.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Palette.inkSoft.opacity(0.5))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cuteCard(tint: Palette.hotPink)
    }

    private func agendaHeader(_ title: String, icon: String, tint: Color, add: @escaping () -> Void) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(tint)
            Spacer()
            Button(action: add) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(tint)
            }
            .accessibilityLabel("Add to \(title)")
        }
    }

    private func toggle(_ task: TaskItem) {
        withAnimation(.snappy) { task.toggleDone() }
        ReminderCenter.sync(task)
        if task.isDone { Haptics.success() } else { Haptics.tap() }
    }
}

struct DayMarker {
    var tasks = 0
    var done = 0
    var journal = 0
    var hasPriority = false
}

/// A compact to-do line used in the calendar agenda.
struct CompactTaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggle) {
                CheckBubble(isOn: task.isDone, tint: Palette.grape, size: 24)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel(task.isDone ? "Mark \(task.title) as not done" : "Mark \(task.title) as done")
            Text(task.title)
                .font(.rounded(.subheadline, weight: .semibold))
                .strikethrough(task.isDone, color: Palette.grape)
                .foregroundStyle(task.isDone ? Color.secondary : Palette.ink)
            Spacer(minLength: 0)
            if task.isPriority {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(Palette.honey)
            }
        }
    }
}

/// The month grid.
struct MonthGrid: View {
    @Binding var month: Date
    @Binding var selected: Date
    let today: Date
    let markers: [Date: DayMarker]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// Leading blanks, then every day of the month, padded to full weeks.
    private var days: [Date?] {
        let calendar = Calendar.current
        let start = month.startOfMonth
        guard let range = calendar.range(of: .day, in: .month, for: start) else { return [] }
        let leading = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        var result: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<range.count {
            result.append(calendar.date(byAdding: .day, value: offset, to: start))
        }
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button { shift(-1) } label: {
                    Image(systemName: "chevron.left.circle.fill")
                }
                .accessibilityLabel("Previous month")
                Spacer()
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(.rounded(.title3, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .contentTransition(.numericText())
                Spacer()
                Button { shift(1) } label: {
                    Image(systemName: "chevron.right.circle.fill")
                }
                .accessibilityLabel("Next month")
            }
            .font(.title2)
            .foregroundStyle(Palette.hotPink)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(weekdaySymbols.indices, id: \.self) { index in
                    Text(weekdaySymbols[index])
                        .font(.rounded(.caption, weight: .bold))
                        .foregroundStyle(Palette.inkSoft)
                }
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        Button {
                            withAnimation(.snappy) { selected = day }
                            Haptics.tap()
                        } label: {
                            DayCell(date: day,
                                    isSelected: day.isSameDay(as: selected),
                                    isToday: day.isSameDay(as: today),
                                    marker: markers[day.startOfDay])
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(height: 46)
                    }
                }
            }
        }
        .cuteCard(tint: Palette.grape)
        .gesture(
            DragGesture(minimumDistance: 30).onEnded { value in
                if value.translation.width < -50 { shift(1) }
                if value.translation.width > 50 { shift(-1) }
            }
        )
    }

    private func shift(_ months: Int) {
        withAnimation(.snappy) { month = month.adding(months: months).startOfMonth }
        Haptics.tap()
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let marker: DayMarker?

    var body: some View {
        VStack(spacing: 3) {
            Text(date.formatted(.dateTime.day()))
                .font(.rounded(.callout, weight: isSelected || isToday ? .heavy : .semibold))
                .foregroundStyle(isSelected ? Color.white : (isToday ? Palette.hotPink : Palette.ink))
                .frame(width: 34, height: 34)
                .background {
                    if isSelected {
                        Circle().fill(Palette.hotPink.gradient)
                    } else if isToday {
                        Circle().strokeBorder(Palette.hotPink, lineWidth: 2)
                    }
                }
            HStack(spacing: 3) {
                if let marker {
                    if marker.tasks > 0 {
                        Circle()
                            .fill(marker.done == marker.tasks ? Palette.mint : Palette.grape)
                            .frame(width: 5, height: 5)
                    }
                    if marker.hasPriority {
                        Image(systemName: "star.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(Palette.honey)
                    }
                    if marker.journal > 0 {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(Palette.hotPink)
                    }
                }
            }
            .frame(height: 7)
        }
        .frame(maxWidth: .infinity, minHeight: 46)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? AccessibilityTraits.isSelected : [])
    }

    private var accessibilityText: String {
        var parts = [date.formatted(date: .complete, time: .omitted)]
        if let marker {
            if marker.tasks > 0 { parts.append("\(marker.done) of \(marker.tasks) to-dos done") }
            if marker.journal > 0 { parts.append("\(marker.journal) journal pages") }
        }
        return parts.joined(separator: ", ")
    }
}
