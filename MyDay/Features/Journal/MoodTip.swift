import SwiftUI

/// Where the ＋ beside the six moods is, so the first-time tip can point at it.
struct MoodPlusAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

/// Shown once, the first time a journal page is written, as in the design: the page takes a
/// soft pink shade, the girl winks and points at a cloud that says "There's a feeling for every
/// kind of day! Tap ⊕ to discover more moods.", and a pink arrow points up at the glowing ＋
/// beside "How are you feeling today?". The ＋ opens Choose your mood; a tap anywhere else
/// closes the tip.
struct MoodTip: View {
    /// The ＋, in this view's space.
    let plusFrame: CGRect
    let size: CGSize
    let onOpen: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var bounce = false
    @State private var pulse = false

    /// `MoodTipArt` is the design's girl, puppy and cloud with the words taken out, on this grid
    /// (the picture is 1080 × 398 pixels); the words are drawn here, where the design has them.
    private static let grid = CGSize(width: 900, height: 332)
    /// Where the arrow leaves the cloud, on that grid.
    private static let arrowStart = CGPoint(x: 706, y: 64)

    /// The picture, as wide as the page allows (so the words are easy to read), just below the ＋.
    private var art: TipArtFrame {
        let width = min(size.width - 16, 400)
        return TipArtFrame(origin: CGPoint(x: (size.width - width) / 2, y: plusFrame.maxY + 6),
                           scale: width / Self.grid.width)
    }

    /// The bright gap round the ＋.
    private var spot: CGRect {
        plusFrame.insetBy(dx: -11, dy: -11)
    }

    var body: some View {
        let place = art
        ZStack(alignment: .topLeading) {
            TipShade(spot: spot, cornerRadius: spot.width / 2, shown: shown, onTap: onDismiss)
            plusGlow
                .position(x: plusFrame.midX, y: plusFrame.midY)
            // The ＋ stays tappable through the gap.
            Circle()
                .fill(Color.white.opacity(0.001))
                .frame(width: spot.width, height: spot.height)
                .position(x: plusFrame.midX, y: plusFrame.midY)
                .onTapGesture(perform: onOpen)
                .accessibilityHidden(true)
            cloud(place)
            arrow(place)
        }
        .frame(width: size.width, height: size.height)
        .onAppear {
            // My Day's discovery sound, as the cloud pops up (not again if the page comes back).
            if !shown { SoundEffects.play(.tip) }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { shown = true }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { bounce = true }
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { pulse = true }
            }
            UIAccessibility.post(notification: .screenChanged,
                                 argument: "Tip: there's a feeling for every kind of day. Tap the plus button to discover more moods.")
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onDismiss)
    }

    // MARK: The cloud

    /// The picture with the design's words on it.
    private func cloud(_ place: TipArtFrame) -> some View {
        let width = place.length(Self.grid.width)
        let height = place.length(Self.grid.height)
        let plus = Text(Image(systemName: "plus.circle.fill")).foregroundStyle(MoodTipStyle.plus)
        return ZStack(alignment: .topLeading) {
            Image("MoodTipArt")
                .resizable()
                .frame(width: width, height: height)
            line(Text("There’s a feeling").foregroundStyle(MoodTipStyle.pink),
                 center: CGPoint(x: 553, y: 85), width: 300, size: 42, weight: .heavy, place: place)
            line(Text("for every kind of day!").foregroundStyle(MoodTipStyle.purple),
                 center: CGPoint(x: 567, y: 136), width: 362, size: 40, weight: .heavy, place: place)
            line(Text("Tap \(plus) to discover").foregroundStyle(MoodTipStyle.body),
                 center: CGPoint(x: 563, y: 181), width: 235, size: 30, weight: .bold, place: place)
            line(Text("more moods.").foregroundStyle(MoodTipStyle.body),
                 center: CGPoint(x: 560, y: 211), width: 151, size: 30, weight: .bold, place: place)
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .scaleEffect(shown ? 1 : 0.85, anchor: .topTrailing)
        .opacity(shown ? 1 : 0)
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
        .position(x: place.origin.x + width / 2, y: place.origin.y + height / 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("There's a feeling for every kind of day! Tap plus to discover more moods.")
        .accessibilityAction(named: "Choose your mood", onOpen)
        .accessibilityAction(named: "Close tip", onDismiss)
    }

    /// One line of the design's words, as wide as in the design (it shrinks to fit).
    private func line(_ text: Text, center: CGPoint, width: CGFloat, size: CGFloat, weight: Font.Weight,
                      place: TipArtFrame) -> some View {
        text
            .font(.system(size: place.length(size), weight: weight, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: place.length(width))
            .position(x: place.length(center.x), y: place.length(center.y))
    }

    // MARK: The ＋ and the arrow

    /// A white ring with a pink glow round the ＋, a ring spreading out, and yellow rays.
    private var plusGlow: some View {
        let d = plusFrame.width
        return ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.85), lineWidth: 9)
                .frame(width: d + 24, height: d + 24)
                .blur(radius: 4)
            Circle()
                .strokeBorder(Palette.hotPink.opacity(0.55), lineWidth: 3)
                .frame(width: d + 14, height: d + 14)
                .scaleEffect(pulse ? 1.5 : 1)
                .opacity(pulse ? 0 : 0.9)
            Circle()
                .strokeBorder(Color.white, lineWidth: 4)
                .frame(width: d + 10, height: d + 10)
                .shadow(color: Palette.hotPink.opacity(0.6), radius: 8)
            TipRays(radius: d / 2 + 12, angles: [-62, -42, 18, 38, 80, 98], animated: bounce)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// From the cloud's top right, up and round to the ＋'s left.
    private func arrow(_ place: TipArtFrame) -> some View {
        let start = place.point(Self.arrowStart.x, Self.arrowStart.y)
        let end = CGPoint(x: plusFrame.minX - 6, y: plusFrame.midY + 5)
        return TipArrow(start: start,
                        control1: CGPoint(x: start.x - 2, y: start.y - max(14, (start.y - end.y) * 0.9)),
                        control2: CGPoint(x: end.x - 12, y: end.y + 10),
                        end: end, lineWidth: 5.5)
            .offset(x: bounce ? 2 : -1, y: bounce ? -2 : 1)
            .opacity(shown ? 1 : 0)
    }
}

/// Colours of the mood tip, sampled from the design.
private enum MoodTipStyle {
    static let pink = LinearGradient(colors: [Color(hex: 0xF0379E), Color(hex: 0xD5098E)],
                                     startPoint: .top, endPoint: .bottom)
    static let purple = Color(hex: 0x4C1E98)
    static let body = Color(hex: 0x4E279C)
    static let plus = LinearGradient(colors: [Color(hex: 0xFD6AB8), Color(hex: 0xF2148E)],
                                     startPoint: .top, endPoint: .bottom)
}
