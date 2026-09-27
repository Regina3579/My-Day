import SwiftUI
import SwiftData

/// "Today's To-Dos — Plan • Do • Achieve". Also used for any other day from the calendar.
struct TodayToDosView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Prefs.showCompleted) private var showCompleted = true
    @Query private var tasks: [TaskItem]
    @State private var draft = ""
    @State private var filter: TaskCategory?
    @State private var editing: TaskItem?
    @State private var isComposing = false
    @FocusState private var draftFocused: Bool
    private let day: Date

    init(day: Date) {
        let start = day.startOfDay
        let end = start.nextDay
        self.day = start
        _tasks = Query(
            filter: #Predicate<TaskItem> { $0.date >= start && $0.date < end },
            sort: [SortDescriptor(\TaskItem.sortOrder), SortDescriptor(\TaskItem.createdAt)]
        )
    }

    private var visible: [TaskItem] {
        guard let filter else { return tasks }
        return tasks.filter { $0.category == filter }
    }

    private var openTasks: [TaskItem] { visible.filter { !$0.isCompleted } }

    private var doneTasks: [TaskItem] {
        visible.filter(\.isCompleted)
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private var progress: Double {
        tasks.isEmpty ? 0 : Double(tasks.filter(\.isCompleted).count) / Double(tasks.count)
    }

    private var title: String {
        day.isToday ? "Today's To-Dos" : day.formatted(.dateTime.weekday(.wide).month().day())
    }

    private var cheer: String {
        switch progress {
        case 0 where tasks.isEmpty: "Plan • Do • Achieve"
        case 0: "Let's make it a wonderful day ✨"
        case ..<0.5: "Great start, keep going! 🌸"
        case ..<1: "Almost there — you've got this! 💪"
        default: "All done — you're a star! ⭐"
        }
    }

    private var usedCategories: [TaskCategory] {
        let used = Set(tasks.map(\.category))
        return TaskCategory.allCases.filter { used.contains($0) }
    }

    var body: some View {
        List {
            Section {
                SectionHeader(title: title, subtitle: cheer, symbol: "checklist", theme: .todos) {
                    ProgressRing(progress: progress, tint: Palette.grape)
                        .frame(width: 62, height: 62)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            Section {
                addRow
                if usedCategories.count > 1 {
                    categoryFilter
                }
            }
            .listRowBackground(Color.white.opacity(0.85))

            if tasks.isEmpty {
                Section {
                    EmptyStateCard(title: "Nothing planned yet",
                                   message: "Add your first to-do above and make today amazing! 💖")
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else {
                Section {
                    if openTasks.isEmpty {
                        celebration
                    }
                    ForEach(openTasks) { task in
                        row(task)
                    }
                    .onMove { move(from: $0, to: $1) }
                } header: {
                    ListHeader(title: "To Do", count: openTasks.count, tint: Palette.grape)
                }
                .listRowBackground(Color.white.opacity(0.85))

                if showCompleted && !doneTasks.isEmpty {
                    Section {
                        ForEach(doneTasks) { task in
                            row(task)
                        }
                    } header: {
                        ListHeader(title: "Done", count: doneTasks.count, tint: Palette.mint)
                    }
                    .listRowBackground(Color.white.opacity(0.7))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(DreamyBackground(theme: .todos))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isComposing = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("New to-do")
            }
        }
        .sheet(item: $editing) { task in
            NewTaskSheet(task: task)
        }
        .sheet(isPresented: $isComposing) {
            NewTaskSheet(date: day, category: filter ?? .personal)
        }
    }

    // MARK: Rows

    private var addRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(Palette.grape.gradient)
            TextField("Add a new to-do…", text: $draft)
                .font(.rounded(.body, weight: .medium))
                .submitLabel(.done)
                .focused($draftFocused)
                .onSubmit { addDraft() }
            Button {
                isComposing = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Palette.grape)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("More options")
        }
        .padding(.vertical, 4)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", symbol: "square.grid.2x2.fill", tint: Palette.grape, isOn: filter == nil) {
                    filter = nil
                }
                ForEach(usedCategories) { category in
                    FilterChip(title: category.label, symbol: category.symbol, tint: category.color,
                               isOn: filter == category) {
                        filter = filter == category ? nil : category
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var celebration: some View {
        HStack(spacing: 12) {
            Text("🎉").font(.largeTitle)
            VStack(alignment: .leading, spacing: 2) {
                Text("All done — you're a star!")
                    .font(.rounded(.headline, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Text("Enjoy the rest of your beautiful day 💖")
                    .font(.rounded(.caption, weight: .medium))
                    .foregroundStyle(Palette.inkSoft)
            }
        }
        .padding(.vertical, 6)
    }

    private func row(_ task: TaskItem) -> some View {
        TaskRow(task: task, onToggle: { toggle(task) }, onOpen: { editing = task })
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    withAnimation(.snappy) { TaskActions.delete(task, in: context) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }

    // MARK: Actions

    private func addDraft() {
        let clean = draft.trimmed
        guard !clean.isEmpty else { return }
        withAnimation(.snappy) {
            context.insert(TaskItem(title: clean, category: filter ?? .personal, date: day))
        }
        draft = ""
        Haptics.tap()
        draftFocused = true
    }

    private func toggle(_ task: TaskItem) {
        withAnimation(.snappy) { TaskActions.toggle(task, in: context) }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = openTasks
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, task) in reordered.enumerated() {
            task.sortOrder = Double(index)
        }
    }
}

/// A single to-do: checkbox, title, category, time, reminder and repeat.
struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                CheckBubble(isOn: task.isCompleted, tint: task.category.color)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(task.isCompleted ? "Mark \(task.title) as not done" : "Mark \(task.title) as done")

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.rounded(.body, weight: .semibold))
                    .strikethrough(task.isCompleted, color: task.category.color)
                    .foregroundStyle(task.isCompleted ? Color.secondary : Palette.ink)
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.rounded(.caption))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(2)
                }
                TaskMetaLine(task: task)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)
            .accessibilityAddTraits(.isButton)
        }
        .padding(.vertical, 4)
    }
}

/// Category, time, reminder and repeat, shown in small type under a to-do.
struct TaskMetaLine: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 8) {
            Label(task.category.label, systemImage: task.category.symbol)
                .foregroundStyle(task.category.color)
            if let time = task.time {
                Label(time.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                    .foregroundStyle(Palette.inkSoft)
            }
            if let reminder = task.activeReminder, !task.isCompleted {
                Label(reminder.formatted(date: .omitted, time: .shortened), systemImage: "bell.fill")
                    .foregroundStyle(Palette.hotPink)
            }
            if task.repeatOption != .never {
                Image(systemName: "repeat")
                    .foregroundStyle(Palette.inkSoft)
                    .accessibilityLabel(task.repeatOption.label)
            }
        }
        .font(.rounded(.caption2, weight: .bold))
        .labelStyle(CompactLabelStyle())
        .lineLimit(1)
    }
}

private struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon
            configuration.title
        }
    }
}

struct FilterChip: View {
    let title: String
    let symbol: String
    let tint: Color
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            withAnimation(.snappy) { action() }
        } label: {
            Label(title, systemImage: symbol)
                .font(.rounded(.caption, weight: .bold))
                .foregroundStyle(isOn ? Color.white : tint)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(isOn ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(tint.opacity(0.12))))
        }
        .buttonStyle(.borderless)
        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
    }
}
