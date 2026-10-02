import Foundation
import SwiftData
import UserNotifications

/// Local notifications for to-do reminders and the two daily nudges.
///
/// Permission is requested only from `requestPermission()`, which the UI calls
/// the first time the person switches a reminder on — never at launch.
enum ReminderCenter {
    private static var center: UNUserNotificationCenter { .current() }

    enum Daily: String {
        case morning = "daily-morning"
        case evening = "daily-evening"

        var title: String {
            switch self {
            case .morning: "Good morning! ☀️"
            case .evening: "Time for your journal 📔"
            }
        }

        var body: String {
            switch self {
            case .morning: "Plan your to-dos and pick today's priority in My Day."
            case .evening: "Capture today's thoughts and beautiful moments."
            }
        }

        var enabledKey: String {
            switch self {
            case .morning: Prefs.morningOn
            case .evening: Prefs.eveningOn
            }
        }
    }

    /// Shows the system prompt if the person has not decided yet.
    /// Returns whether notifications may be delivered.
    @discardableResult
    static func requestPermission() async -> Bool {
        switch await authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    private static func isAllowed() async -> Bool {
        switch await authorizationStatus() {
        case .authorized, .provisional, .ephemeral: true
        default: false
        }
    }

    // MARK: To-do reminders

    private static func identifier(for taskID: UUID) -> String { "task-\(taskID.uuidString)" }

    /// Schedules the reminder that belongs to `task`, or removes it when it is
    /// done, switched off or already in the past. Never shows a permission prompt.
    static func sync(_ task: TaskItem) {
        let id = identifier(for: task.id)
        let title = task.title
        let fireDate = task.isCompleted ? nil : task.activeReminder

        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard let fireDate, fireDate > .now else { return }

        Task {
            guard await isAllowed() else { return }
            let content = UNMutableNotificationContent()
            content.title = "My Day 💖"
            content.body = title
            content.sound = .default
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    static func cancel(taskID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier(for: taskID)])
    }

    /// Schedules the reminder of every to-do (to-dos can come from iCloud) and removes the
    /// reminders whose to-do is gone or no longer has one.
    @MainActor
    static func syncAll(in context: ModelContext) {
        let withReminders = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.reminderEnabled == true })
        ((try? context.fetch(withReminders)) ?? []).forEach(sync)
        Task { @MainActor in
            let pending = await center.pendingNotificationRequests().map(\.identifier)
            // Looked up after the wait, so a to-do added meanwhile keeps its reminder.
            let current = Set(((try? context.fetch(withReminders)) ?? []).map { identifier(for: $0.id) })
            let stale = pending.filter { $0.hasPrefix("task-") && !current.contains($0) }
            center.removePendingNotificationRequests(withIdentifiers: stale)
        }
    }

    // MARK: Daily reminders

    static func scheduleDaily(_ kind: Daily, enabled: Bool, secondsFromMidnight: Double) {
        center.removePendingNotificationRequests(withIdentifiers: [kind.rawValue])
        guard enabled else { return }

        Task {
            guard await isAllowed() else { return }
            // The switch may have been turned off in the meantime.
            guard UserDefaults.standard.bool(forKey: kind.enabledKey) else { return }

            let content = UNMutableNotificationContent()
            content.title = kind.title
            content.body = kind.body
            content.sound = .default

            let totalMinutes = Int(secondsFromMidnight) / 60
            var parts = DateComponents()
            parts.hour = totalMinutes / 60
            parts.minute = totalMinutes % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
            try? await center.add(UNNotificationRequest(identifier: kind.rawValue, content: content, trigger: trigger))
        }
    }
}
