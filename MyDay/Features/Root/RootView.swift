import SwiftUI
import SwiftData
import Combine
import StoreKit

/// Hosts the four tabs, the floating tab bar (hidden under full-screen pages), the Quick Add
/// menu, the side menu, the "Enjoying My Day?" rating card and the app-wide sheets.
struct RootView: View {
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(DataStore.self) private var store
    @Environment(RatingPrompt.self) private var rating
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL
    @AppStorage(Prefs.carryOver) private var carryOver = true

    var body: some View {
        GeometryReader { proxy in
            let barBottom = TabBarLayout.bottomPadding(safeAreaBottom: proxy.safeAreaInsets.bottom)
            let reserved = max(0, TabBarLayout.height + barBottom - proxy.safeAreaInsets.bottom) + 8

            ZStack(alignment: .bottom) {
                tabs(reserved: reserved)

                if router.showsTabBar {
                    BottomTabBar(selection: tabBinding) { tab in
                        router.popToRoot(tab)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, barBottom)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

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

                if rating.isShowing {
                    RatingCard(onRate: rateNow, onLater: { rating.later() })
                        .transition(.opacity)
                        .zIndex(3)
                }

                if let target = router.iCloudTip {
                    GeometryReader { tipProxy in
                        ICloudTip(target: target.moved(from: tipProxy.frame(in: .global).origin),
                                  size: tipProxy.size, onTry: syncFromICloudTip, onDismiss: closeICloudTip)
                    }
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(3)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showsQuickAdd)
            .animation(.easeInOut(duration: 0.25), value: router.showsTabBar)
        }
        .statusBarHidden(router.hidesStatusBar)
        .sheet(item: sheetBinding) { sheet in
            sheetContent(sheet)
        }
        .onChange(of: router.tab) { _, _ in
            router.isQuickAddOpen = false
            router.iCloudTip = nil
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                refreshDay()
                rating.noteActive()
            case .background: appState.isJournalUnlocked = false
            default: break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            refreshDay()
        }
        .onChange(of: store.syncStatus.imports) { _, _ in
            // Changes came from iCloud: from another device, or everything coming back after
            // My Day was installed again.
            TemplateLibrary.removeDuplicateStarters(in: modelContext)
            ReminderCenter.syncAll(in: modelContext)
        }
        .task {
            SampleContent.removeIfNeeded(in: modelContext)
            TemplateLibrary.seedIfNeeded(in: modelContext)
            JournalTrash.purgeExpired(in: modelContext)
            #if DEBUG
            DebugLaunchRoute.addDemoData(in: modelContext)
            #endif
            refreshDay()
            // Each launch, so reminders set by an earlier version carry the current reminder sound.
            ReminderCenter.syncAll(in: modelContext)
            rating.noteActive()
            rating.isScreenFree = { [router] in
                router.sheet == nil && !router.isMenuOpen && !router.isQuickAddOpen && router.iCloudTip == nil
            }
            #if DEBUG
            DebugLaunchRoute.apply(to: router, today: appState.today, context: modelContext)
            if DebugLaunchRoute.takeRatingCard() {
                // `rating-card`: the card over To-Dos, for the screenshot.
                try? await Task.sleep(for: .seconds(1.5))
                rating.preview()
            }
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
            .environment(\.hostTab, .home)
            .tabLayer(visible: router.tab == .home)

            NavigationStack(path: calendarPathBinding) {
                CalendarView()
                    .appDestinations()
            }
            .environment(\.hostTab, .calendar)
            .tabLayer(visible: router.tab == .calendar)

            NavigationStack {
                InsightsView()
            }
            .environment(\.hostTab, .insights)
            .tabLayer(visible: router.tab == .insights)

            NavigationStack {
                SettingsView()
                    .appDestinations()
            }
            .environment(\.hostTab, .settings)
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
                        onJournal: {
                            setQuickAdd(open: false)
                            router.writeInJournal(on: .now, context: modelContext,
                                                  isUnlocked: appState.isJournalUnlocked)
                        }
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
        case .editJournal(let entry):
            NewJournalEntrySheet(entry: entry)
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

    /// "Rate Now": the card goes, then Apple's page to rate My Day opens.
    private func rateNow() {
        rating.rated()
        Task {
            try? await Task.sleep(for: .seconds(0.45))
            AppReview.open(openURL: openURL, requestReview: requestReview)
        }
    }

    // MARK: iCloud tip

    private func closeICloudTip() {
        withAnimation(.easeOut(duration: 0.25)) { router.iCloudTip = nil }
        Haptics.tap()
    }

    /// The glowing switch was tapped: the tip goes, and iCloud Sync turns on when it is off (as
    /// the switch would). When it is already on, nothing else happens: no "Stop syncing?" question
    /// right after a tip about keeping memories safe.
    private func syncFromICloudTip() {
        closeICloudTip()
        guard !store.syncsWithICloud else { return }
        // The store closes for a moment: nothing open may hold one of its items.
        router.closeAll()
        Task { await store.setSyncsWithICloud(true) }
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
        .environment(DataStore())
        .environment(RatingPrompt())
        .modelContainer(for: [TaskItem.self, Priority.self, JournalEntry.self, JournalPhoto.self, JournalVoiceNote.self,
                              TaskTemplate.self],
                        inMemory: true)
}
