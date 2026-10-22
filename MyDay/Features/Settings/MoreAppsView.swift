import SwiftUI

/// One of the other apps from My Day's maker, shown on More Great Apps.
struct GreatApp: Identifiable {
    /// Its App Store ID (the number in its link).
    let id: String
    let name: String
    let subtitle: String
    let blurb: String
    /// The cute tile shown until (or instead of) its App Store icon.
    let emoji: String
    let colors: [Color]

    var storeURL: URL { URL(string: "https://apps.apple.com/app/id\(id)")! }

    static let all: [GreatApp] = [
        GreatApp(id: "6816495354", name: "Quiz Island", subtitle: "Adventure Fun",
                 blurb: "Sail to a sunny island full of fun quizzes and adventures.",
                 emoji: "🏝️", colors: [Color(hex: 0x5FD3F3), Color(hex: 0x2E9BE6)]),
        GreatApp(id: "6785565605", name: "Coloring Fun", subtitle: "Color & Draw",
                 blurb: "Color, draw and make beautiful pictures in bright colours.",
                 emoji: "🎨", colors: [Color(hex: 0xFFB36B), Color(hex: 0xFF6FAE)]),
        GreatApp(id: "6763797554", name: "Jesus Words", subtitle: "New Testament",
                 blurb: "Read the words of Jesus from the New Testament, every day.",
                 emoji: "📖", colors: [Color(hex: 0xFFE08A), Color(hex: 0xE9A93C)]),
    ]
}

/// Settings → More → More Great Apps: Quiz Island, Coloring Fun and Jesus Words, each with its
/// icon, name and a line about it. Tapping one opens it on the App Store to download.
struct MoreAppsView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 6) {
                    Text("💝")
                        .font(.system(size: 40))
                        .accessibilityHidden(true)
                    Text("More apps made with love")
                        .font(.rounded(.title3, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                    Text("From the maker of My Day. Tap one to see it on the App Store.")
                        .font(.rounded(.subheadline, weight: .medium))
                        .foregroundStyle(Palette.inkSoft)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)

                ForEach(GreatApp.all) { app in
                    Button {
                        openURL(app.storeURL)
                        Haptics.tap()
                    } label: {
                        GreatAppCard(app: app)
                    }
                    .buttonStyle(PressScaleStyle(scale: 0.97))
                    .accessibilityLabel("\(app.name): \(app.subtitle). \(app.blurb) Opens the App Store.")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .tabBarSafeArea()
        .background(DreamyBackground(theme: .garden))
        .navigationTitle("More Great Apps")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// An app's card: its icon, name, subtitle, a line about it and a pink Get button.
private struct GreatAppCard: View {
    let app: GreatApp

    var body: some View {
        HStack(spacing: 14) {
            GreatAppIcon(app: app)
                .frame(width: 72, height: 72)
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                Text(app.subtitle)
                    .font(.rounded(.caption, weight: .bold))
                    .foregroundStyle(Palette.hotPink)
                Text(app.blurb)
                    .font(.rounded(.caption, weight: .medium))
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Text("Get")
                .font(.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(Capsule().fill(Palette.hotPink.gradient))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.white))
        .shadow(color: Palette.hotPink.opacity(0.1), radius: 8, x: 0, y: 3)
    }
}

/// The app's own App Store icon, looked up from Apple's iTunes Search API when online; a cute
/// emoji tile in its colours until then (or offline).
private struct GreatAppIcon: View {
    let app: GreatApp
    @State private var iconURL: URL?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(LinearGradient(colors: app.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(Text(app.emoji).font(.system(size: 38)))
            if let iconURL {
                AsyncImage(url: iconURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.clear
                }
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).strokeBorder(Color.black.opacity(0.06)))
        .accessibilityHidden(true)
        .task { iconURL = await GreatAppIcons.url(for: app.id) }
    }
}

/// Finds each app's icon once per launch with Apple's iTunes lookup.
@MainActor
enum GreatAppIcons {
    private static var found: [String: URL] = [:]

    private struct Lookup: Decodable {
        struct Result: Decodable { let artworkUrl512: String? }
        let results: [Result]
    }

    static func url(for appID: String) async -> URL? {
        #if DEBUG
        if DebugLaunchRoute.isScreenshotRun { return nil }
        #endif
        if let url = found[appID] { return url }
        guard let lookup = URL(string: "https://itunes.apple.com/lookup?id=\(appID)"),
              let (data, _) = try? await URLSession.shared.data(from: lookup),
              let decoded = try? JSONDecoder().decode(Lookup.self, from: data),
              let text = decoded.results.first?.artworkUrl512,
              let url = URL(string: text) else { return nil }
        found[appID] = url
        return url
    }
}
