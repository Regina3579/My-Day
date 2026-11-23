import SwiftUI

/// The two first-time tips of My Journal Pages' ⋮ menu, each shown once, from their designs:
///
/// - **More options here!** (`.menu`): the page takes the soft pink shade, ⋮ glows in a white
///   ring with two white rays, the pink star with a bow peeks over a white card that says
///   "More options here! Tap the three dots to explore helpful journal tools.", and a pink arrow
///   curls from the card up to ⋮. Tapping ⋮ opens the menu; anywhere else closes the tip.
/// - **Journal Themes** (`.theme`), the first time the menu is open: Journal Theme glows white
///   with a pink edge and two white rays, the yellow star with a bow peeks over a white cloud that
///   says "Journal Themes ✨ Tap here to discover many beautiful themes for your journal pages.",
///   and a pink arrow curls up from beside the star to the row. Tapping the row opens the themes;
///   anywhere else closes the tip.
///
/// The cards (star, hearts, sparkles and the words, in the design's own lettering) are cut from
/// the designs and enlarged 4× with Real-ESRGAN; the shade, glow, rays and arrow are drawn, so
/// they find ⋮ and the row on any iPhone. Everything is placed on the design's grid (941 pixels
/// across the screen), measured from what the tip points at.
struct JournalMenuTip: View {
    enum Kind {
        case menu, theme
    }

    let kind: Kind
    /// ⋮, or the Journal Theme row, in this view's space.
    let target: CGRect
    let size: CGSize
    let onTarget: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var bounce = false

    /// Points per pixel of the design (the designs are 941 pixels across a phone's width).
    private var k: CGFloat { size.width / 941 }

    private var spot: CGRect {
        switch kind {
        case .menu:
            let side = 92 * k
            return CGRect(x: target.midX - side / 2, y: target.midY - side / 2, width: side, height: side)
        case .theme:
            return target.insetBy(dx: -4, dy: -3)
        }
    }

    /// The card: its picture, size (design pixels) and top-left corner on screen.
    private var card: (image: String, pixels: CGSize, origin: CGPoint) {
        switch kind {
        case .menu:
            // In the design the card's corner is 523 px left of ⋮'s middle and 18 px above it.
            let width = 501 * k
            let x = min(max(6, target.midX - 523 * k), size.width - 6 - width)
            return ("JournalMenuTipArt", CGSize(width: 501, height: 294), CGPoint(x: x, y: target.midY - 18 * k))
        case .theme:
            // 390 px left of the row's start and 27 px above its middle (kept on the screen).
            return ("JournalThemeTipArt", CGSize(width: 477, height: 358),
                    CGPoint(x: max(6, target.minX - 390 * k), y: target.midY - 27 * k))
        }
    }

    var body: some View {
        let card = card
        ZStack(alignment: .topLeading) {
            TipShade(spot: spot, cornerRadius: kind == .menu ? spot.width / 2 : 18, shown: shown, onTap: onDismiss)
            glow
                .frame(width: spot.width, height: spot.height)
                .position(x: spot.midX, y: spot.midY)
            // What the tip points at stays tappable through the gap.
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.001))
                .frame(width: spot.width, height: spot.height)
                .position(x: spot.midX, y: spot.midY)
                .onTapGesture(perform: onTarget)
                .accessibilityHidden(true)
            arrow(card.origin)
            Image(card.image)
                .resizable()
                .frame(width: card.pixels.width * k, height: card.pixels.height * k)
                .scaleEffect(shown ? 1 : 0.85, anchor: kind == .menu ? .topTrailing : .topLeading)
                .opacity(shown ? 1 : 0)
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)
                .offset(x: card.origin.x, y: card.origin.y)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(words)
                .accessibilityAction(named: kind == .menu ? "Open the menu" : "Choose a journal theme", onTarget)
                .accessibilityAction(named: "Close tip", onDismiss)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .onAppear {
            if !shown { SoundEffects.play(.tip) }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { shown = true }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { bounce = true }
            }
            UIAccessibility.post(notification: .screenChanged, argument: "Tip: " + words)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onDismiss)
    }

    private var words: String {
        switch kind {
        case .menu: "More options here! Tap the three dots to explore helpful journal tools."
        case .theme: "Journal Themes. Tap here to discover many beautiful themes for your journal pages."
        }
    }

    /// A white glow with a pink edge round ⋮ or the row, and two white rays at its top right.
    private var glow: some View {
        let shape = RoundedRectangle(cornerRadius: kind == .menu ? spot.width / 2 : 18, style: .continuous)
        return ZStack {
            shape
                .fill(Color.white.opacity(kind == .menu ? 0.85 : 0.55))
            shape
                .strokeBorder(Color.white.opacity(0.95), lineWidth: 8)
                .blur(radius: 5)
                .padding(-5)
            shape
                .strokeBorder(Palette.hotPink.opacity(0.55), lineWidth: 2)
                .shadow(color: Palette.hotPink.opacity(0.55), radius: 8)
            rays
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: kind == .menu ? 14 * k : -10 * k, y: kind == .menu ? -28 * k : -34 * k)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The design's two little white strokes, as if ⋮ or the row sparkled.
    private var rays: some View {
        ZStack {
            Capsule()
                .fill(Color.white)
                .frame(width: 9 * k, height: 34 * k)
                .rotationEffect(.degrees(12))
                .offset(x: -22 * k)
            Capsule()
                .fill(Color.white)
                .frame(width: 9 * k, height: 30 * k)
                .rotationEffect(.degrees(48))
                .offset(x: 4 * k, y: 8 * k)
        }
        .frame(width: 60 * k, height: 50 * k)
        .shadow(color: Palette.hotPink.opacity(0.6), radius: 4)
        .scaleEffect(bounce ? 1.08 : 0.94)
    }

    /// The pink arrow, from the card up to ⋮ (over to its left side) or to the row's start.
    private func arrow(_ origin: CGPoint) -> some View {
        let start: CGPoint
        let end: CGPoint
        let control1: CGPoint
        let control2: CGPoint
        switch kind {
        case .menu:
            start = CGPoint(x: origin.x + 358 * k, y: origin.y + 96 * k)
            end = CGPoint(x: target.midX - 66 * k, y: target.midY - 14 * k)
            control1 = CGPoint(x: start.x - 12 * k, y: start.y - 70 * k)
            control2 = CGPoint(x: end.x - 62 * k, y: end.y + 2 * k)
        case .theme:
            start = CGPoint(x: origin.x + 299 * k, y: origin.y + 99 * k)
            end = CGPoint(x: target.minX + 12 * k, y: target.midY - 14 * k)
            control1 = CGPoint(x: start.x + 4 * k, y: start.y - 52 * k)
            control2 = CGPoint(x: end.x - 40 * k, y: end.y + 4 * k)
        }
        return TipArrow(start: start, control1: control1, control2: control2, end: end, lineWidth: 12 * k)
            .offset(x: bounce ? 1 : -1, y: bounce ? -2 : 1)
            .opacity(shown ? 1 : 0)
    }
}
