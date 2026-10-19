import SwiftUI

/// The ⋮ menu of My Journal Pages, as in its design: a cream card framed in gold under a pink
/// heart bow, with a row for each choice (its picture in a soft round badge, its name in plum,
/// pink hearts), the first one in pink. The bow and the pictures are from the design; the card,
/// the hearts and the lines are drawn here.
struct JournalPagesMenu: View {
    struct Item: Identifiable {
        let title: String
        let art: String
        let action: () -> Void
        var id: String { title }
    }

    let items: [Item]
    /// Where Journal Theme is on screen (for its first-time tip).
    var onThemeRowFrame: ((CGRect) -> Void)?

    private static let plum = Color(hex: 0x6B1442)
    private static let gold = LinearGradient(colors: [Color(hex: 0xF6D9A6), Color(hex: 0xE2A76B), Color(hex: 0xF4CF98),
                                                      Color(hex: 0xD99A62)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
    private static let heart = LinearGradient(colors: [Color(hex: 0xFFC2DA), Color(hex: 0xF77BAE)],
                                              startPoint: .top, endPoint: .bottom)

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle()
                        .fill(Color(hex: 0xF4D6DB))
                        .frame(height: 1)
                        .padding(.horizontal, 12)
                }
                row(item, highlighted: index == 0)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(width: 236)
        .background(card)
        .overlay(alignment: .top) {
            Image("JournalMenuBow")
                .resizable()
                .scaledToFit()
                .frame(width: 112, height: 61)
                .offset(x: -6, y: -34)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private func row(_ item: Item, highlighted: Bool) -> some View {
        Button(action: item.action) {
            HStack(spacing: 10) {
                Image(item.art)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .frame(width: 46, height: 46)
                    .background(
                        Circle()
                            .fill(RadialGradient(colors: [Color.white, Color(hex: 0xFDECEF)], center: .center,
                                                 startRadius: 4, endRadius: 24))
                            .overlay(Circle().strokeBorder(Color(hex: 0xF7C9D6), lineWidth: 1))
                            .shadow(color: Color(hex: 0xF29DBE).opacity(0.3), radius: 3, x: 0, y: 1)
                    )
                    .accessibilityHidden(true)
                Text(item.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Self.plum)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 2)
                hearts
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(minHeight: 60)
            .background {
                if highlighted {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: 0xFDE3EE), Color(hex: 0xFAD0E2)],
                                             startPoint: .leading, endPoint: .trailing))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.8), lineWidth: 1))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle(scale: 0.97))
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
            if item.art == "JournalMenuTheme" { onThemeRowFrame?(frame) }
        }
        .accessibilityLabel(item.title)
    }

    /// A big pink heart and a little one beside each name.
    private var hearts: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "heart.fill")
                .font(.system(size: 17))
                .foregroundStyle(Self.heart)
                .offset(x: -2, y: 4)
            Image(systemName: "heart.fill")
                .font(.system(size: 9))
                .foregroundStyle(Self.heart)
                .offset(x: 4, y: -4)
        }
        .frame(width: 26, height: 26)
        .accessibilityHidden(true)
    }

    /// Cream fading to blush, framed in gold with a white line inside, and a soft pink glow.
    private var card: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        return shape
            .fill(LinearGradient(colors: [Color(hex: 0xFFF9F6), Color(hex: 0xFDEEEF)], startPoint: .top, endPoint: .bottom))
            .overlay(shape.strokeBorder(Self.gold, lineWidth: 2.5))
            .overlay(shape.inset(by: 3).strokeBorder(Color.white.opacity(0.9), lineWidth: 1))
            .overlay(shape.inset(by: 5).strokeBorder(Color(hex: 0xF1C99C).opacity(0.6), lineWidth: 0.7))
            .shadow(color: Color(hex: 0xE88AB0).opacity(0.3), radius: 14, x: 0, y: 6)
            .renderedOnce(bleed: 24)
    }
}
