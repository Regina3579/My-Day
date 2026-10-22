import StoreKit
import SwiftUI

/// The links in `Info.plist`, so they can be filled in without touching the code: My Day's App
/// Store ID (`MyDayAppStoreID`, shared with Rate My Day), the developer's App Store ID
/// (`MyDayDeveloperID`, for More Great Apps), the social pages (`MyDayInstagramURL`,
/// `MyDayFacebookURL`, `MyDayXURL`), a support email (`MyDaySupportEmail`) and the privacy
/// policy and terms (`MyDayPrivacyURL`, `MyDayTermsURL`). A row or icon whose link is empty
/// stays hidden.
enum MoreLinks {
    private static func value(_ key: String) -> String? {
        #if DEBUG
        // Screenshot runs show every row and icon (the links themselves never open there).
        if DebugLaunchRoute.isScreenshotRun { return "https://example.com" }
        #endif
        let text = (Bundle.main.object(forInfoDictionaryKey: key) as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? nil : text
    }

    private static func url(_ key: String) -> URL? { value(key).flatMap(URL.init(string:)) }

    /// My Day on the App Store, for Tell Your Friends.
    static var appStoreURL: URL? {
        AppReview.appStoreID.flatMap { URL(string: "https://apps.apple.com/app/id\($0)") }
    }

    /// The developer's page on the App Store: every app they make.
    static var moreAppsURL: URL? {
        guard let id = value("MyDayDeveloperID") else { return nil }
        #if DEBUG
        if DebugLaunchRoute.isScreenshotRun { return URL(string: id) }
        #endif
        return id.allSatisfy(\.isNumber) ? URL(string: "https://apps.apple.com/developer/id\(id)") : nil
    }

    static var instagram: URL? { url("MyDayInstagramURL") }
    static var facebook: URL? { url("MyDayFacebookURL") }
    static var x: URL? { url("MyDayXURL") }
    static var hasSocial: Bool { instagram != nil || facebook != nil || x != nil }

    static var supportEmail: URL? {
        value("MyDaySupportEmail").flatMap { URL(string: "mailto:\($0)?subject=My%20Day") }
    }

    static var privacy: URL? { url("MyDayPrivacyURL") }
    static var terms: URL? { url("MyDayTermsURL") }

    /// What Tell Your Friends sends.
    static var shareMessage: String {
        var text = "I plan my days and keep my journal with My Day: To-Do & Journal. It's so cute, you'll love it! 💖"
        if let appStoreURL { text += "\n\(appStoreURL.absoluteString)" }
        return text
    }
}

/// Settings → More: Tell Your Friends, More Great Apps, Connect with Us (Instagram, Facebook,
/// X), About and Subscription, as in the reference design, in My Day's own colours.
struct MoreView: View {
    @Environment(MyDayPro.self) private var pro
    @Environment(\.openURL) private var openURL
    @State private var showsPaywall = false
    @State private var managesSubscription = false

    var body: some View {
        Form {
            Section {
                ShareLink(item: MoreLinks.shareMessage) {
                    MoreRow(symbol: "person.2.fill", tint: Color(hex: 0xF0435A), title: "Tell Your Friends",
                            detail: "Share My Day with someone you love")
                }
                if let url = MoreLinks.moreAppsURL {
                    Button { openURL(url) } label: {
                        MoreRow(symbol: "square.grid.2x2.fill", tint: Color(hex: 0x7BC74D), title: "More Great Apps",
                                detail: "Other apps from the maker of My Day")
                    }
                }
                if MoreLinks.hasSocial {
                    HStack(spacing: 0) {
                        MoreRow(symbol: "heart.fill", tint: Color(hex: 0xF29A38), title: "Connect with Us",
                                detail: nil, showsChevron: false)
                        Spacer(minLength: 8)
                        HStack(spacing: 6) {
                            if let url = MoreLinks.facebook {
                                socialButton(url, label: "Facebook") {
                                    Text("f").font(.system(size: 19, weight: .heavy, design: .rounded))
                                }
                            }
                            if let url = MoreLinks.x {
                                socialButton(url, label: "X") {
                                    Text("𝕏").font(.system(size: 17, weight: .bold))
                                }
                            }
                            if let url = MoreLinks.instagram {
                                socialButton(url, label: "Instagram") {
                                    Image(systemName: "camera").font(.system(size: 16, weight: .semibold))
                                }
                            }
                        }
                    }
                }
                NavigationLink {
                    AboutMyDayView()
                } label: {
                    MoreRow(symbol: "info", tint: Color(hex: 0x3D8FD9), title: "About", detail: nil, showsChevron: false)
                }
                Button {
                    if pro.isActive { managesSubscription = true } else { showsPaywall = true }
                } label: {
                    MoreRow(symbol: "crown.fill", tint: Color(hex: 0x2DBE8C), title: "Subscription",
                            detail: pro.isActive ? "My Day Pro is on 💖 · Manage" : "Unlock My Day Pro")
                }
            }

            Section {
                Button {
                    showsPaywall = !pro.isActive
                    managesSubscription = pro.isActive
                } label: {
                    PremiumBanner(isPro: pro.isActive)
                }
                .buttonStyle(PressScaleStyle(scale: 0.98))
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .font(.rounded(.body))
        .scrollContentBackground(.hidden)
        .tabBarSafeArea()
        .background(DreamyBackground(theme: .garden))
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsPaywall) { ProPaywall() }
        .manageSubscriptionsSheet(isPresented: $managesSubscription)
    }

    private func socialButton<Icon: View>(_ url: URL, label: String, @ViewBuilder icon: () -> Icon) -> some View {
        Button { openURL(url) } label: {
            icon()
                .foregroundStyle(Palette.inkSoft)
                .frame(width: 40, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(label)
    }
}

/// A row on More: a white symbol in a coloured circle, the title, and a line under it.
private struct MoreRow: View {
    let symbol: String
    let tint: Color
    let title: String
    let detail: String?
    var showsChevron = true

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(tint.gradient))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.rounded(.body, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                if let detail {
                    Text(detail)
                        .font(.rounded(.caption, weight: .medium))
                        .foregroundStyle(Palette.inkSoft)
                }
            }
            if showsChevron {
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.inkSoft.opacity(0.4))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

/// "Let's go Premium!": the banner at the foot of More (thanks, once Pro is on).
private struct PremiumBanner: View {
    let isPro: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(isPro ? "You're a Pro! 👑" : "Let's go Premium! 👑")
                    .font(.rounded(.title3, weight: .heavy))
                    .foregroundStyle(Color.white)
                Text(isPro ? "Thank you for supporting My Day 💖"
                     : "Themes, photos, sounds, stickers, shared lists and more.")
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image("ProCrownInline")
                .resizable()
                .scaledToFit()
                .frame(width: 54)
                .accessibilityHidden(true)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xFF7DB8), Palette.hotPink, Palette.grape],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: Palette.hotPink.opacity(0.25), radius: 10, x: 0, y: 5)
    }
}

/// More → About: what My Day is, its version, and the support, privacy and terms links.
struct AboutMyDayView: View {
    @Environment(\.openURL) private var openURL

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 10) {
                    HeroBanner(height: 150)
                    Text("My Day")
                        .font(.rounded(.title, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                    Text("To-Do & Journal 💖")
                        .font(.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(Palette.hotPink)
                    Text("Plan your day, tick off your to-dos, keep a journal and celebrate every little win, all in one cute place.")
                        .font(.rounded(.subheadline, weight: .medium))
                        .foregroundStyle(Palette.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .listRowBackground(Color.clear)

            Section {
                LabeledContent("Version", value: version)
                LabeledContent("Made with", value: "💖 for beautiful days")
            }

            if MoreLinks.supportEmail != nil || MoreLinks.privacy != nil || MoreLinks.terms != nil {
                Section {
                    if let url = MoreLinks.supportEmail {
                        Button { openURL(url) } label: {
                            Label("Contact Support", systemImage: "envelope.fill")
                        }
                    }
                    if let url = MoreLinks.privacy {
                        Button { openURL(url) } label: {
                            Label("Privacy Policy", systemImage: "hand.raised.fill")
                        }
                    }
                    if let url = MoreLinks.terms {
                        Button { openURL(url) } label: {
                            Label("Terms of Use", systemImage: "doc.text.fill")
                        }
                    }
                }
                .foregroundStyle(Palette.hotPink)
            }
        }
        .font(.rounded(.body))
        .scrollContentBackground(.hidden)
        .tabBarSafeArea()
        .background(DreamyBackground(theme: .garden))
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
