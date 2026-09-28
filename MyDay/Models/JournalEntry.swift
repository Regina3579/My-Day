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
    case happy, loved, excited, calm, grateful, tired, sad, stressed

    var id: String { rawValue }

    var emoji: String {
        switch self {
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
