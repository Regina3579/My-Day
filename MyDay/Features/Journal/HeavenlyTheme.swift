import SwiftUI

/// Heavenly Angel Wishes 👼, a My Day Pro journal theme: My Journal Pages in a pastel sky with
/// golden stars and clouds, the castle and the moon at the top, little angels on the cards,
/// gold-edged cards, small wings on the buttons and bold serif headings. The angels, the
/// castle and the stars are art from the design; the wings, the moon, the sparkles and the
/// cards are drawn here.
enum HeavenlyStyle {
    static let title = Color(hex: 0x4A0E4E)         // "My Journal Pages", "My week in moods"
    static let month = Color(hex: 0x7A0D42)         // "October 2026"
    static let gold = Color(hex: 0xF7AE4E)          // the cards' gold edges
    static let glow = Color(hex: 0xFFC860)
    static let wingEdge = Color(hex: 0xF2AEC6)
    /// Behind the search bar, at the bottom of the sky.
    static let base = Color(hex: 0xFAE8EE)
    static let goldEdge = LinearGradient(colors: [Color(hex: 0xFFD77F), Color(hex: 0xF4A445), Color(hex: 0xFFD77F)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardFill = LinearGradient(colors: [Color(hex: 0xFFFBF5), Color(hex: 0xFDF0E8)],
                                         startPoint: .top, endPoint: .bottom)
    static let pinkStar = LinearGradient(colors: [Color(hex: 0xFFE2F0), Color(hex: 0xF8A9D1)],
                                         startPoint: .top, endPoint: .bottom)

    /// The design's headings: a bold serif.
    static func serif(_ style: Font.TextStyle) -> Font {
        .system(style, design: .serif, weight: .bold)
    }
}

// MARK: - The sky

/// The sky behind My Journal Pages: lavender at the top right, warm pink and cream below, soft
/// clouds along the sides and golden stars and sparkles peeking out between the cards.
struct HeavenlyBackdrop: View {
    /// Gold stars: where (fractions of the screen), how big, and turned how far.
    private static let stars: [(x: CGFloat, y: CGFloat, size: CGFloat, angle: Double)] = [
        (0.03, 0.19, 22, -8), (0.97, 0.24, 18, 10), (0.02, 0.37, 16, 6), (0.98, 0.44, 22, -6),
        (0.03, 0.56, 20, 12), (0.97, 0.62, 16, -10), (0.02, 0.74, 22, -4), (0.98, 0.81, 20, 8),
        (0.04, 0.92, 18, 10), (0.96, 0.97, 22, -8),
    ]
    private static let sparkles: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.015, 0.28, 9), (0.985, 0.33, 8), (0.02, 0.47, 7), (0.985, 0.53, 9), (0.015, 0.66, 8),
        (0.985, 0.71, 7), (0.02, 0.84, 9), (0.98, 0.89, 8),
    ]
    private static let clouds: [(x: CGFloat, y: CGFloat, scale: CGFloat)] = [
        (-0.04, 0.30, 0.9), (1.04, 0.36, 1), (-0.05, 0.62, 1.1), (1.05, 0.70, 0.9),
        (-0.03, 0.88, 1), (1.04, 0.95, 1.1), (0.3, 1.0, 1.3), (0.72, 1.01, 1.2),
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(colors: [Color(hex: 0xE6DAF7), Color(hex: 0xF7E1EF), Color(hex: 0xFDEAE7),
                                        Color(hex: 0xF8E3EE)],
                               startPoint: .topTrailing, endPoint: .bottomLeading)
                RadialGradient(colors: [Color(hex: 0xE3D1F3).opacity(0.85), Color(hex: 0xE3D1F3).opacity(0)],
                               center: UnitPoint(x: 1, y: 0.55), startRadius: 0, endRadius: size.width * 0.7)
                ForEach(Self.clouds.indices, id: \.self) { index in
                    let cloud = Self.clouds[index]
                    HeavenlyCloud()
                        .scaleEffect(cloud.scale)
                        .position(x: size.width * cloud.x, y: size.height * cloud.y)
                }
                ForEach(Self.stars.indices, id: \.self) { index in
                    let star = Self.stars[index]
                    HeavenlyStarView(size: star.size)
                        .rotationEffect(.degrees(star.angle))
                        .position(x: size.width * star.x, y: size.height * star.y)
                }
                ForEach(Self.sparkles.indices, id: \.self) { index in
                    let sparkle = Self.sparkles[index]
                    HeavenlySparkle(size: sparkle.size)
                        .position(x: size.width * sparkle.x, y: size.height * sparkle.y)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A soft white puff of cloud.
private struct HeavenlyCloud: View {
    var body: some View {
        ZStack {
            Circle().frame(width: 58, height: 58).offset(x: -34, y: 8)
            Circle().frame(width: 78, height: 78).offset(x: 4, y: -6)
            Circle().frame(width: 54, height: 54).offset(x: 42, y: 10)
            Capsule().frame(width: 150, height: 42).offset(y: 22)
        }
        .foregroundStyle(Color.white.opacity(0.78))
        .blur(radius: 6)
        .frame(width: 160, height: 110)
    }
}

// MARK: - The header

extension JournalScene {
    /// Heavenly Angel Wishes: the sky with the castle, the moon, golden stars and two angels
    /// (with room above for the status bar; the title is drawn on it).
    static let heavenly = JournalScene(
        imageName: "HeavenlyHeader", imageSize: CGSize(width: 1320, height: 369), buttonsRow: 285, overlapRows: 0,
        accessibilityLabel: "My Journal Pages")
}

/// The top of My Journal Pages: the castle in the clouds, with "My Journal Pages" in the bold
/// serif of the design, on the row of the back and ⋮ buttons, between the two angels.
struct HeavenlyHeader: View {
    let width: CGFloat
    let statusBar: CGFloat

    var body: some View {
        let scene = JournalScene.heavenly
        let scale = scene.scale(width: width)
        let row = (scene.buttonsRow - scene.topRow(width: width, statusBar: statusBar)) * scale
        JournalHero(scene: scene, width: width, statusBar: statusBar)
            .overlay(alignment: .topLeading) {
                Text("My Journal Pages")
                    .font(.system(size: 21, weight: .bold, design: .serif))
                    .foregroundStyle(HeavenlyStyle.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .shadow(color: Color.white.opacity(0.9), radius: 3)
                    .frame(width: width * 0.37)
                    .position(x: width * 0.537, y: row)
                    .accessibilityHidden(true)
            }
    }
}

// MARK: - Cards

/// A Heavenly card: cream, with a double gold edge and a soft golden glow.
struct HeavenlyCardBackground: View {
    var radius: CGFloat = 26

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape
            .fill(HeavenlyStyle.cardFill)
            .overlay(shape.strokeBorder(HeavenlyStyle.goldEdge, lineWidth: 1.6))
            .overlay(
                RoundedRectangle(cornerRadius: radius - 2.5, style: .continuous)
                    .strokeBorder(Color.white, lineWidth: 1)
                    .padding(1.6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius - 3.5, style: .continuous)
                    .strokeBorder(HeavenlyStyle.gold.opacity(0.55), lineWidth: 0.8)
                    .padding(3.3)
            )
            .shadow(color: HeavenlyStyle.glow.opacity(0.3), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Little pieces

/// One of the design's glossy golden stars.
struct HeavenlyStarView: View {
    var size: CGFloat = 18

    var body: some View {
        Image("HeavenlyStar")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: HeavenlyStyle.glow.opacity(0.7), radius: size * 0.2)
            .accessibilityHidden(true)
    }
}

/// A four-pointed twinkle, white with a gold glow.
struct HeavenlySparkle: View {
    var size: CGFloat = 10

    var body: some View {
        TwinkleShape()
            .fill(Color.white)
            .frame(width: size, height: size)
            .shadow(color: HeavenlyStyle.glow, radius: size * 0.3)
            .accessibilityHidden(true)
    }
}

private struct TwinkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let tips = [CGPoint(x: c.x, y: c.y - r), CGPoint(x: c.x + r, y: c.y),
                    CGPoint(x: c.x, y: c.y + r), CGPoint(x: c.x - r, y: c.y)]
        var path = Path()
        path.move(to: tips[0])
        for index in 0..<4 {
            path.addQuadCurve(to: tips[(index + 1) % 4], control: c)
        }
        path.closeSubpath()
        return path
    }
}

/// A golden crescent moon.
struct HeavenlyMoon: View {
    var body: some View {
        CrescentShape()
            .fill(LinearGradient(colors: [Color(hex: 0xFFF4B0), Color(hex: 0xFFD45C), Color(hex: 0xF5A43A)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(CrescentShape().stroke(Color(hex: 0xF09A2E), lineWidth: 0.8))
            .shadow(color: HeavenlyStyle.glow.opacity(0.8), radius: 3)
            .accessibilityHidden(true)
    }
}

private struct CrescentShape: Shape {
    func path(in rect: CGRect) -> Path {
        let outer = Path(ellipseIn: rect)
        let inner = Path(ellipseIn: rect.offsetBy(dx: rect.width * 0.3, dy: -rect.height * 0.16)
            .insetBy(dx: rect.width * 0.05, dy: rect.height * 0.05))
        return outer.subtracting(inner)
    }
}

/// A soft pink star with little wings: a day of the week with no page yet.
struct WingedPinkStar: View {
    var body: some View {
        RoundedStar()
            .fill(HeavenlyStyle.pinkStar)
            .overlay(RoundedStar().stroke(Color.white.opacity(0.9), lineWidth: 1))
            .shadow(color: Color(hex: 0xF6A3CB).opacity(0.5), radius: 2, x: 0, y: 1)
            .frame(width: 34, height: 34)
            .angelWings(width: 11, tucked: 0.35, y: 2)
            .accessibilityHidden(true)
    }
}

/// A five-pointed star with rounded points.
struct RoundedStar: Shape {
    var innerRatio: CGFloat = 0.5

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.04)
        let r = min(rect.width, rect.height) / 2
        let points: [CGPoint] = (0..<10).map { index in
            let angle = -CGFloat.pi / 2 + CGFloat(index) * .pi / 5
            let radius = index.isMultiple(of: 2) ? r : r * innerRatio
            return CGPoint(x: c.x + cos(angle) * radius, y: c.y + sin(angle) * radius)
        }
        func toward(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }
        var path = Path()
        for index in 0..<10 {
            let point = points[index]
            let t: CGFloat = index.isMultiple(of: 2) ? 0.22 : 0.12
            let from = toward(point, points[(index + 9) % 10], t)
            let to = toward(point, points[(index + 1) % 10], t)
            if index == 0 { path.move(to: from) } else { path.addLine(to: from) }
            path.addQuadCurve(to: to, control: point)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Wings

/// A little angel wing: a feathered white wing with a pink edge, pointing up and out to the
/// left (mirrored, to the right).
struct AngelWing: View {
    var mirrored = false

    var body: some View {
        ZStack {
            WingShape()
                .fill(LinearGradient(colors: [Color.white, Color(hex: 0xFFF0F6)], startPoint: .top, endPoint: .bottom))
            FeatherLines()
                .stroke(HeavenlyStyle.wingEdge.opacity(0.75), style: StrokeStyle(lineWidth: 0.6, lineCap: .round))
            WingShape()
                .stroke(HeavenlyStyle.wingEdge, style: StrokeStyle(lineWidth: 0.9, lineJoin: .round))
        }
        .scaleEffect(x: mirrored ? -1 : 1)
        .shadow(color: HeavenlyStyle.glow.opacity(0.35), radius: 1.5)
        .accessibilityHidden(true)
    }
}

private struct WingShape: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var path = Path()
        path.move(to: p(1, 0.62))
        path.addCurve(to: p(0.03, 0.04), control1: p(0.82, 0.16), control2: p(0.32, -0.06))
        path.addQuadCurve(to: p(0.22, 0.40), control: p(-0.04, 0.34))
        path.addQuadCurve(to: p(0.46, 0.66), control: p(0.18, 0.72))
        path.addQuadCurve(to: p(0.74, 0.90), control: p(0.46, 0.99))
        path.addQuadCurve(to: p(1, 0.86), control: p(0.88, 1.04))
        path.closeSubpath()
        return path
    }
}

private struct FeatherLines: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var path = Path()
        path.move(to: p(0.92, 0.6))
        path.addQuadCurve(to: p(0.26, 0.38), control: p(0.56, 0.36))
        path.move(to: p(0.94, 0.7))
        path.addQuadCurve(to: p(0.5, 0.64), control: p(0.72, 0.6))
        return path
    }
}

extension View {
    /// A pair of little angel wings behind the left and right sides (when `isShown`). `tucked`
    /// is how much of each wing hides behind the view.
    func angelWings(width: CGFloat, tucked: CGFloat = 0.3, y: CGFloat = 0, isShown: Bool = true) -> some View {
        let height = width * 1.3
        return background(alignment: .leading) {
            if isShown {
                AngelWing()
                    .frame(width: width, height: height)
                    .offset(x: -width * (1 - tucked), y: y)
            }
        }
        .background(alignment: .trailing) {
            if isShown {
                AngelWing(mirrored: true)
                    .frame(width: width, height: height)
                    .offset(x: width * (1 - tucked), y: y)
            }
        }
    }

    /// One angel wing behind the right side (when `isShown`).
    func angelWingTrailing(width: CGFloat, tucked: CGFloat = 0.3, y: CGFloat = 0, isShown: Bool = true) -> some View {
        background(alignment: .trailing) {
            if isShown {
                AngelWing(mirrored: true)
                    .frame(width: width, height: width * 1.3)
                    .offset(x: width * (1 - tucked), y: y)
            }
        }
    }
}
