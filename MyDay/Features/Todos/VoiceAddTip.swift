import SwiftUI

/// Where the Speak a Task microphone is, so the first-time tip can point at it.
struct VoiceMicAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

/// Where the home screen's daily quote is, so the first-time tip can point at it.
struct DailyQuoteAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

/// Shown once, the first time the To-Dos page opens: a cute arrow bounces toward the
/// microphone and a bubble says tasks can be added by voice. "Try it now" (or the
/// microphone itself) opens Voice Add; "Got it" or a tap anywhere else closes it.
struct VoiceAddTip: View {
    /// The microphone, in this view's space.
    let micFrame: CGRect
    let size: CGSize
    let onTry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        FirstTimeTip(target: micFrame, size: size, pointing: .down, spotPadding: 12,
                     announcement: "Tip: you can add your task just by using your voice.",
                     onTapTarget: onTry, onDismiss: onDismiss) {
            TipBubble(symbol: "mic.fill",
                      iconColors: [Color(hex: 0xFFDA4D), Color(hex: 0xFFA800)],
                      title: "Add your task with your voice! 🎤",
                      message: "Tap the yellow microphone and just say it, like “Call Mom tomorrow at 5 PM”. I'll write your task for you. ✨",
                      secondaryTitle: "Got it", onSecondary: onDismiss,
                      primaryTitle: "Try it now", primarySymbol: "mic.fill", onPrimary: onTry)
        }
    }
}

/// Shown once, the first time the app opens: a cute arrow bounces up at the daily quote
/// and a bubble says a new one comes every day. Any tap closes it.
struct DailyQuoteTip: View {
    /// The quote, in this view's space.
    let quoteFrame: CGRect
    let size: CGSize
    let onDismiss: () -> Void

    var body: some View {
        FirstTimeTip(target: quoteFrame, size: size, pointing: .up, spotPadding: 12, spotCornerRadius: 22,
                     announcement: "Tip: a new motivational quote is waiting for you here every day.",
                     onTapTarget: onDismiss, onDismiss: onDismiss) {
            TipBubble(symbol: "sparkles",
                      iconColors: [Color(hex: 0xFF8CC6), Palette.hotPink],
                      title: "A new quote for you, every day! 💖",
                      message: "Every day, a fresh motivational quote waits for you right here, to cheer you on and help you shine. ✨",
                      primaryTitle: "Love it!", primarySymbol: "heart.fill", onPrimary: onDismiss)
        }
    }
}

// MARK: - The tip

/// A first-time tip: the screen dims around the thing it is about (which stays bright,
/// with glowing rings), a cute hand-drawn arrow bounces toward it, and a bubble explains it.
/// A tap on the dim closes it.
struct FirstTimeTip<Bubble: View>: View {
    /// Where the thing is, compared with the bubble.
    enum Pointing {
        /// Below the bubble: the arrow points down.
        case down
        /// Above the bubble: the arrow points up.
        case up
    }

    let target: CGRect
    let size: CGSize
    let pointing: Pointing
    /// Space around the thing inside the bright gap.
    var spotPadding: CGFloat = 12
    /// The gap's corner radius (nil: round).
    var spotCornerRadius: CGFloat?
    /// Read out by VoiceOver when the tip appears.
    let announcement: String
    let onTapTarget: () -> Void
    let onDismiss: () -> Void
    @ViewBuilder let bubble: () -> Bubble

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var bounce = false
    @State private var pulse = false

    private static var arrowSize: CGSize { CGSize(width: 86, height: 74) }
    /// Where the arrow's point is across its frame.
    private static var arrowTipX: CGFloat { 62 }

    private var spot: CGRect { target.insetBy(dx: -spotPadding, dy: -spotPadding) }

    private var spotShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: spotCornerRadius ?? min(spot.width, spot.height) / 2, style: .continuous)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            dimming
            rings
                .position(x: spot.midX, y: spot.midY)
            // The thing itself stays tappable through the gap.
            spotShape
                .fill(Color.white.opacity(0.001))
                .frame(width: spot.width, height: spot.height)
                .position(x: spot.midX, y: spot.midY)
                .onTapGesture(perform: onTapTarget)
                .accessibilityHidden(true)
            placedCallout
        }
        .frame(width: size.width, height: size.height)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { shown = true }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { bounce = true }
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { pulse = true }
            }
            UIAccessibility.post(notification: .screenChanged, argument: announcement)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onDismiss)
    }

    /// A soft shade over the screen with a gap around the thing.
    private var dimming: some View {
        ZStack {
            Color.black.opacity(0.32)
            spotShape
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

    /// A ring that keeps spreading out from the gap, and a steady glowing edge.
    private var rings: some View {
        ZStack {
            spotShape
                .strokeBorder(Color(hex: 0xFFD54A), lineWidth: 4)
                .frame(width: spot.width + 8, height: spot.height + 8)
                .scaleEffect(pulse ? 1.25 : 1)
                .opacity(pulse ? 0 : 0.9)
            spotShape
                .strokeBorder(Color.white, lineWidth: 3)
                .frame(width: spot.width, height: spot.height)
                .shadow(color: Color(hex: 0xFFC83D).opacity(0.9), radius: 10)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The bubble and arrow, placed so the arrow's point meets the thing.
    @ViewBuilder
    private var placedCallout: some View {
        let tipToTrailing = Self.arrowSize.width - Self.arrowTipX
        switch pointing {
        case .down:
            VStack(alignment: .trailing, spacing: 2) {
                bubble()
                    .frame(width: min(330, max(220, target.midX + tipToTrailing - 16)))
                arrow
            }
            .modifier(TipAppear(shown: shown, anchor: .bottomTrailing))
            .padding(.trailing, max(16, size.width - target.midX - tipToTrailing))
            .padding(.bottom, max(0, size.height - spot.minY + 2))
            .frame(width: size.width, height: size.height, alignment: .bottomTrailing)
        case .up:
            let leading = max(16, target.midX - Self.arrowTipX)
            VStack(alignment: .leading, spacing: 2) {
                arrow
                bubble()
                    .frame(width: min(330, max(220, size.width - leading - 16)))
            }
            .modifier(TipAppear(shown: shown, anchor: .topLeading))
            .padding(.leading, leading)
            .padding(.top, spot.maxY + 2)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
    }

    private var arrow: some View {
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
            // Pointing up: the same arrow, upside down.
            .scaleEffect(x: 1, y: pointing == .up ? -1 : 1)
            .offset(y: pointing == .up ? (bounce ? -7 : 1) : (bounce ? 7 : -1))
            .accessibilityHidden(true)
    }
}

/// The tip grows in from the arrow's side.
private struct TipAppear: ViewModifier {
    let shown: Bool
    let anchor: UnitPoint

    func body(content: Content) -> some View {
        content
            .scaleEffect(shown ? 1 : 0.85, anchor: anchor)
            .opacity(shown ? 1 : 0)
    }
}

/// The card of a first-time tip: an icon, a title, a line or two, and its buttons.
struct TipBubble: View {
    let symbol: String
    let iconColors: [Color]
    let title: String
    let message: String
    var secondaryTitle: String?
    var onSecondary: (() -> Void)?
    let primaryTitle: String
    var primarySymbol: String?
    let onPrimary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(LinearGradient(colors: iconColors,
                                                             startPoint: .topLeading, endPoint: .bottomTrailing)))
                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                    .shadow(color: (iconColors.last ?? Palette.hotPink).opacity(0.45), radius: 6, x: 0, y: 3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(Palette.berry)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(message)
                        .font(.rounded(.subheadline, weight: .medium))
                        .foregroundStyle(Palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(spacing: 10) {
                if let secondaryTitle, let onSecondary {
                    Button(action: onSecondary) {
                        Text(secondaryTitle)
                            .font(.rounded(.subheadline, weight: .bold))
                            .foregroundStyle(Palette.inkSoft)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Capsule().fill(Color(hex: 0xFFF1F7)))
                    }
                    .buttonStyle(PressScaleStyle(scale: 0.96))
                }
                Button(action: onPrimary) {
                    Group {
                        if let primarySymbol {
                            Label(primaryTitle, systemImage: primarySymbol)
                        } else {
                            Text(primaryTitle)
                        }
                    }
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
