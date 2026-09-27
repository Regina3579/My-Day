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
        case .happy: Color(hex: 0xFFC83D)
        case .loved: Color(hex: 0xFF5C9D)
        case .excited: Color(hex: 0xFF8A3D)
        case .calm: Color(hex: 0x6CC6E8)
        case .grateful: Color(hex: 0x9B7BEA)
        case .tired: Color(hex: 0xA3A6C9)
        case .sad: Color(hex: 0x5B8DEF)
        case .stressed: Color(hex: 0xE26D6D)
        }
    }
}

extension TaskCategory {
    var color: Color {
        switch self {
        case .personal: Palette.hotPink
        case .work: Color(hex: 0x6C63D9)
        case .study: Color(hex: 0x3E9BD6)
        case .home: Color(hex: 0xE58A2B)
        case .health: Color(hex: 0x2DAA6A)
        case .shopping: Color(hex: 0xC357D6)
        case .other: Color(hex: 0x8A86A8)
        }
    }
}
