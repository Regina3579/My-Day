import SwiftUI

/// Opening My Journal, before My Journal Pages shows: the design's picture of the girl winking
/// by her journal with her puppy, and "Get ready to write a beautiful story!". The words pop in,
/// and after `length` (a tap skips it) the journal fades in over it.
///
/// The picture (`JournalOpening`) comes from the design with its words taken out: they are drawn
/// here, where the design has them, on the picture's own 364 × 678 grid, which fills the screen
/// the way the picture does.
struct JournalOpeningView: View {
    /// Debug screenshots only: hold it still at this moment.
    var frozenAt: TimeInterval?
    /// Called at the end, or when it is tapped.
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var isDone = false

    /// How long it shows, in seconds, before the journal opens.
    static let length: TimeInterval = 1.5
    /// The size of the picture in the design, in which the words are placed.
    private static let grid = CGSize(width: 364, height: 678)

    private static let lines = [
        TitleLine("Get ready", width: 218, size: 48, color: 0x93097D),
        TitleLine("to write a", width: 136, size: 28, color: 0x560F8A),
        TitleLine("beautiful story!", width: 232, size: 32, color: 0x5D0E87)
    ]

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
        .accessibilityLabel("Get ready to write a beautiful story!")
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
        // The picture settles from a little zoom as the words pop in.
        let settle = reduceMotion ? 1 : 1.04 - 0.04 * ramp(t, 0, 1.2)
        return ZStack {
            Color(hex: 0xFCE3EE)
            Image("JournalOpening")
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
                .scaleEffect(settle)
            title(shown: ramp(t, 0.15, 0.75, eased: false), place: place)
                .position(place.point(192, 112))
        }
        .frame(width: size.width, height: size.height)
    }

    /// Lines of the design's handwriting, each as wide as in the design, tilted a little and
    /// popping in (`shown` 0…1).
    private func title(shown: Double, place: GridPlacement) -> some View {
        VStack(spacing: place.length(1)) {
            ForEach(Self.lines) { line in
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
        .scaleEffect(reduceMotion ? 1 : 0.7 + 0.3 * Self.overshoot(shown))
        .opacity(min(shown * 2, 1))
    }

    /// 0 before `from`, 1 after `to`, and in between a smooth (or, unless `eased`, even) rise.
    private func ramp(_ t: TimeInterval, _ from: TimeInterval, _ to: TimeInterval, eased: Bool = true) -> Double {
        let x = min(max((t - from) / (to - from), 0), 1)
        return eased ? x * x * (3 - 2 * x) : x
    }

    /// Rises past 1 and settles back, for a "pop".
    private static func overshoot(_ x: Double) -> Double {
        let c = 1.70158
        return 1 + (c + 1) * pow(x - 1, 3) + c * pow(x - 1, 2)
    }
}

private struct TitleLine: Identifiable {
    let text: String
    /// Its width in the design, on the picture's grid.
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

/// Maps the picture's grid onto the screen, the way `scaledToFill` places the picture:
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
