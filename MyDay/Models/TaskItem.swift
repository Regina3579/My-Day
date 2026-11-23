import Foundation
import SwiftData

/// A to-do. (Named `TaskItem` because `Task` is Swift's concurrency type.)
@Model
final class TaskItem {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var categoryRaw: String = "personal"
    /// Start of the day the task belongs to.
    var date: Date = Date()
    /// Optional time of day, stored on the same calendar day as `date`.
    var time: Date?
    var reminderEnabled: Bool = false
    var reminderDate: Date?
    var repeatRaw: String = "never"
    var isCompleted: Bool = false
    var completedAt: Date?
    /// Shared by every occurrence of a repeating task.
    var seriesID: UUID = UUID()
    /// The day's list runs from the lowest value to the highest. A new to-do takes minus the
    /// time it was added, so it comes first, above the older ones (dragging a row renumbers
    /// the day's to-dos from 0, which still keeps later new ones on top).
    var sortOrder: Double = 0
    /// Marked with the ☆ in its row; important to-dos are listed first.
    var isImportant: Bool = false
    /// A category the person added (nil for the five built in). `categoryRaw` then stays
    /// "personal", which is what the to-do shows if that category is deleted.
    var customCategory: CustomCategory?
    /// Optional photo the task is about (max 1600 px), stored outside the database file.
    @Attribute(.externalStorage) var photoData: Data?
    var photoThumbnail: Data?
    /// Smaller steps inside the to-do (＋ Add Step), in order.
    var steps: [String] = []
    /// Which of `steps` are ticked done, by position (a missing value is not done).
    var stepsDone: [Bool] = []
    var createdAt: Date = Date()

    init(
        title: String,
        notes: String = "",
        category: TaskCategory = .personal,
        date: Date,
        time: Date? = nil,
        reminderEnabled: Bool = false,
        reminderDate: Date? = nil,
        repeatOption: RepeatOption = .never,
        seriesID: UUID = UUID()
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.categoryRaw = category.rawValue
        self.date = Calendar.current.startOfDay(for: date)
        self.time = time
        self.reminderEnabled = reminderEnabled
        self.reminderDate = reminderEnabled ? reminderDate : nil
        self.repeatRaw = repeatOption.rawValue
        self.seriesID = seriesID
        self.sortOrder = TaskItem.newestFirstOrder()
        self.createdAt = Date()
    }

    /// A sort order that puts a to-do added now above every to-do already in the list.
    static func newestFirstOrder(at date: Date = Date()) -> Double {
        -date.timeIntervalSinceReferenceDate
    }

    var category: TaskCategory {
        get { TaskCategory(storedValue: categoryRaw) }
        set { categoryRaw = newValue.rawValue }
    }

    /// The category as shown and chosen on screen: built in or added by the person.
    var choice: CategoryChoice {
        get { customCategory.map(CategoryChoice.custom) ?? .builtIn(category) }
        set {
            switch newValue {
            case .builtIn(let builtIn):
                category = builtIn
                customCategory = nil
            case .custom(let custom):
                category = .personal
                customCategory = custom
            }
        }
    }

    var repeatOption: RepeatOption {
        get { RepeatOption(rawValue: repeatRaw) ?? .never }
        set { repeatRaw = newValue.rawValue }
    }

    /// How many steps are ticked done.
    var stepsDoneCount: Int {
        steps.indices.filter { stepsDone.indices.contains($0) && stepsDone[$0] }.count
    }

    /// The reminder moment, only while reminders are switched on for this task.
    var activeReminder: Date? { reminderEnabled ? reminderDate : nil }
}

/// A to-do's category: one of the five built in, or one the person added.
enum CategoryChoice: Hashable {
    case builtIn(TaskCategory)
    case custom(CustomCategory)

    /// A stable text key (for sheet identity).
    var key: String {
        switch self {
        case .builtIn(let builtIn): builtIn.rawValue
        case .custom(let custom): "custom-\(custom.id.uuidString)"
        }
    }
}

/// The order of the categories on the To-Dos screen and in every category picker. Until the
/// person reorders them it is Personal · Work · Health · Learning · Shopping, the categories
/// they added (oldest first), then Entertainment · Hobbies · Finance · Appointments. Deleted
/// built-in categories are left out; a category added after reordering goes at the end.
enum CategoryOrder {
    static func arrange(customs: [CustomCategory], hidden: String, order: String) -> [CategoryChoice] {
        let standard = TaskCategory.visibleCore(hiding: hidden).map(CategoryChoice.builtIn)
            + customs.map(CategoryChoice.custom)
            + TaskCategory.visibleLater(hiding: hidden).map(CategoryChoice.builtIn)
        let saved = order.split(separator: ",").map(String.init)
        guard !saved.isEmpty else { return standard }
        var rank: [String: Int] = [:]
        for (index, key) in saved.enumerated() where rank[key] == nil {
            rank[key] = index
        }
        return standard.enumerated()
            .sorted { (rank[$0.element.key] ?? Int.max, $0.offset) < (rank[$1.element.key] ?? Int.max, $1.offset) }
            .map(\.element)
    }

    /// What `Prefs.categoryOrder` keeps for this order.
    static func stored(_ choices: [CategoryChoice]) -> String {
        choices.map(\.key).joined(separator: ",")
    }
}

enum TaskCategory: String, CaseIterable, Identifiable, Codable {
    case personal, work, health, learning, shopping
    case entertainment, hobbies, finance, appointments

    /// The first five, then (after the categories people add) the four added later.
    static let core: [TaskCategory] = [.personal, .work, .health, .learning, .shopping]
    static let later: [TaskCategory] = [.entertainment, .hobbies, .finance, .appointments]

    /// Every built-in category but Personal can be deleted (hidden); Personal is where the
    /// to-dos of a deleted category go.
    var canDelete: Bool { self != .personal }

    /// The built-in categories the person deleted, from `Prefs.hiddenCategories`.
    static func hidden(in stored: String) -> Set<TaskCategory> {
        Set(stored.split(separator: ",").compactMap { TaskCategory(rawValue: String($0)) })
    }

    /// `stored` with `category` deleted too.
    static func hiding(_ category: TaskCategory, in stored: String) -> String {
        let all = hidden(in: stored).union([category])
        return allCases.filter(all.contains).map(\.rawValue).joined(separator: ",")
    }

    /// The first five and the four added later, without the ones the person deleted.
    static func visibleCore(hiding stored: String) -> [TaskCategory] {
        let gone = hidden(in: stored)
        return core.filter { !gone.contains($0) }
    }

    static func visibleLater(hiding stored: String) -> [TaskCategory] {
        let gone = hidden(in: stored)
        return later.filter { !gone.contains($0) }
    }

    /// Reads a stored value, including the names used by earlier versions.
    init(storedValue: String) {
        switch storedValue {
        case "study": self = .learning
        case "home", "other": self = .personal
        default: self = TaskCategory(rawValue: storedValue) ?? .personal
        }
    }

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var emoji: String {
        switch self {
        case .personal: "🌸"
        case .work: "💻"
        case .health: "🌿"
        case .learning: "📖"
        case .shopping: "🛒"
        case .entertainment: "🍿"
        case .hobbies: "🎨"
        case .finance: "💰"
        case .appointments: "📅"
        }
    }

    var symbol: String {
        switch self {
        case .personal: "heart.fill"
        case .work: "laptopcomputer"
        case .health: "leaf.fill"
        case .learning: "book.fill"
        case .shopping: "cart.fill"
        case .entertainment: "popcorn.fill"
        case .hobbies: "paintpalette.fill"
        case .finance: "dollarsign.circle.fill"
        case .appointments: "calendar.badge.clock"
        }
    }
}

enum RepeatOption: String, CaseIterable, Identifiable, Codable {
    case never, daily, weekdays, weekly, monthly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .never: "Never"
        case .daily: "Every day"
        case .weekdays: "Weekdays"
        case .weekly: "Every week"
        case .monthly: "Every month"
        }
    }

    /// The next occurrence after `date`, or `nil` for tasks that do not repeat.
    func nextDate(after date: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .never:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .weekdays:
            var next = calendar.date(byAdding: .day, value: 1, to: date)
            while let candidate = next, calendar.isDateInWeekend(candidate) {
                next = calendar.date(byAdding: .day, value: 1, to: candidate)
            }
            return next
        }
    }
}
