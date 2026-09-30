import SwiftUI
import SwiftData

/// "My Journal": opens on My Journal Pages (behind the lock when it is on).
struct JournalView: View {
    @Environment(AppState.self) private var appState
    @AppStorage(Prefs.journalLock) private var lockEnabled = false

    var body: some View {
        if lockEnabled && !appState.isJournalUnlocked {
            JournalLockView()
                .tabBarSafeArea()
                .background(DreamyBackground(theme: .journal))
                .navigationTitle("My Journal")
                .navigationBarTitleDisplayMode(.inline)
        } else {
            JournalPagesHome()
        }
    }
}

/// "My Journal Pages", as in the design: the picture, My Pages, Write a new page, My week in
/// moods, the ten tabs, then the pages by month, with the search bar and Filter floating at
/// the bottom. Written pages scroll behind the search bar.
struct JournalPagesHome: View {
    @Environment(AppState.self) private var appState
    @Environment(Router.self) private var router
    @Environment(\.hostTab) private var hostTab
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.date, order: .reverse) private var allEntries: [JournalEntry]

    @State private var shelf: JournalShelf = .all
    @State private var period: JournalPeriod = .allTime
    @State private var filter = JournalFilter()
    @State private var search = ""
    @State private var isFiltering = false
    @State private var heroIsVisible = true
    @State private var confirmEmptyTrash = false
    @FocusState private var searchFocused: Bool
    /// The opening picture shows each time the journal opens (after the lock, when it is on).
    #if DEBUG
    @State private var isOpening = !DebugLaunchRoute.isScreenshotRun || DebugLaunchRoute.journalOpeningMoment != nil
    #else
    @State private var isOpening = true
    #endif

    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { reader in
                scroller(proxy)
                #if DEBUG
                    .task { await applyDebugRoute(reader) }
                #endif
            }
        }
        .background(JournalBackdrop())
        .overlay {
            if isOpening {
                JournalOpeningView(frozenAt: debugOpeningMoment) {
                    withAnimation(.easeOut(duration: 0.5)) { isOpening = false }
                }
                .transition(.opacity)
            }
        }
        .toolbar(isOpening ? .hidden : .automatic, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("My Journal Pages")
                    .font(.rounded(.headline, weight: .bold))
                    .foregroundStyle(JournalStyle.ink)
                    .opacity(heroIsVisible ? 0 : 1)
                    .animation(.easeInOut(duration: 0.2), value: heroIsVisible)
                    .accessibilityHidden(heroIsVisible)
            }
            ToolbarItem(placement: .topBarTrailing) {
                moreMenu
            }
        }
        .navigationTitle("My Journal Pages")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isFiltering) {
            JournalFilterSheet(filter: $filter, period: $period)
        }
        .confirmationDialog("Empty Trash?", isPresented: $confirmEmptyTrash, titleVisibility: .visible) {
            Button(trashed.count == 1 ? "Delete 1 Page Forever" : "Delete \(trashed.count) Pages Forever",
                   role: .destructive, action: emptyTrash)
        } message: {
            Text("These pages will be gone for good.")
        }
        .onAppear { router.setFullScreen(true, in: hostTab) }
        .onDisappear { router.setFullScreen(false, in: hostTab) }
    }

    // MARK: Layout

    /// The picture, then the cards on their panel; the search bar floats at the bottom.
    private func scroller(_ proxy: GeometryProxy) -> some View {
        let statusBar = JournalScene.windowStatusBar(fallback: max(0, proxy.safeAreaInsets.top - 44))
        return ScrollView {
            VStack(spacing: 0) {
                JournalHero(scene: .pages, width: proxy.size.width, statusBar: statusBar)
                    .onGeometryChange(for: Bool.self) { geometry in
                        geometry.frame(in: .global).maxY > proxy.safeAreaInsets.top + 60
                    } action: { isVisible in
                        heroIsVisible = isVisible
                    }
                content
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity)
                    .background(alignment: .top) {
                        JournalPanel()
                    }
                    .padding(.top, -JournalScene.pages.overlap(width: proxy.size.width))
            }
        }
        .scrollDismissesKeyboard(.interactively)
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
            VStack(alignment: .leading, spacing: 14) {
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

    /// The first heading: the month (or the tab), with the period menu beside it.
    private func listHeader(title: String) -> some View {
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

    private func monthTitle(_ title: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.rounded(.title3, weight: .heavy))
                .foregroundStyle(Palette.berry)
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

    private var moreMenu: some View {
        Menu {
            Button {
                router.push(todayPage.map { AppRoute.editJournalPage($0) } ?? .newJournalPage(nil), in: hostTab)
            } label: {
                Label(todayPage == nil ? "Write a New Page" : "Continue Today's Page", systemImage: "square.and.pencil")
            }
            Button {
                isFiltering = true
            } label: {
                Label("Filter Pages", systemImage: "line.3.horizontal.decrease.circle")
            }
            Button(action: openCalendar) {
                Label("View Calendar", systemImage: "calendar")
            }
            Button {
                withAnimation(.snappy) { shelf = .trash }
            } label: {
                Label("Trash", systemImage: "trash")
            }
        } label: {
            Image(uiImage: PriorityMoreSymbol.image)
                .foregroundStyle(JournalStyle.pink)
                .accessibilityLabel("More")
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
