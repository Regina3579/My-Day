import Foundation
import UserNotifications

/// Local notifications: one-off to-do reminders and the two daily nudges.
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

    /// Asks for permission the first time; afterwards returns the saved answer.
    @discardableResult
    static func requestPermission() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
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

    // MARK: To-do reminders

    private static func identifier(for taskID: UUID) -> String { "task-\(taskID.uuidString)" }

    /// Schedules the reminder that belongs to `task`, or removes it when it is
    /// done, has no reminder, or the time has passed.
    static func sync(_ task: TaskItem) {
        let id = identifier(for: task.uuid)
        let title = task.title
        let fireDate = task.reminderAt
        let isDone = task.isDone

        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard let fireDate, !isDone, fireDate > .now else { return }

        Task {
            guard await requestPermission() else { return }
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

    // MARK: Daily reminders

    static func scheduleDaily(_ kind: Daily, enabled: Bool, secondsFromMidnight: Double) {
        center.removePendingNotificationRequests(withIdentifiers: [kind.rawValue])
        guard enabled else { return }

        Task {
            guard await requestPermission() else { return }
            // The switch may have been turned off while we waited for permission.
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
