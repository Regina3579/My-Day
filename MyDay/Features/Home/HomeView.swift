import SwiftUI
import SwiftData

/// The first screen: the illustrated scene with the native header, daily
/// message and the three feature cards.
struct HomeView: View {
    @Environment(Router.self) private var router
    @Query private var tasks: [TaskItem]
    @Query private var priorities: [Priority]
    @Query private var entries: [JournalEntry]
    private let today: Date

    init(today: Date) {
        self.today = today
        let start = today.startOfDay
        let end = start.nextDay
        _tasks = Query(filter: #Predicate<TaskItem> { $0.date >= start && $0.date < end })
        _priorities = Query(filter: #Predicate<Priority> { $0.date >= start && $0.date < end })
        _entries = Query(filter: #Predicate<JournalEntry> { $0.date >= start && $0.date < end })
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    hero(width: width, topInset: proxy.safeAreaInsets.top)
                    cards(width: width)
                }
                .padding(.bottom, 6)
            }
            .scrollBounceBehavior(.basedOnSize)
            .ignoresSafeArea(edges: .top)
        }
        .background(HomeBackdrop())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Scene, header and daily message

    private func hero(width: CGFloat, topInset: CGFloat) -> some View {
        let height = width * HomeLayout.sceneAspect
        return ZStack(alignment: .topLeading) {
            Image("HomeScene")
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
                .mask(
                    LinearGradient(stops: [.init(color: .black, location: 0.9), .init(color: .clear, location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HomeHeader(
                    date: today,
                    onMenu: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { router.isMenuOpen = true }
                    },
                    onCalendar: { router.tab = .calendar },
                    onReminders: { router.sheet = .reminders }
                )
                DailyQuoteView(date: today)
                    .padding(.leading, width * 0.06)
            }
            .padding(.top, topInset + 4)
        }
        .frame(width: width, height: height)
    }

    // MARK: Feature cards

    private func cards(width w: CGFloat) -> some View {
        let openTasks = tasks.filter { !$0.isCompleted }.count
        let openPriorities = priorities.filter { !$0.isCompleted }.count

        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: w * 0.012) {
                HomeFeatureCard(kind: .todos, badge: .progress(open: openTasks, total: tasks.count)) {
                    router.homePath.append(AppRoute.todos(today))
                }
                .frame(width: w * 0.525, height: w * 0.58)

                HomeFeatureCard(kind: .priority, badge: .progress(open: openPriorities, total: priorities.count)) {
                    router.homePath.append(AppRoute.priority(today))
                }
                .frame(width: w * 0.44, height: w * 0.58)
            }
            .frame(width: w)

            HStack(alignment: .bottom, spacing: 0) {
                BookStackArt()
                    .frame(width: w * 0.22, height: w * 0.3)
                HomeFeatureCard(kind: .journal, badge: entries.isEmpty ? CardBadge.Value.hidden : .count(entries.count)) {
                    router.homePath.append(AppRoute.journal)
                }
                .frame(width: w * 0.585, height: w * 0.47)
                Spacer(minLength: 0)
            }
            .frame(width: w)
            .padding(.top, -w * 0.045)
        }
        .padding(.top, -w * HomeLayout.cardOverlap)
    }
}

enum HomeLayout {
    /// Height ÷ width of the `HomeScene` illustration (853 × 830 px).
    static let sceneAspect: CGFloat = 830.0 / 853.0
    /// How far the cards rise over the bottom of the illustration, as a fraction of the width.
    static let cardOverlap: CGFloat = 38.0 / 853.0
}

/// Pastel garden glow behind the cards.
struct HomeBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0xF6DDD9), Color(hex: 0xFDE4EE), Color(hex: 0xF9CFE1)],
                               startPoint: .top, endPoint: .bottom)
                glow(Color(hex: 0xE3D2FF), x: w * 0.28, y: h * 0.58, size: w * 0.7)
                glow(Color(hex: 0xFFEDB3), x: w * 0.76, y: h * 0.58, size: w * 0.6)
                glow(Color(hex: 0xFFC2DB), x: w * 0.5, y: h * 0.86, size: w * 0.8)
                ForEach(Self.petals.indices, id: \.self) { index in
                    let petal = Self.petals[index]
                    Ellipse()
                        .fill(Color(hex: 0xFFB3D1).opacity(0.7))
                        .frame(width: 10, height: 6)
                        .rotationEffect(.degrees(petal.angle))
                        .position(x: w * petal.x, y: h * petal.y)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private static let petals: [(x: CGFloat, y: CGFloat, angle: Double)] = [
        (0.04, 0.62, 20), (0.96, 0.66, -30), (0.03, 0.8, 60), (0.97, 0.84, 10), (0.9, 0.95, -50), (0.1, 0.96, 35)
    ]

    private func glow(_ color: Color, x: CGFloat, y: CGFloat, size: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(0.75))
            .frame(width: size, height: size)
            .blur(radius: size * 0.2)
            .position(x: x, y: y)
    }
}
