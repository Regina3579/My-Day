import SwiftUI
import Observation

enum AppTab: String, CaseIterable, Identifiable {
    case home, calendar, insights, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "My Day"
        case .calendar: "Calendar"
        case .insights: "Insights"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .calendar: "calendar"
        case .insights: "chart.bar.fill"
        case .settings: "gearshape.fill"
        }
    }
}

/// Screens that can be pushed onto a tab's navigation stack.
enum AppRoute: Hashable {
    case todos(Date)
    case priority(Date)
    case journal
    /// Every journal page, with search, favourites and little wins.
    case journalPages
}

/// Sheets that can be opened from anywhere in the app.
enum AppSheet: Identifiable {
    case newTask(Date)
    case newPriority(Date)
    case newJournal(Date)
    case reminders

    var id: String {
        switch self {
        case .newTask(let date): "task-\(date.timeIntervalSince1970)"
        case .newPriority(let date): "priority-\(date.timeIntervalSince1970)"
        case .newJournal(let date): "journal-\(date.timeIntervalSince1970)"
        case .reminders: "reminders"
        }
    }
}

@Observable
final class Router {
    var tab: AppTab = .home
    var homePath = NavigationPath()
    var calendarPath = NavigationPath()
    var sheet: AppSheet?
    var isMenuOpen = false
    var isQuickAddOpen = false
    /// How many full-screen pages (Today's Priority) each tab is showing: the tab bar hides
    /// while the current tab shows one. A count, not a flag, so a page that replaces another
    /// one of its kind (its `onAppear` can run before the old page's `onDisappear`) keeps it hidden.
    private var fullScreenPages: [AppTab: Int] = [:]
    /// The same count for full-screen pages that also hide the status bar.
    private var statusBarHidingPages: [AppTab: Int] = [:]

    var showsTabBar: Bool { fullScreenPages[tab, default: 0] == 0 }

    /// Read by the root view: a status bar hidden from inside a navigation stack is ignored.
    var hidesStatusBar: Bool { statusBarHidingPages[tab, default: 0] > 0 }

    /// Called by a full-screen page when it appears (`true`) and disappears (`false`).
    func setFullScreen(_ isOn: Bool, in tab: AppTab, hidingStatusBar: Bool = false) {
        let step = isOn ? 1 : -1
        fullScreenPages[tab] = max(0, fullScreenPages[tab, default: 0] + step)
        if hidingStatusBar {
            statusBarHidingPages[tab] = max(0, statusBarHidingPages[tab, default: 0] + step)
        }
    }

    /// Jumps to the My Day tab and shows `route` on top of the home screen.
    func open(_ route: AppRoute) {
        tab = .home
        var path = NavigationPath()
        path.append(route)
        homePath = path
    }

    /// Shows `route` on top of what `tab` shows now (on the tabs whose paths the router keeps).
    func push(_ route: AppRoute, in tab: AppTab) {
        switch tab {
        case .home: homePath.append(route)
        case .calendar: calendarPath.append(route)
        case .insights, .settings: break
        }
    }

    func goHome() {
        tab = .home
        homePath = NavigationPath()
    }

    func popToRoot(_ tab: AppTab) {
        switch tab {
        case .home: homePath = NavigationPath()
        case .calendar: calendarPath = NavigationPath()
        case .insights, .settings: break
        }
    }
}

@Observable
final class AppState {
    /// Start of the current day; refreshed when the app becomes active or the date changes.
    var today: Date = Calendar.current.startOfDay(for: .now)
    /// Unlocked for the current session only; relocked when the app goes to the background.
    var isJournalUnlocked = false
}

extension View {
    /// Registers every pushable screen, so each tab's stack can show them.
    func appDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .todos(let day): TodayToDosView(day: day)
            case .priority(let day): TodaysPriorityView(day: day)
            case .journal: JournalView()
            case .journalPages: JournalPagesView()
            }
        }
        .navigationDestination(for: JournalEntry.self) { entry in
            JournalDetailView(entry: entry)
        }
    }
}
