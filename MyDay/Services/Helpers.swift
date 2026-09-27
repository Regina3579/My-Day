import Foundation

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    var nextDay: Date { adding(days: 1) }

    var startOfMonth: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: self)) ?? startOfDay
    }

    var isToday: Bool { Calendar.current.isDateInToday(self) }

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

enum Quotes {
    private static let focusQuotes = [
        "Small steps every day add up to big dreams. 🌸",
        "You don't have to do everything — just the things that matter. ⭐",
        "Progress, not perfection. 💪",
        "Do what matters most, then rest with a happy heart. 💛",
        "Your focus decides your day. ✨",
        "One thing at a time. You've got this! 💖"
    ]

    /// A quote that stays the same for the whole day.
    static func focus(for day: Date) -> String {
        let index = Calendar.current.ordinality(of: .day, in: .era, for: day) ?? 0
        return focusQuotes[index % focusQuotes.count]
    }
}
