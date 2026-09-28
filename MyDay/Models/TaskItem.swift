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
    var sortOrder: Double = 0
    /// Marked with the ☆ in its row; important to-dos are listed first.
    var isImportant: Bool = false
    /// A category the person added (nil for the five built in). `categoryRaw` then stays
    /// "personal", which is what the to-do shows if that category is deleted.
    var customCategory: CustomCategory?
    /// Optional photo the task is about (max 1600 px), stored outside the database file.
    @Attribute(.externalStorage) var photoData: Data?
    var photoThumbnail: Data?
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
        self.sortOrder = Date().timeIntervalSinceReferenceDate
        self.createdAt = Date()
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

enum TaskCategory: String, CaseIterable, Identifiable, Codable {
    case personal, work, health, learning, shopping

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
        }
    }

    var symbol: String {
        switch self {
        case .personal: "heart.fill"
        case .work: "laptopcomputer"
        case .health: "leaf.fill"
        case .learning: "book.fill"
        case .shopping: "cart.fill"
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
