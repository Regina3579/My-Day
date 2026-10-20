import Foundation

/// What one of the person's own templates is about, read from its name and to-dos, so its card
/// can be dressed to match: books for a reading list, fruit and vegetables for a market list,
/// a cake and balloons for a party. A template that matches nothing keeps the pink hearts.
struct TemplateTopic: Equatable {
    /// Three pictures for around the card, biggest first.
    let decorations: [String]
    /// Words that point to this topic. A word ending in `*` matches any word that starts with
    /// it ("bak*" → bake, baking, bakery); the others match the word itself and its plural.
    let words: [String]

    /// The best topic for a template's name and to-dos (words in the name count three times as
    /// much as words in its to-dos), or nil when none fits.
    static func match(name: String, items: [String]) -> TemplateTopic? {
        let nameWords = words(in: name)
        let itemWords = items.flatMap(words(in:))
        var best: (topic: TemplateTopic, score: Int)?
        for topic in all {
            let score = 3 * topic.hits(in: nameWords) + topic.hits(in: itemWords)
            if score > 0, score > best?.score ?? 0 { best = (topic, score) }
        }
        return best?.topic
    }

    private static func words(in text: String) -> [String] {
        text.lowercased().split { !$0.isLetter }.map(String.init)
    }

    private func hits(in tokens: [String]) -> Int {
        tokens.filter { token in
            words.contains { word in
                if word.hasSuffix("*") { return token.hasPrefix(word.dropLast()) }
                return token == word || token == word + "s" || token == word + "es"
            }
        }.count
    }

    /// The topics, the more particular first (a tie goes to the earlier one).
    static let all: [TemplateTopic] = [
        TemplateTopic(decorations: ["📚", "📖", "🔖"],
                      words: ["book", "read", "reading", "novel", "library", "chapter", "story", "stories", "author", "poem", "poetry", "kindle"]),
        TemplateTopic(decorations: ["✏️", "📝", "🎓"],
                      words: ["study", "studies", "studying", "exam", "school", "homework", "class", "lesson", "learn*", "college", "university", "revision", "revise", "notes", "math*", "science", "assignment", "test"]),
        TemplateTopic(decorations: ["🍎", "🥕", "🍌"],
                      words: ["fruit", "vegetable", "veggie", "veg", "apple", "banana", "mango", "orange", "grape", "berry", "berries", "strawberr*", "tomato", "tomatoes", "potato", "potatoes", "carrot", "onion", "salad", "spinach", "lemon", "grocer*", "market", "supermarket", "produce"]),
        TemplateTopic(decorations: ["🧁", "🍳", "🥗"],
                      words: ["cook*", "recipe", "bak*", "kitchen", "dinner", "lunch", "breakfast", "meal", "cake", "cupcake", "food", "snack", "dessert"]),
        TemplateTopic(decorations: ["🎂", "🎈", "🎁"],
                      words: ["birthday", "party", "parties", "celebrat*", "gift", "present", "wedding", "anniversary", "balloon"]),
        TemplateTopic(decorations: ["🎄", "🎁", "⛄️"],
                      words: ["christmas", "xmas", "santa", "winter", "snow"]),
        TemplateTopic(decorations: ["🧳", "🏖️", "🗺️"],
                      words: ["travel*", "trip", "vacation", "holiday", "flight", "airport", "passport", "hotel", "beach", "tour", "packing", "luggage", "suitcase", "visa"]),
        TemplateTopic(decorations: ["🏋️", "👟", "💪"],
                      words: ["workout", "gym", "exercise", "running", "run", "jog*", "yoga", "fitness", "stretch*", "squat", "pushup", "plank", "cardio", "pilates", "steps"]),
        TemplateTopic(decorations: ["⚽️", "🏸", "🏊"],
                      words: ["football", "soccer", "cricket", "tennis", "basketball", "badminton", "swim*", "match", "sport", "team", "training"]),
        TemplateTopic(decorations: ["💊", "🩺", "🍵"],
                      words: ["doctor", "medicine", "medicines", "health", "pill", "hospital", "dentist", "vitamin", "checkup", "clinic", "tablet", "appointment"]),
        TemplateTopic(decorations: ["🧹", "🧺", "🫧"],
                      words: ["clean*", "laundry", "wash*", "tidy", "dust*", "vacuum", "chore", "dishes", "mop", "trash", "iron*"]),
        TemplateTopic(decorations: ["🌷", "🪴", "🌿"],
                      words: ["garden*", "plant*", "flower", "seed", "tree", "water", "soil", "bloom"]),
        TemplateTopic(decorations: ["🐶", "🐱", "🦴"],
                      words: ["dog", "cat", "pet", "puppy", "puppies", "kitten", "vet", "fish", "walkies", "kitty"]),
        TemplateTopic(decorations: ["🍼", "🧸", "👶"],
                      words: ["baby", "babies", "kid", "child", "children", "diaper", "nappy", "nappies", "toddler", "nursery"]),
        TemplateTopic(decorations: ["💼", "💻", "📎"],
                      words: ["work", "office", "meeting", "project", "email", "report", "client", "deadline", "presentation", "boss", "job", "interview"]),
        TemplateTopic(decorations: ["💰", "🧾", "💳"],
                      words: ["bill", "budget", "money", "pay", "payment", "bank", "saving*", "rent", "tax", "taxes", "expense", "salary", "invoice"]),
        TemplateTopic(decorations: ["🎵", "🎹", "🎸"],
                      words: ["music", "song", "piano", "guitar", "sing", "singing", "violin", "dance", "dancing", "concert", "playlist"]),
        TemplateTopic(decorations: ["💅", "🧴", "🛁"],
                      words: ["skincare", "makeup", "spa", "nail", "hair", "bath", "selfcare", "facial", "beauty", "pamper*", "relax*"]),
        TemplateTopic(decorations: ["🚗", "⛽️", "🔧"],
                      words: ["car", "fuel", "petrol", "gas", "drive", "driving", "garage", "tyre", "tire", "service"]),
        TemplateTopic(decorations: ["🏠", "📦", "🔨"],
                      words: ["house", "home", "moving", "move", "furniture", "repair*", "fix", "decor*", "paint*", "renovat*", "diy"]),
        TemplateTopic(decorations: ["🛍️", "👗", "👠"],
                      words: ["shop*", "buy", "mall", "clothes", "dress", "shoe", "outfit", "fashion", "wardrobe"]),
        TemplateTopic(decorations: ["☕️", "🥐", "🍵"],
                      words: ["coffee", "tea", "cafe", "latte"]),
        TemplateTopic(decorations: ["🌅", "☀️", "🌼"],
                      words: ["morning", "wake", "sunrise", "daily", "routine"]),
        TemplateTopic(decorations: ["🌙", "⭐️", "😴"],
                      words: ["night", "sleep", "bed", "bedtime", "evening"]),
        TemplateTopic(decorations: ["🙏", "🕯️", "✨"],
                      words: ["pray*", "church", "temple", "mosque", "meditat*", "gratitude", "puja", "worship"]),
    ]
}
