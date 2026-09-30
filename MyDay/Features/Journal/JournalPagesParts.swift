import SwiftUI
import SwiftData

/// Colours of My Journal Pages, sampled from the design and made a little more vivid.
enum JournalPagesStyle {
    static let title = Color(hex: 0xC2127A)          // "My Pages"
    static let heading = Color(hex: 0x1C1A5E)        // a page's heading
    static let preview = Color(hex: 0x5E4A8C)        // a page's first lines
    static let time = Color(hex: 0x6F6790)
    static let weekday = Color(hex: 0xD61F7E)        // "Tue" on the date
    static let heartPink = Color(hex: 0xFF4FA3)
    static let calendarFill = Color(hex: 0xF6ECFF)
    static let cardFill = LinearGradient(colors: [Color.white.opacity(0.95), Color(hex: 0xFFF6FA)],
                                         startPoint: .top, endPoint: .bottom)
    static let writeButton = LinearGradient(colors: [Color(hex: 0xFF7DBE), Color(hex: 0xF5238F)],
                                            startPoint: .top, endPoint: .bottom)
}

extension View {
    /// A soft white card of My Journal Pages.
    func journalPagesCard(padding: CGFloat = 14, radius: CGFloat = 26) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(JournalPagesStyle.cardFill))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Color.white, lineWidth: 1.5))
            .shadow(color: JournalStyle.pink.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Write a new page

/// The star waving beside the big pink "✏️ Write a new page ›". A journal is one page a day,
/// so once today has a page it reads "Continue writing" and opens that page.
struct WriteNewPageRow: View {
    /// Today's page, when it has been written.
    let todayPage: JournalEntry?

    var body: some View {
        HStack(spacing: 4) {
            Image("JournalWriteStar")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 72)
                .accessibilityHidden(true)
            NavigationLink(value: todayPage.map { AppRoute.editJournalPage($0) } ?? AppRoute.newJournalPage(nil)) {
                HStack(spacing: 10) {
                    Image(systemName: "pencil.line")
                        .font(.system(size: 22, weight: .bold))
                    Text(title)
                        .font(.rounded(.title3, weight: .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(JournalStyle.pink)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.white))
                }
                .foregroundStyle(Color.white)
                .padding(.leading, 20)
                .padding(.trailing, 12)
                .frame(maxWidth: .infinity, minHeight: 66)
                .background(Capsule().fill(JournalPagesStyle.writeButton))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.6), lineWidth: 1.5))
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .padding(.top, 9)
                        .padding(.trailing, 58)
                        .accessibilityHidden(true)
                }
                .shadow(color: JournalStyle.pink.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(PressScaleStyle(scale: 0.97))
            .accessibilityLabel(todayPage == nil ? title : "Continue writing today's page")
        }
    }

    /// Both fit the button: "Continue today's page" did not.
    private var title: String {
        todayPage == nil ? "Write a new page" : "Continue writing"
    }
}

// MARK: - My week in moods

/// The last seven days, each with the star of its latest page (tap one to open that page).
struct MoodWeekCard: View {
    let entries: [JournalEntry]
    let today: Date
    let onCalendar: () -> Void

    var body: some View {
        let days = (0..<7).reversed().map { today.adding(days: -$0) }
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text("My week in moods")
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(JournalStyle.plum)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(JournalPagesStyle.heartPink)
                        .accessibilityHidden(true)
                }
                .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 4)
                Button(action: onCalendar) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(JournalStyle.pink)
                        ViewThatFits(in: .horizontal) {
                            Text("View Calendar")
                            Text("Calendar")
                        }
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(JournalStyle.plum)
                        .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(JournalStyle.purple)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 38)
                    .background(Capsule().fill(JournalPagesStyle.calendarFill))
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityLabel("View Calendar")
            }
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    dayColumn(day)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .journalPagesCard()
    }

    @ViewBuilder
    private func dayColumn(_ day: Date) -> some View {
        if let page = entries.first(where: { $0.date.isSameDay(as: day) }) {
            NavigationLink(value: page) {
                dayLabel(day, mood: page.mood)
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide))): \(page.mood.label)")
        } else {
            dayLabel(day, mood: nil)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide))): no page")
        }
    }

    private func dayLabel(_ day: Date, mood: Mood?) -> some View {
        VStack(spacing: 5) {
            Group {
                if let mood {
                    Image(mood.artName)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "star.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(JournalStyle.pink.opacity(0.14))
                }
            }
            .frame(width: 46, height: 42)
            Text(day.formatted(.dateTime.weekday(.abbreviated)))
                .font(.rounded(.subheadline, weight: .bold))
                .foregroundStyle(day.isToday ? Color.white : JournalStyle.plum)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background {
                    if day.isToday {
                        Capsule().fill(JournalStyle.pinkGradient)
                    }
                }
        }
    }
}

// MARK: - Tabs

/// One row of tabs, left to right: All Pages, Favorites, My Feelings, Photos, Voice Notes and
/// ＋ More, which lists the rest (Little Wins, Templates, My Growth, Dreams and Trash). While
/// one of those is open, the ＋ tile shows it, with a small ＋ still on its icon.
struct JournalTabsRow: View {
    @Binding var selection: JournalShelf

    var body: some View {
        // Six equal columns.
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 6), spacing: 0) {
            ForEach(JournalShelf.shown) { shelf in
                let isOn = shelf == selection
                Button {
                    select(shelf)
                } label: {
                    JournalTabTile(symbol: shelf.symbol, label: shelf.label, color: shelf.color, isOn: isOn)
                }
                .buttonStyle(PressScaleStyle(scale: 0.95))
                .accessibilityLabel(shelf.label)
                .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
            }
            moreMenu
        }
    }

    private var moreMenu: some View {
        let open = JournalShelf.more.contains(selection) ? selection : nil
        return Menu {
            ForEach(JournalShelf.more) { shelf in
                Button {
                    select(shelf)
                } label: {
                    Label(shelf.label, systemImage: shelf.symbol)
                }
            }
        } label: {
            JournalTabTile(symbol: open?.symbol ?? "plus", label: open?.label ?? "More",
                           color: open?.color ?? JournalStyle.pink, isOn: open != nil, showsPlus: open != nil)
        }
        .menuOrder(.fixed)
        .accessibilityLabel(open.map { "\($0.label). More tabs" } ?? "More tabs")
        .accessibilityHint("Little Wins, Templates, My Growth, Dreams and Trash")
        .accessibilityAddTraits(open != nil ? AccessibilityTraits.isSelected : [])
    }

    private func select(_ shelf: JournalShelf) {
        withAnimation(.snappy) { selection = shelf }
        Haptics.tap()
    }
}

/// A tab: a round icon over its name on one line, pink when it is the open tab.
private struct JournalTabTile: View {
    let symbol: String
    let label: String
    let color: Color
    let isOn: Bool
    /// A small ＋ on the icon, on the ＋ More tile while it shows one of the tabs behind it.
    var showsPlus = false

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color.gradient)
                .frame(width: 30, height: 30)
                .background(Circle().fill(isOn ? Color.white : color.opacity(0.13)))
                .overlay(alignment: .topTrailing) {
                    if showsPlus {
                        Image(systemName: "plus")
                            .font(.system(size: 7, weight: .black))
                            .foregroundStyle(Color.white)
                            .frame(width: 13, height: 13)
                            .background(Circle().fill(JournalStyle.pink))
                            .overlay(Circle().strokeBorder(Color.white, lineWidth: 1.5))
                            .offset(x: 4, y: -3)
                    }
                }
            // Small enough for six across; it shrinks a touch only on the narrowest iPhones.
            Text(label)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundStyle(isOn ? Color.white : JournalPagesStyle.heading)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 7)
        .padding(.bottom, 6)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(isOn ? AnyShapeStyle(JournalPagesStyle.writeButton) : AnyShapeStyle(Color.white.opacity(0.9)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(Color.white, lineWidth: isOn ? 2 : 1.5)
        )
        .shadow(color: JournalStyle.pink.opacity(isOn ? 0.3 : 0.08), radius: isOn ? 6 : 4, x: 0, y: isOn ? 3 : 2)
        .contentShape(Rectangle())
    }
}

/// "📅 This Month ⌄": which dates the list shows.
struct JournalPeriodMenu: View {
    @Binding var period: JournalPeriod

    var body: some View {
        Menu {
            Picker("Show pages from", selection: $period) {
                ForEach(JournalPeriod.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JournalStyle.purple)
                Text(period.label)
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(JournalPagesStyle.heading)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(JournalStyle.purple)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 40)
            .background(Capsule().fill(Color.white.opacity(0.92)))
            .overlay(Capsule().strokeBorder(JournalPagesStyle.calendarFill, lineWidth: 1.5))
            .shadow(color: JournalStyle.purple.opacity(0.12), radius: 5, x: 0, y: 2)
        }
        .accessibilityLabel("Show pages from: \(period.label)")
    }
}

// MARK: - A page in the list

/// A page, as in the design: its date under a ribbon bow, its star and heading, its first
/// lines, when it was written, its mood, a heart, its photos and ⋮. In Trash: Restore and
/// Delete Forever.
struct JournalEntryCard: View {
    let entry: JournalEntry
    var shelf: JournalShelf = .all

    @Environment(Router.self) private var router
    @Environment(\.hostTab) private var hostTab
    @Environment(\.modelContext) private var context
    @State private var confirmDelete = false
    @State private var trashChoices = false

    private var inTrash: Bool { entry.isInTrash }

    var body: some View {
        Group {
            if inTrash {
                Button {
                    trashChoices = true
                } label: {
                    card
                }
                .buttonStyle(PressScaleStyle(scale: 0.98))
            } else {
                NavigationLink(value: entry) {
                    card
                }
                .buttonStyle(PressScaleStyle(scale: 0.98))
            }
        }
        .accessibilityActions {
            if inTrash {
                Button("Restore Page", action: restore)
                Button("Delete Forever") { confirmDelete = true }
            } else {
                Button(entry.isFavorite ? "Remove from Favorites" : "Add to Favorites") { entry.isFavorite.toggle() }
                Button("Edit Page") { router.push(.editJournalPage(entry), in: hostTab) }
                Button("Move to Trash") { JournalTrash.moveToTrash(entry) }
            }
        }
        .confirmationDialog(entry.displayTitle, isPresented: $trashChoices, titleVisibility: .visible) {
            Button("Restore Page", action: restore)
            Button("Delete Forever", role: .destructive) { confirmDelete = true }
        }
        .confirmationDialog("Delete this page forever?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Forever", role: .destructive, action: deleteForever)
        } message: {
            Text("This can't be undone.")
        }
    }

    private var card: some View {
        HStack(alignment: .top, spacing: 12) {
            JournalDateTile(date: entry.date)
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .center, spacing: 6) {
                    Image(entry.mood.artName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 30)
                        .accessibilityHidden(true)
                    Text(entry.displayTitle)
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(JournalPagesStyle.heading)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    moreMenu
                }
                HStack(alignment: .top, spacing: 10) {
                    if !previewText.isEmpty {
                        Text(previewText)
                            .font(.rounded(.subheadline, weight: .medium))
                            .foregroundStyle(JournalPagesStyle.preview)
                            .lineSpacing(1)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    JournalCardPhoto(entry: entry)
                }
                metaRow
            }
        }
        .padding(12)
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(JournalPagesStyle.cardFill))
        .overlay(alignment: .bottomTrailing) {
            if !inTrash {
                Image("JournalFlowerCorner")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 44)
                    .offset(x: 4, y: 4)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Color.white, lineWidth: 1.5))
        .shadow(color: JournalStyle.pink.opacity(0.12), radius: 10, x: 0, y: 4)
        .opacity(inTrash ? 0.9 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    /// The page's first lines, or on some tabs the line the tab is about.
    private var previewText: String {
        let body = entry.body.trimmed
        switch shelf {
        case .wins where entry.hasLittleWin: return "🏆 " + entry.littleWin.trimmed
        case .dreams where !entry.lookingForward.trimmed.isEmpty: return "🌙 " + entry.lookingForward.trimmed
        case .growth:
            if !entry.gratitude.trimmed.isEmpty { return "🙏 " + entry.gratitude.trimmed }
            if !entry.highlight.trimmed.isEmpty { return "⭐️ " + entry.highlight.trimmed }
        default: break
        }
        if !body.isEmpty { return body }
        return [entry.highlight, entry.gratitude, entry.littleWin].map(\.trimmed).first { !$0.isEmpty } ?? ""
    }

    private var metaRow: some View {
        HStack(spacing: 8) {
            if inTrash {
                Label(trashText, systemImage: "trash")
                    .font(.rounded(.footnote, weight: .semibold))
                    .foregroundStyle(JournalPagesStyle.time)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 13, weight: .semibold))
                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                        .font(.rounded(.footnote, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(JournalPagesStyle.time)
                .fixedSize()
                MoodChip(mood: entry.mood)
                if entry.hasVoiceNotes {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(JournalStyle.purple)
                        .accessibilityLabel("Has voice notes")
                }
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { entry.isFavorite.toggle() }
                    Haptics.tap()
                } label: {
                    Image(systemName: entry.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(JournalPagesStyle.heartPink)
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressScaleStyle(scale: 0.8))
                .accessibilityLabel(entry.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
            Spacer(minLength: 0)
        }
    }

    private var moreMenu: some View {
        Menu {
            if inTrash {
                Button(action: restore) {
                    Label("Restore Page", systemImage: "arrow.uturn.backward")
                }
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Delete Forever", systemImage: "trash")
                }
            } else {
                Button {
                    router.push(.editJournalPage(entry), in: hostTab)
                } label: {
                    Label("Edit Page", systemImage: "pencil")
                }
                Button {
                    entry.isFavorite.toggle()
                    Haptics.tap()
                } label: {
                    Label(entry.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                          systemImage: entry.isFavorite ? "heart.slash" : "heart")
                }
                Button(role: .destructive) {
                    withAnimation(.snappy) { JournalTrash.moveToTrash(entry) }
                    Haptics.tap()
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                }
            }
        } label: {
            Image(uiImage: PriorityMoreSymbol.image)
                .foregroundStyle(JournalStyle.plum)
                .frame(width: 30, height: 32)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More for this page")
    }

    private var trashText: String {
        let trashedOn = entry.deletedAt ?? .now
        let daysIn = Calendar.current.dateComponents([.day], from: trashedOn.startOfDay, to: Date().startOfDay).day ?? 0
        let left = max(1, JournalTrash.keepDays - daysIn)
        return left == 1 ? "Deleted for good tomorrow" : "\(left) days left in Trash"
    }

    private var accessibilityText: String {
        var parts = [entry.date.formatted(date: .complete, time: .shortened), entry.displayTitle,
                     "Feeling \(entry.mood.label)"]
        if !previewText.isEmpty { parts.append(previewText) }
        let photos = (entry.photos ?? []).count
        if photos > 0 { parts.append(photos == 1 ? "1 photo" : "\(photos) photos") }
        if entry.isFavorite { parts.append("Favorite") }
        if inTrash { parts.append(trashText) }
        return parts.joined(separator: ", ")
    }

    private func restore() {
        withAnimation(.snappy) { JournalTrash.restore(entry) }
        Haptics.success()
    }

    private func deleteForever() {
        withAnimation(.snappy) { context.delete(entry) }
        Haptics.tap()
    }
}

/// The date on a page card: the day and weekday under a ribbon bow, pink, purple or blue.
struct JournalDateTile: View {
    let date: Date

    private enum Ribbon: Int {
        case pink, purple, blue

        var bow: String {
            switch self {
            case .pink: "JournalBowPink"
            case .purple: "JournalBowPurple"
            case .blue: "JournalBowBlue"
            }
        }

        var edge: Color {
            switch self {
            case .pink: Color(hex: 0xF7A6CD)
            case .purple: Color(hex: 0xCDB2F6)
            case .blue: Color(hex: 0xA9CCF4)
            }
        }

        var fill: Color {
            switch self {
            case .pink: Color(hex: 0xFFF0F6)
            case .purple: Color(hex: 0xF6F0FF)
            case .blue: Color(hex: 0xEFF6FF)
            }
        }
    }

    var body: some View {
        // Next days take turns: pink, purple, blue.
        let ribbon = Ribbon(rawValue: ((date.dayNumber % 3) + 3) % 3) ?? .pink
        VStack(spacing: 0) {
            Text(date.formatted(.dateTime.day()))
                .font(.rounded(.title, weight: .heavy))
                .foregroundStyle(Palette.berry)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(JournalPagesStyle.weekday)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.top, 16)
        .frame(width: 64, height: 88)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [Color.white, ribbon.fill], startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ribbon.edge, lineWidth: 1.5)
        )
        .overlay(alignment: .top) {
            Image(ribbon.bow)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 34)
                .offset(y: -15)
                .accessibilityHidden(true)
        }
        .padding(.top, 8)
        .shadow(color: ribbon.edge.opacity(0.35), radius: 4, x: 0, y: 2)
    }
}

/// A page's first photo on its card, with "+2" when there are more.
struct JournalCardPhoto: View {
    let entry: JournalEntry

    var body: some View {
        let photos = entry.sortedPhotos
        if let first = photos.first, let data = first.thumbnailData, let image = UIImage(data: data) {
            Color.clear
                .frame(width: 78, height: 78)
                .overlay(Image(uiImage: image).resizable().scaledToFill())
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white, lineWidth: 3)
                )
                .overlay(alignment: .bottomTrailing) {
                    if photos.count > 1 {
                        Text("+\(photos.count - 1)")
                            .font(.rounded(.subheadline, weight: .heavy))
                            .foregroundStyle(Color.white)
                            .frame(minWidth: 32, minHeight: 32)
                            .background(Circle().fill(Color.black.opacity(0.45)))
                            .padding(5)
                    }
                }
                .shadow(color: JournalStyle.pink.opacity(0.2), radius: 5, x: 0, y: 2)
                .accessibilityHidden(true)
        }
    }
}

/// "⭐ Happy" in the mood's colours.
struct MoodChip: View {
    let mood: Mood

    var body: some View {
        let colors = mood.chooserColors
        HStack(spacing: 4) {
            Image(mood.artName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 19)
            Text(mood.label)
                .font(.rounded(.footnote, weight: .bold))
                .foregroundStyle(colors.label)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.leading, 6)
        .padding(.trailing, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(colors.tile))
        .overlay(Capsule().strokeBorder(Color.white, lineWidth: 1))
    }
}

// MARK: - Search

/// "🔍 Search your journal… 💗" and Filter, floating over the pages.
struct JournalSearchBar: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    /// How many filters are on (shown on the Filter button).
    let filterCount: Int
    let onFilter: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(JournalStyle.plum)
                    .accessibilityHidden(true)
                TextField("Search your journal…", text: $text)
                    .font(.rounded(.callout, weight: .medium))
                    .foregroundStyle(JournalStyle.ink)
                    .focused(focused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                if text.isEmpty {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(JournalPagesStyle.heartPink)
                        .accessibilityHidden(true)
                } else {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(JournalStyle.placeholder)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 56)
            .background(Capsule().fill(Color.white.opacity(0.97)))
            .overlay(Capsule().strokeBorder(JournalStyle.pinkFill, lineWidth: 1.5))
            .shadow(color: JournalStyle.pink.opacity(0.18), radius: 10, x: 0, y: 4)

            Button(action: onFilter) {
                HStack(spacing: 5) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(JournalStyle.pink)
                    Text("Filter")
                        .font(.rounded(.callout, weight: .bold))
                        .foregroundStyle(JournalStyle.plum)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 56)
                .background(Capsule().fill(Color.white.opacity(0.97)))
                .overlay(Capsule().strokeBorder(JournalStyle.pinkFill, lineWidth: 1.5))
                .shadow(color: JournalStyle.pink.opacity(0.18), radius: 10, x: 0, y: 4)
                .overlay(alignment: .topTrailing) {
                    if filterCount > 0 {
                        Text("\(filterCount)")
                            .font(.rounded(.caption, weight: .heavy))
                            .foregroundStyle(Color.white)
                            .frame(minWidth: 22, minHeight: 22)
                            .background(Circle().fill(JournalStyle.pink))
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel(filterCount > 0 ? "Filter, \(filterCount) on" : "Filter")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(alignment: .bottom) {
            LinearGradient(colors: [JournalBackdrop.base.opacity(0), JournalBackdrop.base.opacity(0.92)],
                           startPoint: .top, endPoint: .center)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Small pieces

/// Pages grouped by month, newest month first (or oldest first).
struct JournalMonth: Identifiable {
    let month: Date
    let entries: [JournalEntry]
    var id: Date { month }

    var title: String { month.formatted(.dateTime.month(.wide).year()) }

    static func group(_ pages: [JournalEntry], oldestFirst: Bool) -> [JournalMonth] {
        let groups = Dictionary(grouping: pages) { $0.date.startOfMonth }
        let oldest = groups.keys.sorted()
        let months = oldestFirst ? oldest : Array(oldest.reversed())
        return months.map { JournalMonth(month: $0, entries: groups[$0] ?? []) }
    }
}

/// Shown above the Little Wins: how many there are.
struct LittleWinsSummary: View {
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("🏆")
                .font(.system(size: 30))
                .frame(width: 54, height: 54)
                .background(Circle().fill(Palette.cream))
                .overlay(Circle().strokeBorder(Palette.butter, lineWidth: 1.5))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(count == 1 ? "1 little win" : "\(count) little wins")
                    .font(.rounded(.title3, weight: .heavy))
                    .foregroundStyle(Palette.cocoa)
                    .contentTransition(.numericText(value: Double(count)))
                Text("Look how far you've come! 🌟")
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(JournalStyle.soft)
            }
            Spacer(minLength: 0)
        }
        .journalPagesCard()
        .accessibilityElement(children: .combine)
    }
}

/// A friendly line at the top of a tab.
struct ShelfHint: View {
    let emoji: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.system(size: 30))
                .frame(width: 52, height: 52)
                .background(Circle().fill(JournalStyle.pinkFill))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(JournalPagesStyle.heading)
                Text(message)
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(JournalStyle.soft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .journalPagesCard()
        .accessibilityElement(children: .combine)
    }
}

/// A tab with nothing to show.
struct ShelfEmpty: View {
    let emoji: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 44))
                .accessibilityHidden(true)
            Text(title)
                .font(.rounded(.title3, weight: .heavy))
                .foregroundStyle(JournalPagesStyle.heading)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.rounded(.body, weight: .medium))
                .foregroundStyle(JournalStyle.soft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .journalPagesCard(padding: 20)
        .accessibilityElement(children: .combine)
    }
}
