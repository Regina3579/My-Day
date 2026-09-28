import SwiftData
import SwiftUI
import UIKit

/// "Today's Priority": the illustrated scene fills the top of the screen and a soft pink panel
/// holds "Add today's priority…" and the day's priorities (a little star until there is one).
/// The page is full screen: the status bar and the tab bar hide while it is open.
struct TodaysPriorityView: View {
    @Environment(\.modelContext) private var context
    @Environment(Router.self) private var router
    @Environment(\.hostTab) private var hostTab
    @Query private var priorities: [Priority]
    @Query private var tasks: [TaskItem]
    @State private var draft = ""
    @State private var editing: Priority?
    @State private var heroIsVisible = true
    /// Height of the scene and the add field, so the empty card can fill the rest of the screen.
    @State private var headerHeight: CGFloat = 0
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

    private var title: String { day.isToday ? "Today's Priority" : "Priorities" }

    private var doneCount: Int { priorities.filter(\.isCompleted).count }

    /// Open to-dos that are not already priorities, offered in the ⋮ menu.
    private var suggestions: [TaskItem] {
        let chosen = Set(priorities.map { $0.title.lowercased() })
        return tasks.filter { !chosen.contains($0.title.lowercased()) }
    }

    var body: some View {
        GeometryReader { proxy in
            page(width: proxy.size.width, safeTop: proxy.safeAreaInsets.top,
                 visibleHeight: proxy.size.height + proxy.safeAreaInsets.top)
        }
        .background(PriorityPanel.base.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                principalTitle
            }
            ToolbarItem(placement: .topBarTrailing) {
                moreMenu
            }
        }
        .sheet(item: $editing) { priority in
            NewPrioritySheet(priority: priority)
        }
        // Full screen, as in the design: no clock or battery over the picture (only while
        // this page's tab is showing).
        .statusBarHidden(router.tab == hostTab)
        .onAppear { router.setFullScreen(true, in: hostTab) }
        .onDisappear { router.setFullScreen(false, in: hostTab) }
        #if DEBUG
        .task { await tickForScreenshot() }
        #endif
    }

    #if DEBUG
    /// `priority-hearts`: ticks the first priority about when the screenshot is taken
    /// (10 seconds after the app is ready), so its hearts show.
    private func tickForScreenshot() async {
        guard DebugLaunchRoute.takePriorityTick() else { return }
        try? await Task.sleep(for: .seconds(9.4))
        if let first = priorities.first(where: { !$0.isCompleted }) {
            toggle(first)
        }
    }
    #endif

    /// A List (not a ScrollView), so every priority keeps swipe-left Delete and
    /// press-and-hold reordering. The scene runs up under the status bar.
    private func page(width: CGFloat, safeTop: CGFloat, visibleHeight: CGFloat) -> some View {
        List {
            header(width: width, safeTop: safeTop)
                .onGeometryChange(for: CGFloat.self) { geometry in
                    geometry.size.height
                } action: { height in
                    headerHeight = height
                }
                .plainListRow()

            if priorities.isEmpty {
                // Fills the screen below the add field (the list keeps clear of the home indicator).
                PriorityEmptyCard(isToday: day.isToday,
                                  minHeight: max(300, visibleHeight - headerHeight - 30))
                    .plainListRow(EdgeInsets(top: 12, leading: 16, bottom: 18, trailing: 16))
            } else {
                listHeading
                    .plainListRow(EdgeInsets(top: 14, leading: 20, bottom: 4, trailing: 20))
                priorityRows
                if priorities.count > 3 {
                    Label("Tip: keep it to three — focus is a superpower ✨", systemImage: "lightbulb.fill")
                        .font(.rounded(.footnote, weight: .semibold))
                        .foregroundStyle(Palette.cocoa)
                        .cuteCard(tint: Palette.honey, padding: 14)
                        .plainListRow(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                closing
                    .plainListRow(EdgeInsets(top: 16, leading: 24, bottom: 24, trailing: 24))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: Header

    /// The scene, then the add field on the rounded panel that overlaps it.
    private func header(width: CGFloat, safeTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            hero(width: width, safeTop: safeTop)
            VStack(spacing: 12) {
                PriorityAddField(text: $draft,
                                 placeholder: day.isToday ? "Add today's priority…" : "Add a priority…",
                                 focus: $draftFocused,
                                 onAdd: addDraft)
                if !day.isToday {
                    dateChip
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 2)
            .frame(maxWidth: .infinity)
            .background(alignment: .top) {
                PriorityPanel()
            }
            .padding(.top, -PriorityScene.overlap(width: width))
        }
    }

    /// The scene; once it scrolls away, the title appears in the navigation bar.
    /// (`safeTop` includes the navigation bar; the scene only keeps clear of the status bar.)
    private func hero(width: CGFloat, safeTop: CGFloat) -> some View {
        PriorityHero(width: width, statusBar: statusBar(safeTop: safeTop),
                     label: day.isToday ? "Today's Priority. Focus on what matters most."
                                        : "Priorities for \(day.formatted(date: .complete, time: .omitted))")
            .onGeometryChange(for: Bool.self) { geometry in
                // Visible while its title still shows below the navigation bar.
                geometry.frame(in: .global).maxY > safeTop + 60
            } action: { isVisible in
                heroIsVisible = isVisible
            }
    }

    private func statusBar(safeTop: CGFloat) -> CGFloat {
        Self.statusBarHeight(fallback: max(0, safeTop - 44))
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

    /// Another day (opened from the calendar): which day these priorities are for.
    private var dateChip: some View {
        Label(day.formatted(.dateTime.weekday(.wide).day().month(.wide)), systemImage: "calendar")
            .font(.rounded(.subheadline, weight: .bold))
            .foregroundStyle(PriorityPanel.title)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.white.opacity(0.8)))
    }

    private var principalTitle: some View {
        Text(title)
            .font(.rounded(.headline, weight: .bold))
            .foregroundStyle(Palette.ink)
            .opacity(heroIsVisible ? 0 : 1)
            .animation(.easeInOut(duration: 0.2), value: heroIsVisible)
            .accessibilityHidden(heroIsVisible)
    }

    /// ⋮ — pick a priority from the day's open to-dos, or clear the finished ones.
    private var moreMenu: some View {
        Menu {
            Section(day.isToday ? "Pick from today's to-dos" : "Pick from this day's to-dos") {
                if suggestions.isEmpty {
                    Text("No open to-dos")
                } else {
                    ForEach(suggestions.prefix(8)) { task in
                        Button(task.title, systemImage: "star") { add(task.title) }
                    }
                }
            }
            Section {
                Button("Remove finished priorities", systemImage: "checkmark.circle.badge.xmark",
                       role: .destructive, action: removeFinished)
                    .disabled(doneCount == 0)
            }
        } label: {
            Image(uiImage: PriorityMoreSymbol.image)
                .foregroundStyle(Palette.hotPink)
                .accessibilityLabel("More")
        }
    }

    // MARK: Priorities

    private var listHeading: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundStyle(Palette.honey.gradient)
                .accessibilityHidden(true)
            Text(day.isToday ? "Today's focus" : "Focus for the day")
                .font(.rounded(.headline, weight: .heavy))
                .foregroundStyle(PriorityPanel.title)
            Spacer(minLength: 8)
            Text("\(doneCount) of \(priorities.count) done")
                .font(.rounded(.subheadline, weight: .bold))
                .foregroundStyle(PriorityPanel.title)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.85)))
                .contentTransition(.numericText())
        }
    }

    private var priorityRows: some View {
        ForEach(Array(priorities.enumerated()), id: \.element.persistentModelID) { index, priority in
            PriorityCard(rank: index + 1, priority: priority,
                         onToggle: { toggle(priority) },
                         onOpen: { editing = priority })
                .plainListRow(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        delete(priority)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
        .onMove { move(from: $0, to: $1) }
    }

    /// The day's gentle focus quote, with the heart divider.
    private var closing: some View {
        VStack(spacing: 14) {
            HeartDivider()
            Text(FocusQuotes.quote(for: day))
                .font(.rounded(.callout, weight: .semibold))
                .italic()
                .foregroundStyle(PriorityPanel.message)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Actions

    /// The ＋ button and Return: adds what is typed, or opens the keyboard when nothing is.
    private func addDraft() {
        if draft.trimmed.isEmpty {
            draftFocused = true
        } else {
            add(draft)
        }
    }

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

    private func removeFinished() {
        withAnimation(.snappy) {
            for priority in priorities where priority.isCompleted {
                context.delete(priority)
            }
        }
        Haptics.success()
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = priorities
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, priority) in reordered.enumerated() {
            priority.order = index
        }
    }
}

// MARK: - Scene

/// The picture at the top of Today's Priority, with its "Today's Priority — Focus on what
/// matters most" title. Its first 150 rows are soft curtains that sit behind the status bar.
enum PriorityScene {
    static let imageSize = CGSize(width: 941, height: 792)
    /// The row (px) where the design's back and ⋮ buttons sit: it lines up with the
    /// navigation bar's buttons.
    static let buttonsRow: CGFloat = 216
    /// The panel covers the picture's last 44 rows.
    static let overlapRows: CGFloat = 44

    /// Points per image pixel: the picture spans the screen's width.
    static func scale(width: CGFloat) -> CGFloat {
        width / imageSize.width
    }

    /// The first image row shown.
    static func topRow(width: CGFloat, statusBar: CGFloat) -> CGFloat {
        max(0, buttonsRow - (statusBar + 22) / scale(width: width))
    }

    static func height(width: CGFloat, statusBar: CGFloat) -> CGFloat {
        (imageSize.height - topRow(width: width, statusBar: statusBar)) * scale(width: width)
    }

    static func overlap(width: CGFloat) -> CGFloat {
        overlapRows * scale(width: width)
    }
}

struct PriorityHero: View {
    let width: CGFloat
    /// Height of the status bar (not counting the navigation bar).
    let statusBar: CGFloat
    let label: String

    var body: some View {
        let scale = PriorityScene.scale(width: width)
        let top = PriorityScene.topRow(width: width, statusBar: statusBar)
        Image("PriorityScene")
            .resizable()
            .frame(width: width, height: PriorityScene.imageSize.height * scale)
            .offset(y: -top * scale)
            .frame(width: width, height: PriorityScene.height(width: width, statusBar: statusBar),
                   alignment: .top)
            .clipped()
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Panel

/// The soft pink panel under the scene, with rounded top corners. It fades into `base`,
/// the page colour, so the rest of the page continues it.
struct PriorityPanel: View {
    static let base = Color(hex: 0xFDEEF3)
    static let title = Color(hex: 0xB2003A)
    static let message = Color(hex: 0x7B567C)

    var body: some View {
        UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0xFFF6F9), Self.base], startPoint: .top, endPoint: .bottom))
            // Lifted upwards, so the shadow shows along the top edge only.
            .shadow(color: Palette.hotPink.opacity(0.14), radius: 8, x: 0, y: -6)
    }
}

/// "＋ Add today's priority…": a pale pill with a glowing pink edge and a round pink ＋.
struct PriorityAddField: View {
    @Binding var text: String
    let placeholder: String
    var focus: FocusState<Bool>.Binding
    let onAdd: () -> Void

    private static let edge = LinearGradient(colors: [Color(hex: 0xF76BC8), Color(hex: 0xE58BF0)],
                                             startPoint: .leading, endPoint: .trailing)

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onAdd) {
                PlusBubble(diameter: 44)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel(text.trimmed.isEmpty ? "Type a priority" : "Add priority")

            TextField(placeholder, text: $text,
                      prompt: Text(placeholder).foregroundStyle(Color(hex: 0x916D90)))
                .font(.rounded(.title3, weight: .medium))
                .foregroundStyle(Palette.ink)
                .submitLabel(.done)
                .focused(focus)
                .onSubmit(onAdd)
        }
        .padding(.leading, 7)
        .padding(.trailing, 16)
        .frame(minHeight: 58)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(hex: 0xFFF8FB)))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Self.edge, lineWidth: 2)
        )
        .shadow(color: Color(hex: 0xF06BE0).opacity(0.3), radius: 8, x: 0, y: 3)
    }
}

/// The glossy pink ＋ circle.
struct PlusBubble: View {
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color(hex: 0xFF6FA8), Color(hex: 0xF5106C)],
                                     startPoint: .top, endPoint: .bottom))
            Circle()
                .strokeBorder(Color.white.opacity(0.85), lineWidth: 2)
            Image(systemName: "plus")
                .font(.system(size: diameter * 0.45, weight: .bold))
                .foregroundStyle(Color.white)
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: Palette.hotPink.opacity(0.4), radius: 6, x: 0, y: 3)
    }
}

/// Shown until the day has a priority: the little star hugging a heart.
struct PriorityEmptyCard: View {
    let isToday: Bool
    let minHeight: CGFloat

    /// Short screens (iPhone SE) get a smaller star, so the card still fits.
    private var isCompact: Bool { minHeight < 400 }

    var body: some View {
        VStack(spacing: 10) {
            Image("PriorityEmptyStar")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: isCompact ? 190 : 250)
                .padding(.bottom, 10)
                .accessibilityHidden(true)
            Text(isToday ? "Set your today's priority" : "Set a priority for this day")
                .font(.rounded(.title2, weight: .heavy))
                .foregroundStyle(PriorityPanel.title)
            Text(isToday ? "Add one important task to focus on today and make it happen!"
                         : "Add one important task to focus on and make it happen!")
                .font(.rounded(.body, weight: .medium))
                .foregroundStyle(PriorityPanel.message)
            HeartDivider()
                .padding(.top, 18)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.vertical, isCompact ? 18 : 28)
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white.opacity(0.35)))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color(hex: 0xEBBCD2), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
        )
        .accessibilityElement(children: .combine)
    }
}

/// A short line, a pink heart and a short line.
struct HeartDivider: View {
    private static let line = Color(hex: 0xF77FCF)

    var body: some View {
        HStack(spacing: 10) {
            stroke(fadingTo: .leading)
            ShinyHeart(size: 24)
            stroke(fadingTo: .trailing)
        }
        .accessibilityHidden(true)
    }

    private func stroke(fadingTo edge: UnitPoint) -> some View {
        Capsule()
            .fill(LinearGradient(colors: [Self.line.opacity(0), Self.line],
                                 startPoint: edge, endPoint: edge == .leading ? .trailing : .leading))
            .frame(width: 52, height: 2.5)
    }
}

/// ⋮ for the navigation bar. Toolbar menus draw their label as a plain image (a rotated
/// SwiftUI view would lose its rotation), so the dots are drawn upright here.
@MainActor
enum PriorityMoreSymbol {
    static let image: UIImage = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 17, weight: .heavy)
        if let vertical = UIImage(systemName: "ellipsis.vertical", withConfiguration: configuration) {
            return vertical
        }
        guard let dots = UIImage(systemName: "ellipsis", withConfiguration: configuration) else { return UIImage() }
        let size = CGSize(width: dots.size.height, height: dots.size.width)
        let upright = UIGraphicsImageRenderer(size: size).image { renderer in
            renderer.cgContext.translateBy(x: size.width / 2, y: size.height / 2)
            renderer.cgContext.rotate(by: .pi / 2)
            dots.draw(in: CGRect(x: -dots.size.width / 2, y: -dots.size.height / 2,
                                 width: dots.size.width, height: dots.size.height))
        }
        return upright.withRenderingMode(.alwaysTemplate)
    }()
}

/// A numbered golden card for one priority. Ticking it pops two little pink hearts.
struct PriorityCard: View {
    let rank: Int
    let priority: Priority
    let onToggle: () -> Void
    let onOpen: () -> Void

    /// Goes up each time the priority is ticked; every change pops two little hearts.
    @State private var tickPops = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .overlay(alignment: .trailing) {
            // Over the tick (the card's padding is 16).
            if tickPops > 0 {
                TickPop()
                    .id(tickPops)
                    .frame(width: 32, height: 32)
                    .padding(.trailing, 16)
            }
        }
        .onChange(of: priority.isCompleted) { wasDone, isDone in
            if isDone && !wasDone && !reduceMotion {
                tickPops += 1
            }
        }
    }
}
