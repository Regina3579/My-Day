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
        let id = UUID()
        self.id = id
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
        get { TaskCategory(rawValue: categoryRaw) ?? .personal }
        set { categoryRaw = newValue.rawValue }
    }

    var repeatOption: RepeatOption {
        get { RepeatOption(rawValue: repeatRaw) ?? .never }
        set { repeatRaw = newValue.rawValue }
    }

    /// The reminder moment, only while reminders are switched on for this task.
    var activeReminder: Date? { reminderEnabled ? reminderDate : nil }
}

enum TaskCategory: String, CaseIterable, Identifiable, Codable {
    case personal, work, study, home, health, shopping, other

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .personal: "heart.fill"
        case .work: "briefcase.fill"
        case .study: "book.fill"
        case .home: "house.fill"
        case .health: "leaf.fill"
        case .shopping: "bag.fill"
        case .other: "sparkles"
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
