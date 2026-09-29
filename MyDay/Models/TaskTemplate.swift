import Foundation
import SwiftData

/// A reusable to-do list: a starter (see `TemplateBlueprint`) or one the person made. Every
/// template can be edited and deleted.
@Model
final class TaskTemplate {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "✨"
    var categoryRaw: String = "personal"
    var items: [String] = []
    var createdAt: Date = Date()
    /// Which starter template this began as ("" for one the person made).
    var starterID: String = ""

    init(name: String, emoji: String, category: TaskCategory, items: [String]) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.categoryRaw = category.rawValue
        self.items = items
        self.createdAt = Date()
    }

    var category: TaskCategory {
        get { TaskCategory(storedValue: categoryRaw) }
        set { categoryRaw = newValue.rawValue }
    }
}

/// One of the six starter templates. They are copied into the store once (see
/// `TemplateLibrary`), so they can be edited and deleted like the person's own.
struct TemplateBlueprint {
    let id: String
    let name: String
    let emoji: String
    let category: TaskCategory
    let items: [String]

    static let starters: [TemplateBlueprint] = [
        TemplateBlueprint(id: "morning", name: "Morning Routine", emoji: "🌅", category: .personal,
                          items: ["Drink a glass of water", "Stretch for 5 minutes", "Make the bed",
                                  "Healthy breakfast", "Plan my day"]),
        TemplateBlueprint(id: "grocery", name: "Grocery Shopping", emoji: "🛒", category: .shopping,
                          items: ["Milk", "Eggs", "Vegetables", "Fruits", "Bread"]),
        TemplateBlueprint(id: "travel", name: "Travel Checklist", emoji: "✈️", category: .personal,
                          items: ["Passport and tickets", "Phone charger", "Clothes and toiletries",
                                  "Medicines", "Book a ride to the airport"]),
        TemplateBlueprint(id: "workout", name: "Workout Routine", emoji: "🏋️", category: .health,
                          items: ["Warm up for 5 minutes", "20 squats", "10 push-ups",
                                  "30-second plank", "Cool down and stretch"]),
        TemplateBlueprint(id: "cleaning", name: "Home Cleaning", emoji: "🧹", category: .personal,
                          items: ["Tidy the living room", "Clean the kitchen", "Do the laundry",
                                  "Vacuum the floors", "Take out the trash"]),
        TemplateBlueprint(id: "study", name: "Study Session", emoji: "📚", category: .learning,
                          items: ["Review my notes", "Read one chapter", "Practice questions",
                                  "Make flashcards", "Take a short break"])
    ]
}

/// The starter templates in the store: added once, and brought back on request.
@MainActor
enum TemplateLibrary {
    /// Adds the starters the first time (one deleted later stays deleted).
    static func seedIfNeeded(in context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Prefs.didSeedTemplates) else { return }
        defaults.set(true, forKey: Prefs.didSeedTemplates)
        restoreStarters(in: context)
    }

    /// Adds back any starter that isn't there (edited ones are kept as they are).
    static func restoreStarters(in context: ModelContext) {
        let present = Set(((try? context.fetch(FetchDescriptor<TaskTemplate>())) ?? []).map(\.starterID))
        for (index, starter) in TemplateBlueprint.starters.enumerated() where !present.contains(starter.id) {
            let template = TaskTemplate(name: starter.name, emoji: starter.emoji, category: starter.category,
                                        items: starter.items)
            template.starterID = starter.id
            // Listed first, in their usual order, before the person's own.
            template.createdAt = Date(timeIntervalSinceReferenceDate: Double(index))
            context.insert(template)
        }
    }

    static func isMissingStarters(among templates: [TaskTemplate]) -> Bool {
        let present = Set(templates.map(\.starterID))
        return TemplateBlueprint.starters.contains { !present.contains($0.id) }
    }
}
