import Foundation
import SwiftData

/// One page of the journal.
@Model
final class JournalEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var title: String = ""
    var body: String = ""
    var moodRaw: String = "happy"
    var isFavorite: Bool = false
    /// Today's Little Win: one optional line, like "Finished my workout." ("" when none).
    var littleWin: String = ""
    /// "Today I'm grateful for…", "A highlight of my day…" and "Tomorrow I look forward to…"
    /// ("" when not written).
    var gratitude: String = ""
    var highlight: String = ""
    var lookingForward: String = ""
    /// Emoji stickers, in the order they were added ("" when none).
    var stickers: String = ""
    /// Tags such as "Good Vibes" or "Grateful", one per line (see `tags`).
    var tagsText: String = ""
    /// Where the page was written ("" when not added).
    var place: String = ""
    /// The weather that was picked (a `JournalWeather` raw value, "" when none) and its
    /// temperature as shown, like "28°C" ("" when none).
    var weatherRaw: String = ""
    var temperature: String = ""
    /// A voice note (AAC audio), stored outside the database file.
    @Attribute(.externalStorage) var voiceNote: Data?
    @Relationship(deleteRule: .cascade, inverse: \JournalPhoto.entry)
    var photos: [JournalPhoto]? = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(date: Date = Date(), title: String = "", body: String = "", mood: Mood = .happy,
         littleWin: String = "") {
        self.id = UUID()
        self.date = date
        self.title = title
        self.body = body
        self.moodRaw = mood.rawValue
        self.littleWin = littleWin
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var mood: Mood {
        get { Mood(rawValue: moodRaw) ?? .happy }
        set { moodRaw = newValue.rawValue }
    }

    var sortedPhotos: [JournalPhoto] {
        (photos ?? []).sorted { $0.order < $1.order }
    }

    var hasLittleWin: Bool { !littleWin.trimmed.isEmpty }

    var tags: [String] {
        get { tagsText.split(separator: "\n").map(String.init) }
        set { tagsText = newValue.joined(separator: "\n") }
    }

    var weather: JournalWeather? {
        get { JournalWeather(rawValue: weatherRaw) }
        set { weatherRaw = newValue?.rawValue ?? "" }
    }

    /// The title, or the first line of the text when no title was given.
    var displayTitle: String {
        let cleanTitle = title.trimmed
        if !cleanTitle.isEmpty { return cleanTitle }
        let firstLine = body.trimmed.components(separatedBy: .newlines).first ?? ""
        return firstLine.isEmpty ? "A page of my day" : firstLine
    }
}

/// A photo attached to a journal page.
@Model
final class JournalPhoto {
    var id: UUID = UUID()
    /// Full-size JPEG (max 1600 px), stored outside the database file.
    @Attribute(.externalStorage) var imageData: Data = Data()
    /// Small JPEG used in lists.
    var thumbnailData: Data?
    var order: Int = 0
    var createdAt: Date = Date()
    var entry: JournalEntry?

    init(imageData: Data, thumbnailData: Data?, order: Int) {
        self.id = UUID()
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.order = order
        self.createdAt = Date()
    }
}

enum Mood: String, CaseIterable, Identifiable, Codable {
    case happy, loved, excited, calm, grateful, tired, sad, stressed, amazing

    var id: String { rawValue }

    /// The moods offered when writing a page, each with its little star.
    static let pickerMoods: [Mood] = [.amazing, .happy, .calm, .sad, .stressed, .tired]

    /// The star picture for the moods offered when writing (nil for the older moods).
    var artName: String? {
        Self.pickerMoods.contains(self) ? "Mood" + rawValue.capitalized : nil
    }

    var emoji: String {
        switch self {
        case .amazing: "🌟"
        case .happy: "😊"
        case .loved: "🥰"
        case .excited: "🤩"
        case .calm: "😌"
        case .grateful: "🙏"
        case .tired: "😴"
        case .sad: "😢"
        case .stressed: "😣"
        }
    }

    var label: String { rawValue.capitalized }
}

/// The weather on a journal page, picked by hand.
enum JournalWeather: String, CaseIterable, Identifiable {
    case sunny, partlyCloudy, cloudy, rainy, stormy, snowy, windy, foggy

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sunny: "Sunny"
        case .partlyCloudy: "Partly cloudy"
        case .cloudy: "Cloudy"
        case .rainy: "Rainy"
        case .stormy: "Stormy"
        case .snowy: "Snowy"
        case .windy: "Windy"
        case .foggy: "Foggy"
        }
    }

    /// A multicolour SF Symbol.
    var symbol: String {
        switch self {
        case .sunny: "sun.max.fill"
        case .partlyCloudy: "cloud.sun.fill"
        case .cloudy: "cloud.fill"
        case .rainy: "cloud.rain.fill"
        case .stormy: "cloud.bolt.rain.fill"
        case .snowy: "cloud.snow.fill"
        case .windy: "wind"
        case .foggy: "cloud.fog.fill"
        }
    }
}
