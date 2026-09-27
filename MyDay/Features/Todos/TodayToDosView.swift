import SwiftData
import SwiftUI

/// "Today's To-Dos": the illustrated header, the day's list in soft pastel rows,
/// five ways to add a to-do and the day's progress. Also used for other days from the calendar.
struct TodayToDosView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.tabBarClearance) private var tabBarClearance
    @AppStorage(Prefs.showCompleted) private var showCompleted = true
    @Query private var tasks: [TaskItem]
    @State private var filter: TaskCategory?
    @State private var sheet: TodoSheet?
    @State private var pendingDelete: TaskItem?
    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var heroIsVisible = true
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

    private var title: String {
        day.isToday ? "Today's To-Dos" : day.formatted(.dateTime.weekday(.wide).month().day())
    }

    /// Open to-dos in the person's order, then finished ones (unless hidden in Settings).
    private var visible: [TaskItem] {
        let pool = filter.map { category in tasks.filter { $0.category == category } } ?? tasks
        let open = pool.filter { !$0.isCompleted }
        guard showCompleted else { return open }
        let done = pool.filter(\.isCompleted)
            .sorted { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }
        return open + done
    }

    private var doneCount: Int { tasks.filter(\.isCompleted).count }

    // The body is split into small steps so the compiler can type-check each one quickly.
    var body: some View {
        withSheets
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    principalTitle
                }
            }
            #if DEBUG
            .task { openDebugSheet() }
            #endif
    }

    private var page: some View {
        GeometryReader { proxy in
            scrollingPage(width: proxy.size.width, safeTop: proxy.safeAreaInsets.top)
        }
        .background(TodosBackdrop())
        .overlay(alignment: .bottom) {
            toastView
        }
    }

    private func scrollingPage(width: CGFloat, safeTop: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                hero(width: width, safeTop: safeTop)
                panel
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .tabBarSafeArea()
        .ignoresSafeArea(edges: .top)
    }

    /// The scene; once it scrolls away, the title appears in the navigation bar.
    private func hero(width: CGFloat, safeTop: CGFloat) -> some View {
        TodosHero(width: width, safeTop: safeTop)
            .onGeometryChange(for: Bool.self) { geometry in
                geometry.frame(in: .global).maxY > 150
            } action: { isVisible in
                heroIsVisible = isVisible
            }
    }

    /// Everything below the scene, on a rounded panel that overlaps it slightly.
    private var panel: some View {
        content
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .background(alignment: .top) {
                panelBackground
            }
            .padding(.top, -24)
    }

    private var panelBackground: some View {
        UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
            .fill(Self.panelFill)
            .shadow(color: Palette.hotPink.opacity(0.12), radius: 10, x: 0, y: -4)
    }

    private static let panelFill = LinearGradient(
        colors: [Color(hex: 0xFFF7FA), TodosBackdrop.base], startPoint: .top, endPoint: .bottom
    )

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            TodoToast(text: toast)
                .padding(.bottom, tabBarClearance + 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .allowsHitTesting(false)
        }
    }

    private var principalTitle: some View {
        Text(title)
            .font(.rounded(.headline, weight: .bold))
            .foregroundStyle(Palette.ink)
            .opacity(heroIsVisible ? 0 : 1)
            .animation(.easeInOut(duration: 0.2), value: heroIsVisible)
            .accessibilityHidden(heroIsVisible)
    }

    private var withSheets: some View {
        page
            .sheet(item: $sheet) { sheet in
                sheetContent(sheet)
            }
            .confirmationDialog("Delete this to-do?", isPresented: deleteBinding, titleVisibility: .visible,
                                presenting: pendingDelete) { task in
                Button("Delete “\(task.title)”", role: .destructive) { delete(task) }
            } message: { _ in
                Text("This can't be undone.")
            }
    }

    #if DEBUG
    private func openDebugSheet() {
        if let route = DebugLaunchRoute.takeTodosSheet() {
            sheet = TodoSheet(debugRoute: route)
        }
    }
    #endif

    // MARK: Content

    private var content: some View {
        VStack(spacing: 14) {
            TodayHeaderCard(day: day)
            CategoryChipBar(selection: $filter)
                .padding(.bottom, -8)
            list
            TodosActionBar(
                onAdd: { sheet = .compose(filter, nil) },
                onQuickAdd: { sheet = .quickAdd },
                onVoice: { sheet = .voice(sample: nil) },
                onPhoto: { sheet = .compose(filter, .photo) },
                onTemplate: { sheet = .templates }
            )
            .padding(.top, 4)
            TodosProgressCard(done: doneCount, total: tasks.count)
                .padding(.top, 10)
        }
    }

    @ViewBuilder
    private var list: some View {
        let rows = visible
        if rows.isEmpty {
            if tasks.isEmpty {
                TodosEmptyCard(title: "Nothing planned yet",
                               message: "Add your first to-do and make this day wonderful 💖",
                               actionTitle: "Add a New Task ✨") { sheet = .compose(filter, nil) }
            } else if let filter {
                TodosEmptyCard(title: "No \(filter.label) to-dos",
                               message: "Nothing in \(filter.label) \(day.isToday ? "today" : "on this day") yet.",
                               actionTitle: "Add a \(filter.label) Task") { sheet = .compose(filter, nil) }
            } else {
                TodosEmptyCard(title: "All done — you're a star! ⭐",
                               message: "Finished to-dos are hidden. You can show them again in Settings.",
                               actionTitle: "Add a New Task ✨") { sheet = .compose(nil, nil) }
            }
        } else {
            VStack(spacing: 10) {
                ForEach(Array(rows.enumerated()), id: \.element.persistentModelID) { index, task in
                    row(task, index: index)
                }
            }
        }
    }

    private func row(_ task: TaskItem, index: Int) -> some View {
        TodoRow(
            task: task,
            tint: RowTint.at(index),
            onToggle: { toggle(task) },
            onOpen: { sheet = .edit(task, nil) },
            onAction: { action in handle(action, for: task) }
        )
        .draggable(task.id.uuidString) {
            dragPreview(for: task)
        }
        .dropDestination(for: String.self) { items, _ in
            move(items.first, onto: task)
        }
        .transition(Self.rowTransition)
    }

    private static let rowTransition = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.92).combined(with: .opacity), removal: .opacity
    )

    private func dragPreview(for task: TaskItem) -> some View {
        Text(task.title)
            .font(.rounded(.body, weight: .semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.white))
    }

    @ViewBuilder
    private func sheetContent(_ sheet: TodoSheet) -> some View {
        switch sheet {
        case .compose(let category, let focus):
            NewTaskSheet(date: day, category: category ?? .personal, focus: focus) { saved in
                show("Added “\(saved.title)” ✨")
            }
        case .edit(let task, let focus):
            NewTaskSheet(task: task, focus: focus)
        case .draft(let draft):
            NewTaskSheet(draft: draft) { saved in
                show("Added “\(saved.title)” ✨")
            }
        case .quickAdd:
            QuickAddTaskSheet(day: day)
        case .voice(let sample):
            VoiceTaskSheet(
                day: day,
                onEdit: { draft in self.sheet = .draft(draft) },
                onAdded: { title in show("Added “\(title)” ✨") },
                sample: sample
            )
        case .templates:
            TemplatePickerSheet(day: day, currentTitles: tasks.map(\.title)) { count in
                show(count == 1 ? "Added 1 to-do ✨" : "Added \(count) to-dos ✨")
            }
        }
    }

    // MARK: Actions

    private func toggle(_ task: TaskItem) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            TaskActions.toggle(task, in: context)
        }
        if task.isCompleted, !tasks.isEmpty, tasks.allSatisfy(\.isCompleted) {
            show("All done — you're a star! ⭐")
        }
    }

    private func handle(_ action: TaskMenuAction, for task: TaskItem) {
        switch action {
        case .edit: sheet = .edit(task, .title)
        case .changeDate: sheet = .edit(task, .when)
        case .reminder: sheet = .edit(task, .reminder)
        case .repeatRule: sheet = .edit(task, .repeatRule)
        case .moveToPriority:
            withAnimation(.snappy) { TaskActions.moveToPriority(task, in: context) }
            Haptics.success()
            show("Moved to Today's Priority ⭐")
        case .delete:
            pendingDelete = task
        }
    }

    private func delete(_ task: TaskItem) {
        withAnimation(.snappy) { TaskActions.delete(task, in: context) }
        show("To-do deleted")
    }

    /// Drag a to-do onto another to put it there.
    private func move(_ id: String?, onto target: TaskItem) -> Bool {
        guard let id, let moving = tasks.first(where: { $0.id.uuidString == id }),
              moving.persistentModelID != target.persistentModelID,
              !moving.isCompleted, !target.isCompleted
        else { return false }
        var open = tasks.filter { !$0.isCompleted }
        guard let from = open.firstIndex(where: { $0.persistentModelID == moving.persistentModelID }),
              let to = open.firstIndex(where: { $0.persistentModelID == target.persistentModelID })
        else { return false }
        open.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        withAnimation(.snappy) {
            for (index, task) in open.enumerated() {
                task.sortOrder = Double(index)
            }
        }
        Haptics.tap()
        return true
    }

    private func show(_ message: String) {
        toastTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { toast = message }
        AccessibilityNotification.Announcement(message).post()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) { toast = nil }
        }
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }
}

/// The sheets the To-Dos screen can show.
enum TodoSheet: Identifiable {
    /// A new to-do, optionally in a category and opened at a section (e.g. the photo).
    case compose(TaskCategory?, TaskSheetFocus?)
    case edit(TaskItem, TaskSheetFocus?)
    /// A new to-do filled in by Voice Add, to check and finish.
    case draft(TaskDraft)
    case quickAdd
    case voice(sample: String?)
    case templates

    var id: String {
        switch self {
        case .compose(let category, let focus): "compose-\(category?.rawValue ?? "")-\(focus?.rawValue ?? "")"
        case .edit(let task, let focus): "edit-\(task.id.uuidString)-\(focus?.rawValue ?? "")"
        case .draft: "draft"
        case .quickAdd: "quick"
        case .voice: "voice"
        case .templates: "templates"
        }
    }
}

/// Soft blush behind the list (seen when the content is short or overscrolled).
private struct TodosBackdrop: View {
    static let base = Color(hex: 0xFFF0F6)

    var body: some View {
        ZStack {
            Self.base
            SparkleField(tint: Palette.hotPink)
                .opacity(0.6)
        }
        .ignoresSafeArea()
    }
}

#if DEBUG
extension TodoSheet {
    /// Sheets that `-screenshotRoute todos-<name>` can open.
    init?(debugRoute: String) {
        switch debugRoute {
        case "add": self = .compose(nil, nil)
        case "photo": self = .compose(nil, .photo)
        case "quick": self = .quickAdd
        case "voice": self = .voice(sample: "Remind me to call the doctor tomorrow at 5 PM")
        case "templates": self = .templates
        default: return nil
        }
    }
}
#endif
