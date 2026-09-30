import SwiftUI

/// Where the Speak a Task microphone is, so the first-time tip can point at it.
struct VoiceMicAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

/// Shown once, the first time the To-Dos page opens: the page dims around the microphone,
/// a cute arrow bounces toward it and a bubble says tasks can be added by voice. "Try it
/// now" (or the microphone itself) opens Voice Add; "Got it" or a tap anywhere else closes it.
struct VoiceAddTip: View {
    /// The microphone, in this view's space.
    let micFrame: CGRect
    let size: CGSize
    let onTry: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var bounce = false
    @State private var pulse = false

    private static let arrowSize = CGSize(width: 86, height: 74)
    /// Where the arrow's point is in its frame.
    private static let arrowTip = CGPoint(x: 62, y: 70)

    var body: some View {
        let spot = micFrame.insetBy(dx: -12, dy: -12)
        ZStack(alignment: .topLeading) {
            dimming(around: spot)
            rings
                .position(x: micFrame.midX, y: micFrame.midY)
            // The microphone stays tappable through the gap.
            Circle()
                .fill(Color.white.opacity(0.001))
                .frame(width: spot.width, height: spot.height)
                .position(x: spot.midX, y: spot.midY)
                .onTapGesture(perform: onTry)
                .accessibilityHidden(true)
            callout
                .padding(.trailing, max(16, size.width - micFrame.midX - (Self.arrowSize.width - Self.arrowTip.x)))
                .padding(.bottom, max(0, size.height - spot.minY + 2))
                .frame(width: size.width, height: size.height, alignment: .bottomTrailing)
        }
        .frame(width: size.width, height: size.height)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { shown = true }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { bounce = true }
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { pulse = true }
            }
            UIAccessibility.post(notification: .screenChanged,
                                 argument: "Tip: you can add your task just by using your voice.")
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onDismiss)
    }

    /// A soft shade over the page with a round gap around the microphone.
    private func dimming(around spot: CGRect) -> some View {
        ZStack {
            Color.black.opacity(0.32)
            Circle()
                .frame(width: spot.width, height: spot.height)
                .position(x: spot.midX, y: spot.midY)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
        .opacity(shown ? 1 : 0)
        .accessibilityHidden(true)
    }

    /// Two rings that keep spreading out from the microphone.
    private var rings: some View {
        ZStack {
            Circle()
                .strokeBorder(Color(hex: 0xFFD54A), lineWidth: 4)
                .frame(width: micFrame.width + 20, height: micFrame.height + 20)
                .scaleEffect(pulse ? 1.55 : 1)
                .opacity(pulse ? 0 : 0.9)
            Circle()
                .strokeBorder(Color.white, lineWidth: 3)
                .frame(width: micFrame.width + 14, height: micFrame.height + 14)
                .shadow(color: Color(hex: 0xFFC83D).opacity(0.9), radius: 10)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The bubble, and the arrow from it down to the microphone.
    private var callout: some View {
        VStack(alignment: .trailing, spacing: 2) {
            bubble
                .frame(width: min(330, max(220, micFrame.midX + (Self.arrowSize.width - Self.arrowTip.x) - 16)))
            TipArrow()
                .stroke(LinearGradient(colors: [Color(hex: 0xFF8CC6), Palette.hotPink],
                                       startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                .frame(width: Self.arrowSize.width, height: Self.arrowSize.height)
                .shadow(color: Color.white.opacity(0.9), radius: 2)
                .overlay(alignment: .topLeading) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: 0xFFE27A))
                        .offset(x: 30, y: 4)
                }
                .offset(y: bounce ? 7 : -1)
                .accessibilityHidden(true)
        }
        .scaleEffect(shown ? 1 : 0.85, anchor: .bottomTrailing)
        .opacity(shown ? 1 : 0)
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(LinearGradient(colors: [Color(hex: 0xFFDA4D), Color(hex: 0xFFA800)],
                                                             startPoint: .topLeading, endPoint: .bottomTrailing)))
                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                    .shadow(color: Palette.honey.opacity(0.5), radius: 6, x: 0, y: 3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Add your task with your voice! 🎤")
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(Palette.berry)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text("Tap the yellow microphone and just say it, like “Call Mom tomorrow at 5 PM”. I'll write your task for you. ✨")
                        .font(.rounded(.subheadline, weight: .medium))
                        .foregroundStyle(Palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(spacing: 10) {
                Button(action: onDismiss) {
                    Text("Got it")
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(Palette.inkSoft)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Capsule().fill(Color(hex: 0xFFF1F7)))
                }
                .buttonStyle(PressScaleStyle(scale: 0.96))
                Button(action: onTry) {
                    Label("Try it now", systemImage: "mic.fill")
                        .font(.rounded(.subheadline, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Capsule().fill(LinearGradient(colors: [Color(hex: 0xFF6FB0), Palette.hotPink],
                                                                  startPoint: .top, endPoint: .bottom)))
                        .shadow(color: Palette.hotPink.opacity(0.35), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PressScaleStyle(scale: 0.96))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Palette.bubblegum.opacity(0.4), lineWidth: 1.5)
        )
        .overlay(alignment: .topTrailing) {
            Text("NEW")
                .font(.rounded(.caption2, weight: .heavy))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Palette.hotPink))
                .offset(x: -14, y: -9)
                .accessibilityHidden(true)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 8)
    }
}

/// A hand-drawn curly arrow that swoops down to the right and points straight down.
private struct TipArrow: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 86
        let sy = rect.height / 74
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }
        var path = Path()
        // The swoop, with a small loop on the way.
        path.move(to: point(14, 4))
        path.addCurve(to: point(34, 34), control1: point(6, 22), control2: point(18, 36))
        path.addCurve(to: point(38, 22), control1: point(44, 32), control2: point(44, 20))
        path.addCurve(to: point(62, 70), control1: point(30, 26), control2: point(62, 38))
        // The arrowhead.
        path.move(to: point(52, 58))
        path.addLine(to: point(62, 70))
        path.addLine(to: point(72, 59))
        return path
    }
}
