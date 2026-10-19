import SwiftUI

/// Rose Gold Elegance 🌹, a My Day Pro journal theme: My Journal Pages in soft blush and peach
/// with curtains, hanging gold hearts and pearls at the top, a gold heart ornament over
/// "My Journal Pages", an angel girl hugging a heart, a star with a bow beside Write a new page,
/// cards framed in rose gold with roses at their corners, pale pink stars for days with no page,
/// rose-gold rims on the buttons, dates crowned with a gold filigree heart, and a pink bow at
/// the bottom. The header, the girl, the star, the roses, the crown and the bow are art from the
/// design; the frames, the stars, the hearts and the sparkles are drawn here.
enum RoseStyle {
    static let title = Color(hex: 0x4A0718)         // "My week in moods"
    static let month = Color(hex: 0x45061A)         // "October 2026"
    static let glow = Color(hex: 0xF3A58F)
    /// Behind the search bar, at the bottom of the page.
    static let base = Color(hex: 0xF8D3C8)
    static let roseGold = LinearGradient(colors: [Color(hex: 0xF6D3AA), Color(hex: 0xD58B66), Color(hex: 0xC9774F),
                                                  Color(hex: 0xF1C597)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
    static let goldLine = Color(hex: 0xF0BC8C)
    static let cardFill = LinearGradient(colors: [Color(hex: 0xFFF6F1), Color(hex: 0xFCE7E0)],
                                         startPoint: .top, endPoint: .bottom)
    static let emptyStar = LinearGradient(colors: [Color(hex: 0xFFE6E2), Color(hex: 0xF7BAB6)],
                                          startPoint: .top, endPoint: .bottom)
    static let calendarFill = LinearGradient(colors: [Color(hex: 0xFFE9F1), Color(hex: 0xFBD3E3)],
                                             startPoint: .top, endPoint: .bottom)
}

// MARK: - The page

/// Behind My Journal Pages: blush and peach, soft glows, gold sparkles and little hearts (the
/// roses and the pink bow at the bottom are drawn round the search bar: `RoseSearchBarTrim`).
struct RoseBackdrop: View {
    private static let glows: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.04, 0.28, 46), (0.97, 0.33, 40), (0.02, 0.5, 52), (0.98, 0.56, 44), (0.03, 0.72, 48), (0.97, 0.8, 40),
    ]
    private static let sparkles: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.03, 0.24, 9), (0.97, 0.29, 8), (0.02, 0.43, 7), (0.98, 0.47, 9), (0.03, 0.61, 8), (0.97, 0.66, 7),
        (0.02, 0.78, 9), (0.98, 0.85, 8),
    ]
    private static let hearts: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.03, 0.36, 12), (0.97, 0.42, 11), (0.97, 0.7, 12), (0.03, 0.88, 11),
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(colors: [Color(hex: 0xFBE2D9), Color(hex: 0xF9D3C7), Color(hex: 0xF8C9BE),
                                        Color(hex: 0xF9D6CB)],
                               startPoint: .top, endPoint: .bottom)
                ForEach(Self.glows.indices, id: \.self) { index in
                    let glow = Self.glows[index]
                    Circle()
                        .fill(Color.white.opacity(0.45))
                        .frame(width: glow.size, height: glow.size)
                        .blur(radius: 14)
                        .position(x: size.width * glow.x, y: size.height * glow.y)
                }
                ForEach(Self.sparkles.indices, id: \.self) { index in
                    let sparkle = Self.sparkles[index]
                    HeavenlySparkle(size: sparkle.size)
                        .position(x: size.width * sparkle.x, y: size.height * sparkle.y)
                }
                ForEach(Self.hearts.indices, id: \.self) { index in
                    let heart = Self.hearts[index]
                    GlossyHeart(size: heart.size)
                        .position(x: size.width * heart.x, y: size.height * heart.y)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Header

extension JournalScene {
    /// Rose Gold Elegance: curtains, hanging gold hearts and pearls, the gold heart ornament,
    /// roses and bows, and "My Journal Pages" (with room above for the status bar).
    static let roseGold = JournalScene(
        imageName: "RoseHeader", imageSize: CGSize(width: 1320, height: 465), buttonsRow: 341, overlapRows: 0,
        accessibilityLabel: "My Journal Pages")
}

/// The top of My Journal Pages in Rose Gold Elegance, with the angel girl hugging a heart on
/// its right, in front of the card below (as in the design).
struct RoseHeader: View {
    let width: CGFloat
    let statusBar: CGFloat

    /// The girl's place in the design (852 wide), in the header's rows (60 added on top): she
    /// reaches a little below the header, over the card under it.
    private static let girl = CGRect(x: 571, y: 74 + 60, width: 143, height: 189)
    private static let designWidth: CGFloat = 852

    var body: some View {
        let scene = JournalScene.roseGold
        let s = width / Self.designWidth
        let top = scene.topRow(width: width, statusBar: statusBar) * scene.scale(width: width) / s
        JournalHero(scene: scene, width: width, statusBar: statusBar)
            .overlay(alignment: .topLeading) {
                Image("RoseHeaderGirl")
                    .resizable()
                    .scaledToFit()
                    .frame(width: Self.girl.width * s, height: Self.girl.height * s)
                    .offset(x: Self.girl.minX * s, y: (Self.girl.minY - top) * s)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }
}

// MARK: - Cards and pieces

/// A Rose Gold Elegance card: blush cream, framed in rose gold with a fine gold line inside.
struct RoseCardBackground: View {
    var radius: CGFloat = 26

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape
            .fill(RoseStyle.cardFill)
            .overlay(shape.strokeBorder(RoseStyle.roseGold, lineWidth: 2))
            .overlay(shape.inset(by: 2).strokeBorder(Color.white.opacity(0.9), lineWidth: 1))
            .overlay(shape.inset(by: 4.5).strokeBorder(RoseStyle.goldLine.opacity(0.75), lineWidth: 0.8))
            .shadow(color: RoseStyle.glow.opacity(0.35), radius: 8, x: 0, y: 3)
    }
}

/// A day of the week with no page yet: a pale pink star.
struct RoseEmptyStar: View {
    var body: some View {
        RoundedStar(innerRatio: 0.48)
            .fill(RoseStyle.emptyStar)
            .overlay(RoundedStar(innerRatio: 0.48).stroke(Color.white.opacity(0.85), lineWidth: 1))
            .shadow(color: RoseStyle.glow.opacity(0.4), radius: 2, x: 0, y: 1)
            .frame(width: 38, height: 38)
            .accessibilityHidden(true)
    }
}

/// Round the search bar at the bottom, as in the design: roses and leaves in both corners and
/// the pink bow with its gold heart under the middle.
struct RoseSearchBarTrim: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            HStack {
                Image("RoseCorner")
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(x: -1, y: 1)
                    .frame(width: 76, height: 48)
                Spacer()
                Image("RoseCorner")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 48)
            }
            .padding(.horizontal, -8)
            // Just under the bar's outer corners, clear of the search icon and Filter.
            .offset(y: 40)
            Image("RoseBow")
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 55)
                .offset(y: 36)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
