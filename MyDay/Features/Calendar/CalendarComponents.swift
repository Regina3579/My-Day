import SwiftUI

// MARK: - Colours

/// Colours sampled from the Calendar design.
enum CalendarPalette {
    static let title = Color(hex: 0x9E0F55)        // "Calendar"
    static let subtitle = Color(hex: 0x5E4B8F)     // "Every day is a new page", row notes
    static let pink = Color(hex: 0xF81C7A)         // buttons, today, selected day
    static let heart = Color(hex: 0xFA3895)
    static let purple = Color(hex: 0x7D3BFC)       // To-Dos
    static let weekday = Color(hex: 0x645497)
    static let weekdayFill = Color(hex: 0xFCEAF5)
    static let otherMonth = Color(hex: 0xC5BECF)
    static let card = Color(hex: 0xFBF7FA)
    static let separator = Color(hex: 0xF7E0EE)
    static let doneDot = Color(hex: 0x02B634)
    static let star = Color(hex: 0xFEA200)
}

/// Soft lavender to blush behind the Calendar screen.
struct CalendarBackdrop: View {
    var body: some View {
        LinearGradient(colors: [Color(hex: 0xF1DDF3), Color(hex: 0xFBE8F0), Color(hex: 0xFDDDE8)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}

// MARK: - Header

/// The picture behind the header: the page's top edge, the pink card, the girl, the puppy,
/// the kitten and the flowers (the design's title, icon and Today button were painted out).
/// Its first 100 rows are plain background for the status bar.
enum CalendarHeaderArt {
    static let imageSize = CGSize(width: 853, height: 452)
    /// Rows (px) in the picture: the card's top edge, and where the month card starts.
    static let cardTop: CGFloat = 188
    static let monthCardTop: CGFloat = 447
    /// The design's rows are the picture's rows less the 100 added on top.
    static let designOffset: CGFloat = 100

    /// Points per image pixel: the picture spans the screen's width.
    static func scale(width: CGFloat) -> CGFloat {
        width / imageSize.width
    }

    /// The first row shown: the card starts just below the status bar.
    static func topRow(width: CGFloat, statusBar: CGFloat) -> CGFloat {
        max(0, cardTop - (statusBar + 12) / scale(width: width))
    }

    /// From the top of the screen to the month card.
    static func height(width: CGFloat, statusBar: CGFloat) -> CGFloat {
        (monthCardTop - topRow(width: width, statusBar: statusBar)) * scale(width: width)
    }
}

/// "📅 Calendar — Every day is a new page" with the girl and her pets, and the Today button.
struct CalendarHeader: View {
    let width: CGFloat
    /// Height of the status bar.
    let statusBar: CGFloat
    let onToday: () -> Void

    private var scale: CGFloat { CalendarHeaderArt.scale(width: width) }
    private var topRow: CGFloat { CalendarHeaderArt.topRow(width: width, statusBar: statusBar) }

    /// A point in the design (px) on this screen.
    private func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x * scale, y: (y + CalendarHeaderArt.designOffset - topRow) * scale)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("CalendarHeader")
                .resizable()
                .frame(width: width, height: CalendarHeaderArt.imageSize.height * scale)
                .offset(y: -topRow * scale)
                .accessibilityHidden(true)

            Image("CalendarIcon")
                .resizable()
                .frame(width: 78 * scale, height: 84 * scale)
                .position(point(95, 168))
                .accessibilityHidden(true)

            Text("Calendar")
                .font(.system(size: 60 * scale, weight: .heavy, design: .rounded))
                .foregroundStyle(CalendarPalette.title)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 244 * scale, alignment: .leading)
                .position(point(272, 168))
                .accessibilityAddTraits(.isHeader)

            Text("Every day is a new page")
                .font(.system(size: 29 * scale, weight: .medium, design: .rounded))
                .foregroundStyle(CalendarPalette.subtitle)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 340 * scale, alignment: .leading)
                .position(point(232, 228))

            underline
                .position(point(232, 268))

            todayButton
                .position(point(749, 158))
        }
        .frame(width: width, height: CalendarHeaderArt.height(width: width, statusBar: statusBar),
               alignment: .topLeading)
    }

    /// A pink line, a heart and a pink line.
    private var underline: some View {
        HStack(spacing: 7 * scale) {
            Capsule().frame(width: 106 * scale, height: 4 * scale)
            Image(systemName: "heart.fill")
                .font(.system(size: 20 * scale))
            Capsule().frame(width: 96 * scale, height: 4 * scale)
        }
        .foregroundStyle(CalendarPalette.pink)
        .accessibilityHidden(true)
    }

    private var todayButton: some View {
        Button(action: onToday) {
            Text("Today")
                .font(.system(size: 31 * scale, weight: .heavy, design: .rounded))
                .foregroundStyle(CalendarPalette.pink)
                .frame(width: 138 * scale, height: 76 * scale)
                .background(Capsule().fill(Color.white))
                .shadow(color: CalendarPalette.pink.opacity(0.18), radius: 6, x: 0, y: 3)
                .frame(minHeight: 44)
                .contentShape(Capsule())
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityHint("Shows today")
    }
}

// MARK: - Month

struct DayMarker {
    var tasks = 0
    var done = 0
    var priorities = 0
    var journal = 0
}

/// The month card: ‹ ♥ September 2026 ♥ ›, the weekday pills and the days, with flowers
/// in the bottom corners. Days of the months around it are shown in grey.
struct MonthCard: View {
    @Binding var month: Date
    @Binding var selected: Date
    let today: Date
    let markers: [Date: DayMarker]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// Whole weeks: the month's days with the last days of the month before and the first
    /// days of the month after.
    private var days: [Date] {
        let calendar = Calendar.current
        let start = month.startOfMonth
        guard let range = calendar.range(of: .day, in: .month, for: start) else { return [] }
        let leading = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        let weeks = (leading + range.count + 6) / 7
        let first = start.adding(days: -leading)
        return (0..<(weeks * 7)).map { first.adding(days: $0) }
    }

    var body: some View {
        VStack(spacing: 10) {
            header
            weekdayRow
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(days, id: \.self) { day in
                    let inMonth = Calendar.current.isDate(day, equalTo: month, toGranularity: .month)
                    Button {
                        select(day, inMonth: inMonth)
                    } label: {
                        DayCell(date: day,
                                isInMonth: inMonth,
                                isSelected: day.isSameDay(as: selected),
                                isToday: day.isSameDay(as: today),
                                marker: inMonth ? markers[day.startOfDay] : nil)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(CalendarPalette.card)
                HStack(alignment: .bottom) {
                    Image("CalendarFlowersLeft")
                        .resizable()
                        .frame(width: 27, height: 73)
                    Spacer()
                    Image("CalendarFlowersRight")
                        .resizable()
                        .frame(width: 33, height: 55)
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 2)
                .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white, lineWidth: 1.5)
            )
            .shadow(color: CalendarPalette.pink.opacity(0.1), radius: 12, x: 0, y: 5)
        }
        .gesture(
            DragGesture(minimumDistance: 30).onEnded { value in
                if value.translation.width < -50 { shift(1) }
                if value.translation.width > 50 { shift(-1) }
            }
        )
    }

    private var header: some View {
        HStack(spacing: 4) {
            chevron("chevron.left", label: "Previous month") { shift(-1) }
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                heart
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(.rounded(.title3, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .contentTransition(.numericText())
                heart
            }
            Spacer(minLength: 0)
            chevron("chevron.right", label: "Next month") { shift(1) }
        }
    }

    private var heart: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 12))
            .foregroundStyle(CalendarPalette.heart)
            .accessibilityHidden(true)
    }

    private func chevron(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Color.white)
                .frame(width: 30, height: 30)
                .background(
                    Circle().fill(LinearGradient(colors: [Color(hex: 0xFF4F9C), CalendarPalette.pink],
                                                 startPoint: .top, endPoint: .bottom))
                )
                .shadow(color: CalendarPalette.pink.opacity(0.3), radius: 4, x: 0, y: 2)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(label)
    }

    private var weekdayRow: some View {
        HStack(spacing: 3) {
            ForEach(weekdaySymbols.indices, id: \.self) { index in
                Text(weekdaySymbols[index])
                    .font(.rounded(.footnote, weight: .semibold))
                    .foregroundStyle(CalendarPalette.weekday)
                    .frame(maxWidth: .infinity, minHeight: 26)
                    .background(RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(CalendarPalette.weekdayFill))
            }
        }
        .accessibilityHidden(true)
    }

    private func select(_ day: Date, inMonth: Bool) {
        withAnimation(.snappy) {
            selected = day
            if !inMonth { month = day.startOfMonth }
        }
        Haptics.tap()
    }

    private func shift(_ months: Int) {
        withAnimation(.snappy) { month = month.adding(months: months).startOfMonth }
        Haptics.tap()
    }
}

/// One day: a pink ring for today, a pink circle when selected, and little markers below
/// (a dot for to-dos, green when all are done; a star for priorities; a heart for a journal page).
struct DayCell: View {
    let date: Date
    let isInMonth: Bool
    let isSelected: Bool
    let isToday: Bool
    let marker: DayMarker?

    private var numberColor: Color {
        if isSelected { return Color.white }
        if isToday { return CalendarPalette.pink }
        return isInMonth ? Palette.ink : CalendarPalette.otherMonth
    }

    var body: some View {
        VStack(spacing: 1) {
            Text(date.formatted(.dateTime.day()))
                .font(.rounded(.callout, weight: isSelected || isToday ? .heavy : .semibold))
                .foregroundStyle(numberColor)
                .frame(width: 36, height: 36)
                .background {
                    if isSelected {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: 0xFF4F9C), CalendarPalette.pink],
                                                 startPoint: .top, endPoint: .bottom))
                            .shadow(color: CalendarPalette.pink.opacity(0.35), radius: 5, x: 0, y: 3)
                    } else if isToday {
                        Circle().strokeBorder(CalendarPalette.pink, lineWidth: 2)
                    }
                }
            markerRow
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? AccessibilityTraits.isSelected : [])
    }

    private var markerRow: some View {
        HStack(spacing: 3) {
            if let marker {
                if marker.tasks > 0 {
                    Circle()
                        .fill(marker.done == marker.tasks ? CalendarPalette.doneDot : Palette.grape)
                        .frame(width: 5, height: 5)
                }
                if marker.priorities > 0 {
                    Image(systemName: "star.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(CalendarPalette.star)
                }
                if marker.journal > 0 {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(CalendarPalette.pink)
                }
            }
        }
        .frame(height: 7)
    }

    private var accessibilityText: String {
        var parts = [date.formatted(date: .complete, time: .omitted)]
        if let marker {
            if marker.tasks > 0 { parts.append("\(marker.done) of \(marker.tasks) to-dos done") }
            if marker.priorities > 0 { parts.append("\(marker.priorities) priorities") }
            if marker.journal > 0 { parts.append("\(marker.journal) journal pages") }
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Agenda

/// The look of one agenda row: Priorities, To-Dos or Journal.
struct AgendaStyle {
    let title: String
    let symbol: String
    let symbolFill: [Color]
    let tint: Color
    /// The round ＋.
    let buttonFill: [Color]
    let fill: [Color]
    let art: String
    let showsHeart: Bool

    private static let pinkButton = [Color(hex: 0xFF4F9C), CalendarPalette.pink]
    private static let purpleButton = [Color(hex: 0x9A63FF), CalendarPalette.purple]

    static let priorities = AgendaStyle(
        title: "Priorities", symbol: "star.fill",
        symbolFill: [Color(hex: 0xFFC83D), Color(hex: 0xFE9705)],
        tint: CalendarPalette.pink, buttonFill: pinkButton,
        fill: [Color(hex: 0xFDE3F1), Color(hex: 0xFDEBF4)],
        art: "CalendarStar", showsHeart: true
    )
    static let todos = AgendaStyle(
        title: "To-Dos", symbol: "list.bullet",
        symbolFill: purpleButton,
        tint: CalendarPalette.purple, buttonFill: purpleButton,
        fill: [Color(hex: 0xECDEFC), Color(hex: 0xF0E6FD)],
        art: "CalendarClipboard", showsHeart: true
    )
    static let journal = AgendaStyle(
        title: "Journal", symbol: "book.fill",
        symbolFill: [Color(hex: 0xFF4F9C), Color(hex: 0xF9046B)],
        tint: CalendarPalette.pink, buttonFill: pinkButton,
        fill: [Color(hex: 0xFCDEE4), Color(hex: 0xFDE8EC)],
        art: "CalendarJournal", showsHeart: false
    )
}

/// A tinted row: a round icon, the title with a note, a little picture and a round ＋.
/// The day's items, if any, are listed underneath.
struct AgendaRow<Content: View>: View {
    let style: AgendaStyle
    let note: String
    let addLabel: String
    let onAdd: () -> Void
    let content: Content

    init(style: AgendaStyle, note: String, addLabel: String, onAdd: @escaping () -> Void,
         @ViewBuilder content: () -> Content) {
        self.style = style
        self.note = note
        self.addLabel = addLabel
        self.onAdd = onAdd
        self.content = content()
    }

    private static var headerHeight: CGFloat { 66 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                iconBubble
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(style.title)
                            .font(.rounded(.headline, weight: .heavy))
                            .foregroundStyle(style.tint)
                        if style.showsHeart {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(CalendarPalette.heart)
                                .accessibilityHidden(true)
                        }
                    }
                    Text(note)
                        .font(.rounded(.footnote, weight: .medium))
                        .foregroundStyle(CalendarPalette.subtitle)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                .accessibilityElement(children: .combine)
                Spacer(minLength: 0)
                // Room for the picture, which sits behind this row (its left edge is soft,
                // so the note may run under it a little).
                Color.clear.frame(width: 54, height: 1)
                plusButton
            }
            .frame(minHeight: Self.headerHeight)
            content
                .padding(.leading, 50)
                .padding(.trailing, 6)
        }
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .padding(.bottom, 4)
        .background(alignment: .topTrailing) {
            Image(style.art)
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: Self.headerHeight - 4, alignment: .bottom)
                .padding(.top, 4)
                .padding(.trailing, 44)
                .accessibilityHidden(true)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: style.fill, startPoint: .leading, endPoint: .trailing))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var iconBubble: some View {
        Image(systemName: style.symbol)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(LinearGradient(colors: style.symbolFill, startPoint: .top, endPoint: .bottom))
            .frame(width: 40, height: 40)
            .background(Circle().fill(Color.white))
            .shadow(color: style.tint.opacity(0.15), radius: 4, x: 0, y: 2)
            .accessibilityHidden(true)
    }

    private var plusButton: some View {
        Button(action: onAdd) {
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 34, height: 34)
                .background(Circle().fill(LinearGradient(colors: style.buttonFill,
                                                         startPoint: .top, endPoint: .bottom)))
                .shadow(color: style.tint.opacity(0.35), radius: 5, x: 0, y: 3)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(addLabel)
    }
}

/// A compact line with a checkbox, used in the calendar agenda.
struct CompactCheckRow: View {
    let title: String
    let isDone: Bool
    let tint: Color
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                CheckBubble(isOn: isDone, tint: tint, size: 22)
                Text(title)
                    .font(.rounded(.subheadline, weight: .semibold))
                    .strikethrough(isDone, color: tint)
                    .foregroundStyle(isDone ? Color.secondary : Palette.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isDone ? "\(title), done" : title)
        .accessibilityHint(isDone ? "Mark as not done" : "Mark as done")
    }
}
