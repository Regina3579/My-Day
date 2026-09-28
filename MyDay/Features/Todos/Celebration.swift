import SwiftUI

// MARK: - All done: the big confetti

/// The big "all done" celebration: pink, purple, yellow and blue stars, hearts, sparkles and
/// confetti burst from both bottom corners and rain from the top, then drift down and fade
/// (about three and a half seconds). The To-Dos screen skips it when Reduce Motion is on.
struct ConfettiCelebration: View {
    static let duration: Double = 3.6

    @State private var start = Date.now
    @State private var pieces: [ConfettiPiece] = ConfettiPiece.celebration()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSince(start)
                let symbols = ConfettiSymbols(context: context)
                for piece in pieces {
                    piece.draw(in: context, canvas: size, time: time, symbols: symbols)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The SF Symbols the confetti uses, resolved once per frame.
struct ConfettiSymbols {
    let star: GraphicsContext.ResolvedImage
    let heart: GraphicsContext.ResolvedImage
    let sparkle: GraphicsContext.ResolvedImage

    init(context: GraphicsContext) {
        star = context.resolve(Image(systemName: "star.fill"))
        heart = context.resolve(Image(systemName: "heart.fill"))
        sparkle = context.resolve(Image(systemName: "sparkle"))
    }
}

/// One piece of confetti. It is launched with a speed, slowed by the air and pulled down by
/// gravity, so it flies up, floats and drifts down.
struct ConfettiPiece {
    enum Kind: CaseIterable {
        case star, heart, sparkle, ribbon, dot
    }

    let kind: Kind
    let color: Color
    let size: CGFloat
    /// Where it starts, as fractions of the screen.
    let startX: CGFloat
    let startY: CGFloat
    /// Launch speed in points per second (negative `velocityY` is up).
    let velocityX: Double
    let velocityY: Double
    let delay: Double
    /// Turning speed (radians per second).
    let spin: Double
    /// How fast it flips over, like paper (radians per second).
    let flutter: Double
    let phase: Double

    private static let gravity: Double = 900

    /// Paper pieces feel the air more, so they float down more slowly.
    private var drag: Double {
        switch kind {
        case .star, .heart: 1.6
        case .sparkle, .dot: 2.0
        case .ribbon: 2.4
        }
    }

    func draw(in context: GraphicsContext, canvas: CGSize, time: Double, symbols: ConfettiSymbols) {
        let t = time - delay
        guard t > 0 else { return }
        let decay = (1 - exp(-drag * t)) / drag
        let terminal = Self.gravity / drag
        let x = Double(startX * canvas.width) + velocityX * decay
        let y = Double(startY * canvas.height) + terminal * t + (velocityY - terminal) * decay
        guard y < Double(canvas.height) + 40, x > -40, x < Double(canvas.width) + 40 else { return }
        let fadeIn = min(1, t / 0.08)
        let fadeOut = min(1, max(0, (ConfettiCelebration.duration - time) / 0.7))
        guard fadeIn * fadeOut > 0 else { return }

        var layer = context
        layer.opacity = fadeIn * fadeOut
        layer.translateBy(x: CGFloat(x), y: CGFloat(y))
        let wobble = CGFloat(0.85 + 0.15 * cos(flutter * t + phase))
        switch kind {
        case .star, .sparkle:
            layer.rotate(by: .radians(spin * t))
            layer.scaleBy(x: wobble, y: 1)
            drawSymbol(kind == .star ? symbols.star : symbols.sparkle, in: layer)
        case .heart:
            layer.rotate(by: .radians(0.35 * sin(3 * t + phase)))
            layer.scaleBy(x: wobble, y: 1)
            drawSymbol(symbols.heart, in: layer)
        case .ribbon, .dot:
            layer.rotate(by: .radians(spin * t))
            let flip: Double = cos(flutter * t + phase)
            layer.scaleBy(x: CGFloat(abs(flip) < 0.08 ? 0.08 : flip), y: 1)
            let side: CGFloat = size
            let shape: Path = kind == .ribbon
                ? Path(roundedRect: CGRect(x: -side * 0.22, y: -side / 2, width: side * 0.44, height: side),
                       cornerRadius: side * 0.12)
                : Path(ellipseIn: CGRect(x: -side / 2, y: -side / 2, width: side, height: side))
            layer.fill(shape, with: .color(color))
        }
    }

    private func drawSymbol(_ symbol: GraphicsContext.ResolvedImage, in context: GraphicsContext) {
        var image = symbol
        image.shading = .color(color)
        let aspect = image.size.width > 0 ? image.size.height / image.size.width : 1
        let height = size * aspect
        context.draw(image, in: CGRect(x: -size / 2, y: -height / 2, width: size, height: height))
    }
}

extension ConfettiPiece {
    /// Pink, purple, yellow and blue.
    private static let colors: [Color] = [
        Color(hex: 0xFF4F9A), Color(hex: 0xFF8CC6), Palette.bubblegum,
        Palette.grape, Color(hex: 0xB388FF),
        Color(hex: 0xFFD23F), Palette.butter,
        Color(hex: 0x5AA9FF), Color(hex: 0x7FD1FF)
    ]

    /// Mostly stars and hearts, then confetti ribbons, dots and sparkles.
    private static let kinds: [Kind] = [
        .star, .star, .star, .heart, .heart, .heart, .ribbon, .ribbon, .dot, .sparkle
    ]

    /// About 160 pieces: two bursts from the bottom corners and a shower from the top.
    static func celebration() -> [ConfettiPiece] {
        var pieces: [ConfettiPiece] = []
        for _ in 0..<56 {
            pieces.append(cannon(fromLeft: true))
            pieces.append(cannon(fromLeft: false))
        }
        for _ in 0..<48 {
            pieces.append(shower())
        }
        return pieces
    }

    private static func cannon(fromLeft: Bool) -> ConfettiPiece {
        let angle: Double = Double.random(in: 58...84) * Double.pi / 180
        let speed: Double = Double.random(in: 950...1550)
        let direction: Double = fromLeft ? 1 : -1
        return piece(startX: fromLeft ? 0.02 : 0.98, startY: 0.8,
                     velocityX: cos(angle) * speed * direction, velocityY: -sin(angle) * speed,
                     delay: Double.random(in: 0...0.25))
    }

    private static func shower() -> ConfettiPiece {
        piece(startX: CGFloat.random(in: 0...1), startY: -0.04,
              velocityX: Double.random(in: -80...80), velocityY: Double.random(in: 0...120),
              delay: Double.random(in: 0.2...1.2))
    }

    private static func piece(startX: CGFloat, startY: CGFloat, velocityX: Double, velocityY: Double,
                              delay: Double) -> ConfettiPiece {
        let kind: Kind = kinds.randomElement() ?? .star
        let size: CGFloat
        switch kind {
        case .star, .heart: size = CGFloat.random(in: 13...22)
        case .sparkle: size = CGFloat.random(in: 11...17)
        case .ribbon: size = CGFloat.random(in: 11...16)
        case .dot: size = CGFloat.random(in: 5...9)
        }
        return ConfettiPiece(
            kind: kind,
            color: colors.randomElement() ?? Palette.hotPink,
            size: size,
            startX: startX,
            startY: startY,
            velocityX: velocityX,
            velocityY: velocityY,
            delay: delay,
            spin: Double.random(in: -6...6),
            flutter: Double.random(in: 5...11),
            phase: Double.random(in: 0...(2 * Double.pi))
        )
    }
}

// MARK: - One to-do done: two little hearts

/// Two little hearts, one a bit bigger and one very small, that pop out of a tick box when
/// a to-do (pink) or a priority (purple) is ticked, float up and fade (in under a second).
struct TickPop: View {
    enum Tint {
        case pink, purple
    }

    var tint: Tint = .pink

    @State private var isOut = false
    @State private var isSmallOut = false
    @State private var isRisen = false
    @State private var isFaded = false

    private static let pinkBig = LinearGradient(colors: [Color(hex: 0xFF8CC6), Palette.hotPink],
                                                startPoint: .top, endPoint: .bottom)
    private static let pinkSmall = LinearGradient(colors: [Color(hex: 0xFFC2E0), Palette.bubblegum],
                                                  startPoint: .top, endPoint: .bottom)
    private static let purpleBig = LinearGradient(colors: [Color(hex: 0xC99BFF), Color(hex: 0x8A45E6)],
                                                  startPoint: .top, endPoint: .bottom)
    private static let purpleSmall = LinearGradient(colors: [Color(hex: 0xE6D2FF), Color(hex: 0xAD72F2)],
                                                    startPoint: .top, endPoint: .bottom)

    private var bigFill: LinearGradient { tint == .pink ? Self.pinkBig : Self.purpleBig }
    private var smallFill: LinearGradient { tint == .pink ? Self.pinkSmall : Self.purpleSmall }
    private var glow: Color { tint == .pink ? Palette.hotPink : Palette.grape }
    private var ring: Color { tint == .pink ? Palette.bubblegum : Palette.lavender }

    var body: some View {
        ZStack {
            // A soft ring that pops with them.
            Circle()
                .strokeBorder(ring.opacity(0.55), lineWidth: 1.5)
                .frame(width: 26, height: 26)
                .scaleEffect(isOut ? 1.3 : 0.4)
                .opacity(isOut ? 0 : 0.9)
            heart(size: 15, fill: bigFill)
                .scaleEffect(isOut ? 1 : 0.2)
                .rotationEffect(.degrees(isOut ? -12 : 10))
                .offset(x: isOut ? -5 : 0, y: isOut ? -20 : 0)
            heart(size: 9, fill: smallFill)
                .scaleEffect(isSmallOut ? 1 : 0.2)
                .rotationEffect(.degrees(isSmallOut ? 16 : -10))
                .offset(x: isSmallOut ? 12 : 0, y: isSmallOut ? -12 : 0)
                .opacity(isSmallOut ? 1 : 0)
        }
        .offset(y: isRisen ? -12 : 0)
        .opacity(isFaded ? 0 : 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { isOut = true }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5).delay(0.07)) { isSmallOut = true }
            withAnimation(.easeOut(duration: 0.9)) { isRisen = true }
            withAnimation(.easeIn(duration: 0.3).delay(Self.fadeDelay)) { isFaded = true }
        }
    }

    /// A glossy heart with a thin white edge.
    private func heart(size: CGFloat, fill: LinearGradient) -> some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(fill)
            .overlay(
                Image(systemName: "heart")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(Color.white)
            )
            .shadow(color: glow.opacity(0.5), radius: 4, x: 0, y: 1)
    }

    /// Seconds before they fade (longer in a screenshot run, so they can be captured).
    @MainActor
    private static var fadeDelay: Double {
        #if DEBUG
        if DebugLaunchRoute.holdsTickPop { return 4 }
        #endif
        return 0.6
    }
}
