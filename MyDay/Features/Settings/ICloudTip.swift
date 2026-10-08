import SwiftUI

/// Where Settings → iCloud is on screen, for the first-time tip that points at it: the Sync with
/// iCloud row, the sync status row under it (when it shows) and the switch's row content.
struct ICloudTipTarget: Equatable {
    var toggleRow: CGRect = .zero
    var statusRow: CGRect = .zero
    var toggle: CGRect = .zero

    /// The section's card: its rows together.
    var section: CGRect {
        statusRow.isEmpty ? toggleRow : toggleRow.union(statusRow)
    }

    /// The switch, at the trailing end of its row (the system's size for it).
    var switchFrame: CGRect {
        let size: CGSize
        if #available(iOS 26, *) {
            size = CGSize(width: 63, height: 28)
        } else {
            size = CGSize(width: 51, height: 31)
        }
        return CGRect(x: toggle.maxX - size.width, y: toggle.midY - size.height / 2,
                      width: size.width, height: size.height)
    }

    /// The same places, for a view whose top-left corner is at `origin` on screen.
    func moved(from origin: CGPoint) -> ICloudTipTarget {
        func move(_ rect: CGRect) -> CGRect {
            rect.isEmpty ? rect : rect.offsetBy(dx: -origin.x, dy: -origin.y)
        }
        return ICloudTipTarget(toggleRow: move(toggleRow), statusRow: move(statusRow), toggle: move(toggle))
    }
}

/// Shown once, the first time Settings opens, as in the design: the screen takes a soft pink
/// shade, the iCloud card glows white with a pink edge and yellow rays by its switch, a pink
/// cloud card (a little smiling cloud resting on it) says "Your memories are safe ☁️", and a
/// thin white arrow curls from the card down to the switch, with twinkling sparkles round it.
/// The switch turns iCloud Sync on when it is off; a tap anywhere else closes the tip.
struct ICloudTip: View {
    /// Settings → iCloud, in this view's space.
    let target: ICloudTipTarget
    let size: CGSize
    let onTry: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var bounce = false

    /// `ICloudTipArt` is the design's card and little cloud with the words taken out, on this grid
    /// (the picture is 1504 × 1060 pixels); the words are drawn here, where the design has them.
    private static let grid = CGSize(width: 752, height: 530)
    /// On that grid's scale: the design's iCloud card width, how far right of the card's left edge
    /// the picture starts, how far above the card's top it starts, and where its card begins.
    private static let designSectionWidth: CGFloat = 780
    private static let artLeft: CGFloat = 34
    private static let artAboveSection: CGFloat = 547
    private static let cardAboveSection: CGFloat = 539
    /// Where the arrow leaves (from under) the card's bottom edge.
    private static let arrowStart = CGPoint(x: 480, y: 436)
    /// The largest size: the design's, on a phone as wide as the one it was drawn for.
    private static let maxScale: CGFloat = 0.6

    /// The corners of a settings card.
    private static var sectionCorner: CGFloat {
        if #available(iOS 26, *) { 26 } else { 10 }
    }

    /// Points per grid pixel, from the iCloud card's width.
    private static func scale(for section: CGRect) -> CGFloat {
        min(maxScale, section.width / designSectionWidth)
    }

    /// Whether the tip's card fits above the iCloud card, with the iCloud card itself in view.
    static func fits(_ target: ICloudTipTarget, in visible: CGRect) -> Bool {
        let section = target.section
        guard section.width > 0, target.toggle.width > 0, visible.height > 0 else { return false }
        return section.minY - cardAboveSection * scale(for: section) >= visible.minY + 2
            && section.maxY + 4 <= visible.maxY
    }

    private var art: TipArtFrame {
        let section = target.section
        let scale = Self.scale(for: section)
        return TipArtFrame(origin: CGPoint(x: section.minX + Self.artLeft * scale,
                                           y: section.minY - Self.artAboveSection * scale),
                           scale: scale)
    }

    /// The bright gap round the iCloud card.
    private var spot: CGRect {
        target.section.insetBy(dx: -3, dy: -3)
    }

    var body: some View {
        let place = art
        ZStack(alignment: .topLeading) {
            TipShade(spot: spot, cornerRadius: Self.sectionCorner + 3, shown: shown, onTap: onDismiss)
            sectionGlow(place)
            // The switch stays tappable through the gap.
            RoundedRectangle(cornerRadius: Self.sectionCorner + 3, style: .continuous)
                .fill(Color.white.opacity(0.001))
                .frame(width: spot.width, height: spot.height)
                .position(x: spot.midX, y: spot.midY)
                .onTapGesture(perform: onTry)
                .accessibilityHidden(true)
            // The arrow comes out from under the card, as in the design.
            arrow(place)
            sparkles(place)
            card(place)
        }
        .frame(width: size.width, height: size.height)
        .onAppear {
            // My Day's discovery sound, as the card pops up.
            if !shown { SoundEffects.play(.tip) }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { shown = true }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { bounce = true }
            }
            UIAccessibility.post(notification: .screenChanged,
                                 argument: "Tip: your memories are safe. Turn on iCloud Sync to keep them backed up.")
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onDismiss)
    }

    // MARK: The card

    /// The picture with the words: "Your memories are safe ☁️", "Turn on iCloud Sync to keep your
    /// / journal, to-dos, photos, and voice / notes safely backed up." and, in its pink band,
    /// "Even if you change phones, your / precious moments can come back."
    private func card(_ place: TipArtFrame) -> some View {
        let width = place.length(Self.grid.width)
        let height = place.length(Self.grid.height)
        let bodyFont = Font.system(size: place.length(28))
        let bandFont = Font.system(size: place.length(24))
        let sync = Text("iCloud Sync").fontWeight(.semibold).foregroundStyle(ICloudTipStyle.sync)
        return ZStack(alignment: .topLeading) {
            Image("ICloudTipArt")
                .resizable()
                .frame(width: width, height: height)
                .shadow(color: Palette.hotPink.opacity(0.35), radius: place.length(16))
            line(Text("Your memories are safe ☁️").foregroundStyle(ICloudTipStyle.title),
                 font: .system(size: place.length(35), weight: .heavy, design: .rounded),
                 center: CGPoint(x: 388.5, y: 162), width: 520, place: place)
            leading(Text("Turn on \(sync) to keep your"), font: bodyFont, left: 182, y: 210.5, width: 470, place: place)
            leading(Text("journal, to-dos, photos, and voice"), font: bodyFont, left: 182, y: 247.5, width: 470,
                    place: place)
            leading(Text("notes safely backed up."), font: bodyFont, left: 182, y: 284.5, width: 470, place: place)
            leading(Text("Even if you change phones, your").foregroundStyle(ICloudTipStyle.band), font: bandFont,
                    left: 251, y: 351, width: 425, place: place)
            leading(Text("precious moments can come back.").foregroundStyle(ICloudTipStyle.band), font: bandFont,
                    left: 251, y: 383, width: 425, place: place)
        }
        .foregroundStyle(ICloudTipStyle.body)
        .frame(width: width, height: height, alignment: .topLeading)
        .scaleEffect(shown ? 1 : 0.85, anchor: .bottom)
        .opacity(shown ? 1 : 0)
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
        .position(x: place.origin.x + width / 2, y: place.origin.y + height / 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your memories are safe. Turn on iCloud Sync to keep your journal, to-dos, photos, and voice notes safely backed up. Even if you change phones, your precious moments can come back.")
        .accessibilityAction(named: "Close tip", onDismiss)
    }

    /// One centred line of the words, in its place on the card (it shrinks to fit).
    private func line(_ text: Text, font: Font, center: CGPoint, width: CGFloat, place: TipArtFrame) -> some View {
        text
            .font(font)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: place.length(width))
            .position(x: place.length(center.x), y: place.length(center.y))
    }

    /// One line of the words starting at `left`, as in the design.
    private func leading(_ text: Text, font: Font, left: CGFloat, y: CGFloat, width: CGFloat,
                         place: TipArtFrame) -> some View {
        text
            .font(font)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: place.length(width), alignment: .leading)
            .position(x: place.length(left + width / 2), y: place.length(y))
    }

    /// The twinkling sparkles and the little heart round the card, where the design has them.
    private func sparkles(_ place: TipArtFrame) -> some View {
        ZStack {
            ForEach(Array(ICloudTipStyle.sparkles.enumerated()), id: \.offset) { index, sparkle in
                TipSparkle(isGold: sparkle.isGold)
                    .frame(width: place.length(sparkle.size), height: place.length(sparkle.size))
                    .scaleEffect(bounce == index.isMultiple(of: 2) ? 1.12 : 0.86)
                    .position(place.point(sparkle.x, sparkle.y))
            }
            Image(systemName: "heart")
                .font(.system(size: place.length(24), weight: .bold))
                .foregroundStyle(Color(hex: 0xFF8FC0))
                .shadow(color: Palette.hotPink.opacity(0.5), radius: 4)
                .rotationEffect(.degrees(-14))
                .position(place.point(534, 507))
        }
        .opacity(shown ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: The iCloud card and the arrow

    /// A white glow and a pink edge round the iCloud card, and three yellow rays by the switch.
    private func sectionGlow(_ place: TipArtFrame) -> some View {
        let shape = RoundedRectangle(cornerRadius: Self.sectionCorner + 3, style: .continuous)
        let toggle = target.switchFrame
        return ZStack {
            shape
                .strokeBorder(Color.white.opacity(0.9), lineWidth: 12)
                .blur(radius: 6)
                .padding(-7)
            shape
                .strokeBorder(Palette.hotPink.opacity(0.55), lineWidth: 2.5)
                .shadow(color: Palette.hotPink.opacity(0.6), radius: 10)
            TipRays(radius: place.length(52) - 6, angles: [40, 70, 101], animated: bounce)
                .position(x: toggle.maxX - toggle.height / 2 - spot.minX, y: toggle.midY - spot.minY)
        }
        .frame(width: spot.width, height: spot.height)
        .position(x: spot.midX, y: spot.midY)
        .opacity(shown ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// From under the card's bottom edge, out to the right and down to the switch.
    private func arrow(_ place: TipArtFrame) -> some View {
        let start = place.point(Self.arrowStart.x, Self.arrowStart.y)
        let toggle = target.switchFrame
        let end = CGPoint(x: toggle.minX + toggle.width * 0.27, y: target.section.minY - 2)
        return WhiteLineArrow(start: start,
                              control1: CGPoint(x: start.x + place.length(70), y: start.y + place.length(4)),
                              control2: CGPoint(x: end.x - place.length(6), y: end.y - place.length(70)),
                              end: end)
            .offset(y: bounce ? -2 : 1)
            .opacity(shown ? 1 : 0)
    }
}

/// A thin white arrow with a soft pink glow, as in the iCloud tip's design.
private struct WhiteLineArrow: View {
    let start: CGPoint
    let control1: CGPoint
    let control2: CGPoint
    let end: CGPoint

    var body: some View {
        ZStack {
            curve.stroke(Color.white, style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
            head.stroke(Color.white, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
        }
        .shadow(color: Palette.hotPink.opacity(0.8), radius: 3)
        .shadow(color: Palette.hotPink.opacity(0.4), radius: 8)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var curve: Path {
        Path { path in
            path.move(to: start)
            path.addCurve(to: end, control1: control1, control2: control2)
        }
    }

    /// An open arrowhead, along the line's last direction.
    private var head: Path {
        Path { path in
            let angle = atan2(end.y - control2.y, end.x - control2.x)
            for turn in [CGFloat.pi * 0.8, -CGFloat.pi * 0.8] {
                path.move(to: end)
                path.addLine(to: CGPoint(x: end.x + 13 * cos(angle + turn), y: end.y + 13 * sin(angle + turn)))
            }
        }
    }
}

/// A four-pointed sparkle: gold with a white heart, or white with a pink glow.
private struct TipSparkle: View {
    let isGold: Bool

    var body: some View {
        ZStack {
            FourPointStar()
                .fill(isGold ? AnyShapeStyle(ICloudTipStyle.gold) : AnyShapeStyle(Color.white))
                .shadow(color: isGold ? Color(hex: 0xFFD45C).opacity(0.9) : Palette.hotPink.opacity(0.7), radius: 4)
            FourPointStar()
                .fill(Color.white.opacity(isGold ? 0.85 : 1))
                .scaleEffect(0.38)
        }
    }
}

/// A star with four long, curved-in points.
private struct FourPointStar: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let pinch = r * 0.16
        let tips = [CGPoint(x: c.x, y: c.y - r), CGPoint(x: c.x + r, y: c.y),
                    CGPoint(x: c.x, y: c.y + r), CGPoint(x: c.x - r, y: c.y)]
        return Path { path in
            path.move(to: tips[0])
            for index in 0..<4 {
                let next = tips[(index + 1) % 4]
                path.addQuadCurve(to: next, control: CGPoint(x: c.x + (tips[index].x + next.x - 2 * c.x) * 0.5 * pinch / r,
                                                           y: c.y + (tips[index].y + next.y - 2 * c.y) * 0.5 * pinch / r))
            }
            path.closeSubpath()
        }
    }
}

/// Colours and sparkles of the iCloud tip, from the design.
private enum ICloudTipStyle {
    static let title = Color(hex: 0x16084A)
    static let body = Color(hex: 0x59486B)
    static let sync = Color(hex: 0x8D4E89)
    static let band = Color(hex: 0x8A4CAD)
    static let gold = RadialGradient(colors: [Color(hex: 0xFFF6C4), Color(hex: 0xF9C93E)],
                                     center: .center, startRadius: 0, endRadius: 14)
    /// Where each sparkle is on the picture's grid, how big, and whether it is gold or white.
    static let sparkles: [(x: CGFloat, y: CGFloat, size: CGFloat, isGold: Bool)] = [
        (40, 75, 36, true), (14, 103, 10, true), (32, 156, 34, false), (726, 166, 24, true),
        (734, 334, 38, false), (665, 485, 48, true), (696, 515, 12, false),
    ]
}
