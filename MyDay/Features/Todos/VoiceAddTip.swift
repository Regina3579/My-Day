import SwiftUI

/// Where the Speak a Task microphone is, so the first-time tip can point at it.
struct VoiceMicAnchorKey: PreferenceKey {
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
