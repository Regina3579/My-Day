import SwiftUI

extension View {
    /// Shows the launch page over the app once, as it starts.
    func launchSplash() -> some View {
        modifier(LaunchSplash())
    }
}

private struct LaunchSplash: ViewModifier {
    #if DEBUG
    // Screenshot runs skip it, except "splash", which holds it on screen.
    @State private var isShowing = !DebugLaunchRoute.isScreenshotRun || DebugLaunchRoute.holdsSplash
    private let isHeld = DebugLaunchRoute.holdsSplash
    #else
    @State private var isShowing = true
    private let isHeld = false
    #endif

    func body(content: Content) -> some View {
        content.overlay {
            if isShowing {
                SplashView(isHeld: isHeld) {
                    withAnimation(.easeOut(duration: 0.3)) { isShowing = false }
                }
                .transition(.opacity)
            }
        }
    }
}

/// The launch page, as in the design's last frame: the happy My Day icon in a soft glow, "Make
/// today beautiful 💗" and hearts above it, and "Loading your happy space…" over a full heart
/// bar with its three hearts lit. It fades in from the launch screen's plain pink, stays for
/// `length` (a tap skips it), then fades into the app.
struct SplashView: View {
    /// Debug screenshots only: keep it on screen.
    var isHeld = false
    /// Called at the end, or when it is tapped.
    let onFinish: () -> Void

    @State private var isShown = false
    @State private var isDone = false

    /// How long it shows, in seconds, before the app opens.
    static let length: TimeInterval = 0.9
    /// The size of `LaunchLogoHappy` (720 px at 3x).
    static let iconSize: CGFloat = 240

    var body: some View {
        page
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                SplashBackground()
                    .ignoresSafeArea()
            }
            .opacity(isShown || isHeld ? 1 : 0)
            .background {
                // The launch screen's plain pink, so the page fades in over it without a jump.
                Color("LaunchBackground")
                    .ignoresSafeArea()
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: finish)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("My Day. Loading your happy space.")
            .accessibilityAction(named: "Skip", finish)
            .task {
                guard !isHeld else { return }
                withAnimation(.easeOut(duration: 0.15)) { isShown = true }
                try? await Task.sleep(for: .seconds(Self.length))
                finish()
            }
    }

    private func finish() {
        guard !isHeld, !isDone else { return }
        isDone = true
        onFinish()
    }

    private var page: some View {
        let size = Self.iconSize
        return ZStack {
            SplashGlow(size: size)
            ForEach(SplashHeart.all) { heart in
                heart.view(size: heart.size * size)
                    .offset(x: heart.x * size, y: heart.y * size)
            }
            Image("LaunchLogoHappy")
                .resizable()
                .frame(width: size, height: size)
                .shadow(color: Color(hex: 0xF0428A).opacity(0.28), radius: 18, x: 0, y: 8)
                .overlay(alignment: .top) {
                    title
                        .fixedSize()
                        .alignmentGuide(.top) { $0[.bottom] + 52 }
                }
                .overlay(alignment: .bottom) {
                    loading
                        .alignmentGuide(.bottom) { $0[.top] - 20 }
                }
            ForEach(Array(Self.sparkleSpots.enumerated()), id: \.offset) { _, spot in
                Image(systemName: "sparkle")
                    .font(.system(size: spot.size, weight: .bold))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color(hex: 0xFFE38A), radius: 4)
                    .offset(x: spot.x * size, y: spot.y * size)
            }
        }
    }

    /// "Make today beautiful 💗".
    private var title: some View {
        VStack(alignment: .leading, spacing: -6) {
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
    }

    /// "Loading your happy space…", the full heart bar and its three hearts, lit.
    private var loading: some View {
        VStack(spacing: 14) {
            Text("Loading your happy space…")
                .font(.custom("Noteworthy-Bold", size: 20))
                .foregroundStyle(Color(hex: 0x4A1A8C))
                .fixedSize()
            HeartProgressBar(progress: 1)
                .frame(width: 290, height: 18)
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    ShinyHeart(size: 22)
                }
            }
            .padding(.top, 4)
        }
    }

    /// Sparkles around the icon (in icon sizes from its centre).
    private static let sparkleSpots: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (-0.62, -0.18, 14), (0.64, 0.02, 12), (-0.5, 0.58, 10), (0.58, -0.56, 11), (0.08, -0.7, 9)
    ]
}

/// The pink of the launch screen, with a lighter glow in the middle, faint hearts and sparkles.
private struct SplashBackground: View {
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
                ForEach(Array(Self.faintHearts.enumerated()), id: \.offset) { _, heart in
                    Image(systemName: "heart.fill")
                        .font(.system(size: heart.size))
                        .foregroundStyle(Color(hex: 0xFFB3D1).opacity(0.45))
                        .blur(radius: 2.5)
                        .position(x: heart.x * w, y: heart.y * h)
                }
                ForEach(Array(Self.sparkles.enumerated()), id: \.offset) { _, spark in
                    Image(systemName: "sparkle")
                        .font(.system(size: spark.size, weight: .bold))
                        .foregroundStyle(Color.white)
                        .shadow(color: Color(hex: 0xFFE9A8), radius: 3)
                        .position(x: spark.x * w, y: spark.y * h)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// The soft light behind the icon: a warm white glow with gentle rays.
private struct SplashGlow: View {
    let size: CGFloat

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
            .mask(RadialGradient(colors: [Color.white, Color.white.opacity(0)],
                                 center: .center, startRadius: size * 0.3, endRadius: size * 0.95))
            RadialGradient(colors: [Color.white, Color(hex: 0xFFF3C4).opacity(0.7), Color(hex: 0xFFF3C4).opacity(0)],
                           center: .center, startRadius: size * 0.3, endRadius: size * 0.82)
        }
        .frame(width: size * 1.9, height: size * 1.9)
        .accessibilityHidden(true)
    }
}

/// A heart around the icon: where it sits (in icon sizes from its centre), how big it is and
/// how it looks.
private struct SplashHeart: Identifiable {
    enum Look { case shiny, soft, outline }

    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let look: Look

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
        SplashHeart(id: 0, x: -0.56, y: -0.47, size: 0.2, look: .shiny),
        SplashHeart(id: 1, x: 0.53, y: -0.66, size: 0.19, look: .shiny),
        SplashHeart(id: 2, x: -0.6, y: -0.76, size: 0.09, look: .outline),
        SplashHeart(id: 3, x: -0.27, y: -0.64, size: 0.07, look: .soft),
        SplashHeart(id: 4, x: 0.58, y: 0.42, size: 0.13, look: .outline),
        SplashHeart(id: 5, x: -0.62, y: 0.4, size: 0.08, look: .soft),
        SplashHeart(id: 6, x: 0.68, y: -0.12, size: 0.07, look: .soft)
    ]
}
