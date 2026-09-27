import SwiftUI

/// An invisible button over a painted card. It lights the card up while pressed.
struct ArtHotspot: View {
    let frame: CGRect
    let cornerRadius: CGFloat
    let label: String
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        Button {
            Haptics.tap()
            action()
        } label: {
            shape
                .fill(Color.clear)
                .frame(width: frame.width, height: frame.height)
                .contentShape(shape)
        }
        .buttonStyle(HotspotStyle(cornerRadius: cornerRadius))
        .position(x: frame.midX, y: frame.midY)
        .accessibilityLabel(label)
    }
}

private struct HotspotStyle: ButtonStyle {
    let cornerRadius: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.3 : 0))
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Little counter bubble on the corner of a card.
struct CardBadge: View {
    enum Value: Equatable {
        case hidden
        case count(Int)
        case done

        /// Remaining items, a check when everything is finished, or nothing when empty.
        static func progress(open: Int, total: Int) -> Value {
            if total == 0 { return .hidden }
            return open == 0 ? .done : .count(open)
        }
    }

    let content: Value
    let tint: Color
    let unit: CGFloat

    var body: some View {
        let diameter = max(22, 52 * unit)
        ZStack {
            Circle().fill(content == .done ? Palette.mint.gradient : tint.gradient)
            Circle().strokeBorder(Color.white, lineWidth: max(1.5, 4 * unit))
            switch content {
            case .count(let value):
                Text("\(value)")
                    .font(.system(size: diameter * 0.48, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 3)
            case .done:
                Image(systemName: "checkmark")
                    .font(.system(size: diameter * 0.42, weight: .heavy))
            case .hidden:
                EmptyView()
            }
        }
        .foregroundStyle(Color.white)
        .frame(width: diameter, height: diameter)
        .shadow(color: tint.opacity(0.45), radius: 4, x: 0, y: 2)
        .scaleEffect(content == .hidden ? 0.2 : 1)
        .opacity(content == .hidden ? 0 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: content)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The calendar badge in the top-right corner, always showing today's date.
struct DateBadge: View {
    let date: Date
    let unit: CGFloat

    var body: some View {
        let side = 92 * unit
        VStack(spacing: 0) {
            LinearGradient(colors: [Color(hex: 0xFF7EB6), Palette.hotPink], startPoint: .top, endPoint: .bottom)
                .frame(height: 15 * unit)
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.system(size: 22 * unit, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.hotPink)
                .padding(.top, 2 * unit)
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: 40 * unit, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
                .padding(.top, -4 * unit)
            Spacer(minLength: 0)
        }
        .frame(width: side, height: side)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18 * unit, style: .continuous))
        .overlay(alignment: .top) {
            HStack(spacing: 36 * unit) {
                ForEach(0..<2, id: \.self) { _ in
                    Capsule()
                        .fill(Color(hex: 0xFFD1E4))
                        .overlay(Capsule().strokeBorder(Palette.hotPink.opacity(0.6), lineWidth: max(0.5, 1.5 * unit)))
                        .frame(width: 9 * unit, height: 22 * unit)
                }
            }
            .offset(y: -9 * unit)
        }
        .shadow(color: Palette.hotPink.opacity(0.3), radius: 6 * unit, x: 0, y: 3 * unit)
    }
}

/// One of the white "Add Task / Add Priority / Add Journal" chips.
struct QuickChip: View {
    enum Kind {
        case task, priority, journal

        var title: String {
            switch self {
            case .task: "Add Task"
            case .priority: "Add Priority"
            case .journal: "Add Journal"
            }
        }
    }

    let kind: Kind
    let unit: CGFloat
    var showsTail = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 12 * unit) {
                icon
                    .frame(width: 38 * unit, height: 38 * unit)
                Text(kind.title)
                    .font(.system(size: 23 * unit, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 0)
            }
            .padding(.leading, 14 * unit)
            .padding(.trailing, 8 * unit)
            .frame(width: 164 * unit, height: 60 * unit)
            .background(
                RoundedRectangle(cornerRadius: 27 * unit, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(alignment: .bottom) {
                if showsTail {
                    ChipTail()
                        .fill(Color.white)
                        .frame(width: 22 * unit, height: 14 * unit)
                        .offset(y: 13 * unit)
                }
            }
            .shadow(color: Color.black.opacity(0.12), radius: 5 * unit, x: 0, y: 3 * unit)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(kind.title)
    }

    @ViewBuilder
    private var icon: some View {
        switch kind {
        case .task:
            RoundedRectangle(cornerRadius: 9 * unit, style: .continuous)
                .fill(Palette.mint.gradient)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 20 * unit, weight: .heavy))
                        .foregroundStyle(Color.white)
                )
        case .priority:
            Image(systemName: "star.fill")
                .font(.system(size: 34 * unit))
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFD84A), Palette.honey],
                                                startPoint: .top, endPoint: .bottom))
        case .journal:
            Image(systemName: "book.closed.fill")
                .font(.system(size: 32 * unit))
                .foregroundStyle(Palette.hotPink)
        }
    }
}

private struct ChipTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The glowing pink + button.
struct FloatingAddButton: View {
    let unit: CGFloat
    let action: () -> Void

    var body: some View {
        let diameter = 120 * unit
        Button {
            Haptics.tap()
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color(hex: 0xFF62A5), Palette.hotPink, Color(hex: 0xDD1067)],
                                         center: UnitPoint(x: 0.35, y: 0.3),
                                         startRadius: 0, endRadius: diameter * 0.75))
                Circle()
                    .strokeBorder(Color.white.opacity(0.95), lineWidth: 5 * unit)
                Image(systemName: "plus")
                    .font(.system(size: 54 * unit, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: diameter, height: diameter)
            .shadow(color: Palette.hotPink.opacity(0.6), radius: 14 * unit)
            .contentShape(Circle())
        }
        .buttonStyle(PressScaleStyle(scale: 0.9))
        .accessibilityLabel("Quick add")
    }
}

/// Gently twinkling sparkles and floating hearts over the scene.
struct HomeAmbience: View {
    let space: ArtSpace
    let isActive: Bool

    private struct Spark {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let phase: Double
    }

    private static let sparks: [Spark] = [
        Spark(x: 586, y: 420, size: 26, phase: 0),
        Spark(x: 814, y: 536, size: 20, phase: 1.4),
        Spark(x: 58, y: 640, size: 22, phase: 2.6),
        Spark(x: 652, y: 300, size: 18, phase: 0.8),
        Spark(x: 218, y: 432, size: 22, phase: 2.0)
    ]

    private static let hearts: [Spark] = [
        Spark(x: 668, y: 650, size: 26, phase: 0),
        Spark(x: 96, y: 560, size: 20, phase: 2.5)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !isActive)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            ZStack(alignment: .topLeading) {
                ForEach(Self.sparks.indices, id: \.self) { index in
                    sparkle(Self.sparks[index], time: time)
                }
                ForEach(Self.hearts.indices, id: \.self) { index in
                    heart(Self.hearts[index], time: time)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func sparkle(_ spark: Spark, time: Double) -> some View {
        let wave = CGFloat(0.5 + 0.5 * sin(time * 1.9 + spark.phase))
        let size = space.len(spark.size)
        return Image(systemName: "sparkle")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(Color.white)
            .shadow(color: Color(hex: 0xFFE38A), radius: size * 0.35)
            .scaleEffect(0.35 + 0.65 * wave)
            .opacity(Double(0.15 + 0.8 * wave))
            .position(space.point(spark.x, spark.y))
    }

    private func heart(_ spark: Spark, time: Double) -> some View {
        let cycle = 5.0
        let progress = CGFloat((time + spark.phase).truncatingRemainder(dividingBy: cycle) / cycle)
        let fade: CGFloat = progress < 0.15 ? progress / 0.15 : (1 - progress) / 0.85
        let sway = space.len(12) * CGFloat(sin(Double(progress) * .pi * 3))
        return Image(systemName: "heart.fill")
            .font(.system(size: space.len(spark.size)))
            .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFF9CC8), Palette.hotPink],
                                            startPoint: .top, endPoint: .bottom))
            .scaleEffect(0.5 + 0.5 * progress)
            .opacity(Double(fade) * 0.9)
            .position(x: space.x(spark.x) + sway, y: space.y(spark.y) - space.len(150) * progress)
    }
}
