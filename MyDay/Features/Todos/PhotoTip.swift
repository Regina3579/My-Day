import SwiftUI

/// Where the Photo button is, so the first-time tip can point at it.
struct PhotoButtonAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

/// Shown once on the To-Dos page, after the Speak a Task tip, as in the design: the page takes
/// a soft pink shade, the girl and her puppy peek over a cloud that says "Add photos to your
/// tasks! Tap here to add a photo.", and a pink arrow points down at the glowing Photo button.
/// Photo opens the photo to-do; a tap anywhere else closes the tip.
struct PhotoTip: View {
    /// The Photo button, in this view's space.
    let photoFrame: CGRect
    let size: CGSize
    let onTry: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var bounce = false

    /// `PhotoTipArt` is the design's girl, puppy and cloud with the words taken out, on this grid
    /// (the picture is 850 × 710 pixels); the words are drawn here, where the design has them.
    private static let grid = CGSize(width: 425, height: 355)
    /// On that grid: the Photo button's middle and top, and where the arrow leaves the cloud.
    private static let photoMidX: CGFloat = -67.5
    private static let photoTop: CGFloat = 375
    private static let arrowStart = CGPoint(x: 20, y: 257)

    /// The picture, placed as in the design: right of the Photo button's middle, its cloud just
    /// above the button.
    private var art: TipArtFrame {
        let room = (size.width - 10 - photoFrame.midX) / (Self.grid.width - Self.photoMidX)
        let scale = min(0.6, room)
        return TipArtFrame(origin: CGPoint(x: photoFrame.midX - Self.photoMidX * scale,
                                           y: photoFrame.minY - Self.photoTop * scale),
                           scale: scale)
    }

    /// The bright gap round the Photo button.
    private var spot: CGRect {
        photoFrame.insetBy(dx: -5, dy: -5)
    }

    var body: some View {
        let place = art
        ZStack(alignment: .topLeading) {
            TipShade(spot: spot, cornerRadius: spot.height / 2, shown: shown, onTap: onDismiss)
            photoGlow
                .frame(width: spot.width, height: spot.height)
                .position(x: photoFrame.midX, y: photoFrame.midY)
            // The Photo button stays tappable through the gap.
            Capsule()
                .fill(Color.white.opacity(0.001))
                .frame(width: spot.width, height: spot.height)
                .position(x: photoFrame.midX, y: photoFrame.midY)
                .onTapGesture(perform: onTry)
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
            }
            UIAccessibility.post(notification: .screenChanged,
                                 argument: "Tip: add photos to your tasks. Tap Photo to add a photo.")
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onDismiss)
    }

    // MARK: The cloud

    /// The picture with the words: "Add photos / to your tasks!" and "Tap here to add a photo."
    private func cloud(_ place: TipArtFrame) -> some View {
        let width = place.length(Self.grid.width)
        let height = place.length(Self.grid.height)
        let tasks = Text("tasks!").foregroundStyle(PhotoTipStyle.pink)
        return ZStack(alignment: .topLeading) {
            Image("PhotoTipArt")
                .resizable()
                .frame(width: width, height: height)
            line(Text("Add photos").foregroundStyle(PhotoTipStyle.pink),
                 font: .custom("ChalkboardSE-Bold", size: place.length(32)),
                 center: CGPoint(x: 207, y: 232), width: 250, place: place)
            line(Text("to your \(tasks)").foregroundStyle(PhotoTipStyle.purple),
                 font: .custom("ChalkboardSE-Bold", size: place.length(32)),
                 center: CGPoint(x: 206, y: 268), width: 250, place: place)
            line(Text("Tap here to add a photo.").foregroundStyle(PhotoTipStyle.body),
                 font: .system(size: place.length(21), weight: .semibold, design: .rounded),
                 center: CGPoint(x: 206, y: 307), width: 236, place: place)
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .scaleEffect(shown ? 1 : 0.85, anchor: .bottomLeading)
        .opacity(shown ? 1 : 0)
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
        .position(x: place.origin.x + width / 2, y: place.origin.y + height / 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Add photos to your tasks! Tap here to add a photo.")
        .accessibilityAction(named: "Add a photo", onTry)
        .accessibilityAction(named: "Close tip", onDismiss)
    }

    /// One line of the words, in its place on the cloud (it shrinks to fit).
    private func line(_ text: Text, font: Font, center: CGPoint, width: CGFloat, place: TipArtFrame) -> some View {
        text
            .font(font)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: place.length(width))
            .position(x: place.length(center.x), y: place.length(center.y))
    }

    // MARK: The Photo button and the arrow

    /// A white glow and a pink edge round the Photo button, and yellow rays at its right.
    private var photoGlow: some View {
        ZStack {
            Capsule()
                .strokeBorder(Color.white.opacity(0.9), lineWidth: 10)
                .blur(radius: 5)
                .padding(-6)
            Capsule()
                .strokeBorder(Palette.hotPink.opacity(0.75), lineWidth: 2.5)
                .shadow(color: Palette.hotPink.opacity(0.55), radius: 8)
            TipRays(radius: spot.height / 2 + 2, angles: [48, 78, 108], animated: bounce)
                .position(x: spot.width - spot.height / 2 + 6, y: spot.height / 2)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// From the cloud's left, out and down to the Photo button.
    private func arrow(_ place: TipArtFrame) -> some View {
        let start = place.point(Self.arrowStart.x, Self.arrowStart.y)
        let end = CGPoint(x: photoFrame.minX + photoFrame.width * 0.62, y: photoFrame.minY - 5)
        return TipArrow(start: start,
                        control1: CGPoint(x: start.x - 34, y: start.y + 6),
                        control2: CGPoint(x: end.x + 2, y: end.y - 34),
                        end: end, lineWidth: 6)
            .offset(x: bounce ? -1 : 1, y: bounce ? 3 : -1)
            .opacity(shown ? 1 : 0)
    }
}

/// Colours of the photo tip, sampled from the design.
private enum PhotoTipStyle {
    static let pink = LinearGradient(colors: [Color(hex: 0xE0307A), Color(hex: 0xC2185B)],
                                     startPoint: .top, endPoint: .bottom)
    static let purple = Color(hex: 0x5A2266)
    static let body = Color(hex: 0x3E3362)
}
