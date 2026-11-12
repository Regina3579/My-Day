import SwiftUI

// MARK: - Backgrounds

/// Soft pastel backdrop used behind every section screen.
struct DreamyBackground: View {
    var theme: SectionTheme

    var body: some View {
        ZStack {
            if theme == .garden {
                GeometryReader { proxy in
                    Image("HomeScene")
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .blur(radius: 36, opaque: true)
                        .clipped()
                }
                Color.white.opacity(0.58)
            } else {
                LinearGradient(colors: theme.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle()
                    .fill(theme.glow.opacity(0.35))
                    .frame(width: 340, height: 340)
                    .blur(radius: 70)
                    .offset(x: -150, y: -300)
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 280, height: 280)
                    .blur(radius: 60)
                    .offset(x: 160, y: 60)
                Circle()
                    .fill(Palette.bubblegum.opacity(0.14))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -120, y: 380)
            }
            SparkleField(tint: theme.accent)
        }
        .ignoresSafeArea()
    }
}

/// A few hearts and sparkles scattered over a background.
struct SparkleField: View {
    var tint: Color

    private struct Item {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let isHeart: Bool
    }

    private static let items: [Item] = [
        Item(x: 0.08, y: 0.12, size: 14, isHeart: false),
        Item(x: 0.90, y: 0.08, size: 12, isHeart: true),
        Item(x: 0.82, y: 0.30, size: 10, isHeart: false),
        Item(x: 0.12, y: 0.46, size: 10, isHeart: true),
        Item(x: 0.93, y: 0.58, size: 14, isHeart: false),
        Item(x: 0.06, y: 0.78, size: 12, isHeart: false),
        Item(x: 0.88, y: 0.88, size: 11, isHeart: true)
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(Self.items.indices, id: \.self) { index in
                let item = Self.items[index]
                Image(systemName: item.isHeart ? "heart.fill" : "sparkle")
                    .font(.system(size: item.size, weight: .bold))
                    .foregroundStyle(item.isHeart ? Palette.bubblegum.opacity(0.35) : tint.opacity(0.4))
                    .position(x: proxy.size.width * item.x, y: proxy.size.height * item.y)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Cards

struct CuteCard: ViewModifier {
    var tint: Color
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(0.88))
                    .shadow(color: tint.opacity(0.22), radius: 14, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Color.white, lineWidth: 1.5)
            )
    }
}

extension View {
    /// A List row that shows only its own content: no background, separator or default padding.
    func plainListRow(_ insets: EdgeInsets = EdgeInsets()) -> some View {
        listRowInsets(insets)
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    /// A white, softly glowing rounded card.
    func cuteCard(tint: Color = Palette.bubblegum, padding: CGFloat = 18) -> some View {
        modifier(CuteCard(tint: tint, padding: padding))
    }
}

/// Big rounded title with the pink underline used across the artwork.
struct SectionHeader<Accessory: View>: View {
    let title: String
    let subtitle: String
    let symbol: String
    let theme: SectionTheme
    let accessory: Accessory

    init(title: String, subtitle: String, symbol: String, theme: SectionTheme,
         @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.theme = theme
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: symbol)
                        .font(.rounded(.title2, weight: .bold))
                        .foregroundStyle(theme.accent.gradient)
                    Text(title)
                        .font(.rounded(.title, weight: .heavy))
                        .foregroundStyle(theme.title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Text(subtitle)
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(theme.title.opacity(0.7))
                HeartUnderline(width: 110)
            }
            Spacer(minLength: 0)
            accessory
        }
        .cuteCard(tint: theme.accent)
    }
}

extension SectionHeader where Accessory == EmptyView {
    init(title: String, subtitle: String, symbol: String, theme: SectionTheme) {
        self.init(title: title, subtitle: subtitle, symbol: symbol, theme: theme) { EmptyView() }
    }
}

/// The pink brush-stroke underline with a little heart, as on the home screen.
struct HeartUnderline: View {
    var width: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            Capsule()
                .fill(LinearGradient(colors: [Palette.bubblegum, Palette.hotPink.opacity(0.35)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: width, height: 4)
            Image(systemName: "heart.fill")
                .font(.system(size: 9))
                .foregroundStyle(Palette.bubblegum)
        }
        .accessibilityHidden(true)
    }
}

/// A line, a shiny pink heart and a line: the Priority page's divider, and the partition
/// under a journal page's heading. The lines are `lineLength` long, or share the whole
/// width when it is nil.
struct HeartDivider: View {
    private static let line = Color(hex: 0xF77FCF)

    var lineLength: CGFloat? = 52
    var heartSize: CGFloat = 24

    var body: some View {
        HStack(spacing: 10) {
            stroke(fadingTo: .leading)
            ShinyHeart(size: heartSize)
            stroke(fadingTo: .trailing)
        }
        .accessibilityHidden(true)
    }

    private func stroke(fadingTo edge: UnitPoint) -> some View {
        Capsule()
            .fill(LinearGradient(colors: [Self.line.opacity(0), Self.line],
                                 startPoint: edge, endPoint: edge == .leading ? .trailing : .leading))
            .frame(width: lineLength, height: 2.5)
    }
}

/// Illustrated empty state featuring the girl, the puppy and the kitten.
struct EmptyStateCard: View {
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 12) {
            HeroBanner(height: 140)
            Text(title)
                .font(.rounded(.title3, weight: .bold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.rounded(.subheadline))
                .foregroundStyle(Palette.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cuteCard()
    }
}

struct HeroBanner: View {
    var height: CGFloat
    var cornerRadius: CGFloat = 20

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(
                Image("HeroFriends")
                    .resizable()
                    .scaledToFill()
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - Controls

/// Rounded-square checkbox, like the ones on the To-Dos card.
struct CheckBubble: View {
    var isOn: Bool
    var tint: Color
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(isOn ? tint : Color.white)
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .strokeBorder(tint, lineWidth: 2.5)
            if isOn {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: isOn)
    }
}

struct ProgressRing: View {
    var progress: Double
    var tint: Color
    var lineWidth: CGFloat = 9

    var body: some View {
        let clamped = min(max(progress, 0), 1)
        ZStack {
            Circle()
                .stroke(tint.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AngularGradient(colors: [tint.opacity(0.7), tint, Palette.hotPink], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text(clamped, format: .percent.precision(.fractionLength(0)))
                .font(.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .minimumScaleFactor(0.6)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: clamped)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue(Text(clamped, format: .percent.precision(.fractionLength(0))))
    }
}

struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Big glossy capsule button.
struct PillButtonStyle: ButtonStyle {
    var tint: Color = Palette.hotPink

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(.headline, weight: .bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                Capsule().fill(LinearGradient(colors: [tint.opacity(0.8), tint],
                                              startPoint: .top, endPoint: .bottom))
            )
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.6), lineWidth: 1.5))
            .shadow(color: tint.opacity(0.35), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Section header text for lists.
struct ListHeader: View {
    var title: String
    var count: Int?
    var tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
            if let count {
                Text("\(count)")
                    .font(.rounded(.caption, weight: .heavy))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(tint.opacity(0.15)))
            }
        }
        .font(.rounded(.subheadline, weight: .heavy))
        .foregroundStyle(tint)
        .textCase(nil)
    }
}
