import SwiftUI

/// "Enjoying My Day?", as in the design: the screen takes a soft shade, and a pink card rises
/// with the girl and her puppy resting on its cloud edge, five gold stars, "Rate Now ›" and
/// "Maybe Later". `RatingPrompt` decides when it comes.
///
/// The stars are only a picture (they can't be tapped): the rating itself is given on Apple's
/// own page, as Apple's App Review Guidelines ask.
struct RatingCard: View {
    let onRate: () -> Void
    let onLater: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var floating = false

    /// The card's grid, in the design's pixels: `RatingArt` (the girl, the puppy and the cloud
    /// edge, 652 × 308) at the top, and the card under it, 631 wide, down to 775.
    private static let grid = CGSize(width: 652, height: 775)
    private static let cardWidth: CGFloat = 631
    private static let cardTop: CGFloat = 298
    private static let midX: CGFloat = 325.5

    var body: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width * 0.8, 330)
            let place = TipArtFrame(origin: .zero, scale: width / Self.cardWidth)
            ZStack {
                RatingStyle.shade
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onLater)
                    .opacity(shown ? 1 : 0)
                    .accessibilityHidden(true)
                card(place)
                    .scaleEffect(shown ? 1 : 0.86)
                    .opacity(shown ? 1 : 0)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
        .onAppear {
            SoundEffects.play(.tip)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) { shown = true }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { floating = true }
            }
            UIAccessibility.post(notification: .screenChanged,
                                 argument: "Enjoying My Day? Your little star means a lot!")
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onLater)
    }

    // MARK: The card

    private func card(_ p: TipArtFrame) -> some View {
        ZStack(alignment: .topLeading) {
            UnevenRoundedRectangle(bottomLeadingRadius: p.length(72), bottomTrailingRadius: p.length(72),
                                   style: .continuous)
                .fill(RatingStyle.card)
                .shadow(color: RatingStyle.glow.opacity(0.5), radius: p.length(26))
                .frame(width: p.length(Self.cardWidth), height: p.length(Self.grid.height - Self.cardTop))
                .position(x: p.length(Self.midX), y: p.length((Self.cardTop + Self.grid.height) / 2))
            Image("RatingArt")
                .resizable()
                .frame(width: p.length(Self.grid.width), height: p.length(308))
                .shadow(color: Color.white.opacity(0.45), radius: p.length(8))
                .position(x: p.length(Self.grid.width / 2), y: p.length(154))
                .accessibilityHidden(true)
            decorations(p)
            words(p)
            starsBar(p)
            buttons(p)
            closeButton(p)
        }
        .frame(width: p.length(Self.grid.width), height: p.length(Self.grid.height), alignment: .topLeading)
    }

    /// The hearts, sparkles and the heart in a speech bubble, round the girl and the puppy.
    private func decorations(_ p: TipArtFrame) -> some View {
        let lift = floating ? -p.length(5) : 0
        return ZStack(alignment: .topLeading) {
            sparkle(RatingStyle.brightSparkle, at: CGPoint(x: 456, y: 69), size: CGSize(width: 30, height: 37),
                    scale: floating ? 1.08 : 0.92, p)
            sparkle(RatingStyle.sparkle, at: CGPoint(x: 55, y: 223), size: CGSize(width: 13, height: 20), p)
            heart(at: CGPoint(x: 122, y: 140), size: CGSize(width: 30, height: 25), glows: true, p)
                .offset(y: lift)
            heart(at: CGPoint(x: 78, y: 188), size: CGSize(width: 37, height: 33), glows: true, p)
                .offset(y: -lift)
            heart(at: CGPoint(x: 555, y: 193), size: CGSize(width: 30, height: 27), glows: true, p)
                .offset(y: lift)
            speechBubble(p)
                .offset(y: -lift / 2)
            heart(at: CGPoint(x: 111, y: 331.5), size: CGSize(width: 26, height: 25), glows: false, p)
            heart(at: CGPoint(x: 540, y: 332), size: CGSize(width: 26, height: 24), glows: false, p)
            heart(at: CGPoint(x: 75, y: 406.5), size: CGSize(width: 30, height: 29), glows: false, p)
            heart(at: CGPoint(x: 577.5, y: 406.5), size: CGSize(width: 29, height: 29), glows: false, p)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func heart(at point: CGPoint, size: CGSize, glows: Bool, _ p: TipArtFrame) -> some View {
        Image(systemName: "heart.fill")
            .resizable()
            .foregroundStyle(RatingStyle.heart)
            .frame(width: p.length(size.width), height: p.length(size.height))
            .shadow(color: glows ? Color.white.opacity(0.8) : RatingStyle.glow.opacity(0.35),
                    radius: p.length(glows ? 6 : 3))
            .position(x: p.length(point.x), y: p.length(point.y))
    }

    private func sparkle(_ color: Color, at point: CGPoint, size: CGSize, scale: CGFloat = 1,
                         _ p: TipArtFrame) -> some View {
        Image(systemName: "sparkle")
            .resizable()
            .foregroundStyle(color)
            .frame(width: p.length(size.width), height: p.length(size.height))
            .shadow(color: Color.white.opacity(0.7), radius: p.length(4))
            .scaleEffect(scale)
            .position(x: p.length(point.x), y: p.length(point.y))
    }

    /// A white speech bubble with a pink heart, by the puppy.
    private func speechBubble(_ p: TipArtFrame) -> some View {
        ZStack {
            Path { path in
                path.move(to: p.point(497, 158))
                path.addLine(to: p.point(483, 166))
                path.addLine(to: p.point(487, 150))
                path.closeSubpath()
            }
            .fill(Color.white)
            Circle()
                .fill(Color.white)
                .frame(width: p.length(80), height: p.length(80))
                .position(p.point(517, 128))
            Image(systemName: "heart.fill")
                .resizable()
                .foregroundStyle(RatingStyle.heart)
                .frame(width: p.length(38), height: p.length(33))
                .position(p.point(517, 129))
        }
        .shadow(color: RatingStyle.glow.opacity(0.55), radius: p.length(9))
    }

    // MARK: The words

    private func words(_ p: TipArtFrame) -> some View {
        ZStack(alignment: .topLeading) {
            Text("Enjoying My Day?")
                .font(.system(size: p.length(46), weight: .heavy, design: .rounded))
                .foregroundStyle(RatingStyle.title)
                .shadow(color: RatingStyle.glow.opacity(0.3), radius: p.length(2), y: p.length(1))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: p.length(396))
                .position(x: p.length(Self.midX), y: p.length(333))
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: p.length(8)) {
                Text("Your little")
                Image("RatingStar")
                    .resizable()
                    .frame(width: p.length(40), height: p.length(40))
                Text("means a lot!")
            }
            .font(.system(size: p.length(30), weight: .heavy, design: .rounded))
            .foregroundStyle(RatingStyle.purple)
            .fixedSize()
            .position(x: p.length(Self.midX), y: p.length(392))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Your little star means a lot!")
            VStack(spacing: p.length(9)) {
                Text("If My Day makes your days")
                Text("a little brighter, we’d love your rating.")
            }
            .font(.system(size: p.length(24), weight: .medium, design: .rounded))
            .foregroundStyle(RatingStyle.body)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: p.length(490))
            .position(x: p.length(Self.midX), y: p.length(459.5))
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: The stars

    /// Five gold stars on a pale pink bar, with a sparkle at each end (a picture, not a rating).
    private func starsBar(_ p: TipArtFrame) -> some View {
        let starXs: [CGFloat] = [173.6, 249.7, 326, 402.2, 478.2]
        return ZStack(alignment: .topLeading) {
            Capsule()
                .fill(RatingStyle.bar)
                .overlay(Capsule().strokeBorder(Color.white, lineWidth: p.length(3)))
                .frame(width: p.length(519), height: p.length(93))
                .position(x: p.length(Self.midX), y: p.length(566.5))
            ForEach(starXs.indices, id: \.self) { index in
                Image("RatingStar")
                    .resizable()
                    .frame(width: p.length(65), height: p.length(65))
                    .scaleEffect(shown ? 1 : 0.3)
                    .animation(.spring(response: 0.4, dampingFraction: 0.55).delay(0.15 + Double(index) * 0.07),
                               value: shown)
                    .position(x: p.length(starXs[index]), y: p.length(567))
            }
            sparkle(RatingStyle.sparkle, at: CGPoint(x: 107.6, y: 570.5), size: CGSize(width: 19, height: 25),
                    scale: floating ? 1.1 : 0.9, p)
            sparkle(RatingStyle.sparkle, at: CGPoint(x: 544.1, y: 558.7), size: CGSize(width: 20, height: 25),
                    scale: floating ? 0.9 : 1.1, p)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: The buttons

    private func buttons(_ p: TipArtFrame) -> some View {
        ZStack(alignment: .topLeading) {
            Button(action: onRate) {
                HStack(spacing: p.length(16)) {
                    Text("Rate Now")
                        .font(.system(size: p.length(30), weight: .heavy, design: .rounded))
                    Image(systemName: "chevron.right")
                        .font(.system(size: p.length(22), weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color.white)
                .frame(width: p.length(405), height: p.length(72))
                .background(Capsule().fill(RatingStyle.button))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: p.length(1.5)))
                .shadow(color: RatingStyle.buttonShadow.opacity(0.45), radius: p.length(9), y: p.length(5))
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .position(x: p.length(Self.midX), y: p.length(663))
            .accessibilityLabel("Rate Now")
            .accessibilityHint("Opens Apple's page to rate My Day")
            Button(action: onLater) {
                Text("Maybe Later")
                    .font(.system(size: p.length(22), weight: .semibold, design: .rounded))
                    .foregroundStyle(RatingStyle.later)
                    .frame(width: p.length(240), height: p.length(48))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .position(x: p.length(Self.midX), y: p.length(731))
        }
    }

    /// ✕ on the card's top corner, by the puppy.
    private func closeButton(_ p: TipArtFrame) -> some View {
        Button(action: onLater) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: p.length(98), height: p.length(98))
                    .shadow(color: RatingStyle.glow.opacity(0.35), radius: p.length(8))
                Circle()
                    .fill(RatingStyle.closeFill)
                    .overlay(Circle().strokeBorder(RatingStyle.closeRing, lineWidth: p.length(2)))
                    .frame(width: p.length(60), height: p.length(60))
                Image(systemName: "xmark")
                    .font(.system(size: p.length(24), weight: .semibold))
                    .foregroundStyle(RatingStyle.closeMark)
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .position(x: p.length(599), y: p.length(277))
        .accessibilityLabel("Close")
    }
}

/// Colours of the rating card, sampled from the design.
private enum RatingStyle {
    static let shade = Color(hex: 0x24121E).opacity(0.55)
    static let card = LinearGradient(colors: [Color(hex: 0xFEF8F9), Color(hex: 0xFCEBF0)],
                                     startPoint: .top, endPoint: .bottom)
    static let glow = Color(hex: 0xF46DB4)
    static let title = LinearGradient(colors: [Color(hex: 0xF80B82), Color(hex: 0xE4098F)],
                                      startPoint: .top, endPoint: .bottom)
    static let purple = Color(hex: 0x39049E)
    static let body = Color(hex: 0x7D5A98)
    static let later = Color(hex: 0xA176B0)
    static let heart = LinearGradient(colors: [Color(hex: 0xFF97CC), Color(hex: 0xF7489F)],
                                      startPoint: .top, endPoint: .bottom)
    static let sparkle = Color(hex: 0xFEC43F)
    static let brightSparkle = Color(hex: 0xFFD54A)
    static let bar = LinearGradient(colors: [Color(hex: 0xFCDEF1), Color(hex: 0xFEEAF7)],
                                    startPoint: .top, endPoint: .bottom)
    static let button = LinearGradient(colors: [Color(hex: 0xFE82BE), Color(hex: 0xFA2C82)],
                                       startPoint: .top, endPoint: .bottom)
    static let buttonShadow = Color(hex: 0xF94F9E)
    static let closeFill = Color(hex: 0xFDE3F3)
    static let closeRing = Color(hex: 0xF6C3E0)
    static let closeMark = Color(hex: 0x936AAA)
}
