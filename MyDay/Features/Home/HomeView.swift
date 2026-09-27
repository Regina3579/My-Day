import SwiftUI
import SwiftData

/// The first screen: the illustrated My Day scene with live, tappable controls
/// placed exactly over the painted cards.
struct HomeView: View {
    @Environment(Router.self) private var router
    @Environment(\.artSpace) private var space
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var tasks: [TaskItem]
    @Query private var entries: [JournalEntry]
    private let today: Date

    init(today: Date) {
        self.today = today
        let start = today.startOfDay
        let end = start.nextDay
        _tasks = Query(filter: #Predicate<TaskItem> { $0.day >= start && $0.day < end })
        _entries = Query(filter: #Predicate<JournalEntry> { $0.date >= start && $0.date < end })
    }

    var body: some View {
        Group {
            if space.needsScroll {
                ScrollView(.vertical, showsIndicators: false) { canvas }
            } else {
                canvas
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(hex: 0xF6C8D8))
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Canvas

    private var canvas: some View {
        ZStack(alignment: .topLeading) {
            Image("HomeArt")
                .resizable()
                .interpolation(.high)
                .frame(width: space.artWidth, height: space.artHeight)
                .position(x: space.originX + space.artWidth / 2, y: space.artHeight / 2)
                .accessibilityHidden(true)

            if !reduceMotion {
                HomeAmbience(space: space, isActive: isOnScreen)
            }

            headerControls
            cardControls
            quickAddControls
        }
        .frame(width: space.container.width, height: space.artHeight, alignment: .topLeading)
        .clipped()
    }

    private var isOnScreen: Bool {
        router.tab == .home && router.homePath.isEmpty && scenePhase == .active
    }

    // MARK: Header (☰, date, bell)

    @ViewBuilder
    private var headerControls: some View {
        let hit = max(44, space.len(84))

        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { router.isMenuOpen = true }
        } label: {
            VStack(spacing: space.len(10)) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(Palette.ink)
                        .frame(width: space.len(48), height: space.len(7.5))
                }
            }
            .shadow(color: Color.white.opacity(0.7), radius: 2)
            .frame(width: hit, height: hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle())
        .position(space.point(76, 147))
        .accessibilityLabel("Menu")

        Button {
            router.tab = .calendar
        } label: {
            DateBadge(date: today, unit: space.scale)
                .frame(width: hit, height: hit)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle())
        .position(space.point(693, 152))
        .accessibilityLabel("Calendar, today is \(today.formatted(date: .complete, time: .omitted))")

        Button {
            router.sheet = .reminders
        } label: {
            Image(systemName: "bell.fill")
                .font(.system(size: space.len(54), weight: .semibold))
                .foregroundStyle(Color(hex: 0x2B2838))
                .shadow(color: Color.white.opacity(0.7), radius: 2)
                .frame(width: hit, height: hit)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle())
        .position(space.point(789, 154))
        .accessibilityLabel("Reminders")
    }

    // MARK: The three painted cards

    @ViewBuilder
    private var cardControls: some View {
        let openTasks = tasks.filter { !$0.isDone }.count
        let priorities = tasks.filter(\.isPriority)
        let openPriorities = priorities.filter { !$0.isDone }.count

        ArtHotspot(frame: space.rect(28, 786, 446, 478), cornerRadius: space.len(46),
                   label: "Today's To-Dos, \(openTasks) left") {
            router.homePath.append(AppRoute.todos(today))
        }
        ArtHotspot(frame: space.rect(466, 794, 372, 490), cornerRadius: space.len(46),
                   label: "Today's Priority, \(openPriorities) left") {
            router.homePath.append(AppRoute.priority(today))
        }
        ArtHotspot(frame: space.rect(205, 1252, 478, 396), cornerRadius: space.len(36),
                   label: "My Journal, \(entries.count) pages today") {
            router.homePath.append(AppRoute.journal)
        }

        CardBadge(content: .progress(open: openTasks, total: tasks.count), tint: Palette.grape, unit: space.scale)
            .position(space.point(452, 804))
        CardBadge(content: .progress(open: openPriorities, total: priorities.count), tint: Palette.honey, unit: space.scale)
            .position(space.point(818, 810))
        CardBadge(content: entries.isEmpty ? CardBadge.Value.hidden : .count(entries.count), tint: Palette.hotPink, unit: space.scale)
            .position(space.point(646, 1266))
    }

    // MARK: Quick add chips and + button

    @ViewBuilder
    private var quickAddControls: some View {
        QuickChip(kind: .task, unit: space.scale) {
            router.sheet = .newTask(day: today, priority: false)
        }
        .position(space.point(760, 1314))

        QuickChip(kind: .priority, unit: space.scale) {
            router.sheet = .newTask(day: today, priority: true)
        }
        .position(space.point(760, 1377))

        QuickChip(kind: .journal, unit: space.scale, showsTail: true) {
            router.sheet = .newJournal(.now)
        }
        .position(space.point(760, 1443))

        FloatingAddButton(unit: space.scale) {
            router.sheet = .quickCapture
        }
        .position(space.point(766, 1555))
    }
}
