import SwiftUI

/// Shown once, the first time Quick Add opens on My Day, as in its design: the page takes the
/// soft pink shade, Add Task, Add Priority and Add Journal glow white with pink edges among
/// yellow sparkles, × glows with white rays, the yellow star with a pink bow peeks over a speech
/// card that says "Quick Add ✨ Add a task, priority, or journal in one tap!", and a soft pink
/// arrow curls from under the card to Add Journal. The menu stays usable above the shade; a tap
/// anywhere else closes the menu and the tip.
///
/// The card (star, bow, flowers, heart and the words, in the design's own lettering) is cut from
/// the design and enlarged 4× with Real-ESRGAN; the shade, glows, sparkles, rays and arrow are
/// drawn, placed on the design's grid (941 pixels across the screen) from where Add Journal and
/// × really are.
struct QuickAddTip: View {
    /// Add Journal (the lowest choice) and ×, in this view's space.
    let journalChip: CGRect
    let button: CGRect
    let size: CGSize
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var bounce = false

    /// Points per pixel of the design.
    private var k: CGFloat { size.width / 941 }

    /// The three choices, from Add Journal up (46 pt tall, 8 pt apart).
    private var chips: [CGRect] {
        (0..<3).map { journalChip.offsetBy(dx: 0, dy: -CGFloat($0) * (journalChip.height + 8)) }
    }

    var body: some View {
        // In the design the card's corner is 502 px left of Add Journal and 414 px above its middle.
        let width = 507 * k
        let origin = CGPoint(x: min(max(6, journalChip.minX - 502 * k), size.width - 6 - width),
                             y: journalChip.midY - 414 * k)
        ZStack(alignment: .topLeading) {
            TipShade.tint
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)
                .accessibilityHidden(true)
            glows
            sparkles
            arrow(origin)
            Image("QuickAddTipArt")
                .resizable()
                .frame(width: width, height: 327 * k)
                .scaleEffect(shown ? 1 : 0.85, anchor: .bottomTrailing)
                .opacity(shown ? 1 : 0)
                .offset(x: origin.x, y: origin.y)
                .onTapGesture(perform: onDismiss)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Quick Add. Add a task, priority, or journal in one tap!")
                .accessibilityAction(named: "Close tip", onDismiss)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .opacity(shown ? 1 : 0)
        .onAppear {
            if !shown { SoundEffects.play(.tip) }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { shown = true }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { bounce = true }
            }
            UIAccessibility.post(notification: .screenChanged,
                                 argument: "Tip: Quick Add. Add a task, priority, or journal in one tap!")
        }
    }

    /// A white glow with a pink edge behind each choice and round ×.
    private var glows: some View {
        ZStack(alignment: .topLeading) {
            ForEach(chips.indices, id: \.self) { index in
                let chip = chips[index]
                glow(Capsule(), frame: chip)
            }
            glow(Circle(), frame: button)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func glow<S: InsettableShape>(_ shape: S, frame: CGRect) -> some View {
        ZStack {
            shape.strokeBorder(Color.white.opacity(0.95), lineWidth: 9).blur(radius: 6).padding(-6)
            shape.strokeBorder(Palette.hotPink.opacity(0.45), lineWidth: 2).padding(-2)
                .shadow(color: Palette.hotPink.opacity(0.6), radius: 8)
        }
        .frame(width: frame.width, height: frame.height)
        .offset(x: frame.minX, y: frame.minY)
    }

    /// The design's little yellow sparkles beside the choices, and the white rays by ×.
    private var sparkles: some View {
        let left = journalChip.minX
        let right = journalChip.maxX
        let spots: [(CGPoint, CGFloat)] = [
            (CGPoint(x: left - 8, y: chips[1].midY - 26), 15), (CGPoint(x: left - 8, y: chips[0].midY - 30), 13),
            (CGPoint(x: right + 4, y: chips[1].midY - 24), 14), (CGPoint(x: right + 4, y: chips[0].midY + 24), 15),
            (CGPoint(x: left - 2, y: chips[0].maxY + 10), 11),
        ]
        return ZStack(alignment: .topLeading) {
            ForEach(spots.indices, id: \.self) { index in
                let (point, side) = spots[index]
                Image(systemName: "sparkle")
                    .font(.system(size: side, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFFE27A))
                    .shadow(color: Color(hex: 0xFFC43D).opacity(0.9), radius: 4)
                    .scaleEffect(bounce ? 1.1 : 0.9)
                    .position(point)
            }
            // Three white strokes at ×'s upper left, as if it shone.
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Color.white)
                    .frame(width: 4, height: index == 1 ? 15 : 12)
                    .offset(y: -(button.width / 2 + 14))
                    .rotationEffect(.degrees([-38.0, -62, -86][index]))
                    .shadow(color: Palette.hotPink.opacity(0.6), radius: 3)
                    .opacity(bounce ? 1 : 0.75)
                    .position(x: button.midX, y: button.midY)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// From under the card's tail, down and round, to Add Journal's left end.
    private func arrow(_ origin: CGPoint) -> some View {
        let start = CGPoint(x: origin.x + 370 * k, y: origin.y + 317 * k)
        let end = CGPoint(x: journalChip.minX - 10 * k, y: journalChip.midY + 2 * k)
        return TipArrow(start: start,
                        control1: CGPoint(x: start.x - 4 * k, y: start.y + 80 * k),
                        control2: CGPoint(x: end.x - 70 * k, y: end.y - 2 * k),
                        end: end, lineWidth: 11 * k, fill: TipArrow.softPink)
            .offset(x: bounce ? 1 : -1, y: bounce ? 1 : -1)
            .allowsHitTesting(false)
    }
}
