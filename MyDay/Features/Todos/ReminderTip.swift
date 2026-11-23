import SwiftUI

/// Where the Task Details sheet's Reminder row is, so the first-time tip can point at it.
struct ReminderRowAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

/// Shown once on Task Details, as in the design: the sheet takes a soft pink shade, the Reminder
/// row glows white with a pink edge and yellow rays at its top corners, the puppy peeks over a
/// cream cloud that says "🔔 Task Reminders · Don't let an important task slip away 💕 · Add a
/// reminder and My Day will help you remember.", and a pink arrow curls from the cloud up to the
/// row. The row opens the reminder; a tap anywhere else closes the tip.
struct ReminderTip: View {
    /// The Reminder row, in this view's space.
    let rowFrame: CGRect
    let size: CGSize
    let onTry: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var bounce = false

    /// `ReminderTipArt` is the design's puppy, hearts and cloud with the words taken out, on this
    /// grid (the picture is 1120 × 948 pixels); the words are drawn here, where the design has them.
    private static let grid = CGSize(width: 560, height: 474)
    /// On that grid's scale: the design's Reminder row width, how far right of the row's left
    /// edge the picture starts, and how far above the row's bottom edge (the puppy peeks over it).
    private static let designRowWidth: CGFloat = 774
    private static let artLeft: CGFloat = 171
    private static let artAboveRowBottom: CGFloat = 81
    /// Where the arrow leaves (from under) the cloud, and where it meets the row.
    private static let arrowStart = CGPoint(x: 48, y: 204)
    private static let arrowEndX: CGFloat = 174
    /// The largest size: the design's, on a phone as wide as the one it was drawn for.
    private static let maxScale: CGFloat = 0.6
    private static let rowCorner: CGFloat = 20

    /// Points per grid pixel, from the row's width.
    private static func scale(for row: CGRect) -> CGFloat {
        min(maxScale, row.width / designRowWidth)
    }

    /// Whether the cloud fits under the row, in a sheet `height` points tall.
    static func fits(rowFrame row: CGRect, height: CGFloat) -> Bool {
        row.width > 0 && row.minY >= 0
            && row.maxY + (grid.height - artAboveRowBottom) * scale(for: row) + 8 <= height
    }

    private var art: TipArtFrame {
        let scale = Self.scale(for: rowFrame)
        return TipArtFrame(origin: CGPoint(x: rowFrame.minX + Self.artLeft * scale,
                                           y: rowFrame.maxY - Self.artAboveRowBottom * scale),
                           scale: scale)
    }

    /// The bright gap round the row.
    private var spot: CGRect {
        rowFrame.insetBy(dx: -2, dy: -2)
    }

    var body: some View {
        let place = art
        ZStack(alignment: .topLeading) {
            TipShade(spot: spot, cornerRadius: Self.rowCorner + 2, shown: shown, onTap: onDismiss)
            rowGlow(place)
            // The row stays tappable through the gap (the puppy's head over it too).
            RoundedRectangle(cornerRadius: Self.rowCorner + 2, style: .continuous)
                .fill(Color.white.opacity(0.001))
                .frame(width: spot.width, height: spot.height)
                .position(x: spot.midX, y: spot.midY)
                .onTapGesture(perform: onTry)
                .accessibilityHidden(true)
            // The arrow comes out from under the cloud, as in the design.
            arrow(place)
            cloudRays(place)
            cloud(place)
        }
        .frame(width: size.width, height: size.height)
        .onAppear {
            // My Day's discovery sound, as the cloud pops up (not again if the sheet comes back).
            if !shown { SoundEffects.play(.tip) }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { shown = true }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { bounce = true }
            }
            UIAccessibility.post(notification: .screenChanged,
                                 argument: "Tip: task reminders. Add a reminder and My Day will help you remember.")
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onDismiss)
    }

    // MARK: The cloud

    /// The picture with the words: "🔔 Task Reminders", "Don't let an important task / slip
    /// away 💕" and "Add a reminder and My Day / will help you remember."
    private func cloud(_ place: TipArtFrame) -> some View {
        let width = place.length(Self.grid.width)
        let height = place.length(Self.grid.height)
        let headingFont = Font.system(size: place.length(28), weight: .bold, design: .rounded)
        let bodyFont = Font.system(size: place.length(25.5), weight: .medium, design: .rounded)
        return ZStack(alignment: .topLeading) {
            Image("ReminderTipArt")
                .resizable()
                .frame(width: width, height: height)
                .shadow(color: ReminderTipStyle.glow, radius: place.length(14))
            line(Text("🔔"), font: .system(size: place.length(34)),
                 center: CGPoint(x: 113, y: 222.5), width: 60, place: place)
            line(Text("Task Reminders").foregroundStyle(ReminderTipStyle.title),
                 font: .system(size: place.length(36), weight: .bold, design: .rounded),
                 center: CGPoint(x: 299, y: 224), width: 290, place: place)
            line(Text("Don’t let an important task").foregroundStyle(ReminderTipStyle.heading), font: headingFont,
                 center: CGPoint(x: 283, y: 276.5), width: 384, place: place)
            line(Text("slip away 💕").foregroundStyle(ReminderTipStyle.heading), font: headingFont,
                 center: CGPoint(x: 283, y: 313.5), width: 220, place: place)
            line(Text("Add a reminder and My Day").foregroundStyle(ReminderTipStyle.body), font: bodyFont,
                 center: CGPoint(x: 284, y: 356.5), width: 336, place: place)
            line(Text("will help you remember.").foregroundStyle(ReminderTipStyle.body), font: bodyFont,
                 center: CGPoint(x: 283, y: 390.5), width: 300, place: place)
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .scaleEffect(shown ? 1 : 0.85, anchor: .top)
        .opacity(shown ? 1 : 0)
        .contentShape(LowerPart(top: place.length(Self.artAboveRowBottom)))
        .onTapGesture(perform: onDismiss)
        .position(x: place.origin.x + width / 2, y: place.origin.y + height / 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Task Reminders. Don’t let an important task slip away. Add a reminder and My Day will help you remember.")
        .accessibilityAction(named: "Add a reminder", onTry)
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

    /// Three yellow rays at the cloud's top left and three at its top right, as in the design.
    private func cloudRays(_ place: TipArtFrame) -> some View {
        ZStack {
            TipRays(radius: place.length(44) - 6, angles: [-29, -50, -73], animated: bounce)
                .position(place.point(33, 247))
            TipRays(radius: place.length(50) - 6, angles: [27, 50, 71], animated: bounce)
                .position(place.point(488, 211))
        }
        .opacity(shown ? 1 : 0)
    }

    // MARK: The row and the arrow

    /// A white glow and a pink edge round the row, and three yellow rays at each top corner.
    private func rowGlow(_ place: TipArtFrame) -> some View {
        let shape = RoundedRectangle(cornerRadius: Self.rowCorner + 2, style: .continuous)
        let inset = place.length(25.5)
        let drop = place.length(22.5)
        let radius = place.length(46) - 6
        return ZStack {
            shape
                .strokeBorder(Color.white.opacity(0.9), lineWidth: 10)
                .blur(radius: 5)
                .padding(-6)
            shape
                .strokeBorder(Palette.hotPink.opacity(0.6), lineWidth: 2.5)
                .shadow(color: Palette.hotPink.opacity(0.5), radius: 8)
            TipRays(radius: radius, angles: [-18, -44, -70], animated: bounce)
                .position(x: inset, y: drop)
            TipRays(radius: radius, angles: [18, 44, 70], animated: bounce)
                .position(x: spot.width - inset, y: drop)
        }
        .frame(width: spot.width, height: spot.height)
        .position(x: spot.midX, y: spot.midY)
        .opacity(shown ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// From under the cloud's top left, out and up to the row's lower edge.
    private func arrow(_ place: TipArtFrame) -> some View {
        let start = place.point(Self.arrowStart.x, Self.arrowStart.y)
        let end = CGPoint(x: rowFrame.minX + place.length(Self.arrowEndX), y: rowFrame.maxY + 1)
        return TipArrow(start: start,
                        control1: CGPoint(x: start.x - place.length(50), y: start.y - place.length(12)),
                        control2: CGPoint(x: end.x - place.length(18), y: end.y + place.length(59)),
                        end: end, lineWidth: 6)
            .offset(x: bounce ? -1 : 1, y: bounce ? -2 : 1)
            .opacity(shown ? 1 : 0)
    }
}

/// The picture's part below the row: taps on the puppy's head, over the row, reach the row.
private struct LowerPart: Shape {
    let top: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.minY + top, width: rect.width, height: max(0, rect.height - top)))
    }
}

/// Colours of the reminder tip, sampled from the design.
private enum ReminderTipStyle {
    static let title = Color(hex: 0xCE0570)
    static let heading = Color(hex: 0x22125C)
    static let body = Color(hex: 0x33246A)
    static let glow = Color(hex: 0xFFE7A0).opacity(0.7)
}
