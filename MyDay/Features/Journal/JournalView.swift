import SwiftUI
import SwiftData

/// "My Journal": opens on My Journal Pages (behind the lock when it is on).
struct JournalView: View {
    @Environment(AppState.self) private var appState
    @AppStorage(Prefs.journalLock) private var lockEnabled = false

    var body: some View {
        if lockEnabled && !appState.isJournalUnlocked {
            JournalLockView()
                .navigationTitle("My Journal")
                .navigationBarTitleDisplayMode(.inline)
        } else {
            JournalPagesHome()
        }
    }
}

/// "My Journal Pages", as in the design: the picture, My Pages, Write a new page, My week in
/// moods, the ten tabs, then the pages by month, with the search bar and Filter floating at
/// the bottom. Written pages scroll behind the search bar. It is drawn in the journal theme
/// (Blush Blossom, or with My Day Pro, Heavenly Angel Wishes: the castle in the clouds at the
/// top and the cards in the sky; Enchanted Fairy Garden: the fairies' sign at the top and the
/// cards in a flower garden; Rainbow Glow Unicorn: the unicorns' castle at the top and the
/// cards among rainbows and clouds; Rose Gold Elegance; Cozy Rainy Day; or Candy Cloud Kingdom:
/// the candy castle at the top and frosted cards among lollipops and candy canes).
struct JournalPagesHome: View {
    @Environment(AppState.self) private var appState
    @Environment(Router.self) private var router
    @Environment(MyDayPro.self) private var pro
    @Environment(\.hostTab) private var hostTab
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \JournalEntry.date, order: .reverse) private var allEntries: [JournalEntry]
    @AppStorage(Prefs.journalTheme) private var chosenTheme: JournalTheme = .blushBlossom

    @State private var shelf: JournalShelf = .all
    @State private var period: JournalPeriod = .allTime
    @State private var filter = JournalFilter()
    @State private var search = ""
    @State private var isFiltering = false
    @State private var heroIsVisible = true
    @State private var confirmEmptyTrash = false
    @State private var choosesTheme = false
    @AppStorage(Prefs.showSteps) private var showSteps = true
    @State private var showsMenu = false
    /// The menu card has grown in (it pops from ⋮).
    @State private var menuShown = false
    @AppStorage(Prefs.didShowJournalMenuTip) private var didShowMenuTip = false
    @AppStorage(Prefs.didShowJournalThemeTip) private var didShowThemeTip = false
    @State private var tip: JournalMenuTip.Kind?
    @AppStorage(Prefs.journalLock) private var lockEnabled = false
    @State private var showsLockTip = false
    /// The ⋮ menu's Lock My Journal: the same kitten card, asking, then the lock's set-up (or,
    /// without My Day Pro, its Pro offer).
    @State private var showsLockOffer = false
    @State private var lockGoal: JournalLockSetupSheet.Goal?
    @State private var proOffer: ProFeature?
    /// This opening of the journal has been counted (coming back from a page is not a new one).
    @State private var countedOpening = false
    /// Where ⋮ and the menu's Journal Theme are on screen, for the tips.
    @State private var moreFrame = CGRect.zero
    @State private var themeRowFrame = CGRect.zero
    @FocusState private var searchFocused: Bool
    /// The opening picture shows each time the journal opens (after the lock, when it is on).
    #if DEBUG
    @State private var isOpening = !DebugLaunchRoute.isScreenshotRun || DebugLaunchRoute.journalOpeningMoment != nil
    #else
    @State private var isOpening = true
    #endif

    /// The theme drawn: Blush Blossom while a Pro theme waits for My Day Pro.
    private var theme: JournalTheme { chosenTheme.applying(pro: pro.isActive) }
    private var blush: Bool { theme == .blushBlossom }

    /// Back and ⋮ float over Blush Blossom's picture while it shows.
    private var floatsButtons: Bool { blush && heroIsVisible && !isOpening }

    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { reader in
                scroller(proxy)
                #if DEBUG
                    .task { await applyDebugRoute(reader) }
                #endif
            }
        }
        .background {
            switch theme {
            case .heavenlyAngelWishes: HeavenlyBackdrop()
            case .enchantedFairyGarden: FairyBackdrop()
            case .rainbowGlowUnicorn: UnicornBackdrop()
            case .roseGoldElegance: RoseBackdrop()
            case .cozyRainyDay: RainyBackdrop()
            case .candyCloudKingdom: CandyBackdrop()
            case .blushBlossom: JournalBackdrop()
            }
        }
        .environment(\.journalTheme, theme)
        .overlay(alignment: .topTrailing) { menuCard }
        .overlay { menuTips }
        .overlay {
            if showsLockTip {
                JournalLockTip {
                    JournalLockTipSchedule.finish()
                    showsLockTip = false
                } onLater: {
                    JournalLockTipSchedule.later()
                    showsLockTip = false
                }
            }
        }
        .overlay {
            if showsLockOffer {
                JournalLockTip(kind: .offer) {
                    JournalLockTipSchedule.finish()
                    showsLockOffer = false
                    if pro.isActive {
                        lockGoal = .turnOn
                    } else {
                        proOffer = .journalLock
                    }
                } onLater: {
                    // Seen from the menu: the tip need not come by itself as well.
                    JournalLockTipSchedule.finish()
                    showsLockOffer = false
                }
            }
        }
        .sheet(item: $lockGoal) { goal in
            JournalLockSetupSheet(goal: goal)
        }
        .proOffer($proOffer)
        .task(id: isOpening) {
            await offerLockTip()
            await offerMenuTip()
        }
        .overlay {
            if isOpening {
                JournalOpeningView(frozenAt: debugOpeningMoment) {
                    withAnimation(.easeOut(duration: 0.3)) { isOpening = false }
                }
                .transition(.opacity)
            }
        }
        // Blush Blossom's picture reaches the very top: while it shows, back and ⋮ float in the
        // clock's row over it (the clock hides here) instead of the bar, so nothing covers its
        // title; once it has scrolled away, the soft pink bar comes back.
        .overlay(alignment: .top) {
            if floatsButtons {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(JournalStyle.ink)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.75)))
                            .overlay(Circle().strokeBorder(Color.white, lineWidth: 1))
                            .shadow(color: JournalStyle.pink.opacity(0.18), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PressScaleStyle())
                    .accessibilityLabel("Back")
                    Spacer()
                    moreMenu
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.75)))
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 1))
                        .shadow(color: JournalStyle.pink.opacity(0.18), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .ignoresSafeArea(edges: .top)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: floatsButtons)
        // The bar itself stays (only its back button and ⋮ hide while they float): a bar that
        // comes and goes moves the whole page, and that is the shake on opening and scrolling.
        .navigationBarBackButtonHidden(isOpening || floatsButtons)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("My Journal Pages")
                    .font(blush ? .rounded(.headline, weight: .bold) : theme.headingFont(.headline))
                    .foregroundStyle(blush ? JournalStyle.ink : theme.headingColor)
                    .opacity(heroIsVisible ? 0 : 1)
                    .animation(.easeInOut(duration: 0.2), value: heroIsVisible)
                    .accessibilityHidden(heroIsVisible)
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !floatsButtons && !isOpening {
                    moreMenu
                }
            }
        }
        .navigationTitle("My Journal Pages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(heroIsVisible ? .hidden : .visible, for: .navigationBar)
        .toolbarBackground(JournalBackdrop.base, for: .navigationBar)
        .sheet(isPresented: $isFiltering) {
            JournalFilterSheet(filter: $filter, period: $period)
        }
        .sheet(isPresented: $choosesTheme) {
            NavigationStack {
                JournalThemeView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { choosesTheme = false }
                        }
                    }
            }
        }
        .confirmationDialog("Empty Trash?", isPresented: $confirmEmptyTrash, titleVisibility: .visible) {
            Button(trashed.count == 1 ? "Delete 1 Page Forever" : "Delete \(trashed.count) Pages Forever",
                   role: .destructive, action: emptyTrash)
        } message: {
            Text("These pages will be gone for good.")
        }
        // Full screen: no tab bar, and no clock over the picture.
        .onAppear { router.setFullScreen(true, in: hostTab, hidingStatusBar: true) }
        .onDisappear { router.setFullScreen(false, in: hostTab, hidingStatusBar: true) }
        // The first time the pages show (after the opening picture), Health is asked for the
        // steps on each page.
        .task(id: isOpening) {
            guard !isOpening, showSteps else { return }
            try? await Task.sleep(for: .seconds(1))
            await StepCounter.shared.requestAccess()
        }
    }

    // MARK: Layout

    /// The picture, then the cards on their panel (in the Pro themes, the theme's picture, then
    /// the cards on its backdrop); the search bar floats at the bottom.
    private func scroller(_ proxy: GeometryProxy) -> some View {
        let statusBar = JournalScene.windowStatusBar(fallback: max(0, proxy.safeAreaInsets.top - 44))
        return ScrollView {
            VStack(spacing: 0) {
                Group {
                    switch theme {
                    case .heavenlyAngelWishes:
                        HeavenlyHeader(width: proxy.size.width, statusBar: statusBar)
                    case .enchantedFairyGarden:
                        JournalHero(scene: .fairyGarden, width: proxy.size.width, statusBar: statusBar)
                    case .rainbowGlowUnicorn:
                        JournalHero(scene: .rainbowUnicorn, width: proxy.size.width, statusBar: statusBar)
                    case .roseGoldElegance:
                        RoseHeader(width: proxy.size.width, statusBar: statusBar)
                    case .cozyRainyDay:
                        JournalHero(scene: .rainy, width: proxy.size.width, statusBar: statusBar)
                    case .candyCloudKingdom:
                        JournalHero(scene: .candy, width: proxy.size.width, statusBar: statusBar)
                    case .blushBlossom:
                        JournalHero(scene: .pages, width: proxy.size.width, statusBar: statusBar)
                    }
                }
                .onGeometryChange(for: Bool.self) { geometry in
                    // A Pro theme's picture is about as tall as the bars over it, so it counts
                    // as shown until it has scrolled a little way up.
                    blush ? geometry.frame(in: .global).maxY > proxy.safeAreaInsets.top + 60
                        : geometry.frame(in: .global).minY > -40
                } action: { isVisible in
                    heroIsVisible = isVisible
                }
                // Rose Gold Elegance's angel girl hangs over the card below, in front of it.
                .zIndex(theme == .roseGoldElegance ? 1 : 0)
                content
                    .padding(.horizontal, theme.sideInset)
                    // The fairy and the unicorn beside Write a new page rise into the picture.
                    .padding(.top, contentTop)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity)
                    .background(alignment: .top) {
                        if blush {
                            JournalPanel()
                        }
                    }
                    .padding(.top, blush ? -JournalScene.pages.overlap(width: proxy.size.width) : 0)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        // iOS 26 softens what lies under the navigation bar with a white haze: off while the
        // picture shows (clear and sharp right up to the top, in every theme); once it has
        // scrolled away, the bar turns soft pink so the pages don't run under its title.
        .modifier(TopScrollEdgeEffect(hidden: heroIsVisible))
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            JournalSearchBar(text: $search, focused: $searchFocused, filterCount: filter.count + (period == .allTime ? 0 : 1)) {
                searchFocused = false
                isFiltering = true
            }
        }
    }

    private var debugOpeningMoment: TimeInterval? {
        #if DEBUG
        DebugLaunchRoute.journalOpeningMoment
        #else
        nil
        #endif
    }

    private var content: some View {
        VStack(spacing: 16) {
            WriteNewPageRow(todayPage: todayPage)
            MoodWeekCard(entries: live, today: appState.today, onCalendar: openCalendar)
            JournalTabsRow(selection: $shelf)
                .id("tabs")
            shelfContent
                .id("shelf")
        }
    }

    // MARK: The chosen tab

    @ViewBuilder
    private var shelfContent: some View {
        switch shelf {
        case .templates:
            TemplatesShelf(query: search.trimmed)
        default:
            let pages = shown
            // Lazy: a page card is made as it scrolls into view, so a journal of many months
            // scrolls as lightly as a new one.
            LazyVStack(alignment: .leading, spacing: 14) {
                shelfIntro(pages: pages)
                if shelf == .photos {
                    listHeader(title: pages.isEmpty ? shelf.label : photoCountTitle(pages))
                    if pages.isEmpty {
                        emptyState
                    } else {
                        PhotosShelf(entries: pages)
                    }
                } else {
                    let months = JournalMonth.group(pages, oldestFirst: filter.oldestFirst)
                    if months.isEmpty {
                        listHeader(title: shelf.label)
                        emptyState
                    }
                    ForEach(Array(months.enumerated()), id: \.element.id) { index, month in
                        if index == 0 {
                            listHeader(title: month.title)
                        } else {
                            monthTitle(month.title)
                                .padding(.top, 6)
                        }
                        ForEach(month.entries) { entry in
                            JournalEntryCard(entry: entry, shelf: shelf)
                                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        }
                    }
                }
            }
            .animation(.snappy, value: pages.map(\.persistentModelID))
        }
    }

    @ViewBuilder
    private func shelfIntro(pages: [JournalEntry]) -> some View {
        switch shelf {
        case .wins:
            if !pages.isEmpty {
                LittleWinsSummary(count: pages.count)
            }
        case .feelings:
            FeelingsSummary(entries: periodPages(live), period: period, selected: $filter.moods)
        case .growth:
            GrowthSummary(entries: periodPages(live), today: appState.today)
        case .dreams:
            ShelfHint(emoji: "🌙", title: "My dreams and wishes",
                      message: "Pages with “Tomorrow I look forward to…” or the Dreams tag live here.")
        case .voice:
            ShelfHint(emoji: "🎙️", title: "My voice notes",
                      message: "Pages you talked to. Open one to listen, or record more.")
        case .trash:
            TrashNotice(count: pages.count) { confirmEmptyTrash = true }
        default:
            EmptyView()
        }
    }

    /// Where the cards start, under the picture.
    private var contentTop: CGFloat {
        switch theme {
        case .blushBlossom: -18
        case .heavenlyAngelWishes: 2
        case .enchantedFairyGarden: -18
        case .rainbowGlowUnicorn: -28
        case .roseGoldElegance: 2
        case .cozyRainyDay: -4
        case .candyCloudKingdom: -10
        }
    }

    /// The first heading: the month (or the tab), with the period menu beside it (in the Pro
    /// themes, with the theme's little picture between them when there is room: the angel
    /// asleep on a cloud, two butterflies or the little unicorn).
    @ViewBuilder
    private func listHeader(title: String) -> some View {
        if theme == .candyCloudKingdom {
            // Candy Cloud Kingdom: the candy castle and its rainbow in the clouds, behind the
            // month and All Time, as in the design.
            HStack(spacing: 8) {
                monthTitle(title)
                Spacer(minLength: 14)
                JournalPeriodMenu(period: $period)
                    .padding(.trailing, 4)
            }
            .background(alignment: .trailing) {
                Image("CandyMonthCastle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 116, height: 61)
                    .padding(.trailing, 98)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        } else if let art = theme.monthArt {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) {
                    monthTitle(title)
                        .fixedSize()
                    Spacer(minLength: 2)
                    Image(art.name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: art.size.width, height: art.size.height)
                        .accessibilityHidden(true)
                    Spacer(minLength: 8)
                    JournalPeriodMenu(period: $period)
                        .fixedSize()
                        .padding(.trailing, 6)
                }
                HStack(spacing: 8) {
                    monthTitle(title)
                    Spacer(minLength: 14)
                    JournalPeriodMenu(period: $period)
                        .padding(.trailing, 8)
                }
            }
        } else {
            HStack(spacing: 8) {
                monthTitle(title)
                Spacer(minLength: 4)
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: 0xF7C548))
                    .accessibilityHidden(true)
                JournalPeriodMenu(period: $period)
            }
        }
    }

    private func monthTitle(_ title: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(theme.headingFont(.title3))
                .foregroundStyle(theme.monthColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Image(systemName: "heart.fill")
                .font(.system(size: 15))
                .foregroundStyle(JournalPagesStyle.heartPink)
                .accessibilityHidden(true)
        }
        .accessibilityAddTraits(.isHeader)
    }

    private func photoCountTitle(_ pages: [JournalEntry]) -> String {
        let count = pages.reduce(0) { $0 + ($1.photos ?? []).count }
        return count == 1 ? "1 photo" : "\(count) photos"
    }

    @ViewBuilder
    private var emptyState: some View {
        let searching = !search.trimmed.isEmpty || filter.count > 0 || period != .allTime
        if searching {
            ShelfEmpty(emoji: "🔍", title: "No pages found",
                       message: "Try another word, or change the filter or the dates.")
        } else {
            switch shelf {
            case .favorites:
                ShelfEmpty(emoji: "💗", title: "No favorites yet", message: "Tap the heart on a page to keep it here.")
            case .wins:
                ShelfEmpty(emoji: "🏆", title: "No little wins yet",
                           message: "Add one line to any page: “My little win today…”")
            case .photos:
                ShelfEmpty(emoji: "📸", title: "No photos yet", message: "Add photos to a page to see them all here.")
            case .voice:
                ShelfEmpty(emoji: "🎙️", title: "No voice notes yet",
                           message: "Record a voice note on any page to find it here.")
            case .growth:
                ShelfEmpty(emoji: "🌱", title: "Your growth starts here",
                           message: "Write what you're grateful for, a highlight or a little win on a page.")
            case .dreams:
                ShelfEmpty(emoji: "☁️", title: "No dreams yet",
                           message: "Try the Dream Journal template, or write what you look forward to.")
            case .trash:
                ShelfEmpty(emoji: "🗑️", title: "Trash is empty", message: "Pages you move to Trash stay here for \(JournalTrash.keepDays) days.")
            default:
                ShelfEmpty(emoji: "🌸", title: "Your journal is waiting",
                           message: "Tap “Write a new page” to write about your day.")
            }
        }
    }

    // MARK: Pages

    /// Pages in the journal (not in Trash).
    /// Today's page, once written: Write a new page carries on with it.
    private var todayPage: JournalEntry? {
        JournalEntry.page(on: appState.today, among: live)
    }

    private var live: [JournalEntry] {
        allEntries.filter { $0.deletedAt == nil }
    }

    /// Pages in Trash, the most recently trashed first.
    private var trashed: [JournalEntry] {
        allEntries.filter(\.isInTrash).sorted { ($0.deletedAt ?? .now) > ($1.deletedAt ?? .now) }
    }

    private func periodPages(_ pages: [JournalEntry]) -> [JournalEntry] {
        guard let range = period.range(today: appState.today) else { return pages }
        return pages.filter { range.contains($0.date) }
    }

    /// What the chosen tab lists, after the dates, the filter and the search.
    private var shown: [JournalEntry] {
        let query = search.trimmed
        let pages = periodPages(shelf == .trash ? trashed : live).filter { entry in
            shelf.includes(entry) && filter.includes(entry) && (query.isEmpty || entry.matches(query))
        }
        return filter.oldestFirst ? pages.reversed() : pages
    }

    // MARK: Menu and actions

    /// ⋮: opens (or closes) the menu card.
    private var moreMenu: some View {
        Button {
            if showsMenu { closeMenu() } else { openMenu() }
            Haptics.tap()
        } label: {
            Image(uiImage: PriorityMoreSymbol.image)
                .foregroundStyle(JournalStyle.pink)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { moreFrame = $0 }
        }
        .accessibilityLabel("More")
    }

    /// The menu card from the design, hanging from ⋮ (which stays on top of the card's corner,
    /// as in the design); a tap anywhere else closes it.
    @ViewBuilder
    private var menuCard: some View {
        if showsMenu {
            GeometryReader { proxy in
                let scale = proxy.size.width / 941
                let origin = proxy.frame(in: .global).origin
                let grid = JournalPagesMenu.grid
                let hook = JournalPagesMenu.moreButton
                // ⋮'s middle, in this view's space (the card's right edge stays on screen).
                let x = min(moreFrame.midX - origin.x - hook.x * scale, proxy.size.width - grid.width * scale)
                // Never above the screen's top (⋮ floats in the clock's row over the picture).
                let y = max(moreFrame.midY - hook.y * scale, 8) - origin.y
                ZStack(alignment: .topLeading) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { closeMenu() }
                        .accessibilityHidden(true)
                    JournalPagesMenu(items: menuItems, scale: scale) { themeRowFrame = $0 }
                        .scaleEffect(menuShown ? 1 : 0.85,
                                     anchor: UnitPoint(x: hook.x / grid.width, y: hook.y / grid.height))
                        .opacity(menuShown ? 1 : 0)
                        .offset(x: x, y: y)
                }
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { menuShown = true }
            }
            .onDisappear { menuShown = false }
        }
    }

    private var menuItems: [JournalPagesMenu.Item] {
        [
            .init(title: todayPage == nil ? "Write a New Page" : "Continue Today's Page") {
                closeMenu()
                router.push(todayPage.map { AppRoute.editJournalPage($0) } ?? .newJournalPage(nil), in: hostTab)
            },
            .init(title: "Filter Pages") {
                closeMenu()
                isFiltering = true
            },
            .init(title: "View Calendar") {
                closeMenu()
                openCalendar()
            },
            .init(title: "Journal Theme") {
                closeMenu()
                choosesTheme = true
            },
            // A pink switch on the row: sliding it on, the kitten card offers to set the lock up (a
            // Pro feature); sliding it off asks Face ID, the pattern or the passcode once, then
            // turns the lock off.
            .init(title: lockEnabled || pro.isActive ? "Lock My Journal" : "Lock My Journal 👑", isOn: lockEnabled) {
                closeMenu()
                if lockEnabled {
                    Haptics.tap()
                    lockGoal = .turnOff
                } else {
                    Task {
                        // Once the menu has closed.
                        try? await Task.sleep(for: .seconds(0.2))
                        showsLockOffer = true
                    }
                }
            },
            .init(title: "Trash") {
                closeMenu()
                withAnimation(.snappy) { shelf = .trash }
            },
        ]
    }

    private func openMenu() {
        if tip == .menu {
            didShowMenuTip = true
            withAnimation(.easeOut(duration: 0.2)) { tip = nil }
        }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { showsMenu = true }
        // The first time the menu opens, the Journal Themes tip points at Journal Theme.
        guard !didShowThemeTip else { return }
        Task {
            try? await Task.sleep(for: .seconds(0.45))
            // About the menu just opened, so it needs only a short gap after another tip.
            if showsMenu, !didShowThemeTip, themeRowFrame != .zero, TipPacer.mayShow(contextual: true) {
                TipPacer.shown()
                tip = .theme
            }
        }
    }

    private func closeMenu() {
        if tip == .theme {
            didShowThemeTip = true
            tip = nil
        }
        withAnimation(.easeOut(duration: 0.18)) { showsMenu = false }
    }

    // MARK: First-time tips

    /// The Journal Lock tip, the first time the journal opens on a later day than its very first
    /// opening (and once more 7 days after Maybe Later), never while Lock My Journal is on. While "More options here!" is still to
    /// come, that tip goes first and this one waits for the next opening.
    private func offerLockTip() async {
        guard !isOpening, !countedOpening else { return }
        countedOpening = true
        guard JournalLockTipSchedule.countOpeningAndCheck(lockEnabled: lockEnabled), didShowMenuTip else { return }
        try? await Task.sleep(for: TipPacer.settle)
        guard !Task.isCancelled, !lockEnabled, !showsMenu, !isFiltering, !choosesTheme, tip == nil,
              !showsLockOffer, TipPacer.mayShow() else { return }
        TipPacer.shown()
        showsLockTip = true
    }

    /// "More options here!", once, a moment after the journal opens (when nothing else is open).
    private func offerMenuTip() async {
        guard !isOpening, !didShowMenuTip, !showsLockTip else { return }
        try? await Task.sleep(for: TipPacer.settle)
        guard !Task.isCancelled, !isOpening, !didShowMenuTip, !showsMenu, !isFiltering, !choosesTheme,
              moreFrame != .zero, TipPacer.mayShow() else { return }
        TipPacer.shown()
        tip = .menu
    }

    @ViewBuilder
    private var menuTips: some View {
        if let tip {
            GeometryReader { proxy in
                let origin = proxy.frame(in: .global).origin
                let frame = tip == .menu ? moreFrame : themeRowFrame
                JournalMenuTip(kind: tip, target: frame.offsetBy(dx: -origin.x, dy: -origin.y), size: proxy.size) {
                    if tip == .menu {
                        openMenu()
                    } else {
                        didShowThemeTip = true
                        self.tip = nil
                        closeMenu()
                        choosesTheme = true
                    }
                } onDismiss: {
                    if tip == .menu { didShowMenuTip = true } else { didShowThemeTip = true }
                    withAnimation(.easeOut(duration: 0.2)) { self.tip = nil }
                }
            }
            .ignoresSafeArea()
            .transition(.opacity)
        }
    }

    private func openCalendar() {
        if hostTab == .calendar {
            router.popToRoot(.calendar)
        } else {
            router.tab = .calendar
        }
    }

    private func emptyTrash() {
        withAnimation(.snappy) {
            for entry in trashed {
                context.delete(entry)
            }
        }
        Haptics.success()
    }

    #if DEBUG
    private func applyDebugRoute(_ reader: ScrollViewProxy) async {
        if DebugLaunchRoute.takeJournalMenu() {
            try? await Task.sleep(for: .seconds(0.6))
            openMenu()
            return
        }
        if DebugLaunchRoute.takeJournalLockOffer() {
            try? await Task.sleep(for: .seconds(0.6))
            showsLockOffer = true
            return
        }
        if DebugLaunchRoute.takeJournalPage(), let newest = live.first {
            router.homePath.append(newest)
            return
        }
        guard let name = DebugLaunchRoute.takeJournalShelf(), let chosen = JournalShelf(rawValue: name) else { return }
        shelf = chosen
        try? await Task.sleep(for: .seconds(0.8))
        reader.scrollTo("tabs", anchor: .top)
        if DebugLaunchRoute.takeJournalFilter() {
            try? await Task.sleep(for: .seconds(0.5))
            isFiltering = true
        }
    }
    #endif
}

/// Hides the top scroll edge effect (iOS 26 and later) while `hidden`.
private struct TopScrollEdgeEffect: ViewModifier {
    let hidden: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectHidden(hidden, for: .top)
        } else {
            content
        }
    }
}
