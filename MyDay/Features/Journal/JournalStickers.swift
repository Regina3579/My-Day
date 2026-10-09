import SwiftUI

/// A sticker on a journal page: one of the picture stickers (`StickerCatalog`), or an emoji
/// (on pages from before the picture stickers, and in the Emoji tab).
enum Sticker: Hashable {
    /// A picture sticker's id, like "hearts-01" (its image is `Stickers/hearts-01`).
    case picture(String)
    case emoji(String)

    /// The stickers kept in `JournalEntry.stickers`, in order: a picture sticker as
    /// "[hearts-01]", an emoji as itself, so pages saved with emoji stickers read as before.
    static func list(from text: String) -> [Sticker] {
        var stickers: [Sticker] = []
        var rest = Substring(text)
        while let first = rest.first {
            if first == "[", let close = rest.firstIndex(of: "]") {
                stickers.append(.picture(String(rest[rest.index(after: rest.startIndex)..<close])))
                rest = rest[rest.index(after: close)...]
            } else {
                stickers.append(.emoji(String(first)))
                rest = rest.dropFirst()
            }
        }
        return stickers
    }

    /// The text kept in `JournalEntry.stickers` for `stickers`.
    static func text(for stickers: [Sticker]) -> String {
        stickers.map(\.code).joined()
    }

    private var code: String {
        switch self {
        case .picture(let id): "[\(id)]"
        case .emoji(let emoji): emoji
        }
    }

    /// What VoiceOver says for it.
    var name: String {
        switch self {
        case .picture(let id): StickerCatalog.names[id] ?? "Sticker"
        case .emoji(let emoji): emoji
        }
    }
}

/// A tab of the sticker picker.
struct StickerCategory: Identifiable {
    let id: String
    let title: String
    /// Its label's colour on the sticker sheet.
    let tint: UInt32
    let stickers: [Sticker]
    /// The picture stickers' names, by id.
    let names: [String: String]

    /// Picture stickers `id-01`, `id-02`, … named `names`, in the sheet's order.
    init(id: String, title: String, tint: UInt32, names: [String]) {
        self.id = id
        self.title = title
        self.tint = tint
        let ids = names.indices.map { index in "\(id)-" + (index < 9 ? "0" : "") + "\(index + 1)" }
        stickers = ids.map(Sticker.picture)
        self.names = Dictionary(uniqueKeysWithValues: zip(ids, names))
    }

    init(id: String, title: String, tint: UInt32, emoji: [String]) {
        self.id = id
        self.title = title
        self.tint = tint
        stickers = emoji.map(Sticker.emoji)
        names = [:]
    }
}

/// The stickers in the picker: the sticker sheet's 159 picture stickers, in its 14 groups and
/// order, then the emoji stickers.
enum StickerCatalog {
    static let categories: [StickerCategory] = [
        StickerCategory(id: "hearts", title: "Hearts & Love", tint: 0xFECECE, names: [
            "Pink heart",
            "Heart outline",
            "Layered heart",
            "Gingham heart",
            "Sketched heart",
            "Glitter heart",
            "Ribbon heart",
            "Two little hearts",
            "Little heart",
            "Pink bow",
            "Soft pink heart",
            "Sparkly heart",
            "Shiny heart",
            "Tiny heart"
        ]),
        StickerCategory(id: "moods", title: "Mood & Feelings", tint: 0xFEEAC2, names: [
            "Happy face",
            "Smiling face",
            "Calm face",
            "Laughing face",
            "Sad face with a tear",
            "Neutral face",
            "Sobbing face",
            "Teary face",
            "Worried face",
            "Leafy sprig",
            "Happy heart",
            "Peaceful heart",
            "Sad heart",
            "Calm heart"
        ]),
        StickerCategory(id: "nature", title: "Nature & Outdoors", tint: 0xDEEAD2, names: [
            "Sun",
            "Moon",
            "Sparkles",
            "Cloud",
            "Rainbow",
            "Daisy",
            "Tulip",
            "Cherry blossom",
            "Four-leaf clover",
            "Leafy branch",
            "Leaves",
            "Pink flower",
            "Tree",
            "Mountains",
            "Wave"
        ]),
        StickerCategory(id: "selfcare", title: "Self-care & Wellness", tint: 0xE6D2EE, names: [
            "Lotus",
            "Candle",
            "Cup of tea",
            "Yoga mat",
            "Balancing stones",
            "Water bottle",
            "Sleep mask",
            "Bubble bath",
            "Green sprig"
        ]),
        StickerCategory(id: "growth", title: "Productivity & Growth", tint: 0xDAE6D2, names: [
            "Growth chart",
            "Target",
            "Light bulb",
            "Gold star",
            "Sprout",
            "Books",
            "Notebook",
            "Checklist",
            "Trophy"
        ]),
        StickerCategory(id: "travel", title: "Travel & Adventure", tint: 0xD2E6F2, names: [
            "Airplane",
            "Globe",
            "Map",
            "Camera",
            "Suitcase",
            "Signpost",
            "Compass",
            "Snowy mountains"
        ]),
        StickerCategory(id: "food", title: "Food & Drink", tint: 0xFADACA, names: [
            "Coffee",
            "Bubble tea",
            "Strawberry cake",
            "Cupcake",
            "Croissant",
            "Donut",
            "Strawberry",
            "Cherries",
            "Avocado",
            "Heart jar"
        ]),
        StickerCategory(id: "weather", title: "Weather & Seasons", tint: 0xCEE2F2, names: [
            "Sunny",
            "Partly cloudy",
            "Cloudy",
            "Rainy",
            "Snowflake",
            "Spring blossom",
            "Green leaf",
            "Autumn leaf",
            "Snowman",
            "Umbrella"
        ]),
        StickerCategory(id: "animals", title: "Animals & Cute Characters", tint: 0xFEDAE2, names: [
            "Kitten",
            "Puppy",
            "Bunny",
            "Bear",
            "Panda",
            "Bluebird",
            "Penguin",
            "Fox",
            "Frog",
            "Sleepy cat"
        ]),
        StickerCategory(id: "aesthetic", title: "Aesthetic Elements", tint: 0xE6D2EE, names: [
            "Pink bow",
            "Golden sparkles",
            "Moon and stars",
            "Purple sparkle",
            "Purple cloud",
            "Butterfly",
            "Pink ribbon",
            "Ribbon bow",
            "Crown",
            "Love heart"
        ]),
        StickerCategory(id: "words", title: "Words & Phrases", tint: 0xFEEAB2, names: [
            "Good day",
            "You got this",
            "Be kind",
            "Take a break",
            "Small steps",
            "Keep going",
            "I'm proud of you",
            "Happy thoughts"
        ]),
        StickerCategory(id: "occasions", title: "Special Occasions", tint: 0xDAEAD2, names: [
            "Birthday cake",
            "Gift",
            "Balloons",
            "Party popper",
            "Party hat",
            "Christmas tree",
            "Pumpkin",
            "Snowflake",
            "Love letter",
            "Fireworks"
        ]),
        StickerCategory(id: "misc", title: "Miscellaneous", tint: 0xCEE2EA, names: [
            "Photo",
            "Paper plane",
            "Washi tape",
            "Love note",
            "Heart paperclip",
            "Push pin",
            "Music note",
            "Pink flower",
            "Hand-drawn heart",
            "Swirl"
        ]),
        StickerCategory(id: "colors", title: "Colorful Hearts", tint: 0xFEDAE6, names: [
            "Red heart",
            "Pink heart",
            "Peach heart",
            "Yellow heart",
            "Green heart",
            "Blue heart",
            "Purple heart",
            "Lavender heart",
            "Beige heart",
            "Brown heart",
            "Black heart",
            "Pink outline heart",
            "Red outline heart",
            "Coral sketched heart",
            "Yellow striped heart",
            "Green zigzag heart",
            "Blue sketched heart",
            "Purple gingham heart",
            "Lavender gingham heart",
            "Polka-dot heart",
            "Brown striped heart",
            "Plaid heart"
        ]),
        StickerCategory(id: "emoji", title: "Emoji", tint: 0xF3EBFF, emoji: [
            "💖", "🌸", "⭐️", "🌈", "🦋", "🍓", "🧁", "🎀",
            "🌷", "☀️", "🌙", "✨", "🐶", "🐱", "🐰", "🍰",
            "☕️", "🎈", "🌻", "🍀", "💌", "🎵", "📚", "🏆"
        ])
    ]

    /// Every picture sticker's name, by id.
    static let names: [String: String] = categories.reduce(into: [:]) { all, category in
        all.merge(category.names) { first, _ in first }
    }
}

/// One sticker, `size` points tall (a picture sticker keeps its shape, up to 1.4 times as wide).
struct StickerView: View {
    let sticker: Sticker
    let size: CGFloat

    var body: some View {
        switch sticker {
        case .picture(let id):
            Image("Stickers/" + id)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: size * 1.4, maxHeight: size)
                .shadow(color: Color.black.opacity(0.12), radius: 1.5, x: 0, y: 1)
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: size * 0.82))
        }
    }
}
