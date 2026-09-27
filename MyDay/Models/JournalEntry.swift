import Foundation
import SwiftData

/// One page of the journal.
@Model
final class JournalEntry {
    var uuid: UUID = UUID()
    var date: Date = Date()
    var title: String = ""
    var body: String = ""
    var moodRaw: String = "happy"
    var isFavorite: Bool = false
    /// Full-size photo (max 1600 px), stored outside the database file.
    @Attribute(.externalStorage) var photoData: Data?
    /// Small JPEG used in lists.
    var thumbnailData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(date: Date = Date(), title: String = "", body: String = "", mood: Mood = .happy) {
        self.uuid = UUID()
        self.date = date
        self.title = title
        self.body = body
        self.moodRaw = mood.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var mood: Mood {
        get { Mood(rawValue: moodRaw) ?? .happy }
        set { moodRaw = newValue.rawValue }
    }

    /// The title, or the first line of the text when no title was given.
    var displayTitle: String {
        let trimmedTitle = title.trimmed
        if !trimmedTitle.isEmpty { return trimmedTitle }
        let firstLine = body.trimmed.components(separatedBy: .newlines).first ?? ""
        return firstLine.isEmpty ? "A page of my day" : firstLine
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
