import SwiftUI

/// The journal's look, chosen in Settings → Journal → Journal Theme (or ⋮ on My Journal Pages).
/// Blush Blossom 🌷, the pastel-pink pages with hearts, bows and flowers, is the default and
/// free for everyone; every other theme comes with My Day Pro.
enum JournalTheme: String, CaseIterable, Identifiable {
    case blushBlossom
    case heavenlyAngelWishes
    case enchantedFairyGarden
    case rainbowGlowUnicorn

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blushBlossom: "Blush Blossom 🌷"
        case .heavenlyAngelWishes: "Heavenly Angel Wishes 👼"
        case .enchantedFairyGarden: "Enchanted Fairy Garden 🧚"
        case .rainbowGlowUnicorn: "Rainbow Glow Unicorn 🦄"
        }
    }

    /// A line on how it looks.
    var detail: String {
        switch self {
        case .blushBlossom: "Pastel pink pages with hearts, bows and flowers."
        case .heavenlyAngelWishes: "Little angels, golden stars and a castle in the clouds."
        case .enchantedFairyGarden: "Fairies, butterflies and glowing lanterns in a flower garden."
        case .rainbowGlowUnicorn: "Little unicorns, rainbows, clouds and glowing hearts."
        }
    }

    /// A picture of My Journal Pages in this theme, for the theme list.
    var previewImage: String {
        switch self {
        case .blushBlossom: "ThemePreviewBlushBlossom"
        case .heavenlyAngelWishes: "ThemePreviewHeavenly"
        case .enchantedFairyGarden: "ThemePreviewFairyGarden"
        case .rainbowGlowUnicorn: "ThemePreviewUnicorn"
        }
    }

    var isPro: Bool { self != .blushBlossom }

    /// The theme the journal shows: Blush Blossom while a Pro theme waits for My Day Pro (the
    /// choice itself is kept, so it comes back with Pro).
    func applying(pro: Bool) -> JournalTheme {
        isPro && !pro ? .blushBlossom : self
    }
}

extension EnvironmentValues {
    /// The theme My Journal Pages is drawn in.
    @Entry var journalTheme: JournalTheme = .blushBlossom
}
