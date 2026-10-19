/// The journal's look. Blush Blossom 🌷, the pastel-pink pages with hearts and flowers, is
/// My Day's journal theme, for everyone; more themes are on the way.
enum JournalTheme: String, CaseIterable, Identifiable {
    case blushBlossom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blushBlossom: "Blush Blossom 🌷"
        }
    }
}
