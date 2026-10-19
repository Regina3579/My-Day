import SwiftUI

/// Candy Cloud Kingdom 🍭, a My Day Pro journal theme: My Journal Pages in a pastel candy sky,
/// the candy castle and rainbows at the top with a bunny cloud holding a lollipop, a girl in a
/// crown hugging her bunny, and "My Journal Pages" on a cloud under a gold tiara; lollipops,
/// candy canes, gumdrops and chocolate down both sides; a bunny cloud with a pink bow beside
/// Write a new page; cards iced with vanilla frosting, drips and rainbow sprinkles inside a
/// candy-cane edge; a rainbow cloud on My week in moods (a day with no page is a pale pink
/// star); a candy castle beside the month; dates under lollipops with a candy cane; a candy
/// castle or a sleeping bunny on every page card; and candy by the search bar. The pictures
/// are from the design; the frosting, drips, sprinkles and candy stripes are drawn here.
enum CandyStyle {
    static let title = Color(hex: 0x4D0532)         // "My week in moods"
    static let month = Color(hex: 0x4C0434)         // "October 2026"
    static let glow = Color(hex: 0xF59AC6)
    /// The candy sky behind the cards, and behind the search bar.
    static let base = Color(hex: 0xF9E1EE)
    static let cardFill = LinearGradient(colors: [Color(hex: 0xFFFEFC), Color(hex: 0xFDF8F4)],
                                         startPoint: .top, endPoint: .bottom)
    /// Vanilla frosting, and the soft shadow under it.
    static let frosting = LinearGradient(colors: [Color(hex: 0xFFFDF9), Color(hex: 0xFFF0E4), Color(hex: 0xFADFD3)],
                                         startPoint: .top, endPoint: .bottom)
    static let frostingShade = Color(hex: 0xEFC3CB)
    /// The pink of the candy-cane stripes.
    static let stripe = Color(hex: 0xF27AAB)
    /// The glowing caramel rims of the open tab, All Time, the search bar and Filter.
    static let caramel = LinearGradient(colors: [Color(hex: 0xFFE6BF), Color(hex: 0xF6B07E), Color(hex: 0xFFD7A6),
                                                 Color(hex: 0xF3A374)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing)
    static let caramelGlow = Color(hex: 0xFFB27A)
    static let calendarFill = LinearGradient(colors: [Color(hex: 0xFFEEF9), Color(hex: 0xFBD7F0)],
                                             startPoint: .top, endPoint: .bottom)
    /// Rainbow sprinkles: pink, blue, lemon, mint, lilac and orange.
    static let sprinkles: [Color] = [Color(hex: 0xFF6FA8), Color(hex: 0x6EC3F4), Color(hex: 0xFFCE4F),
                                     Color(hex: 0x6FD8A4), Color(hex: 0xB28CF2), Color(hex: 0xFF9F5A)]
    /// How wide the candy down each side is in the design (40 of its 1672 rows tall).
    static let edgeRatio: CGFloat = 40.0 / 1672.0
}

// MARK: - The sky

/// Behind My Journal Pages: the pastel candy sky with soft clouds, and the lollipops, candy
/// canes, gumdrops and chocolate of the design down both sides (they stay put as the pages
/// scroll).
struct CandyBackdrop: View {
    private static let puffs: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.3, 0.32, 170), (0.75, 0.42, 150), (0.25, 0.58, 160), (0.7, 0.7, 170), (0.35, 0.86, 150),
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let edge = max(18, size.height * CandyStyle.edgeRatio)
            ZStack {
                LinearGradient(colors: [Color(hex: 0xF4DDF6), CandyStyle.base, Color(hex: 0xF7DAF0), Color(hex: 0xFBE3EE)],
                               startPoint: .top, endPoint: .bottom)
                ForEach(Self.puffs.indices, id: \.self) { index in
                    let puff = Self.puffs[index]
                    Ellipse()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: puff.size, height: puff.size * 0.55)
                        .blur(radius: 26)
                        .position(x: size.width * puff.x, y: size.height * puff.y)
                }
                HStack(spacing: 0) {
                    side("CandyEdgeLeft", width: edge, height: size.height, from: .leading, to: .trailing)
                    Spacer(minLength: 0)
                    side("CandyEdgeRight", width: edge, height: size.height, from: .trailing, to: .leading)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// One side of candy, melting into the sky on its inner edge.
    private func side(_ name: String, width: CGFloat, height: CGFloat, from: UnitPoint, to: UnitPoint) -> some View {
        Image(name)
            .resizable()
            .frame(width: width, height: height)
            .mask(LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.72),
                                         .init(color: .clear, location: 1)],
                                 startPoint: from, endPoint: to))
    }
}

// MARK: - Header

extension JournalScene {
    /// Candy Cloud Kingdom: the candy castle and rainbows, the bunny cloud with its lollipop, the
    /// girl hugging her bunny and "My Journal Pages" on a cloud under a gold tiara (with room
    /// above for the status bar).
    static let candy = JournalScene(
        imageName: "CandyHeader", imageSize: CGSize(width: 1320, height: 480), buttonsRow: 313, overlapRows: 0,
        accessibilityLabel: "My Journal Pages")
}

// MARK: - Frosting, drips, sprinkles and stripes

/// The same little scatter every time it is drawn (for the drips and the sprinkles).
struct CandyScatter {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(truncatingIfNeeded: seed &* 2_654_435_761 &+ 12_345) | 1
    }

    /// A number from 0 to 1.
    mutating func next() -> CGFloat {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return CGFloat((state >> 33) % 10_000) / 10_000
    }

    mutating func next(in range: ClosedRange<CGFloat>) -> CGFloat {
        range.lowerBound + (range.upperBound - range.lowerBound) * next()
    }

    mutating func pick<T>(_ items: [T]) -> T {
        items[min(items.count - 1, Int(next() * CGFloat(items.count)))]
    }
}

/// Pink and white candy-cane stripes, slanting.
struct CandyStripes: View {
    var stripe: Color = CandyStyle.stripe
    var width: CGFloat = 4.5

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
            var x = -size.height
            while x < size.width + size.height {
                var band = Path()
                band.move(to: CGPoint(x: x, y: size.height))
                band.addLine(to: CGPoint(x: x + size.height, y: 0))
                band.addLine(to: CGPoint(x: x + size.height + width, y: 0))
                band.addLine(to: CGPoint(x: x + width, y: size.height))
                band.closeSubpath()
                context.fill(band, with: .color(stripe))
                x += width * 2
            }
        }
        .accessibilityHidden(true)
    }
}

/// Vanilla icing along the top, with drips running down and rainbow sprinkles on it.
struct CandyIcing: View {
    /// How deep the icing is before the drips.
    var band: CGFloat = 10
    /// How far the longest drips run below it.
    var dripLength: CGFloat = 8
    var seed = 0
    var sprinkles = true

    var body: some View {
        Canvas { context, size in
            var scatter = CandyScatter(seed: seed)
            var pieces = [Path(CGRect(x: 0, y: 0, width: size.width, height: band))]
            // A puffy, scalloped edge...
            var bump: CGFloat = 3
            while bump < size.width - 3 {
                let radius = scatter.next(in: 2.6...4)
                pieces.append(Path(ellipseIn: CGRect(x: bump - radius, y: band - radius, width: radius * 2, height: radius * 2)))
                bump += radius * 1.7
            }
            // ...and drips running down from it.
            var x: CGFloat = scatter.next(in: 4...14)
            while x < size.width - 8 {
                let width = scatter.next(in: 6...10)
                let length = scatter.next(in: max(2, dripLength * 0.3)...max(3, dripLength))
                pieces.append(Path(roundedRect: CGRect(x: x, y: band - width / 2, width: width, height: length + width / 2),
                                   cornerRadius: width / 2))
                x += width + scatter.next(in: 9...26)
            }
            for piece in pieces {
                context.fill(piece.offsetBy(dx: 0, dy: 1.2), with: .color(CandyStyle.frostingShade))
            }
            for piece in pieces {
                context.fill(piece, with: .linearGradient(Gradient(colors: [Color.white, Color(hex: 0xFFF4EA)]),
                                                          startPoint: .zero, endPoint: CGPoint(x: 0, y: band + dripLength)))
            }
            if sprinkles {
                let count = Int(size.width / 8)
                for _ in 0..<count {
                    let point = CGPoint(x: scatter.next(in: 6...max(7, size.width - 6)), y: scatter.next(in: 2.5...max(3, band - 2.5)))
                    CandyScatter.sprinkle(in: context, at: point, angle: .degrees(scatter.next(in: 0...180)),
                                          color: scatter.pick(CandyStyle.sprinkles))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

extension CandyScatter {
    /// One sprinkle: a tiny rounded stick.
    static func sprinkle(in context: GraphicsContext, at point: CGPoint, angle: Angle, color: Color,
                         length: CGFloat = 4.6) {
        var piece = context
        piece.translateBy(x: point.x, y: point.y)
        piece.rotate(by: angle)
        piece.fill(Path(roundedRect: CGRect(x: -length / 2, y: -0.95, width: length, height: 1.9), cornerRadius: 0.95),
                   with: .color(color))
    }
}

/// Sprinkles scattered round the frosted edge of a card (inside its candy-cane edge).
struct CandyEdgeSprinkles: View {
    var radius: CGFloat
    var ring: CGFloat = 9
    var seed = 0

    var body: some View {
        Canvas { context, size in
            var scatter = CandyScatter(seed: seed &+ 7)
            let inner = max(ring - 1.5, 3.5)
            let along = max(radius * 0.7, 10)
            // Bottom, then the two sides.
            for _ in 0..<Int(size.width / 14) {
                let point = CGPoint(x: scatter.next(in: along...max(along + 1, size.width - along)),
                                    y: size.height - scatter.next(in: 2.5...inner))
                CandyScatter.sprinkle(in: context, at: point, angle: .degrees(scatter.next(in: 0...180)),
                                      color: scatter.pick(CandyStyle.sprinkles), length: 4)
            }
            for side in 0..<2 {
                for _ in 0..<Int(size.height / 15) {
                    let inset = scatter.next(in: 2.5...inner)
                    let point = CGPoint(x: side == 0 ? inset : size.width - inset,
                                        y: scatter.next(in: along...max(along + 1, size.height - along)))
                    CandyScatter.sprinkle(in: context, at: point, angle: .degrees(scatter.next(in: 0...180)),
                                          color: scatter.pick(CandyStyle.sprinkles), length: 4)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// A Candy Cloud Kingdom card: white inside a candy-cane edge, frosted all round, with icing,
/// drips and sprinkles along the top (and a picture in its corner, when it has one).
struct CandyCardBackground: View {
    var radius: CGFloat = 26
    var seed = 0
    /// How wide the frosting round the edge is.
    var ring: CGFloat = 11
    /// The candy-cane edge (the tabs go without).
    var stripes = true
    var icing: CGFloat = 13
    var dripLength: CGFloat = 11
    /// A picture in the bottom corner, under the frosting.
    var scene: String?
    var sceneWidth: CGFloat = 140

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        ZStack(alignment: .top) {
            shape.fill(CandyStyle.cardFill)
            if let scene {
                Image(scene)
                    .resizable()
                    .scaledToFit()
                    .frame(width: sceneWidth)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding([.bottom, .trailing], 5)
                    .accessibilityHidden(true)
            }
            shape
                .strokeBorder(CandyStyle.frosting, lineWidth: ring)
                .shadow(color: CandyStyle.frostingShade, radius: 1.5, x: 0, y: 1)
            // Where the frosting meets the card: a soft pink line, so it looks piped on.
            shape
                .inset(by: ring)
                .stroke(CandyStyle.frostingShade.opacity(0.7), lineWidth: 1)
                .blur(radius: 0.5)
            if icing > 0 {
                CandyIcing(band: icing, dripLength: dripLength, seed: seed)
                    .frame(height: icing + dripLength + 4)
                    .padding(.horizontal, 3)
            }
            CandyEdgeSprinkles(radius: radius, ring: ring, seed: seed)
        }
        .clipShape(shape)
        .overlay {
            if stripes {
                CandyStripes().mask(shape.strokeBorder(lineWidth: 3.5))
            }
        }
        .shadow(color: CandyStyle.glow.opacity(0.35), radius: 8, x: 0, y: 3)
    }
}

/// A day of the week with no page yet: a pale pink star, as in the design.
struct CandyEmptyStar: View {
    var body: some View {
        Image("CandyEmptyStar")
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)
    }
}

/// A round candy rim that glows: caramel round the open tab, All Time, the search bar and Filter.
struct CandyGlowRim<S: InsettableShape>: View {
    let shape: S
    var lineWidth: CGFloat = 2.2

    var body: some View {
        shape
            .strokeBorder(CandyStyle.caramel, lineWidth: lineWidth)
            .overlay(shape.inset(by: lineWidth).strokeBorder(Color.white.opacity(0.85), lineWidth: 0.8))
            .shadow(color: CandyStyle.caramelGlow.opacity(0.55), radius: 3)
            .allowsHitTesting(false)
    }
}

/// By the search bar, as in the design: a pink swirl lollipop at the left of the search field,
/// and another peeking over Filter.
struct CandySearchBarTrim: View {
    var body: some View {
        ZStack {
            Image("CandySearchLeft")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 58)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .offset(x: -2, y: -18)
            Image("CandySearchRight")
                .resizable()
                .scaledToFit()
                .frame(width: 46, height: 46)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: 6, y: -16)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
