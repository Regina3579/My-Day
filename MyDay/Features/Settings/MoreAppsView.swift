import SwiftUI

/// One of the other apps from My Day's maker, shown on More Great Apps.
struct GreatApp: Identifiable {
    /// Its App Store ID (the number in its link).
    let id: String
    let name: String
    let subtitle: String
    let blurb: String
    /// Its App Store icon, in `GreatApps/`.
    let icon: String

    var storeURL: URL { URL(string: "https://apps.apple.com/app/id\(id)")! }

    static let all: [GreatApp] = [
        GreatApp(id: "6816495354", name: "Quiz Island", subtitle: "Adventure Fun",
                 blurb: "Sail to a sunny island full of fun quizzes and adventures.",
                 icon: "GreatApps/QuizIsland"),
        GreatApp(id: "6785565605", name: "Coloring Fun", subtitle: "Color & Draw",
                 blurb: "Color, draw and make beautiful pictures in bright colours.",
                 icon: "GreatApps/ColoringFun"),
        GreatApp(id: "6763797554", name: "Jesus Words", subtitle: "New Testament",
                 blurb: "Read the words of Jesus from the New Testament, every day.",
                 icon: "GreatApps/JesusWords"),
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

/// The app's own App Store icon, with iOS's rounded corners.
private struct GreatAppIcon: View {
    let app: GreatApp

    var body: some View {
        Image(app.icon)
            .resizable()
            .scaledToFill()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).strokeBorder(Color.black.opacity(0.06)))
            .accessibilityHidden(true)
    }
}
