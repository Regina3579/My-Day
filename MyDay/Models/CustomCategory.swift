import Foundation
import SwiftData

/// A category the person added with the ＋ chip, next to the five built in.
@Model
final class CustomCategory {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "✨"
    /// Which of `CategoryPalette.colors` it uses.
    var colorIndex: Int = 0
    var createdAt: Date = Date()
    /// Deleting the category keeps its to-dos: they go back to Personal.
    @Relationship(deleteRule: .nullify, inverse: \TaskItem.customCategory)
    var tasks: [TaskItem]? = []

    init(name: String, emoji: String, colorIndex: Int) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.colorIndex = colorIndex
        self.createdAt = Date()
    }
}
