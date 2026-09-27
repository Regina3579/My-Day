import Foundation

/// Values for a to-do that is not saved yet — filled in by Voice Add, a photo
/// or a template, then shown to the person to confirm.
struct TaskDraft {
    var title = ""
    var notes = ""
    var category: TaskCategory = .personal
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

    /// Builds the to-do. The caller inserts it and syncs its reminder.
    func makeTask() -> TaskItem {
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
        return task
    }
}
