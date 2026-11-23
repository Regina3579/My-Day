import SwiftUI

/// Cozy Rainy Day ☔, a My Day Pro journal theme: My Journal Pages on a soft frosted panel by a
/// rainy window, its frame, lanterns and hydrangeas down both sides, the girl resting her head
/// beside her sleeping puppy at the top with cocoa and "Good Things Ahead" books, a bunny under
/// a pink umbrella beside Write a new page, little rain clouds with faces for days with no
/// page, an umbrella beside the month, dates under umbrellas, a cosy rainy scene on every page
/// card, and rain boots and a sleeping kitten by the search bar. The pictures are from the
/// design; the raindrops, the panel and the cards are drawn here.
enum RainyStyle {
    static let title = Color(hex: 0x3E0626)         // "My week in moods"
    static let month = Color(hex: 0x3E0624)         // "October 2026"
    static let glow = Color(hex: 0xE9A9C4)
    /// The frosted panel the cards sit on, and behind the search bar.
    static let base = Color(hex: 0xF6E9E9)
    static let cardFill = LinearGradient(colors: [Color(hex: 0xFFFBFB), Color(hex: 0xFCF0F1)],
                                         startPoint: .top, endPoint: .bottom)
    static let drop = LinearGradient(colors: [Color(hex: 0xEAF4FF), Color(hex: 0x9EC5F2)],
                                     startPoint: .top, endPoint: .bottom)
    /// How wide the window's edges are in the design (64 of its 1672 rows tall).
    static let edgeRatio: CGFloat = 64.0 / 1672.0
}

// MARK: - The window and the panel

/// Behind My Journal Pages: the frosted panel, with the rainy window (its wooden frame, rain on
/// the glass, glowing lanterns and hydrangeas) down both sides, and raindrops on the panel.
struct RainyBackdrop: View {
    private static let drops: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.1, 0.3, 9), (0.92, 0.36, 8), (0.09, 0.47, 7), (0.91, 0.55, 9), (0.1, 0.64, 8), (0.92, 0.71, 7),
        (0.09, 0.8, 9), (0.91, 0.86, 8),
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let edge = max(24, size.height * RainyStyle.edgeRatio)
            ZStack {
                LinearGradient(colors: [Color(hex: 0xF7EEF1), RainyStyle.base, Color(hex: 0xF7ECEA)],
                               startPoint: .top, endPoint: .bottom)
                HStack(spacing: 0) {
                    Image("RainyEdgeLeft")
                        .resizable()
                        .frame(width: edge, height: size.height)
                    Spacer(minLength: 0)
                    Image("RainyEdgeRight")
                        .resizable()
                        .frame(width: edge, height: size.height)
                }
                // The panel's soft edge against the window.
                HStack(spacing: 0) {
                    LinearGradient(colors: [Color.black.opacity(0.12), Color.clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 6)
                    Spacer(minLength: 0)
                    LinearGradient(colors: [Color.clear, Color.black.opacity(0.12)], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 6)
                }
                .padding(.horizontal, edge)
                ForEach(Self.drops.indices, id: \.self) { index in
                    let drop = Self.drops[index]
                    RainDropView(size: drop.size)
                        .position(x: size.width * drop.x, y: size.height * drop.y)
                }
            }
            // Drawn once: its blurred clouds, glows and stars would otherwise be painted again
            // on every frame while the pages scroll over it.
            .drawingGroup()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A glossy raindrop.
struct RainDropView: View {
    var size: CGFloat = 9

    var body: some View {
        RainDropShape()
            .fill(RainyStyle.drop)
            .overlay(RainDropShape().stroke(Color.white.opacity(0.9), lineWidth: 0.6))
            .frame(width: size * 0.72, height: size)
            .shadow(color: Color(hex: 0x8FB6E8).opacity(0.4), radius: 1, x: 0, y: 0.5)
            .accessibilityHidden(true)
            .renderedOnce(bleed: 3)
    }
}

/// A teardrop, pointed at the top.
struct RainDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = rect.width / 2
        let c = CGPoint(x: rect.midX, y: rect.maxY - r)
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.maxX, y: c.y),
                      control1: CGPoint(x: rect.midX + r * 0.35, y: rect.minY + rect.height * 0.3),
                      control2: CGPoint(x: rect.maxX, y: c.y - r * 0.6))
        path.addArc(center: c, radius: r, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                      control1: CGPoint(x: rect.minX, y: c.y - r * 0.6),
                      control2: CGPoint(x: rect.midX - r * 0.35, y: rect.minY + rect.height * 0.3))
        path.closeSubpath()
        return path
    }
}

// MARK: - Header and pieces

extension JournalScene {
    /// Cozy Rainy Day: the rainy window, the girl and her sleeping puppy on the sill, cocoa,
    /// a candle, books and "My Journal Pages" (with room above for the status bar).
    static let rainy = JournalScene(
        imageName: "RainyHeader", imageSize: CGSize(width: 1320, height: 460), buttonsRow: 354, overlapRows: 0,
        accessibilityLabel: "My Journal Pages")
}

/// A Cozy Rainy Day card: white fading to blush, with a white edge and a soft pink shadow.
struct RainyCardBackground: View {
    var radius: CGFloat = 26

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape
            .fill(RainyStyle.cardFill)
            .overlay(shape.strokeBorder(Color.white, lineWidth: 1.5))
            .shadow(color: RainyStyle.glow.opacity(0.3), radius: 9, x: 0, y: 3)
            .renderedOnce(bleed: 16)
    }
}

/// A day of the week with no page yet: one of the seven little rain clouds with faces.
struct RainyCloudFace: View {
    let day: Date

    var body: some View {
        let index = ((day.dayNumber % 7) + 7) % 7
        Image("RainyCloud\(index)")
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }
}

/// By the search bar, as in the design: pink rain boots on the left and cocoa beside a kitten
/// asleep on a pink blanket on the right.
struct RainySearchBarTrim: View {
    var body: some View {
        HStack(alignment: .bottom) {
            Image("RainyBoots")
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 120)
            Spacer()
            Image("RainyCozyCorner")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 64)
        }
        .padding(.horizontal, -8)
        .offset(y: 34)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
