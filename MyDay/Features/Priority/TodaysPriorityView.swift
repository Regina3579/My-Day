import SwiftUI
import SwiftData

/// "Today's Priority — Focus on what matters most".
struct TodaysPriorityView: View {
    @Environment(\.modelContext) private var context
    @Query private var priorities: [Priority]
    @Query private var tasks: [TaskItem]
    @State private var draft = ""
    @State private var editing: Priority?
    @FocusState private var draftFocused: Bool
    private let day: Date

    init(day: Date) {
        let start = day.startOfDay
        let end = start.nextDay
        self.day = start
        _priorities = Query(
            filter: #Predicate<Priority> { $0.date >= start && $0.date < end },
            sort: [SortDescriptor(\Priority.order), SortDescriptor(\Priority.createdAt)]
        )
        _tasks = Query(
            filter: #Predicate<TaskItem> { $0.date >= start && $0.date < end && $0.isCompleted == false },
            sort: [SortDescriptor(\TaskItem.sortOrder)]
        )
    }

    private var doneCount: Int { priorities.filter(\.isCompleted).count }

    /// Open to-dos that are not already priorities, offered as suggestions.
    private var suggestions: [TaskItem] {
        let chosen = Set(priorities.map { $0.title.lowercased() })
        return tasks.filter { !chosen.contains($0.title.lowercased()) }
    }

    var body: some View {
        List {
            Section {
                hero
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section {
                if priorities.isEmpty {
                    EmptyStateCard(title: "What matters most today?",
                                   message: "Choose one to three things. Doing them makes the whole day feel great. ⭐")
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                }
                ForEach(Array(priorities.enumerated()), id: \.element.persistentModelID) { index, priority in
                    PriorityCard(rank: index + 1, priority: priority,
                                 onToggle: { toggle(priority) },
                                 onOpen: { editing = priority })
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                delete(priority)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onMove { move(from: $0, to: $1) }

                addCard
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))

                if priorities.count > 3 {
                    Label("Tip: keep it to three — focus is a superpower ✨", systemImage: "lightbulb.fill")
                        .font(.rounded(.footnote, weight: .semibold))
                        .foregroundStyle(Palette.cocoa)
                        .cuteCard(tint: Palette.honey, padding: 14)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                }

                if !suggestions.isEmpty {
                    suggestionsCard
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                }

                Text(FocusQuotes.quote(for: day))
                    .font(.rounded(.callout, weight: .semibold))
                    .italic()
                    .foregroundStyle(Palette.cocoa.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .contentMargins(.horizontal, 18, for: .scrollContent)
        .tabBarSafeArea()
        .background(DreamyBackground(theme: .priority))
        .navigationTitle(day.isToday ? "Today's Priority" : "Priorities")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { priority in
            NewPrioritySheet(priority: priority)
        }
    }

    // MARK: Pieces

    private var hero: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color.white, Palette.butter.opacity(0)],
                                         center: .center, startRadius: 4, endRadius: 80))
                    .frame(width: 150, height: 150)
                Image(systemName: "star.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFE066), Palette.honey],
                                                    startPoint: .top, endPoint: .bottom))
                    .shadow(color: Palette.honey.opacity(0.5), radius: 12, x: 0, y: 6)
                ShinyHeart(size: 20).offset(x: -70, y: -24)
                ShinyHeart(size: 14).offset(x: 72, y: 14)
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
                .onSubmit { add(draft) }
            Button("Add") { add(draft) }
                .font(.rounded(.subheadline, weight: .bold))
                .buttonStyle(.borderedProminent)
                .tint(Palette.honey)
                .disabled(draft.trimmed.isEmpty)
        }
        .cuteCard(tint: Palette.honey, padding: 14)
    }

    private var suggestionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick from today's to-dos")
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(Palette.cocoa)
            ForEach(suggestions.prefix(5)) { task in
                Button {
                    add(task.title)
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
                .buttonStyle(.borderless)
                .accessibilityLabel("Make \(task.title) a priority")
            }
        }
        .cuteCard(tint: Palette.honey)
    }

    // MARK: Actions

    private func add(_ text: String) {
        let clean = text.trimmed
        guard !clean.isEmpty else { return }
        let nextOrder = (priorities.map(\.order).max() ?? -1) + 1
        withAnimation(.snappy) {
            context.insert(Priority(title: clean, date: day, order: nextOrder))
        }
        if text == draft {
            draft = ""
            draftFocused = true
        }
        Haptics.success()
    }

    private func toggle(_ priority: Priority) {
        withAnimation(.snappy) { priority.toggleCompleted() }
        if priority.isCompleted { Haptics.success() } else { Haptics.tap() }
    }

    private func delete(_ priority: Priority) {
        withAnimation(.snappy) { context.delete(priority) }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = priorities
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, priority) in reordered.enumerated() {
            priority.order = index
        }
    }
}

/// A numbered golden card for one priority.
struct PriorityCard: View {
    let rank: Int
    let priority: Priority
    let onToggle: () -> Void
    let onOpen: () -> Void

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

            Text(priority.title)
                .font(.rounded(.headline, weight: .bold))
                .strikethrough(priority.isCompleted, color: Palette.honey)
                .foregroundStyle(priority.isCompleted ? Color.secondary : Palette.cocoa)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: onOpen)
                .accessibilityAddTraits(.isButton)

            Button(action: onToggle) {
                CheckBubble(isOn: priority.isCompleted, tint: Palette.honey, size: 32)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(priority.isCompleted ? "Mark as not done" : "Mark as done")
        }
        .cuteCard(tint: Palette.honey, padding: 16)
    }
}
