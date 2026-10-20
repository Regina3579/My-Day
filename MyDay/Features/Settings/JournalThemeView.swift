import SwiftUI

/// Settings → Journal → Journal Theme (also ⋮ → Journal Theme on My Journal Pages): the themes
/// My Journal Pages can wear, each with a picture of it. Blush Blossom is free; the others come
/// with My Day Pro, so for a free account they wear a crown, and tapping one offers Pro.
struct JournalThemeView: View {
    @Environment(MyDayPro.self) private var pro
    @AppStorage(Prefs.journalTheme) private var chosen: JournalTheme = .blushBlossom
    @State private var proOffer: ProFeature?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(JournalTheme.allCases) { theme in
                    Button {
                        choose(theme)
                    } label: {
                        JournalThemeCard(theme: theme, isOn: theme == current,
                                         isLocked: theme.isPro && !pro.isActive)
                    }
                    .buttonStyle(PressScaleStyle(scale: 0.98))
                    .accessibilityAddTraits(theme == current ? AccessibilityTraits.isSelected : [])
                }
                Text(footer)
                    .font(.rounded(.footnote))
                    .foregroundStyle(Palette.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
            }
            .padding(16)
        }
        .tabBarSafeArea()
        .background(DreamyBackground(theme: .garden))
        .navigationTitle("Journal Theme")
        .navigationBarTitleDisplayMode(.inline)
        .proOffer($proOffer)
        #if DEBUG
        .task {
            // `pro-themes`: a free account taps Heavenly Angel Wishes.
            if let offer = DebugLaunchRoute.takeProOffer() {
                try? await Task.sleep(for: .seconds(0.8))
                proOffer = offer
            }
        }
        #endif
    }

    /// The theme the journal wears now: Blush Blossom while a Pro theme waits for Pro.
    private var current: JournalTheme { chosen.applying(pro: pro.isActive) }

    private var footer: String {
        pro.isActive ? "More themes are on the way 🌸" : "Themes with a 👑 come with My Day Pro."
    }

    private func choose(_ theme: JournalTheme) {
        if theme.isPro && !pro.isActive {
            proOffer = .themes
            return
        }
        guard theme != chosen else { return }
        withAnimation(.snappy) { chosen = theme }
        Haptics.tap()
    }
}

/// A theme: its picture, name and look, a tick when it is the one in use, or a crown when it
/// waits for My Day Pro.
private struct JournalThemeCard: View {
    let theme: JournalTheme
    let isOn: Bool
    let isLocked: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(theme.previewImage)
                .resizable()
                .scaledToFill()
                .frame(width: 92, height: 144)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white, lineWidth: 2))
                .overlay(alignment: .topTrailing) {
                    if isLocked {
                        ProCrown(size: 24).offset(x: 6, y: -6)
                    }
                }
                .shadow(color: Palette.hotPink.opacity(0.18), radius: 6, x: 0, y: 3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(theme.title)
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(theme.detail)
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text(status)
                    .font(.rounded(.footnote, weight: .bold))
                    .foregroundStyle(isOn ? Palette.hotPink : isLocked ? ProStyle.title : Palette.inkSoft)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(isOn ? Palette.hotPink.opacity(0.12)
                                                : isLocked ? Color(hex: 0xFFF1C8) : Color.white.opacity(0.7)))
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(isOn ? Palette.hotPink : Palette.inkSoft.opacity(0.4))
                .accessibilityHidden(true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white.opacity(0.88)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(isOn ? Palette.hotPink.opacity(0.6) : Color.white, lineWidth: isOn ? 2 : 1.5))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(isLocked ? "Comes with My Day Pro" : isOn ? "" : "Uses this theme")
    }

    private var status: String {
        if isOn { return "In use" }
        if isLocked { return "👑 My Day Pro" }
        return "Tap to use"
    }
}
