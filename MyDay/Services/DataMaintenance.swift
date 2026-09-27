import Foundation
import SwiftData
import UIKit

/// Everyday data chores shared by several screens.
@MainActor
enum TaskActions {
    /// Ticks a to-do on or off. Finishing a repeating to-do creates its next occurrence.
    static func toggle(_ task: TaskItem, in context: ModelContext) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
        ReminderCenter.sync(task)
        if task.isCompleted {
            scheduleNextOccurrence(of: task, in: context)
            Haptics.success()
        } else {
            Haptics.tap()
        }
    }

    static func delete(_ task: TaskItem, in context: ModelContext) {
        ReminderCenter.cancel(taskID: task.id)
        context.delete(task)
    }

    /// Turns a to-do into one of the day's priorities (added at the end of the list).
    static func moveToPriority(_ task: TaskItem, in context: ModelContext) {
        let start = task.date.startOfDay
        let end = start.nextDay
        let sameDay = FetchDescriptor<Priority>(predicate: #Predicate { $0.date >= start && $0.date < end })
        let nextOrder = (((try? context.fetch(sameDay)) ?? []).map(\.order).max() ?? -1) + 1
        context.insert(Priority(title: task.title, date: start, order: nextOrder))
        delete(task, in: context)
    }

    /// Adds one to-do per title to `day`, after the ones already there.
    static func add(titles: [String], category: TaskCategory, to day: Date, in context: ModelContext) {
        let base = Date().timeIntervalSinceReferenceDate
        for (index, title) in titles.enumerated() {
            let task = TaskItem(title: title, category: category, date: day)
            task.sortOrder = base + Double(index)
            context.insert(task)
        }
    }

    private static func scheduleNextOccurrence(of task: TaskItem, in context: ModelContext) {
        let rule = task.repeatOption
        guard let nextDay = rule.nextDate(after: task.date) else { return }
        let start = nextDay.startOfDay
        let end = start.nextDay
        let series = task.seriesID
        let existing = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.seriesID == series && $0.date >= start && $0.date < end }
        )
        guard ((try? context.fetchCount(existing)) ?? 0) == 0 else { return }

        let next = TaskItem(
            title: task.title,
            notes: task.notes,
            category: task.category,
            date: start,
            time: task.time.map { start.atTime(of: $0) },
            reminderEnabled: task.reminderEnabled,
            reminderDate: task.reminderDate.flatMap { rule.nextDate(after: $0) },
            repeatOption: rule,
            seriesID: series
        )
        context.insert(next)
        ReminderCenter.sync(next)
    }
}

/// Moves unfinished to-dos and priorities from earlier days onto today.
enum DayRollover {
    @MainActor
    static func carryOver(into today: Date, context: ModelContext) {
        let start = today.startOfDay
        let now = Date()

        let staleTasks = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.isCompleted == false && $0.date < start }
        )
        for task in (try? context.fetch(staleTasks)) ?? [] {
            task.date = start
            task.time = task.time.map { start.atTime(of: $0) }
            if task.reminderEnabled, let reminder = task.reminderDate, reminder < now {
                if task.repeatOption == .never {
                    task.reminderEnabled = false
                } else {
                    task.reminderDate = nextFutureReminder(from: reminder, rule: task.repeatOption, now: now)
                    ReminderCenter.sync(task)
                }
            }
        }

        let stalePriorities = FetchDescriptor<Priority>(
            predicate: #Predicate { $0.isCompleted == false && $0.date < start }
        )
        let moving = (try? context.fetch(stalePriorities)) ?? []
        guard !moving.isEmpty else { return }
        let end = start.nextDay
        let todays = FetchDescriptor<Priority>(predicate: #Predicate { $0.date >= start && $0.date < end })
        var nextOrder = ((try? context.fetch(todays)) ?? []).map(\.order).max().map { $0 + 1 } ?? 0
        for priority in moving.sorted(by: { ($0.date, $0.order) < ($1.date, $1.order) }) {
            priority.date = start
            priority.order = nextOrder
            nextOrder += 1
        }
    }

    private static func nextFutureReminder(from date: Date, rule: RepeatOption, now: Date) -> Date? {
        var candidate: Date? = date
        while let current = candidate, current <= now {
            candidate = rule.nextDate(after: current)
        }
        return candidate
    }
}

/// A friendly first page so a brand-new app never looks empty.
enum WelcomeContent {
    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Prefs.didSeedWelcome) else { return }
        defaults.set(true, forKey: Prefs.didSeedWelcome)

        let existing = (try? context.fetchCount(FetchDescriptor<TaskItem>())) ?? 0
        guard existing == 0 else { return }

        let today = Date()
        context.insert(TaskItem(title: "Tap the circle to finish a to-do ✓", category: .personal, date: today))
        context.insert(TaskItem(title: "Drink 8 glasses of water 💧", category: .health, date: today,
                                repeatOption: .daily))
        context.insert(TaskItem(title: "Write my first journal page 📔", category: .personal, date: today))
        context.insert(TaskItem(title: "Buy fresh flowers 🌷", category: .shopping, date: today))
        context.insert(Priority(title: "Do the one thing that matters most ⭐", date: today, order: 0))
        context.insert(JournalEntry(
            date: today,
            title: "Welcome to My Day 💖",
            body: "This is my little place for plans, priorities and beautiful moments.\n\nA new day, a fresh start — I've got this!",
            mood: .happy
        ))
    }
}

/// Shrinks picked photos so the journal stays light.
enum PhotoProcessor {
    struct Output: Sendable {
        let photo: Data
        let thumbnail: Data
    }

    static func prepare(_ data: Data) -> Output? {
        guard let image = UIImage(data: data),
              let photo = resized(image, maxSide: 1600).jpegData(compressionQuality: 0.82),
              let thumbnail = resized(image, maxSide: 360).jpegData(compressionQuality: 0.75)
        else { return nil }
        return Output(photo: photo, thumbnail: thumbnail)
    }

    /// Redraws the image upright and no larger than `maxSide` pixels.
    private static func resized(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let factor = min(1, maxSide / max(pixelWidth, pixelHeight))
        let target = CGSize(width: (pixelWidth * factor).rounded(), height: (pixelHeight * factor).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
