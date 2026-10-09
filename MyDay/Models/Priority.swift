import Foundation
import SwiftData

/// One of the few things that matter most on a given day.
@Model
final class Priority {
    var id: UUID = UUID()
    var title: String = ""
    /// Start of the day the priority belongs to.
    var date: Date = Date()
    /// Position in the day's list, starting at 0.
    var order: Int = 0
    var isCompleted: Bool = false
    var completedAt: Date?
    var createdAt: Date = Date()

    init(title: String, date: Date, order: Int) {
        self.id = UUID()
        self.title = title
        self.date = Calendar.current.startOfDay(for: date)
        self.order = order
        self.createdAt = Date()
    }

    func toggleCompleted() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}
