import SwiftUI

/// Menu button, the "My Day" title, today's date and the reminders bell.
struct HomeHeader: View {
    let date: Date
    let onMenu: () -> Void
    let onCalendar: () -> Void
    let onReminders: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            HeaderButton(label: "Menu", action: onMenu) {
                MenuGlyph()
            }

            Spacer(minLength: 2)
            HomeTitle()
                .padding(.top, 2)
            Spacer(minLength: 2)

            HeaderButton(label: "Calendar, today is \(date.formatted(date: .complete, time: .omitted))",
                         action: onCalendar) {
                DateBadge(date: date)
            }
            HeaderButton(label: "Reminders", action: onReminders) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x2B2838))
                    .shadow(color: Color.white.opacity(0.9), radius: 3)
            }
        }
        .padding(.horizontal, 10)
    }
}

/// A 46-point tap target around a small header icon.
struct HeaderButton<Content: View>: View {
    let label: String
    let action: () -> Void
    let content: Content

    init(label: String, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.label = label
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            content
                .frame(width: 46, height: 46)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(label)
    }
}

/// "My Day" with the "To-Do & Journal" subtitle, glowing softly so it stays readable.
struct HomeTitle: View {
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 44

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 1) {
                Text("My Day")
                    .font(.system(size: min(titleSize, 54), weight: .black, design: .rounded))
                Image(systemName: "heart.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.bubblegum.gradient)
                    .rotationEffect(.degrees(14))
                    .padding(.top, 6)
            }
            .foregroundStyle(Palette.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.6)

            HStack(spacing: 4) {
                Text("To-Do & Journal")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.ink)
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.bubblegum)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Swoosh().frame(width: 128, height: 8)
        }
        .shadow(color: Color.white, radius: 0.5)
        .shadow(color: Color.white.opacity(0.9), radius: 6)
        .background(SoftGlow().padding(-22))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("My Day, To-Do and Journal")
        .accessibilityAddTraits(.isHeader)
    }
}

/// White haze behind text that sits on top of the illustration.
struct SoftGlow: View {
    var body: some View {
        Ellipse()
            .fill(RadialGradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0)],
                                 center: .center, startRadius: 0, endRadius: 110))
            .scaleEffect(x: 1.25, y: 1)
            .blur(radius: 8)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct MenuGlyph: View {
    var body: some View {
        VStack(spacing: 4.5) {
            ForEach(0..<3, id: \.self) { _ in
                Capsule()
                    .fill(Palette.ink)
                    .frame(width: 24, height: 3.6)
            }
        }
        .shadow(color: Color.white.opacity(0.9), radius: 2)
    }
}

/// Little calendar page that always shows today's weekday and date.
struct DateBadge: View {
    let date: Date

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [Color(hex: 0xFF7EB6), Palette.hotPink], startPoint: .top, endPoint: .bottom)
                .frame(height: 8)
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.hotPink)
                .padding(.top, 1)
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.ink)
                .padding(.top, -3)
            Spacer(minLength: 0)
        }
        .frame(width: 40, height: 40)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(alignment: .top) {
            HStack(spacing: 15) {
                ForEach(0..<2, id: \.self) { _ in
                    Capsule()
                        .fill(Color(hex: 0xFFD1E4))
                        .overlay(Capsule().strokeBorder(Palette.hotPink.opacity(0.6), lineWidth: 0.8))
                        .frame(width: 4.5, height: 10)
                }
            }
            .offset(y: -4)
        }
        .shadow(color: Palette.hotPink.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}
