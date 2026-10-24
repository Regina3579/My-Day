import SwiftUI

/// Enchanted Fairy Garden 🧚, a My Day Pro journal theme: My Journal Pages in a flower garden,
/// with the "My Journal Pages" sign and two fairies at the top, a fairy asleep on a mushroom
/// beside Write a new page, cream cards with green vines and little pink flowers, a flower with
/// a face for each day with no page, butterflies and mushrooms on the dates, and a fairy on
/// every page card. The fairies, the sign, the flowers with faces, the butterflies and the
/// mushrooms are art from the design; the vines, the garden behind and the cards are drawn here.
enum FairyStyle {
    static let title = Color(hex: 0x5A0B45)         // "My week in moods"
    static let month = Color(hex: 0x5C0B3A)         // "October 2026"
    static let stem = Color(hex: 0x6FA34A)
    static let leaf = Color(hex: 0x86BC52)
    static let leafDark = Color(hex: 0x5E9A3C)
    static let petal = Color(hex: 0xF9AFCD)
    static let petalEdge = Color(hex: 0xEE7FB0)
    static let wood = Color(hex: 0xCDA77A)          // the date's frame
    static let glow = Color(hex: 0xF4A3C8)
    /// Behind the search bar, at the bottom of the garden.
    static let base = Color(hex: 0xF6E7EE)
    static let cardFill = LinearGradient(colors: [Color(hex: 0xFFFBF7), Color(hex: 0xFDF3F0)],
                                         startPoint: .top, endPoint: .bottom)
    static let parchment = LinearGradient(colors: [Color(hex: 0xFFF8EC), Color(hex: 0xF7EAD6)],
                                          startPoint: .top, endPoint: .bottom)
}

// MARK: - The garden

/// The garden behind My Journal Pages: lavender above, pink and cream below, wisteria along
/// the sides, golden glows, and mushrooms and flowers at the bottom.
struct FairyBackdrop: View {
    private static let wisteria: [(x: CGFloat, y: CGFloat, height: CGFloat, color: UInt32)] = [
        (0.0, 0.2, 120, 0xB89BE6), (1.0, 0.27, 110, 0xC7A6EE), (0.0, 0.45, 140, 0xD2A9E8),
        (1.0, 0.52, 130, 0xB89BE6), (0.0, 0.7, 120, 0xC7A6EE), (1.0, 0.78, 140, 0xD2A9E8),
    ]
    private static let glows: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.02, 0.24, 7), (0.97, 0.3, 9), (0.03, 0.4, 6), (0.98, 0.47, 7), (0.02, 0.58, 9), (0.97, 0.63, 6),
        (0.03, 0.74, 7), (0.98, 0.82, 8), (0.04, 0.88, 6), (0.95, 0.9, 7), (0.2, 0.97, 8), (0.8, 0.96, 7),
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(colors: [Color(hex: 0xEADBF3), Color(hex: 0xF7DDEB), Color(hex: 0xFBE9EE),
                                        Color(hex: 0xF1EEDD)],
                               startPoint: .top, endPoint: .bottom)
                ForEach(Self.wisteria.indices, id: \.self) { index in
                    let bunch = Self.wisteria[index]
                    Capsule()
                        .fill(Color(hex: bunch.color).opacity(0.75))
                        .frame(width: 38, height: bunch.height)
                        .blur(radius: 10)
                        .position(x: size.width * bunch.x, y: size.height * bunch.y)
                }
                ForEach(Self.glows.indices, id: \.self) { index in
                    let glow = Self.glows[index]
                    Circle()
                        .fill(Color(hex: 0xFFF1B8))
                        .frame(width: glow.size, height: glow.size)
                        .shadow(color: Color(hex: 0xFFD66B), radius: glow.size * 0.8)
                        .position(x: size.width * glow.x, y: size.height * glow.y)
                }
                // Grass and flowers along the bottom, and two mushrooms.
                LinearGradient(colors: [Color(hex: 0xCFE3A6).opacity(0), Color(hex: 0xBFD98F).opacity(0.7)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 90)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                Image("FairyMushroomPink")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 44)
                    .position(x: size.width - 14, y: size.height - 30)
                Image("FairyMushroomViolet")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 38)
                    .position(x: 12, y: size.height - 26)
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

// MARK: - Cards

extension JournalScene {
    /// Enchanted Fairy Garden: the garden with its lanterns and mushroom house, and the
    /// "My Journal Pages" sign with two fairies (with room above for the status bar).
    static let fairyGarden = JournalScene(
        imageName: "FairyHeader", imageSize: CGSize(width: 1320, height: 446), buttonsRow: 297, overlapRows: 0,
        accessibilityLabel: "My Journal Pages")
}

/// An Enchanted Fairy Garden card: cream, with a soft pink glow and green vines with leaves
/// and little flowers climbing round its top-left and bottom-right corners.
struct FairyCardBackground: View {
    var radius: CGFloat = 26

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape
            .fill(FairyStyle.cardFill)
            .overlay(shape.strokeBorder(Color.white, lineWidth: 1.5))
            .overlay(shape.inset(by: 1.5).strokeBorder(FairyStyle.glow.opacity(0.35), lineWidth: 0.8))
            .shadow(color: FairyStyle.glow.opacity(0.25), radius: 8, x: 0, y: 3)
            .overlay(FairyVines(radius: radius))
            .renderedOnce(bleed: 16)
    }
}

/// Vines with leaves and little flowers round the top-left and bottom-right corners of a
/// rounded rectangle the size of the view.
struct FairyVines: View {
    var radius: CGFloat = 26
    /// How far along the sides they climb (a fraction of each side).
    var reach: CGFloat = 0.45
    var leafLength: CGFloat = 8

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 1.2
            let r = min(radius, size.height / 2, size.width / 2)
            var topLeading = Path()
            topLeading.move(to: CGPoint(x: inset, y: size.height * (1 - reach) * 0.9))
            topLeading.addLine(to: CGPoint(x: inset, y: r))
            topLeading.addQuadCurve(to: CGPoint(x: r, y: inset), control: CGPoint(x: inset, y: inset))
            topLeading.addLine(to: CGPoint(x: size.width * reach * 0.75, y: inset))
            var bottomTrailing = Path()
            bottomTrailing.move(to: CGPoint(x: size.width - inset, y: size.height * reach))
            bottomTrailing.addLine(to: CGPoint(x: size.width - inset, y: size.height - r))
            bottomTrailing.addQuadCurve(to: CGPoint(x: size.width - r, y: size.height - inset),
                                        control: CGPoint(x: size.width - inset, y: size.height - inset))
            bottomTrailing.addLine(to: CGPoint(x: size.width * (1 - reach * 0.75), y: size.height - inset))
            for path in [topLeading, bottomTrailing] {
                FairyVineDrawing.draw(path, in: &context, leafLength: leafLength)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A vine along a straight line, for under the tabs.
struct FairyVineLine: View {
    var leafLength: CGFloat = 8

    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 6, y: size.height / 2))
            path.addCurve(to: CGPoint(x: size.width - 6, y: size.height / 2),
                          control1: CGPoint(x: size.width * 0.33, y: size.height * 0.1),
                          control2: CGPoint(x: size.width * 0.66, y: size.height * 0.9))
            FairyVineDrawing.draw(path, in: &context, leafLength: leafLength, leaves: 16, flowers: [0.12, 0.38, 0.62, 0.88])
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

enum FairyVineDrawing {
    /// Draws a green stem along `path`, leaves on alternate sides and little pink flowers at
    /// `flowers` (fractions of the way along).
    static func draw(_ path: Path, in context: inout GraphicsContext, leafLength: CGFloat, leaves: Int = 9,
                     flowers: [CGFloat] = [0.06, 0.5, 0.94]) {
        context.stroke(path, with: .color(FairyStyle.stem), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        for index in 0..<leaves {
            let t = (CGFloat(index) + 0.5) / CGFloat(leaves)
            guard let spot = point(on: path, at: t), let ahead = point(on: path, at: min(1, t + 0.02)) else { continue }
            let along = atan2(ahead.y - spot.y, ahead.x - spot.x)
            let side: CGFloat = index.isMultiple(of: 2) ? 1 : -1
            let length = leafLength * (index.isMultiple(of: 3) ? 0.8 : 1)
            let leaf = leafPath(length: length)
                .applying(CGAffineTransform(rotationAngle: along + side * 0.85)
                    .concatenating(CGAffineTransform(translationX: spot.x, y: spot.y)))
            context.fill(leaf, with: .color(index.isMultiple(of: 2) ? FairyStyle.leaf : FairyStyle.leafDark))
        }
        for t in flowers {
            guard let spot = point(on: path, at: t) else { continue }
            drawFlower(at: spot, radius: leafLength * 0.62, in: &context)
        }
    }

    static func point(on path: Path, at t: CGFloat) -> CGPoint? {
        path.trimmedPath(from: 0, to: max(0.0001, t)).currentPoint
    }

    /// A pointed leaf from (0, 0) along +x.
    private static func leafPath(length: CGFloat) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addQuadCurve(to: CGPoint(x: length, y: 0), control: CGPoint(x: length * 0.5, y: -length * 0.42))
        path.addQuadCurve(to: .zero, control: CGPoint(x: length * 0.5, y: length * 0.42))
        return path
    }

    /// Five pink petals round a soft yellow middle.
    static func drawFlower(at center: CGPoint, radius: CGFloat, in context: inout GraphicsContext) {
        for petal in 0..<5 {
            let angle = CGFloat(petal) * 2 * .pi / 5 - .pi / 2
            let c = CGPoint(x: center.x + cos(angle) * radius * 0.62, y: center.y + sin(angle) * radius * 0.62)
            let rect = CGRect(x: c.x - radius * 0.55, y: c.y - radius * 0.55, width: radius * 1.1, height: radius * 1.1)
            context.fill(Path(ellipseIn: rect), with: .color(FairyStyle.petal))
            context.stroke(Path(ellipseIn: rect), with: .color(FairyStyle.petalEdge.opacity(0.6)), lineWidth: 0.5)
        }
        let middle = CGRect(x: center.x - radius * 0.3, y: center.y - radius * 0.3, width: radius * 0.6, height: radius * 0.6)
        context.fill(Path(ellipseIn: middle), with: .color(Color(hex: 0xFFE27A)))
    }
}

// MARK: - Little pieces

/// A day of the week with no page yet: one of the seven pink flowers with a face.
struct FairyFlowerFace: View {
    let day: Date

    var body: some View {
        let index = ((day.dayNumber % 7) + 7) % 7
        Image("FairyFlower\(index)")
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }
}
