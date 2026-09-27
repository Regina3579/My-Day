import Foundation

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    var nextDay: Date { adding(days: 1) }

    var startOfMonth: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: self)) ?? startOfDay
    }

    var isToday: Bool { Calendar.current.isDateInToday(self) }

    /// Start of the day `days` days away.
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: startOfDay) ?? startOfDay
    }

    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// This calendar day, at the clock time of `time`.
    func atTime(of time: Date) -> Date {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: parts.hour ?? 9, minute: parts.minute ?? 0, second: 0, of: self) ?? self
    }

    /// A stable number for the calendar day, used to rotate daily content.
    var dayNumber: Int {
        Calendar.current.ordinality(of: .day, in: .era, for: self) ?? 0
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

enum Greeting {
    static func text(for date: Date = .now, name: String) -> String {
        let base: String
        switch Calendar.current.component(.hour, from: date) {
        case 5..<12: base = "Good morning"
        case 12..<17: base = "Good afternoon"
        case 17..<22: base = "Good evening"
        default: base = "Sweet dreams"
        }
        let cleanName = name.trimmed
        return cleanName.isEmpty ? "\(base)! 💖" : "\(base), \(cleanName)! 💖"
    }
}

/// The three-line message on the home screen. It changes every day.
enum DailyQuotes {
    static let all: [[String]] = [
        ["A new day", "A fresh start", "You got this! 💕"],
        ["Small steps", "Big dreams", "Keep going! 🌸"],
        ["Be kind", "Be brave", "Be you! 💖"],
        ["Breathe in", "Smile wide", "Shine bright! ✨"],
        ["Dream it", "Plan it", "Do it! ⭐"],
        ["One step", "at a time", "You're doing great! 💕"],
        ["Bloom where", "you are", "planted 🌷"]
    ]

    static func lines(for date: Date, offset: Int = 0) -> [String] {
        let index = (date.dayNumber + offset) % all.count
        return all[(index + all.count) % all.count]
    }
}

enum FocusQuotes {
    private static let quotes = [
        "Small steps every day add up to big dreams. 🌸",
        "You don't have to do everything — just the things that matter. ⭐",
        "Progress, not perfection. 💪",
        "Do what matters most, then rest with a happy heart. 💛",
        "Your focus decides your day. ✨",
        "One thing at a time. You've got this! 💖"
    ]

    static func quote(for date: Date) -> String {
        quotes[date.dayNumber % quotes.count]
    }
}
