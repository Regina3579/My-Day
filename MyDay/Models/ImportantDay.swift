import Foundation
import SwiftData

/// A day to remember: a birthday, a wedding, a trip, a first day at school… with its own photo.
/// Important Days counts down to it, and the journal shows it on the day.
@Model
final class ImportantDay {
    var id: UUID = UUID()
    var title: String = ""
    var kindRaw: String = ImportantDayKind.birthday.rawValue
    /// The day itself (the birth date, the wedding day…), at the start of the day.
    var date: Date = Date()
    /// Comes back every year (birthdays, anniversaries) rather than once.
    var repeatsYearly: Bool = true
    /// A reminder at 9 in the morning on the day.
    var remindsMe: Bool = true
    var note: String = ""
    /// Its photo (max 1600 px), stored outside the database file.
    @Attribute(.externalStorage) var photoData: Data?
    var thumbnailData: Data?
    var createdAt: Date = Date()

    init(title: String, kind: ImportantDayKind, date: Date, repeatsYearly: Bool) {
        self.id = UUID()
        self.title = title
        self.kindRaw = kind.rawValue
        self.date = Calendar.current.startOfDay(for: date)
        self.repeatsYearly = repeatsYearly
        self.createdAt = Date()
    }

    var kind: ImportantDayKind {
        get { ImportantDayKind(rawValue: kindRaw) ?? .custom }
        set { kindRaw = newValue.rawValue }
    }

    /// When it comes next, today included (nil for a one-off day already past).
    func nextDate(from today: Date) -> Date? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: today)
        guard repeatsYearly else { return date >= start ? date : nil }
        let year = calendar.component(.year, from: start)
        for candidateYear in [year, year + 1] {
            if let day = occurrence(in: candidateYear), day >= start, day >= date { return day }
        }
        return nil
    }

    /// Its date in `year` (29 February falls on the 28th in other years).
    func occurrence(in year: Int) -> Date? {
        let calendar = Calendar.current
        var parts = calendar.dateComponents([.month, .day], from: date)
        parts.year = year
        if parts.month == 2, parts.day == 29,
           let days = calendar.range(of: .day, in: .month,
                                     for: calendar.date(from: DateComponents(year: year, month: 2)) ?? date),
           days.count < 29 {
            parts.day = 28
        }
        return calendar.date(from: parts)
    }

    /// Every time it has come, from the day itself up to `today` (for a one-off day, just the day).
    func pastOccurrences(through today: Date) -> [Date] {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: today)
        guard date <= end else { return [] }
        guard repeatsYearly else { return [date] }
        let first = calendar.component(.year, from: date)
        let last = calendar.component(.year, from: end)
        return (first...last).compactMap { occurrence(in: $0) }.filter { $0 >= date && $0 <= end }
    }

    /// Whole years from the day itself to `day` (the age on a birthday).
    func years(at day: Date) -> Int {
        Calendar.current.dateComponents([.year], from: date, to: day).year ?? 0
    }

    /// Days from the day itself to `day`.
    func daysSince(at day: Date) -> Int {
        Calendar.current.dateComponents([.day], from: date, to: Calendar.current.startOfDay(for: day)).day ?? 0
    }
}

/// What kind of day it is: the cards of the Important Day design.
enum ImportantDayKind: String, CaseIterable, Identifiable {
    case birthday, relationship, family, travel, home, work, education, custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .birthday: "Birthday"
        case .relationship: "Relationship"
        case .family: "Family"
        case .travel: "Travel"
        case .home: "Home"
        case .work: "Work"
        case .education: "Education"
        case .custom: "Create Your Own"
        }
    }

    /// Its picture from the design.
    var art: String {
        switch self {
        case .custom: "ImportantDay/Create"
        default: "ImportantDay/" + rawValue.capitalized
        }
    }

    /// The little badge on its photo.
    var symbol: String {
        switch self {
        case .birthday: "birthday.cake.fill"
        case .relationship: "heart.fill"
        case .family: "figure.2.and.child.holdinghands"
        case .travel: "airplane"
        case .home: "house.fill"
        case .work: "briefcase.fill"
        case .education: "graduationcap.fill"
        case .custom: "star.fill"
        }
    }

    var placeholder: String {
        switch self {
        case .birthday: "Mom's Birthday"
        case .relationship: "Wedding Day"
        case .family: "Family Day"
        case .travel: "Trip to Paris"
        case .home: "Moving Day"
        case .work: "First Day at Work"
        case .education: "Graduation Day"
        case .custom: "My Special Day"
        }
    }

    /// Birthdays and anniversaries come back every year; trips and the like happen once.
    var repeatsByDefault: Bool {
        switch self {
        case .birthday, .relationship, .family, .home: true
        case .travel, .work, .education, .custom: false
        }
    }
}
