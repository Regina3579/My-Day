#if DEBUG
import Foundation
import SwiftData
import UIKit

/// Debug builds only: `-screenshotRoute <name>` opens a screen at launch,
/// so `scripts/screenshots.sh` can capture every screen in the simulator.
enum DebugLaunchRoute {
    static var isScreenshotRun: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshotRoute")
    }

    /// The launch page: "splash" keeps it on screen. Every other screenshot skips it.
    static var holdsSplash: Bool {
        route == "splash"
    }

    /// Opening My Journal: "journal-opening" holds it still once its words have popped in.
    /// Every other screenshot skips it.
    static var journalOpeningMoment: TimeInterval? {
        route == "journal-opening" ? JournalOpeningView.length - 0.1 : nil
    }

    /// The name after `-screenshotRoute`.
    private static var route: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshotRoute"), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
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
        page.stickers = "[nature-08][food-01][animals-02]"
        page.tags = ["Good Vibes", "Grateful"]
        page.weather = .sunny
        page.temperature = "28°C"
        context.insert(page)
        // Two voice notes, from the morning and the afternoon (silent: for the layout only).
        for (index, (hour, minute, length)) in [(9, 15, 42.0), (14, 30, 18.0)].enumerated() {
            let recorded = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? today
            let note = JournalVoiceNote(audio: Data(), duration: length, order: index, createdAt: recorded)
            context.insert(note)
            note.entry = page
        }
        addDemoPages(in: context, today: today)
    }

    /// Earlier pages for My Journal Pages: a week of moods, photos, a favourite, a little win,
    /// a dream, a page from last month and one in Trash.
    @MainActor
    private static func addDemoPages(in context: ModelContext, today: Date) {
        struct Demo {
            let days: Int, hour: Int, minute: Int
            let title: String, body: String, mood: Mood
            var favorite = false
            var littleWin = ""
            var gratitude = ""
            var lookingForward = ""
            var tags: [String] = []
            var photos: [(String, CGRect)] = []
            var trashedDaysAgo: Int?
        }
        let friends = ("HeroFriends", CGRect(x: 440, y: 0, width: 340, height: 340))
        let cuddle = ("PriorityScene", CGRect(x: 470, y: 330, width: 330, height: 330))
        let window = ("TodosScene", CGRect(x: 520, y: 70, width: 320, height: 320))
        let books = ("JournalScene", CGRect(x: 540, y: 270, width: 290, height: 290))
        let pages = [
            Demo(days: 1, hour: 23, minute: 43, title: "A smiley day 😊",
                 body: "Today felt so calm and beautiful. I enjoyed my time, had good food and laughed a lot with my sister.",
                 mood: .happy, favorite: true, gratitude: "Laughing until my tummy hurt.", tags: ["Family"],
                 photos: [friends, cuddle, window]),
            Demo(days: 2, hour: 22, minute: 20, title: "A peaceful evening 🌙",
                 body: "Spent some quiet time for myself. Read a book, listened to music and lit a little candle.",
                 mood: .calm, lookingForward: "A picnic in the park this weekend.", tags: ["Self-Care"],
                 photos: [books]),
            Demo(days: 3, hour: 18, minute: 5, title: "Big day at work 💼",
                 body: "I presented my project and it went so well! Everyone clapped and my manager said well done.",
                 mood: .proud, littleWin: "Gave my first presentation.", tags: ["Work", "Proud"]),
            Demo(days: 4, hour: 20, minute: 10, title: "Movie night 🍿",
                 body: "Popcorn, blankets and our favourite film. The cosiest evening with the people I love.",
                 mood: .loved, favorite: true, photos: [cuddle]),
            Demo(days: 5, hour: 16, minute: 40, title: "A slow, rainy day",
                 body: "It rained all afternoon, so I stayed in, made tea and took a long nap.",
                 mood: .tired),
            Demo(days: 6, hour: 11, minute: 12, title: "Sunday brunch 🥞",
                 body: "Pancakes with strawberries and a long walk in the sunshine after.",
                 mood: .excited, littleWin: "Walked 10,000 steps.", photos: [window]),
            Demo(days: 33, hour: 19, minute: 30, title: "Beach day 🏖️",
                 body: "Sand, sea and the prettiest sunset. I want to remember this day forever.",
                 mood: .blissful, favorite: true, lookingForward: "Going back next summer.", photos: [friends]),
            Demo(days: 9, hour: 21, minute: 0, title: "Old notes",
                 body: "A few thoughts I didn't want to keep.", mood: .bored, trashedDaysAgo: 3),
        ]
        for demo in pages {
            let day = today.adding(days: -demo.days)
            let date = Calendar.current.date(bySettingHour: demo.hour, minute: demo.minute, second: 0, of: day) ?? day
            let page = JournalEntry(date: date, title: demo.title, body: demo.body, mood: demo.mood,
                                    littleWin: demo.littleWin)
            page.isFavorite = demo.favorite
            page.gratitude = demo.gratitude
            page.lookingForward = demo.lookingForward
            page.tags = demo.tags
            page.createdAt = date
            page.updatedAt = date
            if let trashed = demo.trashedDaysAgo {
                page.deletedAt = today.adding(days: -trashed)
            }
            context.insert(page)
            for (order, (name, crop)) in demo.photos.enumerated() {
                guard let cropped = UIImage(named: name)?.cgImage?.cropping(to: crop),
                      let data = UIImage(cgImage: cropped).jpegData(compressionQuality: 0.9),
                      let prepared = PhotoProcessor.prepare(data)
                else { continue }
                let photo = JournalPhoto(imageData: prepared.photo, thumbnailData: prepared.thumbnail, order: order)
                context.insert(photo)
                photo.entry = page
            }
        }
    }

    /// A To-Dos sheet to open once the screen appears ("todos-add" → "add").
    @MainActor private static var todosSheet: String?
    /// Open the newest journal page once the journal appears ("journal-page").
    @MainActor private static var journalPage = false
    /// The My Journal Pages tab to show, scrolled to the tabs ("journal-pages": All Pages,
    /// "journal-templates", "journal-feelings", "journal-photos", "journal-trash").
    @MainActor private static var journalShelf: String?
    /// Open Filter on My Journal Pages ("journal-filter").
    @MainActor private static var journalFilter = false
    /// Where the journal page scrolls to ("journal-middle": the writing, "journal-bottom": Save,
    /// "journal-proud": the moods).
    @MainActor private static var journalAnchor: String?
    /// Open "Choose your mood" once the journal appears ("journal-moods").
    @MainActor private static var journalMoods = false
    /// Open the Voice Notes sheet once the journal appears ("journal-voice").
    @MainActor private static var journalVoice = false
    /// Open Add Stickers once the journal appears ("journal-stickers").
    @MainActor private static var journalStickers = false
    /// Scroll Settings to Sounds & Haptics ("settings-sounds").
    @MainActor private static var settingsSounds = false
    /// Scroll Settings to the journal lock ("settings-lock"), or open Lock My Journal
    /// ("settings-lock-choose").
    @MainActor private static var settingsLock = false
    @MainActor private static var settingsLockChoose = false
    /// Scroll Settings to iCloud, with a demo sync status ("settings-icloud").
    @MainActor private static var settingsICloud = false
    /// Scroll Settings to Tips, with Show tips again ("settings-tips").
    @MainActor private static var settingsTips = false
    /// Scroll Settings to Rate My Day ("settings-rate").
    @MainActor private static var settingsRate = false
    /// Show the "Enjoying My Day?" rating card over To-Dos ("rating-card").
    @MainActor private static var ratingCard = false
    /// Open the first template's editor in Templates ("todos-template-edit").
    @MainActor private static var templateEdit = false
    /// Move the last template to the front in Templates, as a press-and-hold drag would
    /// ("todos-template-move").
    @MainActor private static var templateMove = false
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
    static func takeTemplateEdit() -> Bool {
        defer { templateEdit = false }
        return templateEdit
    }

    @MainActor
    static func takeTemplateMove() -> Bool {
        defer { templateMove = false }
        return templateMove
    }

    @MainActor
    static func takeSettingsSounds() -> Bool {
        defer { settingsSounds = false }
        return settingsSounds
    }

    @MainActor
    static func takeSettingsLock() -> Bool {
        defer { settingsLock = false }
        return settingsLock
    }

    @MainActor
    static func takeSettingsLockChoose() -> Bool {
        defer { settingsLockChoose = false }
        return settingsLockChoose
    }

    @MainActor
    static func takeSettingsICloud() -> Bool {
        defer { settingsICloud = false }
        return settingsICloud
    }

    @MainActor
    static func takeSettingsTips() -> Bool {
        defer { settingsTips = false }
        return settingsTips
    }

    @MainActor
    static func takeSettingsRate() -> Bool {
        defer { settingsRate = false }
        return settingsRate
    }

    @MainActor
    static func takeRatingCard() -> Bool {
        defer { ratingCard = false }
        return ratingCard
    }

    @MainActor
    static func takeJournalVoice() -> Bool {
        defer { journalVoice = false }
        return journalVoice
    }

    @MainActor
    static func takeJournalStickers() -> Bool {
        defer { journalStickers = false }
        return journalStickers
    }

    @MainActor
    static func takeJournalMoods() -> Bool {
        defer { journalMoods = false }
        return journalMoods
    }

    @MainActor
    static func takeJournalShelf() -> String? {
        defer { journalShelf = nil }
        return journalShelf
    }

    @MainActor
    static func takeJournalFilter() -> Bool {
        defer { journalFilter = false }
        return journalFilter
    }

    /// Opens My Journal Pages, then today's page on the full page (as Edit Page does).
    @MainActor
    private static func openTodaysPage(_ router: Router, today: Date, context: ModelContext) {
        router.open(.journal)
        let start = today.startOfDay
        let end = start.nextDay
        let pages = (try? context.fetch(FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.date >= start && $0.date < end && $0.deletedAt == nil }))) ?? []
        if let page = pages.first {
            router.homePath.append(AppRoute.editJournalPage(page))
        }
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
        // Only the lock routes lock the journal (a demo pattern of five dots, an L, or the
        // passcode 2580).
        JournalLock.disable()
        // Only "todos-voice-tip" and "todos-quote-tip" show the first-time tips.
        UserDefaults.standard.set(arguments[index + 1] != "todos-voice-tip", forKey: Prefs.didShowVoiceTip)
        UserDefaults.standard.set(arguments[index + 1] != "todos-quote-tip", forKey: Prefs.didShowQuoteTip)
        // Only "todos-photo-tip", "journal-mood-tip" and "journal-prompt-tip" show the newer tips.
        UserDefaults.standard.set(arguments[index + 1] != "todos-photo-tip", forKey: Prefs.didShowPhotoTip)
        UserDefaults.standard.set(arguments[index + 1] != "journal-mood-tip", forKey: Prefs.didShowMoodTip)
        UserDefaults.standard.set(arguments[index + 1] != "journal-prompt-tip", forKey: Prefs.didShowPromptTip)

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
        case "journal", "journal-opening":
            router.open(.journal)
        case "journal-page":
            journalPage = true
            router.open(.journal)
        case "journal-pages", "journal-templates", "journal-feelings", "journal-photos", "journal-trash":
            let name = arguments[index + 1].dropFirst("journal-".count)
            journalShelf = name == "pages" ? JournalShelf.all.rawValue : String(name)
            router.open(.journal)
        case "journal-filter":
            journalShelf = JournalShelf.all.rawValue
            journalFilter = true
            router.open(.journal)
        case "journal-new", "journal-mood-tip", "journal-prompt-tip":
            router.open(.journal)
            router.homePath.append(AppRoute.newJournalPage(nil))
        case "journal-middle":
            journalAnchor = "write"
            openTodaysPage(router, today: today, context: context)
        case "journal-bottom":
            journalAnchor = "save"
            openTodaysPage(router, today: today, context: context)
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
            openTodaysPage(router, today: today, context: context)
        case "journal-moods":
            journalMoods = true
            openTodaysPage(router, today: today, context: context)
        case "journal-voice":
            journalVoice = true
            openTodaysPage(router, today: today, context: context)
        case "journal-stickers":
            journalStickers = true
            openTodaysPage(router, today: today, context: context)
        case "calendar": router.tab = .calendar
        case "calendar-tomorrow":
            calendarDayOffset = 1
            router.tab = .calendar
        case "insights": router.tab = .insights
        case "settings": router.tab = .settings
        case "settings-sounds":
            settingsSounds = true
            router.tab = .settings
        case "journal-lock-pattern":
            JournalLock.enable(.pattern, secret: "0-3-6-7-8")
            router.open(.journal)
        case "journal-lock-passcode":
            JournalLock.enable(.passcode, secret: "2580")
            router.open(.journal)
        case "settings-lock":
            JournalLock.enable(.pattern, secret: "0-3-6-7-8")
            settingsLock = true
            router.tab = .settings
        case "settings-lock-choose":
            settingsLockChoose = true
            router.tab = .settings
        case "settings-icloud":
            settingsICloud = true
            router.tab = .settings
        case "settings-tips":
            settingsTips = true
            router.tab = .settings
        case "settings-rate":
            settingsRate = true
            router.tab = .settings
        case "rating-card":
            ratingCard = true
            router.open(.todos(today))
        case "newtask": router.sheet = .newTask(today)
        case "newjournal": router.sheet = .newJournal(.now)
        case let route where route.hasPrefix("todos-"):
            todosSheet = String(route.dropFirst("todos-".count))
            holdsTickPop = route == "todos-hearts"
            templateEdit = route == "todos-template-edit"
            templateMove = route == "todos-template-move"
            router.open(.todos(today))
        default: break
        }
    }
}
#endif
