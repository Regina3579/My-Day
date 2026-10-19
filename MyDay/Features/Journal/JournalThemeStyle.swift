import SwiftUI

/// What each journal theme brings to My Journal Pages' words and colours.
extension JournalTheme {
    /// The headings ("My week in moods", "October 2026"): rounded in Blush Blossom and Rainbow
    /// Glow Unicorn, a bold serif in Heavenly Angel Wishes and Enchanted Fairy Garden.
    func headingFont(_ style: Font.TextStyle) -> Font {
        switch self {
        case .heavenlyAngelWishes, .enchantedFairyGarden: .system(style, design: .serif, weight: .bold)
        case .blushBlossom, .rainbowGlowUnicorn: .rounded(style, weight: .heavy)
        }
    }

    /// "My week in moods".
    var headingColor: Color {
        switch self {
        case .blushBlossom: JournalStyle.plum
        case .heavenlyAngelWishes: HeavenlyStyle.title
        case .enchantedFairyGarden: FairyStyle.title
        case .rainbowGlowUnicorn: UnicornStyle.title
        }
    }

    /// The month over the pages ("October 2026").
    var monthColor: Color {
        switch self {
        case .blushBlossom: Palette.berry
        case .heavenlyAngelWishes: HeavenlyStyle.month
        case .enchantedFairyGarden: FairyStyle.month
        case .rainbowGlowUnicorn: UnicornStyle.month
        }
    }

    /// The colour the pages fade into behind the search bar.
    var pagesBase: Color {
        switch self {
        case .blushBlossom: JournalBackdrop.base
        case .heavenlyAngelWishes: HeavenlyStyle.base
        case .enchantedFairyGarden: FairyStyle.base
        case .rainbowGlowUnicorn: UnicornStyle.base
        }
    }

    /// The little picture between the month and All Time, and its size.
    var monthArt: (name: String, size: CGSize)? {
        switch self {
        case .blushBlossom: nil
        case .heavenlyAngelWishes: ("HeavenlyMonthAngel", CGSize(width: 62, height: 42))
        case .enchantedFairyGarden: ("FairyButterflyPair", CGSize(width: 52, height: 36))
        case .rainbowGlowUnicorn: ("UnicornMonth", CGSize(width: 60, height: 40))
        }
    }
}
