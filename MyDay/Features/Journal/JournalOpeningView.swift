import SwiftUI

/// Opening My Journal, as in the design, before My Journal Pages shows. It is paced slowly
/// enough to see each picture and read each message (5.6 s in all; a tap skips it), with quick
/// pops. Its stages (`Stage`), the design's four frames:
/// - 0–2.0 s: "Get ready to write a beautiful story!" pops in over the girl winking by her
///   journal with her puppy.
/// - 2.0–3.4 s: "Opening your journal…" as she hugs the journal, and the heart bar starts to fill.
/// - 3.4–5.0 s: "Almost there… Your beautiful stories are ready!" as the bar nearly fills.
/// - 5.0–5.6 s: the journal lies open in a burst of light; then the page shows.
///
/// The four pictures (`JournalOpening1`…`4`) come from the design, with its words, bar and
/// hearts taken out: those are drawn here, in the places the design has them. Everything is
/// placed on the pictures' own 364 × 678 grid, which fills the screen the way the pictures do.
struct JournalOpeningView: View {
    /// Debug screenshots only: hold the animation still at this moment.
    var frozenAt: TimeInterval?
    /// Called at the end, or when it is tapped.
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var isDone = false

    /// When each stage starts, in seconds; change these to pace it.
    enum Stage {
        static let opening: TimeInterval = 2.0
        static let almost: TimeInterval = 3.4
        static let open: TimeInterval = 5.0
        static let end: TimeInterval = 5.6
    }

    static let length = Stage.end
    /// The size of the pictures in the design, in which everything here is placed.
    private static let grid = CGSize(width: 364, height: 678)

    var body: some View {
        TimelineView(.animation(paused: frozenAt != nil)) { context in
            let t = frozenAt ?? context.date.timeIntervalSince(start)
            GeometryReader { proxy in
                scene(at: t, in: proxy.size)
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture(perform: finish)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Opening your journal")
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

    private func scene(at t: TimeInterval, in size: CGSize) -> some View {
        let place = GridPlacement(grid: Self.grid, screen: size)
        return ZStack {
            Color(hex: 0xFCE3EE)
            pictures(at: t, in: size)
            titles(at: t, place: place)
            HeartProgressBar(progress: Self.progress(at: t))
                .frame(width: place.length(287), height: place.length(23))
                .position(place.point(181.5, 572.5))
                .opacity(barShown(at: t))
            hearts(at: t, place: place)
                .position(place.point(179.5, 618))
                .opacity(barShown(at: t))
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: Pictures

    private func pictures(at t: TimeInterval, in size: CGSize) -> some View {
        // Each fades in over the last; the first settles from a little zoom, the open journal
        // grows a touch as it opens.
        let settle = reduceMotion ? 1 : 1.04 - 0.04 * ramp(t, 0, 0.8)
        let opening = reduceMotion ? 1 : 1 + 0.06 * ramp(t, Stage.open, Stage.end)
        return ZStack {
            picture("JournalOpening1", in: size).scaleEffect(settle)
            picture("JournalOpening2", in: size).opacity(ramp(t, Stage.opening, Stage.opening + 0.25))
            picture("JournalOpening3", in: size).opacity(ramp(t, Stage.almost, Stage.almost + 0.25))
            picture("JournalOpening4", in: size).opacity(ramp(t, Stage.open, Stage.open + 0.25)).scaleEffect(opening)
        }
    }

    private func picture(_ name: String, in size: CGSize) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
    }

    // MARK: Words

    private func titles(at t: TimeInterval, place: GridPlacement) -> some View {
        ZStack {
            title(shown: ramp(t, 0.1, 0.45, eased: false), hidden: leaving(t, Stage.opening), place: place, lines: [
                TitleLine("Get ready", width: 218, size: 48, color: 0x93097D),
                TitleLine("to write a", width: 136, size: 28, color: 0x560F8A),
                TitleLine("beautiful story!", width: 232, size: 32, color: 0x5D0E87)
            ])
            .position(place.point(192, 112))
            title(shown: arriving(t, Stage.opening), hidden: leaving(t, Stage.almost), place: place, lines: [
                TitleLine("Opening", width: 138, size: 42, color: 0x5820A7),
                // As in the design, it ends just before the butterfly.
                TitleLine("your journal…", width: 198, size: 38, color: 0x94097A)
            ])
            .position(place.point(179, 122))
            title(shown: arriving(t, Stage.almost), hidden: leaving(t, Stage.open), place: place, lines: [
                TitleLine("Almost there…", width: 240, size: 42, color: 0x9E0A7B),
                TitleLine("Your beautiful stories", width: 214, size: 24, color: 0x7F0D82),
                TitleLine("are ready!", width: 108, size: 24, color: 0x820B7F)
            ])
            .position(place.point(187, 112))
        }
    }

    /// Lines of the design's handwriting, each as wide as in the design, tilted a little and
    /// popping in (`shown` 0…1), then fading (`hidden` 0…1).
    private func title(shown: Double, hidden: Double, place: GridPlacement, lines: [TitleLine]) -> some View {
        VStack(spacing: place.length(1)) {
            ForEach(lines) { line in
                Text(line.text)
                    .font(.custom("Noteworthy-Bold", size: place.length(line.size)))
                    .foregroundStyle(Color(hex: line.color))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: place.length(line.width))
            }
        }
        .shadow(color: Color.white.opacity(0.9), radius: 3)
        .rotationEffect(.degrees(-5))
        .scaleEffect(reduceMotion ? 1 : 0.7 + 0.3 * SplashView.overshoot(shown))
        .opacity(min(shown * 2, 1) * (1 - hidden))
    }

    // MARK: Bar and hearts

    /// The bar and hearts show from "Opening your journal…" until the journal opens.
    private func barShown(at t: TimeInterval) -> Double {
        ramp(t, Stage.opening, Stage.opening + 0.25) * (1 - ramp(t, Stage.open - 0.1, Stage.open + 0.05))
    }

    /// How full the bar is: 70% as "Almost there…" comes, about 80% a little later, full just
    /// before the journal opens.
    static func progress(at t: TimeInterval) -> Double {
        let stops: [(TimeInterval, Double)] = [(Stage.opening + 0.05, 0), (Stage.almost, 0.7),
                                               (Stage.open - 0.4, 0.82), (Stage.open - 0.05, 1)]
        guard t > stops[0].0 else { return 0 }
        for (a, b) in zip(stops, stops.dropFirst()) where t <= b.0 {
            let x = (t - a.0) / (b.0 - a.0)
            return a.1 + (b.1 - a.1) * x * x * (3 - 2 * x)
        }
        return 1
    }

    /// When each of the four hearts under the bar lights up.
    private static let heartTimes: [TimeInterval] = [Stage.opening + 0.3, Stage.almost + 0.1,
                                                      Stage.almost + 0.6, Stage.open - 0.2]

    private func hearts(at t: TimeInterval, place: GridPlacement) -> some View {
        HStack(spacing: place.length(11)) {
            ForEach(0..<4, id: \.self) { index in
                let lit = ramp(t, Self.heartTimes[index], Self.heartTimes[index] + 0.15, eased: false)
                ZStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: place.length(25)))
                        .foregroundStyle(Color(hex: 0xFFC3DC))
                    ShinyHeart(size: place.length(25))
                        .scaleEffect(reduceMotion ? 1 : 0.5 + 0.5 * SplashView.overshoot(lit))
                        .opacity(lit)
                }
                .frame(width: place.length(27))
            }
        }
    }

    // MARK: Timing

    /// A message popping in just after its stage starts.
    private func arriving(_ t: TimeInterval, _ stage: TimeInterval) -> Double {
        ramp(t, stage + 0.05, stage + 0.4, eased: false)
    }

    /// A message fading as the next stage starts.
    private func leaving(_ t: TimeInterval, _ next: TimeInterval) -> Double {
        ramp(t, next - 0.1, next + 0.05)
    }

    /// 0 before `from`, 1 after `to`, and in between a smooth (or, unless `eased`, even) rise.
    private func ramp(_ t: TimeInterval, _ from: TimeInterval, _ to: TimeInterval, eased: Bool = true) -> Double {
        let x = min(max((t - from) / (to - from), 0), 1)
        return eased ? x * x * (3 - 2 * x) : x
    }
}

private struct TitleLine: Identifiable {
    let text: String
    /// Its width in the design, on the pictures' grid.
    let width: CGFloat
    /// The largest font size, on the grid (it shrinks to fit `width`).
    let size: CGFloat
    let color: UInt32

    var id: String { text }

    init(_ text: String, width: CGFloat, size: CGFloat, color: UInt32) {
        self.text = text
        self.width = width
        self.size = size
        self.color = color
    }
}

/// Maps the pictures' grid onto the screen, the way `scaledToFill` places the pictures:
/// scaled to cover it, centred.
private struct GridPlacement {
    let scale: CGFloat
    let origin: CGPoint

    init(grid: CGSize, screen: CGSize) {
        scale = max(screen.width / grid.width, screen.height / grid.height)
        origin = CGPoint(x: (screen.width - grid.width * scale) / 2, y: (screen.height - grid.height * scale) / 2)
    }

    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
    }

    func length(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}
