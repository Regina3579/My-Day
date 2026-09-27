import SwiftUI
import SwiftData

/// "Today's To-Dos — Plan • Do • Achieve". Also used for any other day from the calendar.
struct TodosView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Prefs.showCompleted) private var showCompleted = true
    @Query private var tasks: [TaskItem]
    @State private var draft = ""
    @State private var draftIsPriority = false
    @State private var editing: TaskItem?
    @State private var isComposing = false
    @FocusState private var draftFocused: Bool
    private let day: Date

    init(day: Date) {
        let start = day.startOfDay
        let end = start.nextDay
        self.day = start
        _tasks = Query(
            filter: #Predicate<TaskItem> { $0.day >= start && $0.day < end },
            sort: [SortDescriptor(\TaskItem.sortIndex), SortDescriptor(\TaskItem.createdAt)]
        )
    }

    private var openTasks: [TaskItem] { tasks.filter { !$0.isDone } }

    private var doneTasks: [TaskItem] {
        tasks.filter(\.isDone).sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private var progress: Double {
        tasks.isEmpty ? 0 : Double(doneTasks.count) / Double(tasks.count)
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
            TaskEditorView(mode: .edit(task))
        }
        .sheet(isPresented: $isComposing) {
            TaskEditorView(mode: .new(day: day, priority: false))
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
                draftIsPriority.toggle()
                Haptics.tap()
            } label: {
                Image(systemName: draftIsPriority ? "star.fill" : "star")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(draftIsPriority ? Palette.honey : Color.secondary.opacity(0.6))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(draftIsPriority ? "Will be a priority" : "Make it a priority")
        }
        .padding(.vertical, 4)
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
        TaskRow(task: task, tint: Palette.grape,
                onToggle: { toggle(task) },
                onStar: { star(task) },
                onOpen: { editing = task })
            .swipeActions(edge: .leading) {
                Button {
                    star(task)
                } label: {
                    Label(task.isPriority ? "Unstar" : "Priority", systemImage: task.isPriority ? "star.slash" : "star.fill")
                }
                .tint(Palette.honey)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    delete(task)
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
            context.insert(TaskItem(title: clean, day: day, isPriority: draftIsPriority))
        }
        draft = ""
        draftIsPriority = false
        Haptics.tap()
        draftFocused = true
    }

    private func toggle(_ task: TaskItem) {
        withAnimation(.snappy) { task.toggleDone() }
        ReminderCenter.sync(task)
        if task.isDone { Haptics.success() } else { Haptics.tap() }
    }

    private func star(_ task: TaskItem) {
        withAnimation(.snappy) { task.isPriority.toggle() }
        Haptics.tap()
    }

    private func delete(_ task: TaskItem) {
        ReminderCenter.cancel(taskID: task.uuid)
        withAnimation(.snappy) { context.delete(task) }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = openTasks
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, task) in reordered.enumerated() {
            task.sortIndex = Double(index)
        }
    }
}

/// A single to-do: checkbox, title, note, reminder time and priority star.
struct TaskRow: View {
    let task: TaskItem
    var tint: Color = Palette.grape
    let onToggle: () -> Void
    let onStar: () -> Void
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                CheckBubble(isOn: task.isDone, tint: tint)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(task.isDone ? "Mark as not done" : "Mark as done")

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.rounded(.body, weight: .semibold))
                    .strikethrough(task.isDone, color: tint)
                    .foregroundStyle(task.isDone ? Color.secondary : Palette.ink)
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.rounded(.caption))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(2)
                }
                if let reminder = task.reminderAt, !task.isDone {
                    Label(reminder.formatted(date: .omitted, time: .shortened), systemImage: "bell.fill")
                        .font(.rounded(.caption2, weight: .bold))
                        .foregroundStyle(Palette.hotPink)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)
            .accessibilityAddTraits(.isButton)

            Button(action: onStar) {
                Image(systemName: task.isPriority ? "star.fill" : "star")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(task.isPriority ? Palette.honey : Color.secondary.opacity(0.6))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(task.isPriority ? "Remove from priorities" : "Make it a priority")
        }
        .padding(.vertical, 4)
    }
}
