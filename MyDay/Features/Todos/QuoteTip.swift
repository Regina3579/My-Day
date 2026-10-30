import SwiftUI

/// Shown once, the first time the To-Dos page opens, as in the design: the page takes a soft
/// pink shade, the day's quote at the top glows in a bright frame with hearts, a pink arrow
/// runs between it and a card where the girl and her puppy lie reading, and the card says
/// "A New Quote Every Day!". "Show me" (or the quote itself) closes it and makes the quote
/// glow; ✕, "Got it" or a tap anywhere else closes it.
struct QuoteTip: View {
    /// The quote, in this view's space.
    let quoteFrame: CGRect
    let size: CGSize
    let onShowMe: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var bounce = false

    /// The girl picture: its size.
    private static let girlSize = CGSize(width: 666, height: 351)

    /// Short screens (iPhone SE) get a smaller picture and a shorter arrow, so it all fits.
    private var isShort: Bool { size.height < 740 }

    /// The bright frame around the quote.
    private var spot: CGRect { quoteFrame.insetBy(dx: -8, dy: -7) }

    private var cardWidth: CGFloat { min(330, max(280, size.width * 0.8)) }

    private var cardLeading: CGFloat { size.width - 18 - cardWidth }

    /// Room between the quote and the card, for the arrow.
    private var arrowGap: CGFloat { isShort ? 64 : 92 }

    private var cardTop: CGFloat { spot.maxY + arrowGap }

    private var girlWidth: CGFloat { cardWidth * (isShort ? 0.74 : 0.94) }

    private var girlHeight: CGFloat { girlWidth * Self.girlSize.height / Self.girlSize.width }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TipShade(spot: spot, cornerRadius: 18, shown: shown, onTap: onDismiss)
            quoteGlow
            // The quote stays tappable through the gap.
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.001))
                .frame(width: spot.width, height: spot.height)
                .position(x: spot.midX, y: spot.midY)
                .onTapGesture(perform: onShowMe)
                .accessibilityHidden(true)
            arrow
            card
                .frame(width: cardWidth)
                .scaleEffect(shown ? 1 : 0.88, anchor: .top)
                .opacity(shown ? 1 : 0)
                .padding(.top, cardTop)
                .padding(.leading, cardLeading)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .onAppear {
            // My Day's discovery sound, as the card pops up (not again if the page comes back).
            if !shown { SoundEffects.play(.quoteTip) }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { shown = true }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { bounce = true }
            }
            UIAccessibility.post(notification: .screenChanged,
                                 argument: "Tip: a new motivational quote appears here every day.")
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onDismiss)
    }

    // MARK: The quote

    /// A glowing white frame around the quote, with hearts and sparkles at its corners.
    private var quoteGlow: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white, lineWidth: 3.5)
                .shadow(color: Color(hex: 0xFF8CC6).opacity(0.9), radius: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(Color(hex: 0xFFB3D6).opacity(0.8), lineWidth: 1)
                        .padding(3)
                )
                .frame(width: spot.width, height: spot.height)
                .position(x: spot.midX, y: spot.midY)
            Image(systemName: "heart.fill")
                .font(.system(size: 17))
                .foregroundStyle(QuoteTipStyle.heart)
                .rotationEffect(.degrees(-14))
                .position(x: spot.minX + 4, y: spot.minY - 2)
            Image(systemName: "sparkle")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: 0xE0A0FF))
                .position(x: spot.minX + 26, y: spot.minY - 6)
            Image(systemName: "sparkle")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: 0xFFD23F))
                .position(x: spot.maxX - 26, y: spot.minY - 6)
            Image(systemName: "heart.fill")
                .font(.system(size: 23))
                .foregroundStyle(QuoteTipStyle.heart)
                .rotationEffect(.degrees(12))
                .position(x: spot.maxX - 2, y: spot.minY - 2)
        }
        .scaleEffect(bounce ? 1.01 : 1, anchor: .center)
        .opacity(shown ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: The arrow

    /// A pink arrow with a head at each end, as in the design: one smooth curve from the left
    /// of the quote down to the card, a small head pointing up at the quote and a bigger one
    /// pointing straight down at the card, with a white outline and a soft pink glow. Its
    /// shape scales with its length, so short screens get the same arrow, only shorter.
    private var arrow: some View {
        let start = CGPoint(x: spot.minX + spot.width * 0.22, y: spot.maxY + 5)
        let drop = cardTop - 4 - start.y
        let end = CGPoint(x: start.x + drop * 0.53, y: cardTop - 4)
        let control1 = CGPoint(x: start.x + drop * 0.22, y: start.y + drop * 0.35)
        let control2 = CGPoint(x: end.x + 2, y: end.y - drop * 0.45)
        let upHead = ArrowHead(tip: start, from: control1, length: 14, halfWidth: 7)
        let downHead = ArrowHead(tip: end, from: control2, length: 18, halfWidth: 9)
        // The line runs between the heads' backs, so each head points along it.
        let line = Path { path in
            path.move(to: upHead.back)
            path.addCurve(to: downHead.back, control1: control1, control2: control2)
        }
        let heads = Path { path in
            upHead.add(to: &path)
            downHead.add(to: &path)
        }
        return ZStack {
            line.stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
            heads.fill(Color.white)
            heads.stroke(Color.white, style: StrokeStyle(lineWidth: 3.5, lineJoin: .round))
            line.stroke(QuoteTipStyle.arrow, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
            heads.fill(QuoteTipStyle.arrow)
        }
        .shadow(color: QuoteTipStyle.arrowGlow, radius: 4)
        .overlay {
            Image(systemName: "sparkle")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.white)
                .position(x: end.x - 30, y: end.y - 10)
            Image(systemName: "sparkle")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.white)
                .position(x: end.x + 26, y: end.y - 4)
        }
        .offset(y: bounce ? 3 : -3)
        .opacity(shown ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: The card

    private var card: some View {
        VStack(spacing: 0) {
            illustration
                .zIndex(1)
            VStack(spacing: 10) {
                Text("A New Quote Every Day!")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(QuoteTipStyle.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
                Text("Every day, a new motivational quote will appear here to inspire and brighten your day. ✨💖")
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(QuoteTipStyle.body)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 10)
                HStack(spacing: 10) {
                    Button(action: onDismiss) {
                        Text("Got it")
                            .font(.rounded(.headline, weight: .bold))
                            .foregroundStyle(QuoteTipStyle.gotIt)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Capsule().fill(LinearGradient(colors: [Color.white, Color(hex: 0xFFF3F8)],
                                                                      startPoint: .top, endPoint: .bottom)))
                            .overlay(Capsule().strokeBorder(QuoteTipStyle.border, lineWidth: 1.5))
                            .shadow(color: Palette.hotPink.opacity(0.12), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(PressScaleStyle(scale: 0.96))
                    Button(action: onShowMe) {
                        HStack(spacing: 8) {
                            Image(systemName: "sun.max.fill")
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 20))
                            Text("Show me")
                        }
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Capsule().fill(QuoteTipStyle.pinkButton))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.5), lineWidth: 1.5))
                        .shadow(color: Palette.hotPink.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PressScaleStyle(scale: 0.96))
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)
            .background(bodyBackground)
            .overlay { decorations }
        }
        .overlay(alignment: .topTrailing) {
            closeButton
                .padding(.top, girlHeight * 0.18)
                .offset(x: 10)
        }
    }

    /// The girl and her puppy with their book, on a soft pink cloud, with a sun.
    private var illustration: some View {
        ZStack(alignment: .bottom) {
            cloud
                .frame(width: cardWidth, height: girlHeight * 0.86)
            Image("QuoteTipGirl")
                .resizable()
                .scaledToFit()
                .frame(width: girlWidth, height: girlHeight)
                .overlay(alignment: .topLeading) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: girlWidth * 0.12))
                        .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFD84A), Color(hex: 0xFFA41C)],
                                                        startPoint: .top, endPoint: .bottom))
                        .shadow(color: Color(hex: 0xFFB800).opacity(0.5), radius: 6)
                        .rotationEffect(.degrees(bounce ? 12 : 0))
                        .position(x: girlWidth * 0.845, y: girlHeight * 0.445)
                }
                .accessibilityHidden(true)
        }
        .frame(width: cardWidth, height: girlHeight)
        .padding(.bottom, -6)
    }

    /// Puffs of pale pink cloud behind the picture.
    private var cloud: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let fill = LinearGradient(colors: [Color(hex: 0xFFF6FA), Color(hex: 0xFDE6F0)],
                                      startPoint: .top, endPoint: .bottom)
            ZStack {
                Ellipse().fill(fill).frame(width: w * 0.55, height: h * 0.8).position(x: w * 0.3, y: h * 0.5)
                Ellipse().fill(fill).frame(width: w * 0.5, height: h * 0.9).position(x: w * 0.62, y: h * 0.48)
                Ellipse().fill(fill).frame(width: w * 0.42, height: h * 0.7).position(x: w * 0.82, y: h * 0.6)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(fill)
                    .frame(width: w, height: h * 0.55)
                    .position(x: w / 2, y: h * 0.75)
            }
            .compositingGroup()
            .shadow(color: Color.white, radius: 2)
            .shadow(color: Color(hex: 0xFF8CC6).opacity(0.35), radius: 12)
        }
        .accessibilityHidden(true)
    }

    private var bodyBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0xFFF7FB), Color(hex: 0xFDEAF3)], startPoint: .top, endPoint: .bottom))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Color.white, lineWidth: 3)
            )
            .shadow(color: Color(hex: 0xFF8CC6).opacity(0.45), radius: 16, x: 0, y: 6)
    }

    /// Hearts, sparkles and flowers around the card, as in the design.
    private var decorations: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(QuoteTipStyle.heart)
                    .rotationEffect(.degrees(-14))
                    .position(x: 8, y: h * 0.18)
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFFD23F))
                    .position(x: 10, y: h * 0.4)
                Image(systemName: "heart.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(QuoteTipStyle.heart)
                    .rotationEffect(.degrees(-8))
                    .position(x: 16, y: h * 0.56)
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(QuoteTipStyle.heart)
                    .rotationEffect(.degrees(12))
                    .position(x: w - 8, y: h * 0.14)
                Image(systemName: "sparkle")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFFD23F))
                    .position(x: w - 12, y: h * 0.34)
                Image(systemName: "heart.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(QuoteTipStyle.heart)
                    .rotationEffect(.degrees(10))
                    .position(x: w - 14, y: h * 0.56)
                FlowerCluster()
                    .position(x: 6, y: h - 14)
                FlowerCluster(mirrored: true)
                    .position(x: w - 4, y: h - 18)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(QuoteTipStyle.title)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.white))
                .overlay(Circle().strokeBorder(QuoteTipStyle.border.opacity(0.6), lineWidth: 1))
                .shadow(color: Palette.hotPink.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PressScaleStyle(scale: 0.9))
        .accessibilityLabel("Close")
    }
}

/// A little bunch of daisies and blossoms with leaves, at the card's bottom corners.
private struct FlowerCluster: View {
    var mirrored = false

    var body: some View {
        ZStack {
            Image(systemName: "leaf.fill")
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: 0x6DBE6A))
                .rotationEffect(.degrees(-40))
                .offset(x: -14, y: 6)
            Image(systemName: "leaf.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: 0x58A957))
                .rotationEffect(.degrees(50))
                .offset(x: 14, y: 10)
            Text("🌼")
                .font(.system(size: 26))
                .offset(x: -4, y: -4)
            Text("🌸")
                .font(.system(size: 18))
                .offset(x: 12, y: -16)
            Text("🌼")
                .font(.system(size: 16))
                .offset(x: 10, y: 12)
        }
        .scaleEffect(x: mirrored ? -1 : 1, y: 1)
    }
}

/// Colours of the quote tip, sampled from the design.
enum QuoteTipStyle {
    static let title = Color(hex: 0x6B0F4E)
    static let body = Color(hex: 0x4B3F8A)
    static let gotIt = Color(hex: 0x6A3FA0)
    static let border = Color(hex: 0xF7B5D3)
    static let heart = Color(hex: 0xFF5FA8)
    static let pinkButton = LinearGradient(colors: [Color(hex: 0xFF6FB0), Color(hex: 0xF2148E)],
                                           startPoint: .top, endPoint: .bottom)
    static let arrow = LinearGradient(colors: [Color(hex: 0xFF7BC0), Color(hex: 0xF2148E)],
                                      startPoint: .top, endPoint: .bottom)
    static let arrowGlow = Color(hex: 0xF2148E).opacity(0.45)
}

/// A filled arrowhead at the end of a curve: its point at `tip`, facing away from the
/// curve's nearby control point `from`, so it follows the line.
private struct ArrowHead {
    let tip: CGPoint
    /// Where the line meets the head (a little inside it, so no gap shows).
    let back: CGPoint
    private let corners: (CGPoint, CGPoint)

    init(tip: CGPoint, from control: CGPoint, length: CGFloat, halfWidth: CGFloat) {
        let dx = tip.x - control.x
        let dy = tip.y - control.y
        let size = max(hypot(dx, dy), 0.001)
        let along = CGPoint(x: dx / size, y: dy / size)
        let base = CGPoint(x: tip.x - along.x * length, y: tip.y - along.y * length)
        let across = CGPoint(x: -along.y * halfWidth, y: along.x * halfWidth)
        self.tip = tip
        back = CGPoint(x: tip.x - along.x * length * 0.75, y: tip.y - along.y * length * 0.75)
        corners = (CGPoint(x: base.x + across.x, y: base.y + across.y),
                   CGPoint(x: base.x - across.x, y: base.y - across.y))
    }

    func add(to path: inout Path) {
        path.move(to: tip)
        path.addLine(to: corners.0)
        path.addLine(to: corners.1)
        path.closeSubpath()
    }
}
