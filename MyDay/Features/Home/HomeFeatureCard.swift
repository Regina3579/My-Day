import SwiftUI

/// One of the three big cards on the home screen. The whole card is a button.
struct HomeFeatureCard: View {
    enum Kind {
        case todos, priority, journal

        var title: String {
            switch self {
            case .todos: "Today's To-Dos"
            case .priority: "Today's Priority"
            case .journal: "My Journal"
            }
        }

        var subtitle: String {
            switch self {
            case .todos: "Plan, do, achieve"
            case .priority: "Focus on what matters most"
            case .journal: "Capture your thoughts and beautiful moments"
            }
        }

        var badgeTint: Color {
            switch self {
            case .todos: Palette.grape
            case .priority: Palette.honey
            case .journal: Palette.hotPink
            }
        }

        /// Where the counter bubble sits, relative to the top-trailing corner.
        var badgeOffset: CGSize {
            switch self {
            case .todos: CGSize(width: -2, height: 6)
            case .priority: CGSize(width: -4, height: 0)
            case .journal: CGSize(width: -14, height: -4)
            }
        }
    }

    let kind: Kind
    var badge: CardBadge.Value = .hidden
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            GeometryReader { proxy in
                art(size: proxy.size)
            }
            .overlay(alignment: .topTrailing) {
                CardBadge(value: badge, tint: kind.badgeTint)
                    .offset(kind.badgeOffset)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(CardPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(kind.title)
        .accessibilityValue(badge.spokenText)
        .accessibilityHint(kind.subtitle)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private func art(size: CGSize) -> some View {
        switch kind {
        case .todos: NotebookArt(size: size)
        case .priority: PriorityArt(size: size)
        case .journal: JournalBookArt(size: size)
        }
    }
}

/// Gentle press-down and bounce-back for the big cards.
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .brightness(configuration.isPressed ? 0.03 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

/// Small counter bubble on the corner of a card.
struct CardBadge: View {
    enum Value: Equatable {
        case hidden
        case count(Int)
        case done

        /// Items left, a check when everything is finished, or nothing when empty.
        static func progress(open: Int, total: Int) -> Value {
            if total == 0 { return .hidden }
            return open == 0 ? .done : .count(open)
        }

        var spokenText: String {
            switch self {
            case .hidden: ""
            case .count(let value): "\(value) left"
            case .done: "All done"
            }
        }
    }

    let value: Value
    let tint: Color

    var body: some View {
        ZStack {
            Circle().fill(value == .done ? Palette.mint.gradient : tint.gradient)
            Circle().strokeBorder(Color.white, lineWidth: 2)
            switch value {
            case .count(let number):
                Text("\(number)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 3)
            case .done:
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .heavy))
            case .hidden:
                EmptyView()
            }
        }
        .foregroundStyle(Color.white)
        .frame(width: 26, height: 26)
        .shadow(color: tint.opacity(0.45), radius: 4, x: 0, y: 2)
        .scaleEffect(value == .hidden ? 0.2 : 1)
        .opacity(value == .hidden ? 0 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: value)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
