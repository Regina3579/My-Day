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

/// Shown once, the first time the To-Dos page opens, as in the design: the page takes a soft
/// pink shade, the girl and her puppy peek over a card and point down at it, the card says
/// "Add your task with your voice!", and a pink arrow points at the glowing microphone.
/// "Try it now" (or the microphone) opens Voice Add; ✕, "Got it" or a tap anywhere else
/// closes it.
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

    /// Short screens (iPhone SE) get a smaller girl and a shorter arrow, so it all fits.
    private var isShort: Bool { size.height < 740 }

    /// Room between the card and the microphone, for the arrow.
    private var arrowGap: CGFloat { isShort ? 48 : 64 }
    /// The girl picture: its size, and the row where the card's top edge meets it.
    private static let girlSize = CGSize(width: 506, height: 282)
    private static let girlCardRow: CGFloat = 246

    /// The bright gap: the microphone and its "Speak a Task" label.
    private var spot: CGRect {
        CGRect(x: micFrame.midX - 46, y: micFrame.minY - 12, width: 92, height: micFrame.height + 50)
    }

    private var cardWidth: CGFloat { min(320, max(270, size.width * 0.8)) }

    private var girlWidth: CGFloat { cardWidth * (isShort ? 0.6 : 0.78) }

    private var girlHeight: CGFloat { girlWidth * Self.girlSize.height / Self.girlSize.width }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TipShade(spot: spot, cornerRadius: 34, shown: shown, onTap: onDismiss)
            micGlow
                .position(x: micFrame.midX, y: micFrame.midY)
            // The microphone stays tappable through the gap.
            Circle()
                .fill(Color.white.opacity(0.001))
                .frame(width: micFrame.width + 24, height: micFrame.height + 24)
                .position(x: micFrame.midX, y: micFrame.midY)
                .onTapGesture(perform: onTry)
                .accessibilityHidden(true)
            arrow
            card
                .frame(width: cardWidth)
                .scaleEffect(shown ? 1 : 0.85, anchor: .bottomTrailing)
                .opacity(shown ? 1 : 0)
                .padding(.trailing, 18)
                .padding(.bottom, max(0, size.height - spot.minY + arrowGap))
                .frame(width: size.width, height: size.height, alignment: .bottomTrailing)
        }
        .frame(width: size.width, height: size.height)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { shown = true }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { bounce = true }
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { pulse = true }
            }
            UIAccessibility.post(notification: .screenChanged,
                                 argument: "Tip: you can add your task just by using your voice.")
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onDismiss)
    }

    // MARK: The card

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VoiceTipMicBadge()
                VStack(alignment: .leading, spacing: 8) {
                    title
                    Text("Tap the yellow microphone and just say it, like:")
                        .font(.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(VoiceTipStyle.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                quote
                Text("I'll write your task for you! ✨")
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(VoiceTipStyle.body)
            }
            .padding(.leading, 58)
            HStack(spacing: 10) {
                Button(action: onDismiss) {
                    Text("Got it")
                        .font(.rounded(.headline, weight: .bold))
                        .foregroundStyle(VoiceTipStyle.gotIt)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Capsule().fill(Color.white))
                        .overlay(Capsule().strokeBorder(VoiceTipStyle.border, lineWidth: 1.5))
                        .shadow(color: Palette.hotPink.opacity(0.12), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PressScaleStyle(scale: 0.96))
                Button(action: onTry) {
                    Label("Try it now", systemImage: "mic.fill")
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Capsule().fill(VoiceTipStyle.pinkButton))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.5), lineWidth: 1.5))
                        .shadow(color: Palette.hotPink.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PressScaleStyle(scale: 0.96))
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 18)
        .padding(.top, 24)
        .padding(.bottom, 18)
        .background(cardBackground)
        .overlay { decorations }
        .overlay(alignment: .topTrailing) {
            newTag
                .padding(.top, 42)
                .padding(.trailing, 16)
        }
        .overlay(alignment: .topLeading) {
            girl
        }
        .overlay(alignment: .topTrailing) {
            closeButton
                .offset(x: 12, y: -14)
        }
    }

    /// "Add your task with / your voice! 🎙️", with "voice!" big and pink.
    private var title: some View {
        VStack(alignment: .leading, spacing: -2) {
            Text("Add your task with")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(VoiceTipStyle.title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.trailing, 52)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("your")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(VoiceTipStyle.title)
                Text("voice!")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .italic()
                    .foregroundStyle(VoiceTipStyle.voice)
                Text("🎙️")
                    .font(.system(size: 22))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Add your task with your voice!")
        .accessibilityAddTraits(.isHeader)
    }

    /// ❝ "Call Mom tomorrow at 5 PM." ❞ in a soft pink pill.
    private var quote: some View {
        HStack(spacing: 6) {
            Image(systemName: "quote.opening")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(Palette.hotPink)
            Text("“Call Mom tomorrow at 5 PM.”")
                .font(.custom("Noteworthy-Bold", size: 15, relativeTo: .subheadline))
                .foregroundStyle(VoiceTipStyle.title)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Image(systemName: "quote.closing")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(Color(hex: 0xC77DFF))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Capsule().fill(VoiceTipStyle.quoteFill))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("For example: Call Mom tomorrow at 5 PM.")
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(LinearGradient(colors: [Color.white, Color(hex: 0xFFF2F8)], startPoint: .top, endPoint: .bottom))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(VoiceTipStyle.border, lineWidth: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .strokeBorder(VoiceTipStyle.border.opacity(0.9), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    .padding(8)
            )
            .shadow(color: Palette.hotPink.opacity(0.28), radius: 18, x: 0, y: 8)
    }

    /// Hearts and stars around the card, as in the design.
    private var decorations: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(VoiceTipStyle.heart)
                    .rotationEffect(.degrees(-12))
                    .position(x: 10, y: h * 0.46)
                Image(systemName: "sparkle")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFFD23F))
                    .position(x: 16, y: h * 0.6)
                Image(systemName: "suit.diamond.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(VoiceTipStyle.heart.opacity(0.9))
                    .rotationEffect(.degrees(20))
                    .position(x: 32, y: h * 0.67)
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: 0xFFD23F))
                    .rotationEffect(.degrees(14))
                    .position(x: w - 22, y: h * 0.38)
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(VoiceTipStyle.heart)
                    .rotationEffect(.degrees(14))
                    .position(x: w - 20, y: h * 0.66)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var newTag: some View {
        Text("NEW")
            .font(.rounded(.caption, weight: .black))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(VoiceTipStyle.pinkButton))
            .shadow(color: Palette.hotPink.opacity(0.3), radius: 4, x: 0, y: 2)
            .rotationEffect(.degrees(-8))
            .accessibilityHidden(true)
    }

    /// The girl and her puppy peeking over the card, her finger pointing down at it.
    private var girl: some View {
        Image("VoiceTipGirl")
            .resizable()
            .scaledToFit()
            .frame(width: girlWidth, height: girlHeight)
            .overlay(alignment: .topLeading) {
                ZStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(VoiceTipStyle.heart)
                        .rotationEffect(.degrees(-15))
                        .offset(x: -6, y: girlHeight * 0.36)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(VoiceTipStyle.heart)
                        .rotationEffect(.degrees(12))
                        .offset(x: girlWidth * 0.66, y: girlHeight * 0.14)
                    Image(systemName: "sparkle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white)
                        .offset(x: girlWidth * 0.1, y: girlHeight * 0.12)
                    Image(systemName: "sparkle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: 0xFFE27A))
                        .offset(x: girlWidth * 0.96, y: girlHeight * 0.3)
                }
                .scaleEffect(bounce ? 1.08 : 0.95)
            }
            .offset(x: cardWidth * 0.04, y: -girlHeight * Self.girlCardRow / Self.girlSize.height)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(VoiceTipStyle.title)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.white))
                .overlay(Circle().strokeBorder(VoiceTipStyle.border.opacity(0.6), lineWidth: 1))
                .shadow(color: Palette.hotPink.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PressScaleStyle(scale: 0.9))
        .accessibilityLabel("Close")
    }

    // MARK: The microphone and the arrow

    /// A bright ring on the microphone, a ring spreading out, and pink sparks around it.
    private var micGlow: some View {
        let d = micFrame.width
        return ZStack {
            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: d + 34, height: d + 34)
                .blur(radius: 9)
            Circle()
                .strokeBorder(Color(hex: 0xFFD54A), lineWidth: 3)
                .frame(width: d + 16, height: d + 16)
                .scaleEffect(pulse ? 1.5 : 1)
                .opacity(pulse ? 0 : 0.9)
            Circle()
                .strokeBorder(Color.white, lineWidth: 5)
                .frame(width: d + 14, height: d + 14)
                .shadow(color: Color(hex: 0xFFC83D).opacity(0.9), radius: 10)
            ForEach(Array(VoiceTipStyle.sparks.enumerated()), id: \.offset) { index, spark in
                Capsule()
                    .fill(index.isMultiple(of: 3) ? Color.white : VoiceTipStyle.heart)
                    .frame(width: 5, height: spark.length)
                    .offset(y: -(d / 2 + 22))
                    .rotationEffect(.degrees(spark.angle))
                    .scaleEffect(bounce ? 1.06 : 0.94)
            }
            Image(systemName: "sparkle")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(VoiceTipStyle.heart)
                .offset(x: -(d / 2 + 26), y: -(d / 2 + 8))
            Image(systemName: "sparkle")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.white)
                .offset(x: d / 2 + 30, y: 4)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// A thick pink arrow from the card down to the microphone.
    private var arrow: some View {
        let cardBottom = spot.minY - arrowGap
        let start = CGPoint(x: micFrame.midX - 62, y: cardBottom + 4)
        let end = CGPoint(x: micFrame.midX - 14, y: micFrame.minY - 10)
        let control2 = CGPoint(x: end.x - 24, y: end.y - 24)
        return ZStack {
            Path { path in
                path.move(to: start)
                path.addCurve(to: end,
                              control1: CGPoint(x: start.x - 4, y: start.y + (end.y - start.y) * 0.75),
                              control2: control2)
            }
            .stroke(VoiceTipStyle.arrow, style: StrokeStyle(lineWidth: 6, lineCap: .round))
            Path { path in
                // The arrowhead, along the line's last direction.
                let angle = atan2(end.y - control2.y, end.x - control2.x)
                for turn in [CGFloat.pi * 0.8, -CGFloat.pi * 0.8] {
                    path.move(to: end)
                    path.addLine(to: CGPoint(x: end.x + 15 * cos(angle + turn), y: end.y + 15 * sin(angle + turn)))
                }
            }
            .stroke(VoiceTipStyle.arrow, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
        }
        .shadow(color: Color.white.opacity(0.9), radius: 2)
        .offset(x: bounce ? 3 : -1, y: bounce ? 4 : -2)
        .opacity(shown ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The big yellow microphone on the tip's card.
private struct VoiceTipMicBadge: View {
    var body: some View {
        Image(systemName: "mic.fill")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(Color.white)
            .frame(width: 58, height: 58)
            .background(Circle().fill(LinearGradient(colors: [Color(hex: 0xFFDA4D), Color(hex: 0xFFA800)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay(Circle().strokeBorder(Color.white, lineWidth: 4))
            .background(Circle().fill(Color(hex: 0xFFE7A0).opacity(0.7)).padding(-7))
            .shadow(color: Color(hex: 0xFFB800).opacity(0.5), radius: 8, x: 0, y: 3)
            .accessibilityHidden(true)
    }
}

/// Colours of the voice tip, sampled from the design.
enum VoiceTipStyle {
    static let title = Color(hex: 0x3E1340)
    static let body = Color(hex: 0x5B4C8A)
    static let gotIt = Color(hex: 0x6A4C9C)
    static let border = Color(hex: 0xF7B5D3)
    static let heart = Color(hex: 0xFF5FA8)
    static let quoteFill = Color(hex: 0xFDE4F0)
    static let voice = LinearGradient(colors: [Color(hex: 0xFF6FB5), Color(hex: 0xF2148E)],
                                      startPoint: .top, endPoint: .bottom)
    static let pinkButton = LinearGradient(colors: [Color(hex: 0xFF6FB0), Color(hex: 0xF2148E)],
                                           startPoint: .top, endPoint: .bottom)
    static let arrow = LinearGradient(colors: [Color(hex: 0xFF7BC0), Color(hex: 0xF2148E)],
                                      startPoint: .top, endPoint: .bottom)
    /// The sparks around the microphone: their angle (0 is straight up) and length.
    static let sparks: [(angle: Double, length: CGFloat)] = [
        (-105, 12), (-70, 14), (20, 14), (45, 16), (70, 13), (100, 12),
    ]
}

/// A soft pink shade over the screen, with a bright gap around what a tip is about.
struct TipShade: View {
    let spot: CGRect
    let cornerRadius: CGFloat
    let shown: Bool
    let onTap: () -> Void

    static let tint = Color(hex: 0xE9A6C6).opacity(0.55)

    var body: some View {
        ZStack {
            Self.tint
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .frame(width: spot.width, height: spot.height)
                .position(x: spot.midX, y: spot.midY)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .opacity(shown ? 1 : 0)
        .accessibilityHidden(true)
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

    /// A soft pink shade over the screen with a gap around the thing.
    private var dimming: some View {
        TipShade(spot: spot, cornerRadius: spotCornerRadius ?? min(spot.width, spot.height) / 2,
                 shown: shown, onTap: onDismiss)
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
