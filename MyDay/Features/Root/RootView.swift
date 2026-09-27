import SwiftUI
import SwiftData
import Combine

/// Hosts the four tabs, the floating tab bar, the Quick Add menu, the side menu
/// and the app-wide sheets.
struct RootView: View {
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(Prefs.carryOver) private var carryOver = true

    var body: some View {
        GeometryReader { proxy in
            let barBottom = TabBarLayout.bottomPadding(safeAreaBottom: proxy.safeAreaInsets.bottom)
            let reserved = max(0, TabBarLayout.height + barBottom - proxy.safeAreaInsets.bottom) + 8

            ZStack(alignment: .bottom) {
                tabs(reserved: reserved)

                BottomTabBar(selection: tabBinding) { tab in
                    router.popToRoot(tab)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, barBottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)

                if showsQuickAdd {
                    quickAddLayer(aboveBottom: barBottom + TabBarLayout.height + 40)
                        .transition(.opacity)
                }

                if router.isMenuOpen {
                    Color.black.opacity(0.28)
                        .ignoresSafeArea()
                        .onTapGesture { closeMenu() }
                        .transition(.opacity)
                        .zIndex(1)
                        .accessibilityLabel("Close menu")
                        .accessibilityAddTraits(.isButton)

                    SideMenuView(today: appState.today, close: { closeMenu() })
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .transition(.move(edge: .leading))
                        .zIndex(2)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showsQuickAdd)
        }
        .sheet(item: sheetBinding) { sheet in
            sheetContent(sheet)
        }
        .onChange(of: router.tab) { _, _ in
            router.isQuickAddOpen = false
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: refreshDay()
            case .background: appState.isJournalUnlocked = false
            default: break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            refreshDay()
        }
        .task {
            WelcomeContent.seedIfNeeded(in: modelContext)
            refreshDay()
            #if DEBUG
            DebugLaunchRoute.apply(to: router, today: appState.today)
            #endif
        }
    }

    // MARK: Tabs

    private func tabs(reserved: CGFloat) -> some View {
        ZStack {
            NavigationStack(path: homePathBinding) {
                HomeView(today: appState.today)
                    .appDestinations()
            }
            .tabLayer(visible: router.tab == .home)

            NavigationStack(path: calendarPathBinding) {
                CalendarView()
                    .appDestinations()
            }
            .tabLayer(visible: router.tab == .calendar)

            NavigationStack {
                InsightsView()
            }
            .tabLayer(visible: router.tab == .insights)

            NavigationStack {
                SettingsView()
                    .appDestinations()
            }
            .tabLayer(visible: router.tab == .settings)
        }
        .environment(\.tabBarClearance, reserved)
    }

    // MARK: Quick Add

    private var showsQuickAdd: Bool {
        router.tab == .home && router.homePath.isEmpty
    }

    private func quickAddLayer(aboveBottom: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if router.isQuickAddOpen {
                // Tapping anywhere outside the menu closes it.
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { setQuickAdd(open: false) }
                    .transition(.opacity)
                    .accessibilityLabel("Close quick add")
                    .accessibilityAddTraits(.isButton)
            }

            VStack(alignment: .trailing, spacing: 16) {
                if router.isQuickAddOpen {
                    QuickAddMenu(
                        onTask: { quickAdd(.newTask(appState.today)) },
                        onPriority: { quickAdd(.newPriority(appState.today)) },
                        onJournal: { quickAdd(.newJournal(.now)) }
                    )
                    .transition(.scale(scale: 0.4, anchor: .bottomTrailing).combined(with: .opacity))
                }
                QuickAddButton(isOpen: router.isQuickAddOpen) {
                    setQuickAdd(open: !router.isQuickAddOpen)
                }
            }
            .padding(.trailing, 12)
            .padding(.bottom, aboveBottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .ignoresSafeArea(edges: .bottom)
    }

    private func setQuickAdd(open: Bool) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            router.isQuickAddOpen = open
        }
    }

    private func quickAdd(_ sheet: AppSheet) {
        setQuickAdd(open: false)
        router.sheet = sheet
    }

    @ViewBuilder
    private func sheetContent(_ sheet: AppSheet) -> some View {
        switch sheet {
        case .newTask(let date):
            NewTaskSheet(date: date)
        case .newPriority(let date):
            NewPrioritySheet(date: date)
        case .newJournal(let date):
            NewJournalEntrySheet(date: date)
        case .reminders:
            NavigationStack {
                RemindersView(showsDoneButton: true)
            }
        }
    }

    // MARK: Bindings

    private var tabBinding: Binding<AppTab> {
        Binding(get: { router.tab }, set: { router.tab = $0 })
    }

    private var homePathBinding: Binding<NavigationPath> {
        Binding(get: { router.homePath }, set: { router.homePath = $0 })
    }

    private var calendarPathBinding: Binding<NavigationPath> {
        Binding(get: { router.calendarPath }, set: { router.calendarPath = $0 })
    }

    private var sheetBinding: Binding<AppSheet?> {
        Binding(get: { router.sheet }, set: { router.sheet = $0 })
    }

    // MARK: Actions

    private func closeMenu() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            router.isMenuOpen = false
        }
    }

    private func refreshDay() {
        let today = Date().startOfDay
        if appState.today != today {
            appState.today = today
        }
        if carryOver {
            DayRollover.carryOver(into: today, context: modelContext)
        }
    }
}

private extension View {
    /// Keeps every tab alive (so each keeps its navigation state) and shows one at a time.
    /// Screens keep clear of the tab bar with `tabBarSafeArea()`.
    func tabLayer(visible: Bool) -> some View {
        self
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(visible)
            .accessibilityHidden(!visible)
    }
}

#Preview {
    RootView()
        .environment(Router())
        .environment(AppState())
        .modelContainer(for: [TaskItem.self, Priority.self, JournalEntry.self, JournalPhoto.self, TaskTemplate.self],
                        inMemory: true)
}
