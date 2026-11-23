import Foundation
import SwiftUI

/// The numbers behind a Goal Report (a week, a month or a year): the goals on the person's
/// My Goals list (and any others ticked in the period), and on which days each was ticked on a
/// journal page.
struct GoalReport {
    enum Span: String, CaseIterable, Identifiable {
        case week = "Week", month = "Month", year = "Year"
        var id: String { rawValue }
    }

    let span: Span
    let start: Date
    /// The day after the period.
    let end: Date
    /// The period's days up to today (the whole period once it is over).
    let days: [Date]
    let goals: [String]
    /// Goal (lowercased) → the days it was ticked.
    let ticks: [String: Set<Date>]
    /// The journal page of each day.
    let pages: [Date: JournalEntry]

    /// A goal met on at least this share of the days counts as Completed.
    static let completedShare = 0.7

    init(span: Span, containing day: Date, entries: [JournalEntry], goalList: [String], today: Date) {
        let calendar = Calendar.current
        let anchor = calendar.startOfDay(for: day)
        let interval: DateInterval?
        switch span {
        case .week: interval = calendar.dateInterval(of: .weekOfYear, for: anchor)
        case .month: interval = calendar.dateInterval(of: .month, for: anchor)
        case .year: interval = calendar.dateInterval(of: .year, for: anchor)
        }
        let start = interval?.start ?? anchor
        let end = interval?.end ?? anchor.adding(days: 1)
        self.span = span
        self.start = start
        self.end = end
        let last = min(end, calendar.startOfDay(for: today).adding(days: 1))
        var days: [Date] = []
        var cursor = start
        while cursor < last {
            days.append(cursor)
            cursor = cursor.adding(days: 1)
        }
        self.days = days

        var pages: [Date: JournalEntry] = [:]
        var ticks: [String: Set<Date>] = [:]
        var names: [String] = goalList
        for entry in entries where !entry.isInTrash && entry.date >= start && entry.date < end {
            let day = calendar.startOfDay(for: entry.date)
            pages[day] = entry
            for goal in entry.goals {
                let key = goal.lowercased()
                ticks[key, default: []].insert(day)
                if !names.contains(where: { $0.lowercased() == key }) { names.append(goal) }
            }
        }
        self.pages = pages
        self.ticks = ticks
        self.goals = names
    }

    // MARK: Totals

    func met(_ goal: String) -> Int { ticks[goal.lowercased()]?.count ?? 0 }

    private func share(_ goal: String) -> Double {
        days.isEmpty ? 0 : Double(met(goal)) / Double(days.count)
    }

    var totalGoals: Int { goals.count }
    var completed: Int { goals.filter { share($0) >= Self.completedShare }.count }
    var inProgress: Int { goals.filter { share($0) > 0 && share($0) < Self.completedShare }.count }
    var missed: Int { goals.filter { met($0) == 0 }.count }

    /// Every tick in the period, and how many there could have been.
    var totalTicks: Int { goals.reduce(0) { $0 + met($1) } }
    var possibleTicks: Int { goals.count * days.count }
    var percent: Double { possibleTicks == 0 ? 0 : Double(totalTicks) / Double(possibleTicks) }

    func fraction(_ count: Int) -> Double { totalGoals == 0 ? 0 : Double(count) / Double(totalGoals) }

    // MARK: Days, weeks, months

    /// How many goals were ticked on `day`.
    func ticked(on day: Date) -> Int { pages[day]?.goals.count ?? 0 }

    func dayShare(_ day: Date) -> Double {
        goals.isEmpty ? 0 : min(1, Double(ticked(on: day)) / Double(goals.count))
    }

    /// The period's weeks (for a month): their days and how much was done.
    var weeks: [(start: Date, days: [Date], share: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allDays) { calendar.dateInterval(of: .weekOfYear, for: $0)?.start ?? $0 }
        return grouped.keys.sorted().map { week in
            let days = grouped[week] ?? []
            let elapsed = days.filter { $0 <= (self.days.last ?? .distantPast) }
            let share = elapsed.isEmpty ? 0 : elapsed.map(dayShare).reduce(0, +) / Double(elapsed.count)
            return (week, days, share)
        }
    }

    /// The period's months (for a year) and how much was done in each.
    var months: [(month: Date, share: Double, hasDays: Bool)] {
        let calendar = Calendar.current
        return (0..<12).compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: offset, to: start) else { return nil }
            let elapsed = days.filter { calendar.isDate($0, equalTo: month, toGranularity: .month) }
            let share = elapsed.isEmpty ? 0 : elapsed.map(dayShare).reduce(0, +) / Double(elapsed.count)
            return (month, share, !elapsed.isEmpty)
        }
    }

    /// Every day of the period, today's future included (for the month's week columns).
    var allDays: [Date] {
        var result: [Date] = []
        var cursor = start
        while cursor < end {
            result.append(cursor)
            cursor = cursor.adding(days: 1)
        }
        return result
    }

    // MARK: Highlights

    /// The goals ticked most, with how often.
    var topGoals: [(goal: String, met: Int)] {
        goals.map { ($0, met($0)) }.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }.prefix(3).map { ($0.0, $0.1) }
    }

    /// The most days in a row with at least one goal ticked.
    var bestStreak: Int {
        var best = 0
        var run = 0
        for day in days {
            run = ticked(on: day) > 0 ? run + 1 : 0
            best = max(best, run)
        }
        return best
    }

    var pagesWritten: Int { pages.count }

    /// Days "Drink Water" (or the like) was ticked.
    var waterDays: Int {
        goals.filter { $0.lowercased().contains("water") }.map(met).max() ?? 0
    }

    /// The goals by kind, for the donut.
    var categories: [(category: GoalCategory, count: Int)] {
        let counts = Dictionary(grouping: goals, by: GoalCategory.of).mapValues(\.count)
        return GoalCategory.allCases.compactMap { category in
            counts[category].map { (category, $0) }
        }
    }
}

/// What a goal is about, from its words.
enum GoalCategory: String, CaseIterable, Identifiable {
    case health = "Health", selfCare = "Self Care", productivity = "Productivity"
    case personal = "Personal", learning = "Learning", travel = "Travel"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .health: Color(hex: 0xF77FB4)
        case .selfCare: Color(hex: 0xF29BD8)
        case .productivity: Color(hex: 0xB18CF0)
        case .personal: Color(hex: 0xFFD978)
        case .learning: Color(hex: 0x8EDB8A)
        case .travel: Color(hex: 0x7FC2F5)
        }
    }

    var symbol: String {
        switch self {
        case .health: "dumbbell.fill"
        case .selfCare: "sparkles"
        case .productivity: "laptopcomputer"
        case .personal: "house.fill"
        case .learning: "graduationcap.fill"
        case .travel: "airplane"
        }
    }

    static func of(_ goal: String) -> GoalCategory {
        let words = goal.lowercased()
        let table: [(GoalCategory, [String])] = [
            (.travel, ["travel", "trip", "flight", "holiday", "vacation"]),
            (.learning, ["read", "learn", "study", "language", "book", "course"]),
            (.selfCare, ["meditat", "mindful", "grateful", "skincare", "self", "pray", "positive", "relax", "journal"]),
            (.health, ["water", "eat", "exercise", "gym", "walk", "step", "sleep", "run", "yoga", "overeat", "health"]),
            (.productivity, ["work", "screen", "plan", "focus", "project", "clean"]),
        ]
        return table.first { _, keys in keys.contains { words.contains($0) } }?.0 ?? .personal
    }
}
