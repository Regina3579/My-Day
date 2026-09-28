#if DEBUG
import Foundation
import SwiftData

/// Debug builds only: `-screenshotRoute <name>` opens a screen at launch,
/// so `scripts/screenshots.sh` can capture every screen in the simulator.
enum DebugLaunchRoute {
    private static var isScreenshotRun: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshotRoute")
    }

    /// Screenshot runs only: adds demo to-dos, a priority and a journal page once, so the
    /// screenshots have something to show. Every other launch, even of a Debug build, starts empty.
    @MainActor
    static func addDemoData(in context: ModelContext) {
        let key = "debugDemoDataAdded"
        guard isScreenshotRun, !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        let today = Date()
        context.insert(TaskItem(title: "Team meeting at 10 💼", category: .work, date: today))
        context.insert(TaskItem(title: "Evening walk 🌸", category: .health, date: today, repeatOption: .daily))
        let reading = TaskItem(title: "Read 20 pages 📚", category: .learning, date: today)
        reading.isImportant = true
        context.insert(reading)
        context.insert(TaskItem(title: "Buy milk and bread 🥛", category: .shopping, date: today))
        let home = CustomCategory(name: "Home", emoji: "🏠", colorIndex: 0)
        context.insert(home)
        let plants = TaskItem(title: "Water the plants 🪴", date: today)
        context.insert(plants)
        plants.customCategory = home
        context.insert(Priority(title: "Finish the project report ⭐", date: today, order: 0))
        context.insert(JournalEntry(
            date: today,
            title: "A calm, happy day 💖",
            body: "Coffee in the garden, a long walk and a good talk with a friend.\n\nGrateful for the little things.",
            mood: .happy,
            littleWin: "Finished my workout."
        ))
    }

    /// A To-Dos sheet to open once the screen appears ("todos-add" → "add").
    @MainActor private static var todosSheet: String?
    /// Open the newest journal page once the journal appears ("journal-page").
    @MainActor private static var journalPage = false
    /// "todos-star" and "todos-heart": keep a tick's star or heart (and its to-do's place) a
    /// few seconds longer, so the screenshot can catch it.
    @MainActor static private(set) var holdsStar = false

    @MainActor
    static func takeTodosSheet() -> String? {
        defer { todosSheet = nil }
        return todosSheet
    }

    @MainActor
    static func takeJournalPage() -> Bool {
        defer { journalPage = false }
        return journalPage
    }

    /// Tells `scripts/screenshots.sh` the app is up: it waits for this file (in the app's
    /// Caches folder) before it starts timing a screenshot.
    static func markReady() {
        guard isScreenshotRun,
              let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        else { return }
        try? Data().write(to: caches.appendingPathComponent("screenshot-ready"))
    }

    @MainActor
    static func apply(to router: Router, today: Date, context: ModelContext) {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshotRoute"), index + 1 < arguments.count else { return }
        defer { markReady() }

        switch arguments[index + 1] {
        case "quickadd": router.isQuickAddOpen = true
        case "menu": router.isMenuOpen = true
        case "todos": router.open(.todos(today))
        case "priority": router.open(.priority(today))
        case "priority-empty":
            // The last route: clears the day's demo priority to show the empty page.
            let start = today.startOfDay
            let end = start.nextDay
            let priorities = (try? context.fetch(FetchDescriptor<Priority>(
                predicate: #Predicate { $0.date >= start && $0.date < end }))) ?? []
            for priority in priorities {
                context.delete(priority)
            }
            router.open(.priority(today))
        case "journal": router.open(.journal)
        case "journal-page":
            journalPage = true
            router.open(.journal)
        case "calendar": router.tab = .calendar
        case "insights": router.tab = .insights
        case "settings": router.tab = .settings
        case "newtask": router.sheet = .newTask(today)
        case "newjournal": router.sheet = .newJournal(.now)
        case let route where route.hasPrefix("todos-"):
            todosSheet = String(route.dropFirst("todos-".count))
            holdsStar = route == "todos-star" || route == "todos-heart"
            router.open(.todos(today))
        default: break
        }
    }
}
#endif
