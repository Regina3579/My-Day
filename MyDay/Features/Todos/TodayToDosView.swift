import SwiftData
import SwiftUI

/// "Today's To-Dos": the illustrated header, the day's list in soft pastel rows,
/// four ways to add a to-do and the day's progress. Also used for other days from the calendar.
struct TodayToDosView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.tabBarClearance) private var tabBarClearance
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Whether the Completed list is open (also "Show finished to-dos" in Settings).
    @AppStorage(Prefs.showCompleted) private var showCompleted = false
    @AppStorage(Prefs.didShowVoiceTip) private var didShowVoiceTip = false
    @AppStorage(Prefs.didShowQuoteTip) private var didShowQuoteTip = false
    @AppStorage(Prefs.didShowPhotoTip) private var didShowPhotoTip = false
    /// The first-time tips, one at a time: the day's quote, then Speak a Task, then Photo.
    @State private var showsVoiceTip = false
    @State private var showsQuoteTip = false
    @State private var showsPhotoTip = false
    /// Where the day's quote is on screen (global), for its tip.
    @State private var quoteFrame: CGRect = .zero
    /// "Show me": the quote glows for a moment.
    @State private var quoteGlows = false
    @Query private var tasks: [TaskItem]
    @State private var filter: CategoryChoice?
    @State private var sheet: TodoSheet?
    @State private var pendingDelete: TaskItem?
    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var heroIsVisible = true
    /// Height of the pinned add buttons, so the toast can float above them.
    @State private var dockHeight: CGFloat = 0
    /// Goes up each time the last to-do of the day is ticked; each change plays the confetti.
    @State private var celebration = 0
    @State private var showsConfetti = false
    /// Just-ticked to-dos stay in place for a moment (so their hearts can pop) before they
    /// move down to the finished ones.
    @State private var settling: Set<PersistentIdentifier> = []
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

    /// The day's to-dos in the chosen category (all of them with "All").
    private var pool: [TaskItem] {
        filter.map { choice in tasks.filter { $0.choice == choice } } ?? tasks
    }

    /// Open to-dos in the person's order, important ones (★) first. A to-do ticked a moment
    /// ago still sits here until it slides into Completed.
    private var openRows: [TaskItem] {
        let unfinished = pool.filter { !$0.isCompleted || settling.contains($0.persistentModelID) }
        return unfinished.filter(\.isImportant) + unfinished.filter { !$0.isImportant }
    }

    /// Finished to-dos, in the order they were ticked: listed under "Completed" when it is open.
    private var doneRows: [TaskItem] {
        pool.filter { $0.isCompleted && !settling.contains($0.persistentModelID) }
            .sorted { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }
    }

    private var doneCount: Int { tasks.filter(\.isCompleted).count }

    /// The add buttons stay pinned above the tab bar. At the largest text sizes they would
    /// cover most of the screen, so there they sit at the end of the list instead.
    private var pinsActions: Bool { !typeSize.isAccessibilitySize }

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
            .task { await openDebugRoute() }
            #endif
    }

    private var page: some View {
        GeometryReader { proxy in
            scrollingPage(width: proxy.size.width, safeTop: proxy.safeAreaInsets.top)
        }
        .background(TodosBackdrop())
        .overlay {
            if showsConfetti {
                ConfettiCelebration()
                    .id(celebration)
                    .ignoresSafeArea()
            }
        }
        .overlay(alignment: .bottom) {
            toastView
        }
        .overlayPreferenceValue(VoiceMicAnchorKey.self) { anchor in
            if showsVoiceTip, let anchor {
                GeometryReader { proxy in
                    VoiceAddTip(micFrame: proxy[anchor], size: proxy.size,
                                onTry: tryVoiceFromTip, onDismiss: closeVoiceTip)
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .overlayPreferenceValue(PhotoButtonAnchorKey.self) { anchor in
            if showsPhotoTip, let anchor {
                GeometryReader { proxy in
                    PhotoTip(photoFrame: proxy[anchor], size: proxy.size,
                             onTry: tryPhotoFromTip, onDismiss: closePhotoTip)
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .overlay {
            if showsQuoteTip {
                GeometryReader { proxy in
                    // The quote's frame is global; the tip's space starts where this view does.
                    let origin = proxy.frame(in: .global).origin
                    QuoteTip(quoteFrame: quoteFrame.offsetBy(dx: -origin.x, dy: -origin.y), size: proxy.size,
                             onShowMe: showQuoteFromTip, onDismiss: closeQuoteTip)
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .task { await showTipsIfNew() }
        .onChange(of: sheet == nil) { _, isClosed in
            // "Try it now" opened Speak a Task: the Photo tip comes once it is closed.
            guard isClosed else { return }
            Task {
                try? await Task.sleep(for: .seconds(0.7))
                showPhotoTipIfNew()
            }
        }
    }

    // MARK: First-time tip

    /// New here: after a moment, the tips not seen yet, one at a time: the day's quote, Speak a
    /// Task, then Photo (the last two not at the largest text sizes, where the buttons are at
    /// the end of the list). Each comes once the one before it is closed.
    private func showTipsIfNew() async {
        guard !didShowQuoteTip || (pinsActions && (!didShowVoiceTip || !didShowPhotoTip)) else { return }
        try? await Task.sleep(for: .seconds(0.9))
        guard !Task.isCancelled, sheet == nil else { return }
        if !didShowQuoteTip, quoteFrame != .zero {
            didShowQuoteTip = true
            withAnimation(.easeOut(duration: 0.3)) { showsQuoteTip = true }
        } else if !didShowVoiceTip {
            showVoiceTipIfNew()
        } else {
            showPhotoTipIfNew()
        }
    }

    private func showVoiceTipIfNew() {
        guard !didShowVoiceTip, pinsActions, sheet == nil else { return }
        didShowVoiceTip = true
        withAnimation(.easeOut(duration: 0.3)) { showsVoiceTip = true }
    }

    /// The Photo tip, after the Speak a Task tip, when no other tip or sheet is open.
    private func showPhotoTipIfNew() {
        guard !didShowPhotoTip, didShowVoiceTip, pinsActions, sheet == nil,
              !showsQuoteTip, !showsVoiceTip, !showsPhotoTip
        else { return }
        didShowPhotoTip = true
        withAnimation(.easeOut(duration: 0.3)) { showsPhotoTip = true }
    }

    /// Closing the quote tip brings the Speak a Task tip, when it hasn't been shown yet.
    private func closeQuoteTip() {
        withAnimation(.easeOut(duration: 0.25)) { showsQuoteTip = false }
        Haptics.tap()
        Task {
            try? await Task.sleep(for: .seconds(0.7))
            showVoiceTipIfNew()
        }
    }

    /// "Show me": the tip closes and the quote glows for a moment.
    private func showQuoteFromTip() {
        closeQuoteTip()
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            quoteGlows = true
            try? await Task.sleep(for: .seconds(2.4))
            quoteGlows = false
        }
    }

    /// Closing the Speak a Task tip brings the Photo tip, when it hasn't been shown yet.
    private func closeVoiceTip() {
        withAnimation(.easeOut(duration: 0.25)) { showsVoiceTip = false }
        Haptics.tap()
        Task {
            try? await Task.sleep(for: .seconds(0.7))
            showPhotoTipIfNew()
        }
    }

    private func tryVoiceFromTip() {
        closeVoiceTip()
        sheet = .voice(sample: nil)
    }

    private func closePhotoTip() {
        withAnimation(.easeOut(duration: 0.25)) { showsPhotoTip = false }
        Haptics.tap()
    }

    private func tryPhotoFromTip() {
        closePhotoTip()
        sheet = .compose(filter, .photo)
    }

    /// A List (not a ScrollView), so every to-do gets the standard swipe-left Delete
    /// and press-and-hold reordering. The add buttons and Today's Progress are pinned at the
    /// bottom and the list scrolls behind them.
    private func scrollingPage(width: CGFloat, safeTop: CGFloat) -> some View {
        List {
            header(width: width, safeTop: safeTop)
                .plainListRow()
            CategoryChipBar(selection: $filter)
                .plainListRow(EdgeInsets(top: 2, leading: 0, bottom: 0, trailing: 0))
            progressLine
            taskRows
            if pinsActions {
                // A little room between the last to-do and the pinned panel.
                Color.clear
                    .frame(height: 8)
                    .plainListRow()
            } else {
                actionBar
                    .plainListRow(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
                TodosProgressCard(done: doneCount, total: tasks.count)
                    .plainListRow(EdgeInsets(top: 18, leading: 16, bottom: 24, trailing: 16))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if pinsActions {
                actionDock
            }
        }
        .tabBarSafeArea()
        .ignoresSafeArea(edges: .top)
    }

    /// The scene, then the date card on a rounded panel that overlaps it slightly.
    private func header(width: CGFloat, safeTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            hero(width: width, safeTop: safeTop)
            TodayHeaderCard(day: day, quoteGlows: quoteGlows) { frame in
                quoteFrame = frame
            }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 6)
                .frame(maxWidth: .infinity)
                .background(alignment: .top) {
                    panelBackground
                }
                .padding(.top, -16)
        }
    }

    /// The scene; once it scrolls away, the title appears in the navigation bar.
    /// (`safeTop` includes the navigation bar; the scene only keeps clear of the status bar.)
    private func hero(width: CGFloat, safeTop: CGFloat) -> some View {
        TodosHero(width: width, statusBar: Self.statusBarHeight(fallback: max(0, safeTop - 44)))
            .onGeometryChange(for: Bool.self) { geometry in
                // Visible while it still reaches below the navigation bar.
                geometry.frame(in: .global).maxY > safeTop + 8
            } action: { isVisible in
                heroIsVisible = isVisible
            }
    }

    /// The height of the status bar (and the Dynamic Island), from the app's window.
    @MainActor
    private static func statusBarHeight(fallback: CGFloat) -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        return window?.safeAreaInsets.top ?? fallback
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
                .padding(.bottom, tabBarClearance + (pinsActions ? dockHeight : 0) + 12)
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
    /// `todos-<name>` opens a sheet. `todos-alldone` ticks every to-do; `todos-hearts` ticks
    /// one (two little hearts pop), and `todos-confetti` plays the
    /// confetti, timed so the screenshot (taken about 10 seconds after the app is ready)
    /// catches them.
    private func openDebugRoute() async {
        guard let route = DebugLaunchRoute.takeTodosSheet() else { return }
        switch route {
        case "alldone":
            try? await Task.sleep(for: .seconds(1))
            for task in tasks where !task.isCompleted {
                toggle(task)
            }
        case "hearts":
            try? await Task.sleep(for: .seconds(9.4))
            if let first = openRows.first(where: { !$0.isCompleted }) {
                toggle(first)
            }
        case "confetti":
            try? await Task.sleep(for: .seconds(9.4))
            celebrate()
        case "voice-shopping":
            // Shopping is the chip chosen, so the spoken to-do goes to Shopping.
            filter = .builtIn(.shopping)
            try? await Task.sleep(for: .seconds(0.5))
            sheet = .voice(sample: "Get flowers for Mom tomorrow at 6 PM")
        default:
            sheet = TodoSheet(debugRoute: route)
        }
    }
    #endif

    // MARK: Content

    /// The add buttons, then Today's Progress, on a frosted panel that reaches down behind
    /// the tab bar.
    private var actionDock: some View {
        VStack(spacing: 8) {
            actionBar
            TodosProgressStrip(done: doneCount, total: tasks.count)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(alignment: .top) {
            dockBackground
        }
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.height
        } action: { height in
            dockHeight = height
        }
    }

    private var dockBackground: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
        return shape
            .fill(.ultraThinMaterial)
            .overlay(shape.fill(Self.dockTint))
            .overlay(shape.stroke(Color.white.opacity(0.9), lineWidth: 1))
            .shadow(color: Palette.hotPink.opacity(0.16), radius: 14, x: 0, y: -4)
            .ignoresSafeArea(edges: .bottom)
    }

    private static let dockTint = LinearGradient(
        colors: [Color.white.opacity(0.72), TodosBackdrop.base.opacity(0.9)], startPoint: .top, endPoint: .bottom
    )

    private var actionBar: some View {
        TodosActionBar(
            onAdd: { sheet = .compose(filter, nil) },
            onVoice: { sheet = .voice(sample: nil) },
            onPhoto: { sheet = .compose(filter, .photo) },
            onTemplate: { sheet = .templates }
        )
    }

    /// Daily Progress: how many of the day's to-dos are done (hidden while the day is empty).
    @ViewBuilder
    private var progressLine: some View {
        if !tasks.isEmpty {
            DailyProgressLine(day: day, done: doneCount, total: tasks.count)
                .plainListRow(EdgeInsets(top: 0, leading: 16, bottom: 6, trailing: 16))
        }
    }

    /// Open to-dos, then "› Completed" with the finished ones under it while it is open.
    @ViewBuilder
    private var taskRows: some View {
        let open = openRows
        let done = doneRows
        if open.isEmpty && done.isEmpty {
            emptyCard
                .plainListRow(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        } else {
            ForEach(open, id: \.persistentModelID) { task in
                row(task)
            }
            .onMove { source, destination in
                move(from: source, to: destination, in: open)
            }
            if !done.isEmpty {
                CompletedHeader(count: done.count, isOpen: showCompleted) {
                    withAnimation(.snappy) { showCompleted.toggle() }
                }
                .plainListRow(EdgeInsets(top: open.isEmpty ? 4 : 10, leading: 16, bottom: 4, trailing: 16))
                if showCompleted {
                    ForEach(done, id: \.persistentModelID) { task in
                        row(task)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var emptyCard: some View {
        if let filter, !tasks.isEmpty {
            TodosEmptyCard(title: "No \(filter.label) to-dos",
                           message: "Nothing in \(filter.label) \(day.isToday ? "today" : "on this day") yet.",
                           actionTitle: "Add a \(filter.label) Task") { sheet = .compose(filter, nil) }
        } else {
            TodosEmptyCard(title: "Nothing planned yet",
                           message: "Add your first to-do and make this day wonderful 💖",
                           actionTitle: "Add a New Task ✨") { sheet = .compose(filter, nil) }
        }
    }

    /// One to-do, in its category's colour. Swipe left to delete it; press and hold to drag it
    /// to a new place.
    private func row(_ task: TaskItem) -> some View {
        TodoRow(
            task: task,
            tint: RowTint.of(task.choice),
            onToggle: { toggle(task) },
            onImportant: { toggleImportant(task) },
            onOpen: { sheet = .edit(task, nil) },
            onAction: { action in handle(action, for: task) }
        )
        .plainListRow(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                delete(task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .moveDisabled(task.isCompleted)
    }

    @ViewBuilder
    private func sheetContent(_ sheet: TodoSheet) -> some View {
        switch sheet {
        case .compose(let category, let focus):
            NewTaskSheet(date: day, category: category ?? .builtIn(.personal), focus: focus) { saved in
                show("Added “\(saved.title)” ✨")
            }
        case .edit(let task, let focus):
            NewTaskSheet(task: task, focus: focus)
        case .draft(let draft):
            NewTaskSheet(draft: draft) { saved in
                show("Added “\(saved.title)” ✨")
            }
        case .voice(let sample):
            VoiceTaskSheet(
                day: day,
                selectedCategory: filter,
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
        let id = task.persistentModelID
        let isFinishing = !task.isCompleted
        if isFinishing {
            settling.insert(id)
        } else {
            settling.remove(id)
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            TaskActions.toggle(task, in: context)
        }
        if isFinishing {
            // Let the tick and its hearts show, then move it down to the finished ones.
            let settle = TickPop.settleDelay
            Task {
                try? await Task.sleep(for: .seconds(settle))
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    _ = settling.remove(id)
                }
            }
        }
        if task.isCompleted, !tasks.isEmpty, tasks.allSatisfy(\.isCompleted) {
            celebrate()
        }
    }

    /// ☆ / ★: important to-dos move to the top of the list.
    private func toggleImportant(_ task: TaskItem) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            task.isImportant.toggle()
        }
        AccessibilityNotification.Announcement(task.isImportant ? "Marked important" : "No longer important").post()
    }

    /// Everything is done: "All done for today!" and the big confetti.
    private func celebrate() {
        celebration += 1
        AccessibilityNotification.Announcement("All done for \(day.isToday ? "today" : "the day")!").post()
        guard !reduceMotion else { return }
        showsConfetti = true
        let run = celebration
        Task {
            try? await Task.sleep(for: .seconds(ConfettiCelebration.duration + 0.2))
            if celebration == run {
                showsConfetti = false
            }
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

    /// Press-and-hold reordering. The shown to-dos take their new order; to-dos hidden by
    /// the category filter keep their places.
    private func move(from source: IndexSet, to destination: Int, in rows: [TaskItem]) {
        var reordered = rows
        reordered.move(fromOffsets: source, toOffset: destination)
        let shownOpen = reordered.filter { !$0.isCompleted }
        let shownIDs = Set(shownOpen.map(\.persistentModelID))
        var allOpen = tasks.filter { !$0.isCompleted }
        var next = shownOpen.makeIterator()
        for index in allOpen.indices where shownIDs.contains(allOpen[index].persistentModelID) {
            if let task = next.next() {
                allOpen[index] = task
            }
        }
        for (index, task) in allOpen.enumerated() {
            task.sortOrder = Double(index)
        }
        Haptics.tap()
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
    case compose(CategoryChoice?, TaskSheetFocus?)
    case edit(TaskItem, TaskSheetFocus?)
    /// A new to-do filled in by Voice Add, to check and finish.
    case draft(TaskDraft)
    case voice(sample: String?)
    case templates

    var id: String {
        switch self {
        case .compose(let category, let focus): "compose-\(category?.key ?? "")-\(focus?.rawValue ?? "")"
        case .edit(let task, let focus): "edit-\(task.id.uuidString)-\(focus?.rawValue ?? "")"
        case .draft: "draft"
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
        case "voice": self = .voice(sample: "Remind me to call the doctor tomorrow at 5 PM")
        case "templates", "template-edit", "template-move": self = .templates
        default: return nil
        }
    }
}
#endif
