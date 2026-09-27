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

    /// Jumps to the My Day tab and shows `route` on top of the home screen.
    func open(_ route: AppRoute) {
        tab = .home
        var path = NavigationPath()
        path.append(route)
        homePath = path
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
            }
        }
        .navigationDestination(for: JournalEntry.self) { entry in
            JournalDetailView(entry: entry)
        }
    }
}
