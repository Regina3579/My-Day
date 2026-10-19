import SwiftUI

/// Rainbow Glow Unicorn 🦄, a My Day Pro journal theme: My Journal Pages in a pastel sky with
/// rainbows, clouds, golden stars and pink hearts, the castle with "My Journal Pages" and two
/// unicorns at the top, a unicorn peeking beside Write a new page and over My week in moods, a
/// rainbow star with a face for each day with no page, a little unicorn beside the month, dates
/// under a cute rainbow cloud, and a unicorn on every page card in front of a rainbow. The
/// unicorns, the castle and the stars with faces are art from the design; the rainbows, the
/// clouds, the hearts and the cards are drawn here.
enum UnicornStyle {
    static let title = Color(hex: 0x5E0B4E)         // "My week in moods"
    static let month = Color(hex: 0x5A0A2E)         // "October 2026"
    static let glow = Color(hex: 0xF29BD0)
    /// Behind the search bar, at the bottom of the sky.
    static let base = Color(hex: 0xF5E4F4)
    static let cardFill = LinearGradient(colors: [Color.white.opacity(0.96), Color(hex: 0xFFF1F8)],
                                         startPoint: .top, endPoint: .bottom)
    /// The rainbow's bands, outside in.
    static let rainbow: [Color] = [Color(hex: 0xFF9CC8), Color(hex: 0xFFC48C), Color(hex: 0xFFEE98),
                                   Color(hex: 0xA9EBC4), Color(hex: 0xA2D4FF), Color(hex: 0xC9A9FF)]
}

// MARK: - The sky

/// The sky behind My Journal Pages: lilac and pink, rainbows peeking in from the sides, soft
/// clouds, golden stars and glossy pink hearts.
struct UnicornBackdrop: View {
    private static let stars: [(x: CGFloat, y: CGFloat, size: CGFloat, angle: Double)] = [
        (0.04, 0.22, 20, -8), (0.97, 0.3, 18, 10), (0.03, 0.42, 16, 6), (0.97, 0.5, 22, -6),
        (0.04, 0.63, 18, 12), (0.96, 0.7, 16, -10), (0.03, 0.82, 20, -4), (0.97, 0.9, 18, 8),
    ]
    private static let hearts: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.03, 0.3, 16), (0.97, 0.39, 14), (0.02, 0.55, 14), (0.98, 0.6, 16), (0.03, 0.75, 16),
        (0.6, 0.985, 18),
    ]
    private static let clouds: [(x: CGFloat, y: CGFloat, scale: CGFloat, tint: UInt32)] = [
        (-0.04, 0.34, 0.9, 0xFFFFFF), (1.04, 0.26, 1, 0xDDEBFF), (-0.05, 0.58, 1.1, 0xFFE3F1),
        (1.05, 0.66, 0.9, 0xFFFFFF), (-0.03, 0.86, 1, 0xDDEBFF), (1.04, 0.92, 1.1, 0xFFE3F1),
        (0.28, 1.0, 1.3, 0xFFFFFF), (0.74, 1.01, 1.2, 0xFFE3F1),
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(colors: [Color(hex: 0xE2D7FA), Color(hex: 0xF8DDF0), Color(hex: 0xFCE7F2),
                                        Color(hex: 0xE9DEFB)],
                               startPoint: .top, endPoint: .bottom)
                RainbowArc(band: 7)
                    .frame(width: 170, height: 170)
                    .position(x: -10, y: size.height * 0.5)
                RainbowArc(band: 7)
                    .frame(width: 210, height: 210)
                    .position(x: size.width + 20, y: size.height * 0.9)
                ForEach(Self.clouds.indices, id: \.self) { index in
                    let cloud = Self.clouds[index]
                    PuffCloud(tint: Color(hex: cloud.tint))
                        .scaleEffect(cloud.scale)
                        .position(x: size.width * cloud.x, y: size.height * cloud.y)
                }
                ForEach(Self.stars.indices, id: \.self) { index in
                    let star = Self.stars[index]
                    HeavenlyStarView(size: star.size)
                        .rotationEffect(.degrees(star.angle))
                        .position(x: size.width * star.x, y: size.height * star.y)
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

/// A soft rainbow: six pastel bands, as an arch.
struct RainbowArc: View {
    var band: CGFloat = 6

    var body: some View {
        ZStack {
            ForEach(UnicornStyle.rainbow.indices, id: \.self) { index in
                Circle()
                    .trim(from: 0.5, to: 1)
                    .stroke(UnicornStyle.rainbow[index], style: StrokeStyle(lineWidth: band, lineCap: .round))
                    .padding(CGFloat(index) * band + band / 2)
            }
        }
        .opacity(0.85)
        .blur(radius: 1.2)
        .accessibilityHidden(true)
    }
}

/// A cute rainbow cloud: a little pastel rainbow resting on two smiling clouds, for the top of
/// a page's date.
struct RainbowCloud: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let arc = w * 0.78
            ZStack {
                // The top half of the rainbow, its ends resting on the clouds.
                RainbowArc(band: arc * 0.06)
                    .frame(width: arc, height: arc)
                    .frame(width: arc, height: arc * 0.5, alignment: .top)
                    .clipped()
                    .position(x: w / 2, y: h - arc * 0.25 - h * 0.18)
                SmilingCloud()
                    .frame(width: w * 0.42, height: h * 0.5)
                    .position(x: w * 0.23, y: h * 0.72)
                SmilingCloud()
                    .frame(width: w * 0.42, height: h * 0.5)
                    .position(x: w * 0.77, y: h * 0.72)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A small fluffy white cloud with a sleepy smile and rosy cheeks.
struct SmilingCloud: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                Group {
                    Circle().frame(width: w * 0.46, height: w * 0.46).position(x: w * 0.3, y: h * 0.52)
                    Circle().frame(width: w * 0.56, height: w * 0.56).position(x: w * 0.56, y: h * 0.42)
                    Circle().frame(width: w * 0.4, height: w * 0.4).position(x: w * 0.78, y: h * 0.58)
                    Capsule().frame(width: w * 0.92, height: h * 0.42).position(x: w * 0.52, y: h * 0.72)
                }
                .foregroundStyle(LinearGradient(colors: [Color.white, Color(hex: 0xF4ECFF)],
                                                startPoint: .top, endPoint: .bottom))
                .shadow(color: UnicornStyle.glow.opacity(0.45), radius: 1.2, x: 0, y: 0.5)
                // The face: two little eyes, a smile and pink cheeks.
                Circle().fill(Color(hex: 0x3A2340)).frame(width: w * 0.07, height: w * 0.07)
                    .position(x: w * 0.42, y: h * 0.6)
                Circle().fill(Color(hex: 0x3A2340)).frame(width: w * 0.07, height: w * 0.07)
                    .position(x: w * 0.64, y: h * 0.6)
                Path { path in
                    path.move(to: CGPoint(x: w * 0.48, y: h * 0.68))
                    path.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.68), control: CGPoint(x: w * 0.53, y: h * 0.76))
                }
                .stroke(Color(hex: 0xE2557F), style: StrokeStyle(lineWidth: max(0.8, w * 0.035), lineCap: .round))
                Ellipse().fill(Color(hex: 0xFF9EC4).opacity(0.7)).frame(width: w * 0.11, height: w * 0.07)
                    .position(x: w * 0.33, y: h * 0.68)
                Ellipse().fill(Color(hex: 0xFF9EC4).opacity(0.7)).frame(width: w * 0.11, height: w * 0.07)
                    .position(x: w * 0.73, y: h * 0.68)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A puffy cloud, white or tinted.
struct PuffCloud: View {
    var tint: Color = .white

    var body: some View {
        ZStack {
            Circle().frame(width: 56, height: 56).offset(x: -34, y: 8)
            Circle().frame(width: 76, height: 76).offset(x: 4, y: -6)
            Circle().frame(width: 52, height: 52).offset(x: 40, y: 10)
            Capsule().frame(width: 146, height: 40).offset(y: 22)
        }
        .foregroundStyle(tint.opacity(0.85))
        .blur(radius: 4)
        .frame(width: 160, height: 110)
        .accessibilityHidden(true)
    }
}

/// A glossy pink heart.
struct GlossyHeart: View {
    var size: CGFloat = 14

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size))
            .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFA9D2), Color(hex: 0xF7489C)],
                                            startPoint: .top, endPoint: .bottom))
            .shadow(color: UnicornStyle.glow.opacity(0.8), radius: size * 0.3)
            .accessibilityHidden(true)
    }
}

// MARK: - Header and cards

extension JournalScene {
    /// Rainbow Glow Unicorn: the castle and rainbows in the clouds, "My Journal Pages" with
    /// hearts, a winged unicorn and a sleeping one (with room above for the status bar).
    static let rainbowUnicorn = JournalScene(
        imageName: "UnicornHeader", imageSize: CGSize(width: 1320, height: 498), buttonsRow: 309, overlapRows: 0,
        accessibilityLabel: "My Journal Pages")
}

/// A Rainbow Glow Unicorn card: white fading to pink, with a white edge and a soft pink glow.
struct UnicornCardBackground: View {
    var radius: CGFloat = 26

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape
            .fill(UnicornStyle.cardFill)
            .overlay(shape.strokeBorder(Color.white, lineWidth: 1.5))
            .overlay(shape.inset(by: 1.5).strokeBorder(UnicornStyle.glow.opacity(0.3), lineWidth: 0.8))
            .shadow(color: UnicornStyle.glow.opacity(0.28), radius: 9, x: 0, y: 3)
    }
}

/// A day of the week with no page yet: one of the seven rainbow stars with a face.
struct UnicornFaceStar: View {
    let day: Date

    var body: some View {
        let index = ((day.dayNumber % 7) + 7) % 7
        Image("UnicornStar\(index)")
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }
}
