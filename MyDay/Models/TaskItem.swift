import Foundation
import SwiftData

/// A to-do. Starring a to-do makes it one of the day's priorities.
@Model
final class TaskItem {
    /// Stable identifier used for notification requests.
    var uuid: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    /// Start of the day this to-do belongs to.
    var day: Date = Date()
    var isDone: Bool = false
    var completedAt: Date?
    var isPriority: Bool = false
    var reminderAt: Date?
    var sortIndex: Double = 0
    var createdAt: Date = Date()

    init(title: String, notes: String = "", day: Date, isPriority: Bool = false, reminderAt: Date? = nil) {
        self.uuid = UUID()
        self.title = title
        self.notes = notes
        self.day = Calendar.current.startOfDay(for: day)
        self.isPriority = isPriority
        self.reminderAt = reminderAt
        self.sortIndex = Date().timeIntervalSinceReferenceDate
        self.createdAt = Date()
    }

    func toggleDone() {
        isDone.toggle()
        completedAt = isDone ? Date() : nil
    }
}
