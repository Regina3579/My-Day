import SwiftUI
import SwiftData

/// The first screen: the illustrated scene with the native header, daily
/// message and the three feature cards.
struct HomeView: View {
    @Environment(Router.self) private var router
    @Environment(\.tabBarClearance) private var tabBarClearance
    @AppStorage(Prefs.didShowQuoteTip) private var didShowQuoteTip = false
    /// The first-time tip pointing at the daily quote.
    @State private var showsQuoteTip = false
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
        _entries = Query(filter: #Predicate<JournalEntry> { $0.date >= start && $0.date < end && $0.deletedAt == nil })
    }

    var body: some View {
        GeometryReader { proxy in
            let layout = HomeLayout(
                width: proxy.size.width,
                safeTop: proxy.safeAreaInsets.top,
                // From the top of the screen down to just above the floating tab bar.
                availableHeight: proxy.size.height + proxy.safeAreaInsets.top - tabBarClearance
            )
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    hero(layout, topInset: proxy.safeAreaInsets.top)
                    cards(layout)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .tabBarSafeArea()
            .ignoresSafeArea(edges: .top)
        }
        .background(HomeBackdrop())
        .overlayPreferenceValue(DailyQuoteAnchorKey.self) { anchor in
            if showsQuoteTip, let anchor {
                GeometryReader { proxy in
                    DailyQuoteTip(quoteFrame: proxy[anchor], size: proxy.size, onDismiss: closeQuoteTip)
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await showQuoteTipIfNew() }
    }

    // MARK: First-time tip

    /// New here: after a moment, point at the daily quote once.
    private func showQuoteTipIfNew() async {
        guard !didShowQuoteTip else { return }
        try? await Task.sleep(for: .seconds(1))
        guard !Task.isCancelled, !didShowQuoteTip, router.homePath.isEmpty, router.tab == .home,
              !router.isMenuOpen, !router.isQuickAddOpen, router.sheet == nil
        else { return }
        didShowQuoteTip = true
        withAnimation(.easeOut(duration: 0.3)) { showsQuoteTip = true }
    }

    private func closeQuoteTip() {
        withAnimation(.easeOut(duration: 0.25)) { showsQuoteTip = false }
        Haptics.tap()
    }

    // MARK: Scene, header and daily message

    private func hero(_ layout: HomeLayout, topInset: CGFloat) -> some View {
        let w = layout.width
        return ZStack(alignment: .topLeading) {
            Image("HomeScene")
                .resizable()
                .frame(width: w, height: w * HomeLayout.sceneImageHeight)
                .mask(
                    LinearGradient(stops: [.init(color: .black, location: 0.94), .init(color: .clear, location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .offset(y: layout.sceneShift - w * HomeLayout.sceneExtension)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HomeHeader(
                    date: today,
                    onMenu: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { router.isMenuOpen = true }
                    },
                    onCalendar: { router.tab = .calendar },
                    onReminders: { router.sheet = .reminders }
                )
                DailyQuoteView(date: today, maxWidth: w * 0.33)
                    .anchorPreference(key: DailyQuoteAnchorKey.self, value: .bounds) { $0 }
                    .padding(.leading, w * 0.09)
            }
            .padding(.top, topInset + 4)
        }
        .frame(width: w, height: layout.heroHeight, alignment: .top)
        .clipped()
    }

    // MARK: Feature cards

    private func cards(_ layout: HomeLayout) -> some View {
        let w = layout.width
        let k = layout.squeeze
        let openTasks = tasks.filter { !$0.isCompleted }.count
        let openPriorities = priorities.filter { !$0.isCompleted }.count

        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                HomeFeatureCard(kind: .todos, badge: .progress(open: openTasks, total: tasks.count)) {
                    router.homePath.append(AppRoute.todos(today))
                }
                .frame(width: w * 0.551, height: w * 0.762 * k)

                HomeFeatureCard(kind: .priority, badge: .progress(open: openPriorities, total: priorities.count)) {
                    router.homePath.append(AppRoute.priority(today))
                }
                .frame(width: w * 0.443, height: w * 0.744 * k)
                .padding(.top, w * 0.023 * k)
                .padding(.leading, -w * 0.018)
            }
            .padding(.leading, w * 0.012)
            .frame(width: w, alignment: .leading)

            ZStack(alignment: .topLeading) {
                BookStackArt()
                    .frame(width: w * 0.225, height: w * 0.387 * k)
                    .padding(.top, w * 0.076 * k)
                HomeFeatureCard(kind: .journal,
                                badge: entries.isEmpty ? CardBadge.Value.hidden : .count(entries.count)) {
                    router.homePath.append(AppRoute.journal)
                }
                .frame(width: w * 0.686, height: w * 0.668 * k)
                .padding(.leading, w * 0.164)
            }
            .frame(width: w, height: w * 0.668 * k, alignment: .topLeading)
            .padding(.top, -w * 0.041 * k)
        }
        .padding(.top, -w * (HomeLayout.sceneBody - HomeLayout.cardsTop))
        .padding(.bottom, w * HomeLayout.bottomMargin)
    }
}

/// Proportions taken from the 853 px-wide design, as fractions of the screen width.
struct HomeLayout {
    /// Soft strip above the scenery, used when the status bar is taller than in the design.
    static let sceneExtension: CGFloat = 80.0 / 853.0
    /// The scenery itself (the design's top 490 px).
    static let sceneBody: CGFloat = 490.0 / 853.0
    static let sceneImageHeight: CGFloat = 570.0 / 853.0
    /// Height of the design's status bar.
    static let designStatusBar: CGFloat = 60.0 / 853.0
    /// Where the cards begin.
    static let cardsTop: CGFloat = 470.0 / 853.0
    /// Card rows below `cardsTop`: notebook and star card, then the journal (which overlaps them slightly).
    static let cardRows: CGFloat = (650.0 - 35.0 + 570.0) / 853.0
    /// Brick strip between the journal and the tab bar, as in the design
    /// (about 44 px there; the tab bar clearance already adds 8 points).
    static let bottomMargin: CGFloat = 27.0 / 853.0
    /// The cards may shrink to this much of their height before the screen scrolls instead.
    static let minimumSqueeze: CGFloat = 0.82

    let width: CGFloat
    /// How far the scenery moves down so the header keeps its place on it.
    let sceneShift: CGFloat
    /// Vertical scale for the cards, so the whole design fits above the tab bar.
    let squeeze: CGFloat

    init(width: CGFloat, safeTop: CGFloat, availableHeight: CGFloat) {
        self.width = width
        sceneShift = min(max(0, safeTop - width * Self.designStatusBar), width * Self.sceneExtension)
        let fixed = sceneShift + width * (Self.cardsTop + Self.bottomMargin)
        let fit = (availableHeight - fixed) / (width * Self.cardRows)
        squeeze = fit.isFinite ? min(1, max(Self.minimumSqueeze, fit)) : 1
    }

    var heroHeight: CGFloat { sceneShift + width * Self.sceneBody }
}

/// The warm brick courtyard with petals and soft roses behind the cards.
struct HomeBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0xF1D2C9), Color(hex: 0xE9BFB2), Color(hex: 0xF2CACA)],
                               startPoint: .top, endPoint: .bottom)
                BrickPattern()
                    .opacity(0.5)
                RoseBokeh(size: w * 0.34).position(x: w * 0.02, y: h * 0.93)
                RoseBokeh(size: w * 0.3).position(x: w * 0.98, y: h * 0.9)
                RoseBokeh(size: w * 0.16).position(x: w * 0.0, y: h * 0.62)
                ForEach(Self.blossoms.indices, id: \.self) { index in
                    let blossom = Self.blossoms[index]
                    Daisy(petal: Color(hex: 0xFFB8D2), petals: 5)
                        .frame(width: blossom.size, height: blossom.size)
                        .rotationEffect(.degrees(blossom.angle))
                        .position(x: w * blossom.x, y: h * blossom.y)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private static let blossoms: [(x: CGFloat, y: CGFloat, size: CGFloat, angle: Double)] = [
        (0.93, 0.6, 16, 10), (0.9, 0.68, 12, -20), (0.96, 0.74, 14, 35),
        (0.06, 0.84, 15, 5), (0.5, 0.97, 13, -15), (0.3, 0.95, 11, 25), (0.72, 0.96, 12, 40)
    ]
}

/// Rows of soft, rounded bricks.
struct BrickPattern: View {
    var body: some View {
        Canvas { context, size in
            let rowHeight: CGFloat = 16
            let brickWidth: CGFloat = 34
            let gap: CGFloat = 2.5
            let colors = [Color(hex: 0xD49A89), Color(hex: 0xE0AE9E), Color(hex: 0xCB9281)]
            var row = 0
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = row.isMultiple(of: 2) ? 0 : -brickWidth / 2
                var column = 0
                while x < size.width {
                    let rect = CGRect(x: x + gap / 2, y: y + gap / 2, width: brickWidth - gap, height: rowHeight - gap)
                    let color = colors[(row * 7 + column * 3) % colors.count]
                    context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(color))
                    x += brickWidth
                    column += 1
                }
                y += rowHeight
                row += 1
            }
        }
        .allowsHitTesting(false)
    }
}

/// Out-of-focus pink roses, like the blurred flowers in the design's corners.
struct RoseBokeh: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xF7A8C6)).frame(width: size, height: size)
            Circle().fill(Color(hex: 0xFFC7DA)).frame(width: size * 0.6, height: size * 0.6)
                .offset(x: size * 0.25, y: -size * 0.2)
            Circle().fill(Color(hex: 0xEE86AE)).frame(width: size * 0.45, height: size * 0.45)
                .offset(x: -size * 0.15, y: size * 0.15)
            Circle().fill(Color(hex: 0x8CC47E).opacity(0.7)).frame(width: size * 0.3, height: size * 0.3)
                .offset(x: size * 0.35, y: size * 0.3)
        }
        .blur(radius: size * 0.08)
        .opacity(0.9)
        .allowsHitTesting(false)
    }
}
