#if DEBUG
import Foundation
import SwiftData

/// Debug builds only: `-screenshotRoute <name>` opens a screen at launch,
/// so `scripts/screenshots.sh` can capture every screen in the simulator.
enum DebugLaunchRoute {
    private static var isScreenshotRun: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshotRoute")
    }

    /// Screenshot runs only: adds demo to-dos, priorities and a journal page once, so the
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
        context.insert(Priority(title: "Call Mom 💕", date: today, order: 1))
        let yoga = Priority(title: "Morning yoga 🧘‍♀️", date: today, order: 2)
        yoga.toggleCompleted()
        context.insert(yoga)
        let page = JournalEntry(
            date: today,
            title: "A calm, happy day 💖",
            body: "Coffee in the garden, a long walk and a good talk with a friend.\n\nGrateful for the little things.",
            mood: .amazing,
            littleWin: "Finished my workout."
        )
        page.gratitude = "My family and our cozy home."
        page.highlight = "Watching the sunset with my puppy."
        page.stickers = "🌸☕️🐶"
        page.tags = ["Good Vibes", "Grateful"]
        page.weather = .sunny
        page.temperature = "28°C"
        context.insert(page)
    }

    /// A To-Dos sheet to open once the screen appears ("todos-add" → "add").
    @MainActor private static var todosSheet: String?
    /// Open the newest journal page once the journal appears ("journal-page").
    @MainActor private static var journalPage = false
    /// Show every journal page once the journal appears ("journal-pages").
    @MainActor private static var journalPages = false
    /// Where the journal page scrolls to ("journal-middle": the writing, "journal-bottom": Save,
    /// "journal-proud": the moods).
    @MainActor private static var journalAnchor: String?
    /// Open "Choose your mood" once the journal appears ("journal-moods").
    @MainActor private static var journalMoods = false
    /// Tick the first priority once Today's Priority appears ("priority-hearts").
    @MainActor private static var priorityTick = false
    /// Tick every priority left once Today's Priority appears ("priority-alldone").
    @MainActor private static var priorityAllDone = false
    /// Days from today that the calendar selects when it appears ("calendar-tomorrow").
    @MainActor private static var calendarDayOffset = 0
    /// "todos-hearts" and "priority-hearts": keep a tick's two hearts (and a to-do's place) a
    /// few seconds longer, so the screenshot can catch them.
    @MainActor static private(set) var holdsTickPop = false

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

    @MainActor
    static func takeJournalAnchor() -> String? {
        defer { journalAnchor = nil }
        return journalAnchor
    }

    @MainActor
    static func takeJournalMoods() -> Bool {
        defer { journalMoods = false }
        return journalMoods
    }

    @MainActor
    static func takeJournalPages() -> Bool {
        defer { journalPages = false }
        return journalPages
    }

    @MainActor
    static func takePriorityAllDone() -> Bool {
        defer { priorityAllDone = false }
        return priorityAllDone
    }

    @MainActor
    static func takePriorityTick() -> Bool {
        defer { priorityTick = false }
        return priorityTick
    }

    @MainActor
    static func takeCalendarDayOffset() -> Int {
        defer { calendarDayOffset = 0 }
        return calendarDayOffset
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
        case "priority-hearts":
            priorityTick = true
            holdsTickPop = true
            router.open(.priority(today))
        case "priority-alldone":
            // After priority-hearts: ticks the rest, so the all-done card and confetti show.
            priorityAllDone = true
            router.open(.priority(today))
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
        case "journal-pages":
            journalPages = true
            router.open(.journal)
        case "journal-middle":
            journalAnchor = "write"
            router.open(.journal)
        case "journal-bottom":
            journalAnchor = "save"
            router.open(.journal)
        case "journal-proud":
            // One of the last routes: today's page is felt "Proud", a mood picked with ＋.
            let start = today.startOfDay
            let end = start.nextDay
            let pages = (try? context.fetch(FetchDescriptor<JournalEntry>(
                predicate: #Predicate { $0.date >= start && $0.date < end }))) ?? []
            for page in pages {
                page.mood = .proud
            }
            journalAnchor = "mood"
            router.open(.journal)
        case "journal-moods":
            journalMoods = true
            router.open(.journal)
        case "calendar": router.tab = .calendar
        case "calendar-tomorrow":
            calendarDayOffset = 1
            router.tab = .calendar
        case "insights": router.tab = .insights
        case "settings": router.tab = .settings
        case "newtask": router.sheet = .newTask(today)
        case "newjournal": router.sheet = .newJournal(.now)
        case let route where route.hasPrefix("todos-"):
            todosSheet = String(route.dropFirst("todos-".count))
            holdsTickPop = route == "todos-hearts"
            router.open(.todos(today))
        default: break
        }
    }
}
#endif
