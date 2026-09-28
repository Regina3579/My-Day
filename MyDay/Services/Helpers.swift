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
    var dayNumber: Int { dayNumber(in: .current) }

    /// Days from 1 January of year 1 to this date as it reads in `calendar`'s time zone.
    /// Only the year, month and day count, so the same date gives the same number in every
    /// time zone, and the number changes exactly at local midnight.
    func dayNumber(in calendar: Calendar) -> Int {
        var local = Calendar(identifier: .gregorian)
        local.timeZone = calendar.timeZone
        let day = local.dateComponents([.year, .month, .day], from: self)
        let noon = DateComponents(year: day.year, month: day.month, day: day.day, hour: 12)
        guard let date = Self.utcCalendar.date(from: noon) else { return 0 }
        let daysSince2001 = Int((date.timeIntervalSinceReferenceDate / 86_400).rounded(.down))
        return daysSince2001 + Self.daysFromYear1To2001
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// 1 Jan 0001 to 1 Jan 2001 in the (proleptic) Gregorian calendar.
    private static let daysFromYear1To2001 = 730_485
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

/// The gentle line in the To-Dos header. It changes every day.
enum TodoQuotes {
    private static let quotes = [
        "Small steps still move you forward.",
        "Little by little, a little becomes a lot.",
        "Done is better than perfect.",
        "One task at a time — you've got this.",
        "Start where you are. Do what you can.",
        "Progress, not perfection.",
        "Your future self will thank you."
    ]

    static func quote(for date: Date) -> String {
        quotes[date.dayNumber % quotes.count]
    }
}
