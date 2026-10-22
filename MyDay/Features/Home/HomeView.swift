import SwiftUI
import SwiftData

/// The first screen, as in the design: the girl with her puppy and kitten, "My Day" and the
/// three cards are one picture, with today's date, the counts and today's quote drawn live on
/// it, and buttons over the menu, calendar, bell and cards.
struct HomeView: View {
    @Environment(Router.self) private var router
    @Query private var tasks: [TaskItem]
    @Query private var priorities: [Priority]
    @Query private var entries: [JournalEntry]
    private let today: Date

    init(today: Date) {
        self.today = today
        let start = today.startOfDay
        let end = start.nextDay
        _tasks = Query(filter: #Predicate<TaskItem> { $0.date >= start && $0.date < end })
        _priorities = Query(filter: #Predicate<Priority> { $0.date >= start && $0.date < end })
        _entries = Query(filter: #Predicate<JournalEntry> { $0.date >= start && $0.date < end && $0.deletedAt == nil })
    }

    var body: some View {
        GeometryReader { proxy in
            // The whole screen, under the status bar and the tab bar too, as in the design;
            // a shorter screen scrolls.
            let screen = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
            ScrollView(.vertical, showsIndicators: false) {
                page(width: proxy.size.width)
                    .frame(minHeight: screen, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
            .ignoresSafeArea()
        }
        .background(HomePage.floor.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func page(width w: CGFloat) -> some View {
        let s = w / HomePage.size.width
        let todos = CardBadge.Value.progress(open: tasks.filter { !$0.isCompleted }.count, total: tasks.count)
        let priority = CardBadge.Value.progress(open: priorities.filter { !$0.isCompleted }.count,
                                                total: priorities.count)
        let journal = entries.isEmpty ? CardBadge.Value.hidden : .count(entries.count)
        return Image("HomePage")
            .resizable()
            .frame(width: w, height: HomePage.size.height * s)
            .accessibilityHidden(true)
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    spot(HomePage.menu, s, label: "Menu") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { router.isMenuOpen = true }
                    }
                    spot(HomePage.calendar, s,
                         label: "Calendar, today is \(today.formatted(date: .complete, time: .omitted))") {
                        router.tab = .calendar
                    }
                    HomePageDate(date: today, scale: s)
                        .place(HomePage.calendar, s)
                    spot(HomePage.bell, s, label: "Reminders") { router.sheet = .reminders }
                    HomePageQuote(date: today, scale: s)
                        .place(HomePage.quote, s)

                    card(HomePage.todos, s, kind: .todos, badge: todos) {
                        router.homePath.append(AppRoute.todos(today))
                    }
                    card(HomePage.priority, s, kind: .priority, badge: priority) {
                        router.homePath.append(AppRoute.priority(today))
                    }
                    card(HomePage.journal, s, kind: .journal, badge: journal) {
                        router.homePath.append(AppRoute.journal)
                    }

                    HomePageBadge(value: todos, tint: HomePage.purple, scale: s)
                        .place(HomePage.todosBadge, s)
                    HomePageBadge(value: priority, tint: HomePage.orange, scale: s)
                        .place(HomePage.priorityBadge, s)
                    HomePageBadge(value: journal, tint: HomePage.pink, scale: s)
                        .place(HomePage.journalBadge, s)
                }
            }
    }

    /// A button over one of the picture's round header icons.
    private func spot(_ rect: CGRect, _ s: CGFloat, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Color.clear.contentShape(Rectangle())
        }
        .buttonStyle(HomeSpotStyle(cornerRadius: rect.width * s / 2))
        .accessibilityLabel(label)
        .place(rect, s)
    }

    /// A button over one of the picture's cards.
    private func card(_ rect: CGRect, _ s: CGFloat, kind: HomeFeatureCard.Kind, badge: CardBadge.Value,
                      action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Color.clear.contentShape(Rectangle())
        }
        .buttonStyle(HomeSpotStyle(cornerRadius: 34 * s))
        .accessibilityLabel(kind.title)
        .accessibilityValue(badge.spokenText)
        .accessibilityHint(kind.subtitle)
        .place(rect, s)
    }
}

/// Where everything is on the home design (852 × 1846 pixels).
enum HomePage {
    static let size = CGSize(width: 852, height: 1846)
    static let menu = CGRect(x: 25, y: 95, width: 90, height: 90)
    static let calendar = CGRect(x: 638, y: 96, width: 90, height: 92)
    static let bell = CGRect(x: 738, y: 98, width: 86, height: 86)
    static let quote = CGRect(x: 630, y: 212, width: 210, height: 78)
    static let todos = CGRect(x: 36, y: 612, width: 410, height: 548)
    static let priority = CGRect(x: 454, y: 612, width: 386, height: 548)
    static let journal = CGRect(x: 42, y: 1165, width: 798, height: 452)
    static let todosBadge = CGRect(x: 384, y: 605, width: 64, height: 64)
    static let priorityBadge = CGRect(x: 773, y: 604, width: 64, height: 64)
    static let journalBadge = CGRect(x: 748, y: 1155, width: 62, height: 62)

    static let purple = Color(hex: 0x9B55FC)
    static let orange = Color(hex: 0xFCA319)
    static let pink = Color(hex: 0xFC117E)
    /// The courtyard at the foot of the picture, for a screen taller than it.
    static let floor = Color(hex: 0xECA684)
}

private extension View {
    /// Puts the view on `rect` of the design, drawn `s` points per pixel.
    func place(_ rect: CGRect, _ s: CGFloat) -> some View {
        frame(width: rect.width * s, height: rect.height * s)
            .offset(x: rect.minX * s, y: rect.minY * s)
    }
}

/// A soft white glow where the picture is pressed.
private struct HomeSpotStyle: ButtonStyle {
    let cornerRadius: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.28 : 0))
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Today's weekday and date on the picture's pink calendar.
private struct HomePageDate: View {
    let date: Date
    let scale: CGFloat

    var body: some View {
        VStack(spacing: -3 * scale) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.system(size: 22 * scale, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0xEC1C7C))
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: 37 * scale, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: 0x2E0F3A))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .padding(.top, 22 * scale)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Today's Daily Motivation, written where the design has "Your pace is the right pace".
private struct HomePageQuote: View {
    let date: Date
    let scale: CGFloat

    var body: some View {
        let quote = DailyMotivation.quote(for: date)
        VStack(spacing: -4 * scale) {
            Text(quote.firstLine)
            Text(quote.secondLine)
        }
        .font(.custom("ChalkboardSE-Bold", fixedSize: 23 * scale))
        .foregroundStyle(Color(hex: 0xA40D3D))
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .shadow(color: Color.white.opacity(0.9), radius: 3)
        .rotationEffect(.degrees(-8))
        .id(quote)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.4), value: quote)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today's motivation: \(quote.text)")
    }
}

/// The count on a card's corner, as the design draws it: a coloured ball in a white ring. A
/// check on mint once everything is done, and 0 while the day has nothing yet.
private struct HomePageBadge: View {
    let value: CardBadge.Value
    let tint: Color
    let scale: CGFloat

    var body: some View {
        let fill = value == .done ? Palette.mint : tint
        ZStack {
            Circle().fill(Color.white)
            Circle()
                .fill(fill.gradient)
                .padding(5 * scale)
            switch value {
            case .count(let number):
                Text("\(number)")
                    .font(.system(size: 30 * scale, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 10 * scale)
            case .done:
                Image(systemName: "checkmark")
                    .font(.system(size: 24 * scale, weight: .heavy))
            case .hidden:
                Text("0")
                    .font(.system(size: 30 * scale, weight: .heavy, design: .rounded))
            }
        }
        .foregroundStyle(Color.white)
        .shadow(color: fill.opacity(0.35), radius: 4 * scale, x: 0, y: 2 * scale)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: value)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
