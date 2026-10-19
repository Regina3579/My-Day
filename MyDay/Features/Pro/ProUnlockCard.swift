import SwiftUI

/// The My Day Pro pop-up, as in the design: the screen softens and dims, and a pink card rises
/// with the girl and her puppy among hearts and sparkles, a gold "👑 My Day Pro" badge,
/// "Unlock …" with a line on what it brings (for the feature that was tapped), "Maybe Later" and
/// "👑 Unlock Pro". It comes whenever a free account taps a Pro feature (`.proOffer`).
struct ProUnlockCard: View {
    let feature: ProFeature
    let onUnlock: () -> Void
    let onLater: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var floating = false

    /// The card's grid, in the design's pixels: 702 wide, from the top of the girl's bun (0) to
    /// the card's bottom (764). The card's own top is the wave at about 66; its lower, paler
    /// panel starts at 322.
    private static let grid = CGSize(width: 702, height: 764)
    private static let cardTop: CGFloat = 60
    private static let panelTop: CGFloat = 322
    private static let midX: CGFloat = 351

    var body: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width * 0.86, 360)
            let place = TipArtFrame(origin: .zero, scale: width / Self.grid.width)
            ZStack {
                // The page stays readable, as in the design: only softened (frosted glass, at
                // part strength) and dimmed.
                ZStack {
                    Rectangle().fill(.ultraThinMaterial).opacity(0.4)
                    ProStyle.shade
                }
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { close(then: onLater) }
                .opacity(shown ? 1 : 0)
                .accessibilityHidden(true)
                Group {
                    if feature == .unlimitedWriting {
                        storyCard(width: min(proxy.size.width * 0.9, 390))
                    } else {
                        card(place)
                    }
                }
                    .scaleEffect(shown ? 1 : 0.86)
                    .opacity(shown ? 1 : 0)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
        .onAppear {
            // Over a reminder sound being heard, the card comes quietly.
            if feature != .reminderSounds { SoundEffects.play(.tip) }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) { shown = true }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { floating = true }
            }
            UIAccessibility.post(notification: .screenChanged, argument: "My Day Pro. \(feature.title)")
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { close(then: onLater) }
    }

    /// Fades the card away, then hands over (to close the pop-up, or open the subscriptions).
    private func close(then action: @escaping () -> Void) {
        withAnimation(.easeIn(duration: 0.18)) { shown = false }
        Task {
            try? await Task.sleep(for: .seconds(0.18))
            action()
        }
    }

    // MARK: Your Story Deserves More!

    /// The pop-up when a free page is full (250 words), from its design: the girl and her puppy
    /// over a pink card with "My Day Pro", "Your Story Deserves More! 💖", "Every memory is worth
    /// telling. Unlock unlimited journal writing with My Day Pro! ✨", **Unlock Pro 👑** and
    /// **Maybe Later**. The whole card, words and buttons, is the design's own picture (cut out
    /// and enlarged 4× with Real-ESRGAN), so its lettering is exactly the design's; the two
    /// buttons are tappable where the picture shows them.
    private func storyCard(width: CGFloat) -> some View {
        // On the picture's own grid (719 × 1008 pixels): where the two buttons are.
        let scale = width / 719
        func spot(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat) -> CGRect {
            CGRect(x: x0 * scale, y: y0 * scale, width: (x1 - x0) * scale, height: (y1 - y0) * scale)
        }
        let unlock = spot(76, 780, 644, 887)
        let later = spot(84, 902, 634, 982)
        return Image("ProStoryCardArt")
            .resizable()
            .frame(width: width, height: 1008 * scale)
            .accessibilityElement()
            .accessibilityLabel("My Day Pro. Your Story Deserves More! Every memory is worth telling. Unlock unlimited journal writing with My Day Pro!")
            .overlay(alignment: .topLeading) {
                Button { close(then: onUnlock) } label: { Color.clear }
                    .buttonStyle(StoryButtonStyle())
                    .frame(width: unlock.width, height: unlock.height)
                    .offset(x: unlock.minX, y: unlock.minY)
                    .accessibilityLabel("Unlock Pro")
            }
            .overlay(alignment: .topLeading) {
                Button { close(then: onLater) } label: { Color.clear }
                    .buttonStyle(StoryButtonStyle())
                    .frame(width: later.width, height: later.height)
                    .offset(x: later.minX, y: later.minY)
                    .accessibilityLabel("Maybe Later")
            }
    }

    // MARK: The card

    private func card(_ p: TipArtFrame) -> some View {
        ZStack(alignment: .topLeading) {
            ProCardShape(top: p.length(Self.cardTop), radius: p.length(46))
                .fill(ProStyle.card)
                .overlay(ProCardShape(top: p.length(Self.cardTop), radius: p.length(46))
                    .stroke(Color.white, lineWidth: p.length(4)))
                .shadow(color: ProStyle.glow.opacity(0.45), radius: p.length(28))
                .frame(width: p.length(Self.grid.width), height: p.length(Self.grid.height))
            topDecorations(p)
            Image("ProUnlockArt")
                .resizable()
                .frame(width: p.length(476), height: p.length(338))
                .position(x: p.length(130 + 238), y: p.length(169))
                .accessibilityHidden(true)
            panel(p)
            panelDecorations(p)
            badge(p)
            words(p)
            buttons(p)
            closeButton(p)
        }
        .frame(width: p.length(Self.grid.width), height: p.length(Self.grid.height), alignment: .topLeading)
    }

    /// The paler lower panel that the girl and the puppy lean on.
    private func panel(_ p: TipArtFrame) -> some View {
        RoundedRectangle(cornerRadius: p.length(44), style: .continuous)
            .fill(ProStyle.panel)
            .overlay(RoundedRectangle(cornerRadius: p.length(44), style: .continuous)
                .strokeBorder(Color.white.opacity(0.9), lineWidth: p.length(3)))
            .shadow(color: Color.white.opacity(0.9), radius: p.length(10), y: -p.length(4))
            .frame(width: p.length(687), height: p.length(Self.grid.height - Self.panelTop - 6))
            .position(x: p.length(Self.midX), y: p.length((Self.panelTop + Self.grid.height - 6) / 2))
    }

    /// The hearts and sparkles round the girl and the puppy.
    private func topDecorations(_ p: TipArtFrame) -> some View {
        let lift = floating ? -p.length(5) : 0
        return ZStack(alignment: .topLeading) {
            sparkle(ProStyle.gold, at: CGPoint(x: 110, y: 156), size: 38, scale: floating ? 1.08 : 0.92, p)
            sparkle(Color.white, at: CGPoint(x: 133, y: 124), size: 16, p)
            heart(at: CGPoint(x: 74, y: 206), size: CGSize(width: 38, height: 34), p).offset(y: lift)
            heart(at: CGPoint(x: 112, y: 259), size: CGSize(width: 46, height: 42), p).offset(y: -lift)
            sparkle(Color.white, at: CGPoint(x: 62, y: 294), size: 22, p)
            sparkle(ProStyle.gold, at: CGPoint(x: 424, y: 101), size: 40, scale: floating ? 0.92 : 1.08, p)
            heart(at: CGPoint(x: 482, y: 141), size: CGSize(width: 46, height: 42), p).offset(y: lift)
            sparkle(Color.white, at: CGPoint(x: 580, y: 136), size: 20, p)
            sparkle(ProStyle.gold, at: CGPoint(x: 535, y: 172), size: 22, p)
            heart(at: CGPoint(x: 590, y: 194), size: CGSize(width: 44, height: 40), p).offset(y: -lift)
            sparkle(ProStyle.gold, at: CGPoint(x: 630, y: 259), size: 36, scale: floating ? 1.08 : 0.92, p)
            heart(at: CGPoint(x: 612, y: 300), size: CGSize(width: 26, height: 24), p)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The hearts and sparkles round the words.
    private func panelDecorations(_ p: TipArtFrame) -> some View {
        ZStack(alignment: .topLeading) {
            heart(at: CGPoint(x: 63, y: 392), size: CGSize(width: 40, height: 36), p)
            sparkle(ProStyle.gold, at: CGPoint(x: 165, y: 372), size: 22, p)
            sparkle(ProStyle.gold, at: CGPoint(x: 45, y: 452), size: 22, p)
            heart(at: CGPoint(x: 45, y: 519), size: CGSize(width: 32, height: 29), p)
            heart(at: CGPoint(x: 85, y: 559), size: CGSize(width: 14, height: 13), p)
            outlineHeart(at: CGPoint(x: 62, y: 576), size: 22, p)
            sparkle(ProStyle.gold, at: CGPoint(x: 98, y: 597), size: 20, p)
            sparkle(ProStyle.gold, at: CGPoint(x: 540, y: 374), size: 22, p)
            heart(at: CGPoint(x: 642, y: 394), size: CGSize(width: 40, height: 36), p)
            heart(at: CGPoint(x: 662, y: 421), size: CGSize(width: 14, height: 13), p)
            sparkle(ProStyle.gold, at: CGPoint(x: 618, y: 438), size: 40, scale: floating ? 1.1 : 0.9, p)
            sparkle(ProStyle.gold, at: CGPoint(x: 655, y: 470), size: 18, p)
            outlineHeart(at: CGPoint(x: 650, y: 547), size: 44, p)
            sparkle(ProStyle.gold, at: CGPoint(x: 608, y: 587), size: 22, p)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func heart(at point: CGPoint, size: CGSize, _ p: TipArtFrame) -> some View {
        Image(systemName: "heart.fill")
            .resizable()
            .foregroundStyle(ProStyle.heart)
            .frame(width: p.length(size.width), height: p.length(size.height))
            .shadow(color: Color.white.opacity(0.8), radius: p.length(5))
            .position(x: p.length(point.x), y: p.length(point.y))
    }

    private func outlineHeart(at point: CGPoint, size: CGFloat, _ p: TipArtFrame) -> some View {
        Image(systemName: "heart")
            .resizable()
            .fontWeight(.medium)
            .foregroundStyle(ProStyle.outlineHeart)
            .frame(width: p.length(size), height: p.length(size * 0.9))
            .position(x: p.length(point.x), y: p.length(point.y))
    }

    private func sparkle(_ color: Color, at point: CGPoint, size: CGFloat, scale: CGFloat = 1,
                         _ p: TipArtFrame) -> some View {
        Image(systemName: "sparkle")
            .resizable()
            .foregroundStyle(color)
            .frame(width: p.length(size * 0.8), height: p.length(size))
            .shadow(color: color == Color.white ? ProStyle.glow.opacity(0.4) : Color.white.opacity(0.7),
                    radius: p.length(4))
            .scaleEffect(scale)
            .position(x: p.length(point.x), y: p.length(point.y))
    }

    // MARK: The badge and the words

    /// "👑 My Day Pro" on a gold pill, where the panel begins.
    private func badge(_ p: TipArtFrame) -> some View {
        HStack(spacing: p.length(10)) {
            Text("👑")
                .font(.system(size: p.length(42)))
            Text("My Day Pro")
                .font(.system(size: p.length(30), weight: .heavy, design: .rounded))
                .foregroundStyle(ProStyle.badgeText)
        }
        .frame(width: p.length(273), height: p.length(66))
        .background(Capsule().fill(ProStyle.badge))
        .overlay(Capsule().strokeBorder(ProStyle.badgeEdge, lineWidth: p.length(2.5)))
        .shadow(color: ProStyle.badgeEdge.opacity(0.35), radius: p.length(6), y: p.length(2))
        .position(x: p.length(Self.midX), y: p.length(366))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("My Day Pro")
    }

    private func words(_ p: TipArtFrame) -> some View {
        ZStack(alignment: .topLeading) {
            Text(feature.title)
                .font(.custom("ChalkboardSE-Bold", size: p.length(46)))
                .foregroundStyle(ProStyle.title)
                .shadow(color: Color.white, radius: p.length(2))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: p.length(540))
                .position(x: p.length(Self.midX), y: p.length(446))
                .accessibilityAddTraits(.isHeader)
            Text(feature.message)
                .font(.system(size: p.length(27), weight: .medium, design: .rounded))
                .foregroundStyle(ProStyle.body)
                .multilineTextAlignment(.center)
                .lineSpacing(p.length(10))
                .lineLimit(3)
                .minimumScaleFactor(0.75)
                .frame(width: p.length(540), height: p.length(140))
                .position(x: p.length(Self.midX), y: p.length(538))
        }
    }

    // MARK: The buttons

    private func buttons(_ p: TipArtFrame) -> some View {
        ZStack(alignment: .topLeading) {
            Button {
                close(then: onLater)
            } label: {
                Text("Maybe Later")
                    .font(.system(size: p.length(29), weight: .bold, design: .rounded))
                    .foregroundStyle(ProStyle.later)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: p.length(292), height: p.length(86))
                    .background(Capsule().fill(Color.white))
                    .overlay(Capsule().strokeBorder(ProStyle.laterEdge, lineWidth: p.length(2.5)))
                    .contentShape(Capsule())
            }
            .buttonStyle(PressScaleStyle())
            .position(x: p.length(181), y: p.length(680))
            Button {
                close(then: onUnlock)
            } label: {
                HStack(spacing: p.length(10)) {
                    Text("👑")
                        .font(.system(size: p.length(38)))
                        .accessibilityHidden(true)
                    Text("Unlock Pro")
                        .font(.system(size: p.length(34), weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .foregroundStyle(Color.white)
                .frame(width: p.length(326), height: p.length(90))
                .background(Capsule().fill(ProStyle.unlock))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.55), lineWidth: p.length(2)))
                .shadow(color: ProStyle.glow.opacity(0.5), radius: p.length(10), y: p.length(5))
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "sparkle")
                        .font(.system(size: p.length(16)))
                        .foregroundStyle(Color.white)
                        .padding(.top, p.length(16))
                        .padding(.trailing, p.length(26))
                        .accessibilityHidden(true)
                }
                .overlay(alignment: .bottomLeading) {
                    Image(systemName: "sparkle")
                        .font(.system(size: p.length(14)))
                        .foregroundStyle(Color.white)
                        .padding(.bottom, p.length(14))
                        .padding(.leading, p.length(30))
                        .accessibilityHidden(true)
                }
                .contentShape(Capsule())
            }
            .buttonStyle(PressScaleStyle())
            .position(x: p.length(510), y: p.length(679))
            .accessibilityLabel("Unlock Pro")
            .accessibilityHint("Shows the My Day Pro subscriptions")
        }
    }

    /// ✕ in the card's top corner.
    private func closeButton(_ p: TipArtFrame) -> some View {
        Button {
            close(then: onLater)
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: p.length(68), height: p.length(68))
                    .shadow(color: ProStyle.glow.opacity(0.3), radius: p.length(6))
                Circle()
                    .strokeBorder(ProStyle.closeRing, lineWidth: p.length(2))
                    .frame(width: p.length(68), height: p.length(68))
                Image(systemName: "xmark")
                    .font(.system(size: p.length(26), weight: .semibold))
                    .foregroundStyle(ProStyle.closeMark)
            }
            .frame(width: max(44, p.length(68)), height: max(44, p.length(68)))
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .position(x: p.length(659), y: p.length(126))
        .accessibilityLabel("Close")
    }
}

/// The card's outline: a rounded card whose top edge rises in one soft wave.
private struct ProCardShape: Shape {
    let top: CGFloat
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: 0, y: top + radius + 12))
        path.addQuadCurve(to: CGPoint(x: radius, y: top + 14), control: CGPoint(x: 0, y: top + 14))
        path.addCurve(to: CGPoint(x: w - radius, y: top + 8),
                      control1: CGPoint(x: w * 0.38, y: top + 18), control2: CGPoint(x: w * 0.55, y: top - 10))
        path.addQuadCurve(to: CGPoint(x: w, y: top + radius + 8), control: CGPoint(x: w, y: top + 8))
        path.addLine(to: CGPoint(x: w, y: h - radius))
        path.addQuadCurve(to: CGPoint(x: w - radius, y: h), control: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: radius, y: h))
        path.addQuadCurve(to: CGPoint(x: 0, y: h - radius), control: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

/// Colours of the Pro pop-up, sampled from the design.
enum ProStyle {
    /// The dim over the page: in the design, white turns to about (170, 164, 169).
    static let shade = Color(hex: 0x251622).opacity(0.38)
    static let card = LinearGradient(colors: [Color(hex: 0xFCE2EE), Color(hex: 0xFDEDF5)],
                                     startPoint: .top, endPoint: .bottom)
    static let panel = LinearGradient(colors: [Color(hex: 0xFFF9FB), Color(hex: 0xFEF1F6)],
                                      startPoint: .top, endPoint: .bottom)
    static let glow = Color(hex: 0xF46DB4)
    static let heart = LinearGradient(colors: [Color(hex: 0xFFA3CF), Color(hex: 0xF7559F)],
                                      startPoint: .top, endPoint: .bottom)
    static let outlineHeart = Color(hex: 0xF98CC0)
    static let gold = Color(hex: 0xFCCB45)
    static let badge = LinearGradient(colors: [Color(hex: 0xFFF6CF), Color(hex: 0xFDDF86)],
                                      startPoint: .top, endPoint: .bottom)
    static let badgeEdge = Color(hex: 0xF3C54F)
    static let badgeText = Color(hex: 0x4E2A12)
    static let title = Color(hex: 0x5E0A40)
    static let body = Color(hex: 0x7A5A98)
    static let later = Color(hex: 0x7D5A9C)
    static let laterEdge = Color(hex: 0xF4D0E4)
    static let unlock = LinearGradient(colors: [Color(hex: 0xFF8AC4), Color(hex: 0xF7369A)],
                                       startPoint: .top, endPoint: .bottom)
    static let closeRing = Color(hex: 0xF4C6DE)
    static let closeMark = Color(hex: 0xF0559E)
    /// The small crown on a Pro button.
    static let crown = LinearGradient(colors: [Color(hex: 0xFFD95C), Color(hex: 0xF5A623)],
                                      startPoint: .top, endPoint: .bottom)
}

/// A button drawn in a picture: a soft white flash on it while it is pressed.
private struct StoryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .fill(Color.white.opacity(configuration.isPressed ? 0.28 : 0.001))
            .overlay(configuration.label)
            .contentShape(Capsule())
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
