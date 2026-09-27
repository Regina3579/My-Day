import Foundation
import SwiftData

/// A reusable to-do list the person saved themselves.
@Model
final class TaskTemplate {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "✨"
    var categoryRaw: String = "personal"
    var items: [String] = []
    var createdAt: Date = Date()

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

/// A template as shown in the picker: a built-in starter or a saved `TaskTemplate`.
struct TemplateBlueprint: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let category: TaskCategory
    let items: [String]
    /// Set for templates the person made, so they can be deleted.
    var customID: UUID?

    init(id: String, name: String, emoji: String, category: TaskCategory, items: [String], customID: UUID? = nil) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.category = category
        self.items = items
        self.customID = customID
    }

    init(_ template: TaskTemplate) {
        self.init(id: template.id.uuidString, name: template.name, emoji: template.emoji,
                  category: template.category, items: template.items, customID: template.id)
    }

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
