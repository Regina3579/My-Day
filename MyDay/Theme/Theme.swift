import SwiftUI

extension Color {
    /// Creates a color from a `0xRRGGBB` literal.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Colors sampled from the My Day artwork.
enum Palette {
    static let ink = Color(hex: 0x1B1446)        // "My Day" title
    static let inkSoft = Color(hex: 0x564B87)    // tab icons
    static let hotPink = Color(hex: 0xF81C7A)    // + button, selected tab
    static let bubblegum = Color(hex: 0xFC5CA8)  // hearts, underline
    static let blush = Color(hex: 0xFFE4EF)
    static let petal = Color(hex: 0xFFF4F8)
    static let berry = Color(hex: 0x7A0A2E)      // "My Journal" title
    static let lavender = Color(hex: 0xC9B3F2)
    static let lilac = Color(hex: 0xEFE6FF)
    static let grape = Color(hex: 0x955CEF)      // To-Dos button
    static let butter = Color(hex: 0xFDD374)
    static let cream = Color(hex: 0xFFF6D6)
    static let honey = Color(hex: 0xFEA707)      // Priority button
    /// The round yellow microphone (Speak a Task, and speaking a journal page).
    static let micYellow = LinearGradient(colors: [Color(hex: 0xFFDA4D), Color(hex: 0xFFA800)],
                                          startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cocoa = Color(hex: 0x4A1A0A)      // "Today's Priority" title
    static let mint = Color(hex: 0x22C46E)       // "Add Task" check
}

/// The look of each section, matching its card on the home screen.
enum SectionTheme {
    case todos, priority, journal, garden

    var colors: [Color] {
        switch self {
        case .todos: [Color(hex: 0xF6F0FF), Color(hex: 0xE9DDFF), Color(hex: 0xFCEBFA)]
        case .priority: [Color(hex: 0xFFFBEA), Color(hex: 0xFFF0BF), Color(hex: 0xFFE6EE)]
        case .journal: [Color(hex: 0xFFF3F8), Color(hex: 0xFFDCEA), Color(hex: 0xFFEAF3)]
        case .garden: [Color(hex: 0xFFF1F7), Color(hex: 0xF3EAFF), Color(hex: 0xFFF6E5)]
        }
    }

    var accent: Color {
        switch self {
        case .todos: Palette.grape
        case .priority: Palette.honey
        case .journal, .garden: Palette.hotPink
        }
    }

    var title: Color {
        switch self {
        case .todos, .garden: Palette.ink
        case .priority: Palette.cocoa
        case .journal: Palette.berry
        }
    }

    var glow: Color {
        switch self {
        case .todos: Palette.lavender
        case .priority: Palette.butter
        case .journal, .garden: Palette.bubblegum
        }
    }
}

extension Font {
    /// SF Rounded, which matches the soft lettering of the artwork.
    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    static func rounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Mood {
    var color: Color {
        switch self {
        case .amazing: Color(hex: 0xFFB800)
        case .happy: Color(hex: 0xFFC83D)
        case .loved: Color(hex: 0xFF5C9D)
        case .excited: Color(hex: 0xFF8A3D)
        case .calm: Color(hex: 0x6CC6E8)
        case .grateful: Color(hex: 0x9B7BEA)
        case .tired: Color(hex: 0xA3A6C9)
        case .sad: Color(hex: 0x5B8DEF)
        case .stressed: Color(hex: 0xE26D6D)
        case .grumpy: Color(hex: 0xA66BF0)
        case .bored: Color(hex: 0x3FC9A2)
        case .anxious: Color(hex: 0x8A93F5)
        case .overwhelmed: Color(hex: 0xF7836E)
        case .motivated: Color(hex: 0xF5A623)
        case .confident: Color(hex: 0xF2659A)
        case .peaceful: Color(hex: 0x5DB6F0)
        case .lonely: Color(hex: 0xA58AF2)
        case .hopeful: Color(hex: 0xF2C230)
        case .energetic: Color(hex: 0x2FCBB0)
        case .creative: Color(hex: 0xF59A5C)
        case .confused: Color(hex: 0x5AAFEF)
        case .emotional: Color(hex: 0xF07DB5)
        case .proud: Color(hex: 0xF5B82E)
        case .relaxed: Color(hex: 0xB07FF0)
        case .blissful: Color(hex: 0xF77F92)
        case .angry: Color(hex: 0xEF5A45)
        case .frustrated: Color(hex: 0xF28A5B)
        case .content: Color(hex: 0x46CFA0)
        case .melancholy: Color(hex: 0x6F95E8)
        case .playful: Color(hex: 0xF7C52E)
        }
    }
}

/// Each category has its own colour, so a to-do's category shows at a glance:
/// Personal pink, Work blue, Health green, Learning yellow, Shopping purple.
extension TaskCategory {
    var color: Color {
        switch self {
        case .personal: Palette.hotPink
        case .work: Color(hex: 0x3F6FE0)
        case .health: Color(hex: 0x2DAA6A)
        case .learning: Color(hex: 0xE39B0B)
        case .shopping: Color(hex: 0x8A55E8)
        }
    }

    /// A slightly deeper shade of `color` for text, so even the yellow stays easy to read.
    var textColor: Color {
        switch self {
        case .personal: Color(hex: 0xD6106A)
        case .work: Color(hex: 0x2F5BC9)
        case .health: Color(hex: 0x1F8A52)
        case .learning: Color(hex: 0xAD7200)
        case .shopping: Color(hex: 0x7442D6)
        }
    }
}

/// Colours for the categories people add. New categories are pink (the first one) unless
/// the person picks another.
enum CategoryPalette {
    static let colors: [Color] = tints.map(\.accent)

    /// The row colours for each: a soft fill and edge, and the colour itself.
    static let tints: [RowTint] = [
        RowTint(fill: Color(hex: 0xFCE8F1), edge: Color(hex: 0xF7C5DB), accent: Color(hex: 0xE85D9C)),
        RowTint(fill: Color(hex: 0xE2F5F3), edge: Color(hex: 0xB4E5DF), accent: Color(hex: 0x2FB8A6)),
        RowTint(fill: Color(hex: 0xF4E8FD), edge: Color(hex: 0xE3C4F9), accent: Color(hex: 0xB15CEF)),
        RowTint(fill: Color(hex: 0xFFECEA), edge: Color(hex: 0xFFCFCA), accent: Color(hex: 0xFF7A6B)),
        RowTint(fill: Color(hex: 0xE4F1FC), edge: Color(hex: 0xBADBF7), accent: Color(hex: 0x3F9BEA)),
        RowTint(fill: Color(hex: 0xFBF2DF), edge: Color(hex: 0xF4DEAD), accent: Color(hex: 0xE0A21B)),
        RowTint(fill: Color(hex: 0xE8EAF6), edge: Color(hex: 0xC4CAE8), accent: Color(hex: 0x5C6BC0)),
        RowTint(fill: Color(hex: 0xEBF4E3), edge: Color(hex: 0xCAE2B8), accent: Color(hex: 0x6DAF3A))
    ]

    static func color(at index: Int) -> Color {
        tint(at: index).accent
    }

    static func tint(at index: Int) -> RowTint {
        tints[((index % tints.count) + tints.count) % tints.count]
    }
}

extension CustomCategory {
    var color: Color { CategoryPalette.color(at: colorIndex) }
}

extension CategoryChoice {
    var label: String {
        switch self {
        case .builtIn(let builtIn): builtIn.label
        case .custom(let custom): custom.name
        }
    }

    var emoji: String {
        switch self {
        case .builtIn(let builtIn): builtIn.emoji
        case .custom(let custom): custom.emoji
        }
    }

    var color: Color {
        switch self {
        case .builtIn(let builtIn): builtIn.color
        case .custom(let custom): custom.color
        }
    }

    /// The colour for the category's name.
    var textColor: Color {
        switch self {
        case .builtIn(let builtIn): builtIn.textColor
        case .custom(let custom): custom.color
        }
    }

    var symbol: String {
        switch self {
        case .builtIn(let builtIn): builtIn.symbol
        case .custom: "tag.fill"
        }
    }
}

/// The soft colours the to-do rows take in turn, as in the design.
struct RowTint {
    let fill: Color
    let edge: Color
    let accent: Color

    static let cycle: [RowTint] = [
        RowTint(fill: Color(hex: 0xFDE6F1), edge: Color(hex: 0xF9C4DD), accent: Color(hex: 0xEE2F86)),
        RowTint(fill: Color(hex: 0xEEE8FD), edge: Color(hex: 0xD6CAF8), accent: Color(hex: 0x7A4FE0)),
        RowTint(fill: Color(hex: 0xFFF3DB), edge: Color(hex: 0xF9DEA6), accent: Color(hex: 0xEE9A12)),
        RowTint(fill: Color(hex: 0xE4EEFD), edge: Color(hex: 0xBFD3F8), accent: Color(hex: 0x3F63DC)),
        RowTint(fill: Color(hex: 0xE5F6E6), edge: Color(hex: 0xBFE6C2), accent: Color(hex: 0x33A447)),
        RowTint(fill: Color(hex: 0xFFEADD), edge: Color(hex: 0xF9CDAF), accent: Color(hex: 0xEB7426))
    ]

    static func at(_ index: Int) -> RowTint {
        cycle[((index % cycle.count) + cycle.count) % cycle.count]
    }

    static let pink = cycle[0]
    static let purple = cycle[1]
    static let yellow = cycle[2]
    static let blue = cycle[3]
    static let green = cycle[4]

    /// A to-do row's colours, from its category.
    static func of(_ choice: CategoryChoice) -> RowTint {
        switch choice {
        case .builtIn(.personal): pink
        case .builtIn(.work): blue
        case .builtIn(.health): green
        case .builtIn(.learning): yellow
        case .builtIn(.shopping): purple
        case .custom(let custom): CategoryPalette.tint(at: custom.colorIndex)
        }
    }
}
