import SwiftUI
import SwiftData
import Combine

/// Hosts the four tabs, the floating tab bar, the side menu and app-wide sheets.
struct RootView: View {
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(Prefs.carryOver) private var carryOver = true

    var body: some View {
        GeometryReader { proxy in
            let screen = CGSize(
                width: proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing,
                height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
            )
            let space = ArtSpace(container: screen)
            let bar = TabBarMetrics(space: space)
            let reserved = max(0, bar.height + bar.bottomPadding - proxy.safeAreaInsets.bottom) + 8

            ZStack(alignment: .bottom) {
                tabs(reserved: reserved)

                MyDayTabBar(selection: tabBinding, metrics: bar) { tab in
                    router.popToRoot(tab)
                }
                .padding(.bottom, bar.bottomPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)

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
            .environment(\.artSpace, space)
        }
        .sheet(item: sheetBinding) { sheet in
            sheetContent(sheet)
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
        }
    }

    // MARK: Tabs

    private func tabs(reserved: CGFloat) -> some View {
        ZStack {
            NavigationStack(path: homePathBinding) {
                HomeView(today: appState.today)
                    .appDestinations()
            }
            .tabLayer(visible: router.tab == .home, reserved: reserved)

            NavigationStack(path: calendarPathBinding) {
                CalendarScreen()
                    .appDestinations()
            }
            .tabLayer(visible: router.tab == .calendar, reserved: reserved)

            NavigationStack {
                InsightsView()
            }
            .tabLayer(visible: router.tab == .insights, reserved: reserved)

            NavigationStack {
                SettingsView()
                    .appDestinations()
            }
            .tabLayer(visible: router.tab == .settings, reserved: reserved)
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: AppSheet) -> some View {
        switch sheet {
        case .newTask(let day, let priority):
            TaskEditorView(mode: .new(day: day, priority: priority))
        case .newJournal(let date):
            JournalEditorView(entry: nil, date: date)
        case .quickCapture:
            QuickCaptureView()
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
    func tabLayer(visible: Bool, reserved: CGFloat) -> some View {
        self
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: reserved)
            }
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(visible)
            .accessibilityHidden(!visible)
    }
}

#Preview {
    RootView()
        .environment(Router())
        .environment(AppState())
        .modelContainer(for: [TaskItem.self, JournalEntry.self], inMemory: true)
}
