import SwiftUI

/// A tip picture placed on screen: where its top-left corner is, and how many points one pixel
/// of its own grid takes. Words and arrows are placed on the same grid as in the design.
struct TipArtFrame {
    let origin: CGPoint
    let scale: CGFloat

    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
    }

    func length(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

/// A thick pink arrow with a white edge, from a tip to what it points at (a curve from `start`
/// to `end`, shaped by two control points).
struct TipArrow: View {
    let start: CGPoint
    let control1: CGPoint
    let control2: CGPoint
    let end: CGPoint
    var lineWidth: CGFloat = 6

    private static let fill = LinearGradient(colors: [Color(hex: 0xFF7BC0), Color(hex: 0xF2148E)],
                                             startPoint: .top, endPoint: .bottom)

    var body: some View {
        ZStack {
            curve.stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth + 4, lineCap: .round))
            head.stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth + 4, lineCap: .round, lineJoin: .round))
            curve.stroke(Self.fill, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            head.stroke(Self.fill, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
        .shadow(color: Palette.hotPink.opacity(0.3), radius: 3, x: 0, y: 2)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var curve: Path {
        Path { path in
            path.move(to: start)
            path.addCurve(to: end, control1: control1, control2: control2)
        }
    }

    /// The arrowhead, along the line's last direction.
    private var head: Path {
        Path { path in
            let angle = atan2(end.y - control2.y, end.x - control2.x)
            let length = lineWidth * 2.6
            for turn in [CGFloat.pi * 0.78, -CGFloat.pi * 0.78] {
                path.move(to: end)
                path.addLine(to: CGPoint(x: end.x + length * cos(angle + turn), y: end.y + length * sin(angle + turn)))
            }
        }
    }
}

/// Little yellow rays around something a tip points at, as in the designs.
struct TipRays: View {
    /// The distance from the centre to the rays' inner ends.
    let radius: CGFloat
    /// The rays' directions, in degrees (0 is straight up, clockwise).
    let angles: [Double]
    var animated = false

    static let yellow = Color(hex: 0xFDC423)

    var body: some View {
        ZStack {
            ForEach(Array(angles.enumerated()), id: \.offset) { index, angle in
                Capsule()
                    .fill(Self.yellow)
                    .frame(width: 4.5, height: index.isMultiple(of: 2) ? 13 : 10)
                    .offset(y: -(radius + 6))
                    .rotationEffect(.degrees(angle))
            }
        }
        .scaleEffect(animated ? 1.08 : 0.94)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
