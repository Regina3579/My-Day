import SwiftUI

/// Where Get a Prompt is, so the first-time tip can point at it.
struct PromptButtonAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

/// Shown once on the journal's writing page, after the moods tip, as in the design: the page
/// takes a soft pink shade, Get a Prompt glows with yellow rays on both sides, the kitten winks
/// over a yellow cloud that says "Not sure what to write? Tap for a little inspiration 💭", and
/// a pink arrow curls from under the cloud up to the button. Get a Prompt adds a prompt; a tap
/// anywhere else closes the tip.
struct PromptTip: View {
    /// Get a Prompt, in this view's space.
    let buttonFrame: CGRect
    let size: CGSize
    let onTry: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var bounce = false

    /// `PromptTipArt` is the design's kitten, hearts and cloud with the words taken out, on this
    /// grid (the picture is 900 × 900 pixels); the words are drawn here, where the design has them.
    private static let grid = CGSize(width: 400, height: 400)
    /// On that grid: the gap from the button to the picture, how far the picture's top is above
    /// the button's middle, and where the arrow leaves (from under) the cloud.
    private static let gap: CGFloat = 43
    private static let aboveMiddle: CGFloat = 265
    private static let arrowStart = CGPoint(x: 88, y: 338)
    /// The largest size: the design's, on a phone as wide as the one it was drawn for.
    private static let maxScale: CGFloat = 0.5

    /// The picture's place: right of the button as in the design, or left of it when the button
    /// is at the right of the page.
    private var layout: (art: TipArtFrame, isLeft: Bool) {
        let span = Self.gap + Self.grid.width
        let right = min(Self.maxScale, (size.width - 6 - buttonFrame.maxX) / span)
        let left = min(Self.maxScale, (buttonFrame.minX - 6) / span)
        let isLeft = right < 0.36 && left > right
        let scale = max(0.2, isLeft ? left : right)
        let x = isLeft ? buttonFrame.minX - span * scale : buttonFrame.maxX + Self.gap * scale
        return (TipArtFrame(origin: CGPoint(x: x, y: buttonFrame.midY - Self.aboveMiddle * scale), scale: scale),
                isLeft)
    }

    /// The bright gap round the button.
    private var spot: CGRect {
        buttonFrame.insetBy(dx: -5, dy: -5)
    }

    var body: some View {
        let placed = layout
        ZStack(alignment: .topLeading) {
            TipShade(spot: spot, cornerRadius: spot.height / 2, shown: shown, onTap: onDismiss)
            buttonGlow
                .frame(width: spot.width, height: spot.height)
                .position(x: buttonFrame.midX, y: buttonFrame.midY)
            // Get a Prompt stays tappable through the gap.
            Capsule()
                .fill(Color.white.opacity(0.001))
                .frame(width: spot.width, height: spot.height)
                .position(x: buttonFrame.midX, y: buttonFrame.midY)
                .onTapGesture(perform: onTry)
                .accessibilityHidden(true)
            // The arrow comes out from under the cloud, as in the design.
            arrow(placed.art, isLeft: placed.isLeft)
            cloud(placed.art, isLeft: placed.isLeft)
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
                                 argument: "Tip: not sure what to write? Tap Get a Prompt for a little inspiration.")
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onDismiss)
    }

    // MARK: The cloud

    /// The picture with the words: "Not sure what / to write?" and "Tap for a little /
    /// inspiration 💭".
    private func cloud(_ place: TipArtFrame, isLeft: Bool) -> some View {
        let width = place.length(Self.grid.width)
        let height = place.length(Self.grid.height)
        let sure = Text("sure what").foregroundStyle(PromptTipStyle.pink)
        let headingFont = Font.system(size: place.length(35), weight: .heavy, design: .rounded)
        let bodyFont = Font.system(size: place.length(25), weight: .medium)
        return ZStack(alignment: .topLeading) {
            Image("PromptTipArt")
                .resizable()
                .frame(width: width, height: height)
            line(Text("Not \(sure)").foregroundStyle(PromptTipStyle.plum), font: headingFont,
                 center: CGPoint(x: 199.5, y: 216.5), width: 280, place: place)
            line(Text("to write?").foregroundStyle(PromptTipStyle.plum), font: headingFont,
                 center: CGPoint(x: 199, y: 255), width: 200, place: place)
            line(Text("Tap for a little").foregroundStyle(PromptTipStyle.body), font: bodyFont,
                 center: CGPoint(x: 199.5, y: 300), width: 230, place: place)
            line(Text("inspiration 💭").foregroundStyle(PromptTipStyle.body), font: bodyFont,
                 center: CGPoint(x: 199, y: 332), width: 230, place: place)
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .scaleEffect(shown ? 1 : 0.85, anchor: isLeft ? .bottomTrailing : .bottomLeading)
        .opacity(shown ? 1 : 0)
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
        .position(x: place.origin.x + width / 2, y: place.origin.y + height / 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Not sure what to write? Tap for a little inspiration.")
        .accessibilityAction(named: "Get a prompt", onTry)
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

    // MARK: The button and the arrow

    /// A white glow and a pink edge round the button, and three yellow rays at each end.
    private var buttonGlow: some View {
        let end = spot.height / 2
        return ZStack {
            Capsule()
                .strokeBorder(Color.white.opacity(0.9), lineWidth: 10)
                .blur(radius: 5)
                .padding(-6)
            Capsule()
                .strokeBorder(Palette.hotPink.opacity(0.6), lineWidth: 2.5)
                .shadow(color: Palette.hotPink.opacity(0.5), radius: 8)
            TipRays(radius: end + 2, angles: [-45, -78, -102], animated: bounce)
                .position(x: end - 6, y: end)
            TipRays(radius: end + 2, angles: [45, 78, 102], animated: bounce)
                .position(x: spot.width - end + 6, y: end)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// From under the cloud's lower corner, down and round, up to the button's lower end.
    private func arrow(_ place: TipArtFrame, isLeft: Bool) -> some View {
        let side: CGFloat = isLeft ? -1 : 1
        let start = place.point(isLeft ? Self.grid.width - Self.arrowStart.x : Self.arrowStart.x, Self.arrowStart.y)
        let end = CGPoint(x: isLeft ? buttonFrame.minX + 6 : buttonFrame.maxX - 6, y: buttonFrame.maxY + 3)
        return TipArrow(start: start,
                        control1: CGPoint(x: start.x - side * place.length(43), y: start.y + place.length(59)),
                        control2: CGPoint(x: end.x + side * place.length(32), y: end.y + place.length(42)),
                        end: end, lineWidth: 6)
            .offset(x: bounce ? -side : side, y: bounce ? -2 : 1)
            .opacity(shown ? 1 : 0)
    }
}

/// Colours of the prompt tip, sampled from the design.
private enum PromptTipStyle {
    static let plum = Color(hex: 0x86055C)
    static let pink = Color(hex: 0xE20781)
    static let body = Color(hex: 0x10111E)
}
