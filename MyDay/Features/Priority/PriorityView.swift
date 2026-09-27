import SwiftUI
import SwiftData

/// "Today's Priority — Focus on what matters most".
/// Priorities are starred to-dos, so they also appear in the to-do list.
struct PriorityView: View {
    @Environment(\.modelContext) private var context
    @Query private var tasks: [TaskItem]
    @State private var draft = ""
    @State private var editing: TaskItem?
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

    private var priorities: [TaskItem] { tasks.filter(\.isPriority) }
    private var candidates: [TaskItem] { tasks.filter { !$0.isPriority && !$0.isDone } }
    private var doneCount: Int { priorities.filter(\.isDone).count }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero

                if priorities.isEmpty {
                    EmptyStateCard(title: "What matters most today?",
                                   message: "Choose one to three things. Doing them makes the whole day feel great. ⭐")
                } else {
                    ForEach(Array(priorities.enumerated()), id: \.element.id) { index, task in
                        PriorityCard(rank: index + 1, task: task,
                                     onToggle: { toggle(task) },
                                     onOpen: { editing = task },
                                     onUnstar: { unstar(task) })
                    }
                }

                addCard

                if priorities.count > 3 {
                    Label("Tip: keep it to three — focus is a superpower ✨", systemImage: "lightbulb.fill")
                        .font(.rounded(.footnote, weight: .semibold))
                        .foregroundStyle(Palette.cocoa)
                        .cuteCard(tint: Palette.honey, padding: 14)
                }

                if !candidates.isEmpty {
                    pickCard
                }

                Text(Quotes.focus(for: day))
                    .font(.rounded(.callout, weight: .semibold))
                    .italic()
                    .foregroundStyle(Palette.cocoa.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .animation(.snappy, value: priorities.map(\.isDone))
        }
        .scrollDismissesKeyboard(.interactively)
        .background(DreamyBackground(theme: .priority))
        .navigationTitle(day.isToday ? "Today's Priority" : "Priorities")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { task in
            TaskEditorView(mode: .edit(task))
        }
    }

    // MARK: Pieces

    private var hero: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color.white, Palette.butter.opacity(0)],
                                         center: .center, startRadius: 4, endRadius: 80))
                    .frame(width: 160, height: 160)
                Image(systemName: "star.fill")
                    .font(.system(size: 76))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFE066), Palette.honey],
                                                    startPoint: .top, endPoint: .bottom))
                    .shadow(color: Palette.honey.opacity(0.5), radius: 12, x: 0, y: 6)
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Palette.bubblegum)
                    .offset(x: -70, y: -24)
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.bubblegum)
                    .offset(x: 72, y: 14)
                Image(systemName: "sparkle")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Palette.honey)
                    .offset(x: 58, y: -52)
            }
            .accessibilityHidden(true)

            Text(day.isToday ? "Today's Priority" : "Priorities")
                .font(.rounded(.largeTitle, weight: .heavy))
                .foregroundStyle(Palette.cocoa)
            Text("Focus on what matters most")
                .font(.rounded(.headline, weight: .semibold))
                .foregroundStyle(Palette.cocoa.opacity(0.75))
            HeartUnderline(width: 120)

            if !priorities.isEmpty {
                Text("\(doneCount) of \(priorities.count) done")
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(Palette.cocoa)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.85)))
                    .contentTransition(.numericText())
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var addCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "star.circle.fill")
                .font(.title2)
                .foregroundStyle(Palette.honey.gradient)
            TextField("Add a priority…", text: $draft)
                .font(.rounded(.body, weight: .medium))
                .submitLabel(.done)
                .focused($draftFocused)
                .onSubmit { add() }
            Button("Add", action: add)
                .font(.rounded(.subheadline, weight: .bold))
                .buttonStyle(.borderedProminent)
                .tint(Palette.honey)
                .disabled(draft.trimmed.isEmpty)
        }
        .cuteCard(tint: Palette.honey, padding: 14)
    }

    private var pickCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick from today's to-dos")
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(Palette.cocoa)
            ForEach(candidates) { task in
                Button {
                    promote(task)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "star")
                            .foregroundStyle(Palette.honey)
                        Text(task.title)
                            .font(.rounded(.body, weight: .medium))
                            .foregroundStyle(Palette.ink)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Palette.honey)
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Make \(task.title) a priority")

                if task.id != candidates.last?.id {
                    Divider()
                }
            }
        }
        .cuteCard(tint: Palette.honey)
    }

    // MARK: Actions

    private func add() {
        let clean = draft.trimmed
        guard !clean.isEmpty else { return }
        withAnimation(.snappy) {
            context.insert(TaskItem(title: clean, day: day, isPriority: true))
        }
        draft = ""
        Haptics.success()
        draftFocused = true
    }

    private func toggle(_ task: TaskItem) {
        withAnimation(.snappy) { task.toggleDone() }
        ReminderCenter.sync(task)
        if task.isDone { Haptics.success() } else { Haptics.tap() }
    }

    private func promote(_ task: TaskItem) {
        withAnimation(.snappy) { task.isPriority = true }
        Haptics.tap()
    }

    private func unstar(_ task: TaskItem) {
        withAnimation(.snappy) { task.isPriority = false }
        Haptics.tap()
    }
}

/// A numbered golden card for one priority.
struct PriorityCard: View {
    let rank: Int
    let task: TaskItem
    let onToggle: () -> Void
    let onOpen: () -> Void
    let onUnstar: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(.rounded(.title3, weight: .heavy))
                .foregroundStyle(Color.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(LinearGradient(colors: [Color(hex: 0xFFE27A), Palette.honey],
                                                 startPoint: .top, endPoint: .bottom))
                )
                .shadow(color: Palette.honey.opacity(0.4), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.rounded(.headline, weight: .bold))
                    .strikethrough(task.isDone, color: Palette.honey)
                    .foregroundStyle(task.isDone ? Color.secondary : Palette.cocoa)
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.rounded(.caption))
                        .foregroundStyle(Palette.cocoa.opacity(0.7))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)

            Button(action: onToggle) {
                CheckBubble(isOn: task.isDone, tint: Palette.honey, size: 32)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel(task.isDone ? "Mark as not done" : "Mark as done")
        }
        .cuteCard(tint: Palette.honey, padding: 16)
        .contextMenu {
            Button(action: onOpen) {
                Label("Edit", systemImage: "pencil")
            }
            Button(action: onUnstar) {
                Label("Remove from priorities", systemImage: "star.slash")
            }
        }
    }
}
