import Foundation
import SwiftData

/// Values for a to-do that is not saved yet — filled in by Voice Add, a photo
/// or a template, then shown to the person to confirm.
struct TaskDraft {
    var title = ""
    var notes = ""
    var category: TaskCategory = .personal
    /// A category the person added; when set, it is used instead of `category`.
    var customCategory: CustomCategory?
    /// Start of the day the to-do belongs to.
    var day: Date
    /// Clock time on `day`, if any.
    var time: Date?
    var reminderEnabled = false
    var reminderDate: Date?
    var repeatOption: RepeatOption = .never
    var photo: PhotoProcessor.Output?

    init(day: Date, category: TaskCategory = .personal) {
        self.day = day.startOfDay
        self.category = category
    }

    init(day: Date, choice: CategoryChoice) {
        self.day = day.startOfDay
        self.choice = choice
    }

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

    /// Builds the to-do and adds it to `context`. The caller syncs its reminder.
    func insertTask(into context: ModelContext) -> TaskItem {
        let task = TaskItem(
            title: title.trimmed,
            notes: notes.trimmed,
            category: category,
            date: day,
            time: time.map { day.atTime(of: $0) },
            reminderEnabled: reminderEnabled,
            reminderDate: reminderDate,
            repeatOption: repeatOption
        )
        task.photoData = photo?.photo
        task.photoThumbnail = photo?.thumbnail
        context.insert(task)
        // Link the category once the to-do is in the store.
        task.customCategory = customCategory
        return task
    }
}
