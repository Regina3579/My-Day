import SwiftUI

extension View {
    /// Plays the launch animation over the app once, as it starts.
    func launchSplash() -> some View {
        modifier(LaunchSplash())
    }
}

private struct LaunchSplash: ViewModifier {
    #if DEBUG
    // Screenshot runs skip it, except the two that show it held still.
    @State private var isShowing = !DebugLaunchRoute.isScreenshotRun || DebugLaunchRoute.splashMoment != nil
    private let frozenAt = DebugLaunchRoute.splashMoment
    #else
    @State private var isShowing = true
    private let frozenAt: TimeInterval? = nil
    #endif

    func body(content: Content) -> some View {
        content.overlay {
            if isShowing {
                SplashView(frozenAt: frozenAt) {
                    // The app opens at once: the splash fades away as it grows a touch.
                    withAnimation(.easeOut(duration: 0.25)) { isShowing = false }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.06)))
            }
        }
    }
}

/// The launch animation, as in the design, paced slowly enough to see the picture and read its
/// words (3.6 s; a tap skips it). It starts from exactly what the launch screen shows (the pink
/// `LaunchBackground` and the 240 pt `LaunchLogo`, centred in the safe area), so it carries on
/// from it without a jump. Its stages (`Stage`), the design's four frames:
/// - 0–0.8 s: the icon glows, with soft light rays.
/// - 0.8–1.6 s: "Make today beautiful 💗" and the hearts pop in, with "Loading your happy space…".
/// - 1.6–3.0 s: the heart bar fills, and the hearts under it light up one by one.
/// - 3.0–3.6 s: the bar completes; as the icon gives a little bounce, the girl, her puppy and
///   kitten close their eyes in a happy smile (`LaunchLogoHappy`); then the app opens.
/// The stages are longer than the design's 0.8 s, not the pops and bounces, which stay quick.
struct SplashView: View {
    /// Debug screenshots only: hold the animation still at this moment.
    var frozenAt: TimeInterval?
    /// Called at the end, or when it is tapped.
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var isDone = false

    /// When each stage starts, in seconds; change these to pace it.
    enum Stage {
        static let words: TimeInterval = 0.8
        static let filling: TimeInterval = 1.6
        static let done: TimeInterval = 3.0
        static let end: TimeInterval = 3.6
    }

    static let length = Stage.end
    /// The size of `LaunchLogo` (720 px at 3x).
    static let iconSize: CGFloat = 240

    var body: some View {
        TimelineView(.animation(paused: frozenAt != nil)) { context in
            scene(at: frozenAt ?? context.date.timeIntervalSince(start))
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: finish)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("My Day. Loading your happy space.")
        .accessibilityAction(named: "Skip", finish)
        .task {
            guard frozenAt == nil else { return }
            try? await Task.sleep(for: .seconds(Self.length))
            finish()
        }
    }

    private func finish() {
        guard frozenAt == nil, !isDone else { return }
        isDone = true
        onFinish()
    }

    private func scene(at t: TimeInterval) -> some View {
        let size = Self.iconSize
        return ZStack {
            SplashGlow(size: size, turn: reduceMotion ? 0 : t * 14)
                .opacity(ramp(t, 0, 0.6))
                .scaleEffect(0.75 + 0.25 * ramp(t, 0, 0.6))
            ForEach(SplashHeart.all) { heart in
                floating(heart, at: t, size: size)
            }
            icon(at: t, size: size)
                .overlay(alignment: .top) {
                    title(at: t)
                        .fixedSize()
                        .alignmentGuide(.top) { $0[.bottom] + 52 }
                }
                .overlay(alignment: .bottom) {
                    loading(at: t)
                        .alignmentGuide(.bottom) { $0[.top] - 20 }
                }
            finalSparkles(at: t, size: size)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            SplashBackground(decor: ramp(t, 0, 0.8))
                .ignoresSafeArea()
        }
    }

    // MARK: The icon

    private func icon(at t: TimeInterval, size: CGFloat) -> some View {
        // A soft bounce as loading completes.
        let bounce = reduceMotion ? 0 : sin(ramp(t, Stage.done, Stage.done + 0.4, eased: false) * .pi) * 0.04
        // The happy icon is lined up on the "My Day" lettering, so only the girl and pets change.
        return ZStack {
            Image("LaunchLogo")
                .resizable()
            Image("LaunchLogoHappy")
                .resizable()
                .opacity(ramp(t, Stage.done, Stage.done + 0.2))
        }
        .frame(width: size, height: size)
        .shadow(color: Color(hex: 0xF0428A).opacity(0.28 * ramp(t, 0, 0.6)), radius: 18, x: 0, y: 8)
        .scaleEffect(1 + bounce)
    }

    // MARK: "Make today beautiful 💗"

    private func title(at t: TimeInterval) -> some View {
        let shown = ramp(t, Stage.words, Stage.words + 0.35, eased: false)
        return VStack(alignment: .leading, spacing: -6) {
            Text("Make today")
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFF4FA3), Color(hex: 0xEC1D86)],
                                                startPoint: .top, endPoint: .bottom))
            HStack(alignment: .center, spacing: 8) {
                Text("beautiful")
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0xB42794), Color(hex: 0x7E1E8C)],
                                                    startPoint: .top, endPoint: .bottom))
                ShinyHeart(size: 26)
                    .rotationEffect(.degrees(12))
            }
            .padding(.leading, 22)
        }
        .font(.custom("Noteworthy-Bold", size: 36))
        .shadow(color: Color.white.opacity(0.9), radius: 2)
        .rotationEffect(.degrees(-6))
        .scaleEffect(reduceMotion ? 1 : 0.8 + 0.2 * Self.overshoot(shown))
        .offset(y: reduceMotion ? 0 : 10 * (1 - ramp(t, Stage.words, Stage.words + 0.3)))
        .opacity(ramp(t, Stage.words, Stage.words + 0.25))
    }

    // MARK: Loading

    private func loading(at t: TimeInterval) -> some View {
        VStack(spacing: 14) {
            Text("Loading your happy space…")
                .font(.custom("Noteworthy-Bold", size: 20))
                .foregroundStyle(Color(hex: 0x4A1A8C))
                .fixedSize()
            HeartProgressBar(progress: Self.progress(at: t))
                .frame(width: 290, height: 18)
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    let lit = ramp(t, Self.heartTimes[index], Self.heartTimes[index] + 0.15, eased: false)
                    ZStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(hex: 0xFFC3DC))
                        ShinyHeart(size: 22)
                            .scaleEffect(reduceMotion ? 1 : 0.5 + 0.5 * Self.overshoot(lit))
                            .opacity(lit)
                    }
                }
            }
            .padding(.top, 4)
        }
        .opacity(ramp(t, Stage.words + 0.05, Stage.words + 0.3))
    }

    /// When each heart under the bar lights up: one per stage of the design.
    private static let heartTimes: [TimeInterval] = [Stage.filling - 0.3, Stage.done - 0.3, Stage.done + 0.2]

    /// How full the bar is: about a third as the words stage ends, 60% as the filling one ends,
    /// full soon after (the design's 36% and 60% moments).
    static func progress(at t: TimeInterval) -> Double {
        let stops: [(TimeInterval, Double)] = [(Stage.words + 0.1, 0), (Stage.filling, 0.36),
                                               (Stage.done, 0.62), (Stage.done + 0.3, 1)]
        guard t > stops[0].0 else { return 0 }
        for (a, b) in zip(stops, stops.dropFirst()) where t <= b.0 {
            let x = (t - a.0) / (b.0 - a.0)
            return a.1 + (b.1 - a.1) * x * x * (3 - 2 * x)
        }
        return 1
    }

    // MARK: Hearts around the icon

    private func floating(_ heart: SplashHeart, at t: TimeInterval, size: CGFloat) -> some View {
        let start = Stage.words + heart.delay
        let shown = ramp(t, start, start + 0.3, eased: false)
        let bob = reduceMotion ? 0 : sin((t + heart.delay * 7) * 4) * 3
        return heart.view(size: heart.size * size)
            .scaleEffect(reduceMotion ? 1 : 0.3 + 0.7 * Self.overshoot(shown))
            .opacity(min(shown * 1.5, 1))
            .offset(x: heart.x * size, y: heart.y * size + bob)
    }

    /// The sparkles that twinkle as loading completes (in icon sizes from its centre).
    private static let sparkleSpots: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (-0.62, -0.18, 14), (0.64, 0.02, 12), (-0.5, 0.58, 10), (0.58, -0.56, 11), (0.08, -0.7, 9)
    ]

    private func finalSparkles(at t: TimeInterval, size: CGFloat) -> some View {
        ForEach(Array(Self.sparkleSpots.enumerated()), id: \.offset) { index, spot in
            let shown = ramp(t, Stage.done - 0.05 + Double(index) * 0.05, Stage.done + 0.45)
            Image(systemName: "sparkle")
                .font(.system(size: spot.size, weight: .bold))
                .foregroundStyle(Color.white)
                .shadow(color: Color(hex: 0xFFE38A), radius: 4)
                .scaleEffect(reduceMotion ? 1 : 0.4 + 0.6 * shown)
                .opacity(shown)
                .offset(x: spot.x * size, y: spot.y * size)
        }
    }

    // MARK: Timing

    /// 0 before `from`, 1 after `to`, and in between a smooth (or, unless `eased`, even) rise.
    private func ramp(_ t: TimeInterval, _ from: TimeInterval, _ to: TimeInterval, eased: Bool = true) -> Double {
        let x = min(max((t - from) / (to - from), 0), 1)
        return eased ? x * x * (3 - 2 * x) : x
    }

    /// Rises past 1 and settles back, for a "pop".
    static func overshoot(_ x: Double) -> Double {
        let c = 1.70158
        return 1 + (c + 1) * pow(x - 1, 3) + c * pow(x - 1, 2)
    }
}

/// The pink of the launch screen, then a lighter glow in the middle with faint hearts and
/// sparkles that fade in (`decor` 0…1).
private struct SplashBackground: View {
    let decor: Double

    private static let faintHearts: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.2, 0.2, 34), (0.86, 0.12, 26), (0.08, 0.6, 52), (0.9, 0.56, 44), (0.28, 0.86, 40), (0.84, 0.88, 30)
    ]
    private static let sparkles: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.14, 0.34, 12), (0.9, 0.3, 10), (0.76, 0.2, 8), (0.1, 0.8, 9), (0.92, 0.74, 12), (0.5, 0.94, 8)
    ]

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height
            ZStack {
                Color("LaunchBackground")
                RadialGradient(colors: [Color(hex: 0xFFF6FA), Color(hex: 0xFFF6FA).opacity(0)],
                               center: .center, startRadius: 0, endRadius: max(w, h) * 0.55)
                    .opacity(decor)
                ForEach(Array(Self.faintHearts.enumerated()), id: \.offset) { _, heart in
                    Image(systemName: "heart.fill")
                        .font(.system(size: heart.size))
                        .foregroundStyle(Color(hex: 0xFFB3D1).opacity(0.45))
                        .blur(radius: 2.5)
                        .position(x: heart.x * w, y: heart.y * h)
                }
                .opacity(decor)
                ForEach(Array(Self.sparkles.enumerated()), id: \.offset) { _, spark in
                    Image(systemName: "sparkle")
                        .font(.system(size: spark.size, weight: .bold))
                        .foregroundStyle(Color.white)
                        .shadow(color: Color(hex: 0xFFE9A8), radius: 3)
                        .position(x: spark.x * w, y: spark.y * h)
                }
                .opacity(decor)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The soft light behind the icon: a warm white glow with gentle rays.
private struct SplashGlow: View {
    let size: CGFloat
    /// How far the rays have turned, in degrees.
    let turn: Double

    var body: some View {
        ZStack {
            Canvas { context, canvas in
                let centre = CGPoint(x: canvas.width / 2, y: canvas.height / 2)
                let reach = canvas.width / 2
                for index in 0..<16 {
                    let angle = Double(index) / 16 * 2 * .pi
                    var ray = Path()
                    ray.move(to: centre)
                    ray.addLine(to: CGPoint(x: centre.x + reach * cos(angle - 0.07), y: centre.y + reach * sin(angle - 0.07)))
                    ray.addLine(to: CGPoint(x: centre.x + reach * cos(angle + 0.07), y: centre.y + reach * sin(angle + 0.07)))
                    ray.closeSubpath()
                    context.fill(ray, with: .color(Color.white.opacity(0.55)))
                }
            }
            .blur(radius: 6)
            .rotationEffect(.degrees(turn))
            .mask(RadialGradient(colors: [Color.white, Color.white.opacity(0)],
                                 center: .center, startRadius: size * 0.3, endRadius: size * 0.95))
            RadialGradient(colors: [Color.white, Color(hex: 0xFFF3C4).opacity(0.7), Color(hex: 0xFFF3C4).opacity(0)],
                           center: .center, startRadius: size * 0.3, endRadius: size * 0.82)
        }
        .frame(width: size * 1.9, height: size * 1.9)
        .accessibilityHidden(true)
    }
}

/// A heart around the icon: where it sits (in icon sizes from its centre), how big it is,
/// how it looks and when it pops in.
private struct SplashHeart: Identifiable {
    enum Look { case shiny, soft, outline }

    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let look: Look
    /// After the words stage starts.
    let delay: TimeInterval

    @ViewBuilder
    func view(size: CGFloat) -> some View {
        switch look {
        case .shiny:
            ShinyHeart(size: size)
        case .soft:
            Image(systemName: "heart.fill")
                .font(.system(size: size))
                .foregroundStyle(Color(hex: 0xFFB0D0))
        case .outline:
            Image(systemName: "heart")
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(Color(hex: 0xFF9CC0))
        }
    }

    /// As in the design: two big glossy hearts up by the title, smaller ones at the sides.
    static let all: [SplashHeart] = [
        SplashHeart(id: 0, x: -0.56, y: -0.47, size: 0.2, look: .shiny, delay: 0),
        SplashHeart(id: 1, x: 0.53, y: -0.66, size: 0.19, look: .shiny, delay: 0.1),
        SplashHeart(id: 2, x: -0.6, y: -0.76, size: 0.09, look: .outline, delay: 0.17),
        SplashHeart(id: 3, x: -0.27, y: -0.64, size: 0.07, look: .soft, delay: 0.25),
        SplashHeart(id: 4, x: 0.58, y: 0.42, size: 0.13, look: .outline, delay: 0.15),
        SplashHeart(id: 5, x: -0.62, y: 0.4, size: 0.08, look: .soft, delay: 0.3),
        SplashHeart(id: 6, x: 0.68, y: -0.12, size: 0.07, look: .soft, delay: 0.35)
    ]
}
