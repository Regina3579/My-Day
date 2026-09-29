import SwiftUI
import SwiftData

// MARK: - Tabs, dates and filters

/// The tabs of My Journal Pages.
enum JournalShelf: String, CaseIterable, Identifiable {
    case all, favorites, wins, templates, photos, voice, feelings, growth, dreams, trash

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "All Pages"
        case .favorites: "Favorites"
        case .wins: "Little Wins"
        case .templates: "Templates"
        case .photos: "Photos"
        case .voice: "Voice Notes"
        case .feelings: "My Feelings"
        case .growth: "My Growth"
        case .dreams: "Dreams"
        case .trash: "Trash"
        }
    }

    /// The label on its tile, on two lines where it is long.
    var tileTitle: String {
        switch self {
        case .all: "All\nPages"
        case .wins: "Little\nWins"
        case .voice: "Voice\nNotes"
        case .feelings: "My\nFeelings"
        case .growth: "My\nGrowth"
        default: label
        }
    }

    var symbol: String {
        switch self {
        case .all: "book.fill"
        case .favorites: "heart.fill"
        case .wins: "trophy.fill"
        case .templates: "doc.text.fill"
        case .photos: "photo.fill"
        case .voice: "mic.fill"
        case .feelings: "face.smiling.inverse"
        case .growth: "leaf.fill"
        case .dreams: "moon.stars.fill"
        case .trash: "trash.fill"
        }
    }

    var color: Color {
        switch self {
        case .all: Color(hex: 0xF2148E)
        case .favorites: Color(hex: 0xFF3E9A)
        case .wins: Color(hex: 0xF29A00)
        case .templates: Color(hex: 0x8B5CF6)
        case .photos: Color(hex: 0x16A874)
        case .voice: Color(hex: 0x9D4EF0)
        case .feelings: Color(hex: 0xF0A800)
        case .growth: Color(hex: 0x2DB552)
        case .dreams: Color(hex: 0x5B6CF0)
        case .trash: Color(hex: 0xEE4B7A)
        }
    }

    /// Whether a page belongs on this tab (Trash lists trashed pages; Templates lists none).
    func includes(_ entry: JournalEntry) -> Bool {
        switch self {
        case .all, .feelings, .trash: true
        case .favorites: entry.isFavorite
        case .wins: entry.hasLittleWin
        case .templates: false
        case .photos: entry.hasPhotos
        case .voice: entry.hasVoiceNotes
        case .growth: entry.hasReflections
        case .dreams: entry.isDream
        }
    }
}

/// Which dates the list shows.
enum JournalPeriod: String, CaseIterable, Identifiable {
    case allTime, last7Days, thisMonth, lastMonth, last3Months, thisYear

    var id: String { rawValue }

    var label: String {
        switch self {
        case .allTime: "All Time"
        case .last7Days: "Last 7 Days"
        case .thisMonth: "This Month"
        case .lastMonth: "Last Month"
        case .last3Months: "Last 3 Months"
        case .thisYear: "This Year"
        }
    }

    /// The dates it covers (nil: every date).
    func range(today: Date) -> Range<Date>? {
        let month = today.startOfMonth
        switch self {
        case .allTime:
            return nil
        case .last7Days:
            return today.adding(days: -6)..<today.nextDay
        case .thisMonth:
            return month..<month.adding(months: 1)
        case .lastMonth:
            return month.adding(months: -1)..<month
        case .last3Months:
            return month.adding(months: -2)..<month.adding(months: 1)
        case .thisYear:
            guard let year = Calendar.current.dateInterval(of: .year, for: today) else { return nil }
            return year.start..<year.end
        }
    }
}

/// What Filter narrows the pages to.
struct JournalFilter: Equatable {
    var moods: Set<Mood> = []
    var favoritesOnly = false
    var withPhotos = false
    var withVoiceNotes = false
    var withLittleWin = false
    var oldestFirst = false

    /// How many are on.
    var count: Int {
        (moods.isEmpty ? 0 : 1) + [favoritesOnly, withPhotos, withVoiceNotes, withLittleWin, oldestFirst].filter { $0 }.count
    }

    func includes(_ entry: JournalEntry) -> Bool {
        (moods.isEmpty || moods.contains(entry.mood))
            && (!favoritesOnly || entry.isFavorite)
            && (!withPhotos || entry.hasPhotos)
            && (!withVoiceNotes || entry.hasVoiceNotes)
            && (!withLittleWin || entry.hasLittleWin)
    }
}

// MARK: - Templates

/// Page templates: each starts a new page with its heading, prompts and tags.
struct TemplatesShelf: View {
    let query: String

    private var templates: [JournalPageTemplate] {
        guard !query.isEmpty else { return JournalPageTemplate.allCases }
        return JournalPageTemplate.allCases.filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.summary.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ShelfHint(emoji: "📝", title: "Page templates",
                      message: "Pick one to start a new page with a few gentle prompts.")
            if templates.isEmpty {
                ShelfEmpty(emoji: "🔍", title: "No templates found", message: "Try another word.")
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                          spacing: 12) {
                    ForEach(templates) { template in
                        NavigationLink(value: AppRoute.newJournalPage(template)) {
                            card(template)
                        }
                        .buttonStyle(PressScaleStyle(scale: 0.97))
                    }
                }
            }
        }
    }

    private func card(_ template: JournalPageTemplate) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(template.emoji)
                .font(.system(size: 30))
                .frame(width: 52, height: 52)
                .background(Circle().fill(Color.white.opacity(0.9)))
                .accessibilityHidden(true)
            Text(template.name)
                .font(.rounded(.headline, weight: .heavy))
                .foregroundStyle(JournalPagesStyle.heading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)
            Text(template.summary)
                .font(.rounded(.subheadline, weight: .medium))
                .foregroundStyle(JournalStyle.soft)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            HStack(spacing: 4) {
                Text("Write")
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .heavy))
            }
            .font(.rounded(.subheadline, weight: .heavy))
            .foregroundStyle(JournalStyle.pink)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 196, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [template.tint, Color.white.opacity(0.9)],
                                     startPoint: .top, endPoint: .bottom))
        )
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.white, lineWidth: 1.5))
        .shadow(color: JournalStyle.pink.opacity(0.12), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Starts a new page")
    }
}

// MARK: - Photos

/// Every photo on the pages shown, three across; tap one to open its page.
struct PhotosShelf: View {
    let entries: [JournalEntry]

    private struct Item: Identifiable {
        let entry: JournalEntry
        let photo: JournalPhoto
        var id: PersistentIdentifier { photo.persistentModelID }
    }

    var body: some View {
        let items = entries.flatMap { entry in entry.sortedPhotos.map { Item(entry: entry, photo: $0) } }
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(items) { item in
                NavigationLink(value: item.entry) {
                    tile(item)
                }
                .buttonStyle(PressScaleStyle(scale: 0.96))
                .accessibilityLabel("Photo from \(item.entry.displayTitle), \(item.entry.date.formatted(date: .abbreviated, time: .omitted))")
            }
        }
    }

    private func tile(_ item: Item) -> some View {
        Color.white
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let data = item.photo.thumbnailData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.white, lineWidth: 3))
            .overlay(alignment: .bottomLeading) {
                Image(item.entry.mood.artName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 28)
                    .padding(5)
            }
            .shadow(color: JournalStyle.pink.opacity(0.18), radius: 6, x: 0, y: 3)
    }
}

// MARK: - My Feelings

/// How the pages felt: the mood felt most, and each mood with a bar. Tap one to see its pages.
struct FeelingsSummary: View {
    let entries: [JournalEntry]
    let period: JournalPeriod
    @Binding var selected: Set<Mood>

    var body: some View {
        let counts = Dictionary(grouping: entries, by: \.mood).mapValues(\.count)
        // The most felt first; moods felt as often, by name.
        let ranked = counts.sorted { lhs, rhs in
            lhs.value == rhs.value ? lhs.key.rawValue < rhs.key.rawValue : lhs.value > rhs.value
        }
        let moods = ranked.map(\.key)
        let most = ranked.first?.value ?? 0
        // "Mostly Happy" only when one mood really was felt most.
        let isMix = ranked.count > 1 && ranked[1].value == most
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("How I've been feeling")
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(JournalStyle.plum)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 4)
                Text(period.label)
                    .font(.rounded(.footnote, weight: .bold))
                    .foregroundStyle(JournalStyle.pink)
            }
            if let top = moods.first {
                HStack(spacing: 12) {
                    Image(top.artName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 64)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isMix ? "A mix of feelings" : "Mostly \(top.label)")
                            .font(.rounded(.title2, weight: .heavy))
                            .foregroundStyle(isMix ? JournalStyle.plum : top.chooserColors.label)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text(isMix ? "\(moods.count) moods on \(entries.count) pages"
                                   : "\(most) of \(entries.count) \(entries.count == 1 ? "page" : "pages")")
                            .font(.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(JournalStyle.soft)
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
                VStack(spacing: 8) {
                    ForEach(moods.prefix(6)) { mood in
                        row(mood, count: counts[mood] ?? 0, most: most)
                    }
                }
                if !selected.isEmpty {
                    Button {
                        withAnimation(.snappy) { selected = [] }
                    } label: {
                        Label("Show every mood", systemImage: "xmark.circle.fill")
                            .font(.rounded(.subheadline, weight: .bold))
                            .foregroundStyle(JournalStyle.pink)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("Write a page and pick a mood to see your feelings here. 💗")
                    .font(.rounded(.body, weight: .medium))
                    .foregroundStyle(JournalStyle.soft)
            }
        }
        .journalPagesCard()
    }

    private func row(_ mood: Mood, count: Int, most: Int) -> some View {
        let isOn = selected.contains(mood)
        let colors = mood.chooserColors
        return Button {
            withAnimation(.snappy) { selected = isOn ? [] : [mood] }
            Haptics.tap()
        } label: {
            HStack(spacing: 10) {
                Image(mood.artName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 30)
                Text(mood.label)
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(colors.label)
                    .frame(width: 96, alignment: .leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                GeometryReader { proxy in
                    Capsule()
                        .fill(colors.tile)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(mood.color.gradient)
                                .frame(width: max(12, proxy.size.width * CGFloat(count) / CGFloat(max(most, 1))))
                        }
                }
                .frame(height: 12)
                Text("\(count)")
                    .font(.rounded(.subheadline, weight: .heavy))
                    .foregroundStyle(JournalPagesStyle.heading)
                    .frame(minWidth: 24, alignment: .trailing)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isOn ? colors.tile : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isOn ? JournalStyle.selectedMoodEdge : Color.clear, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mood.label): \(count) \(count == 1 ? "page" : "pages")")
        .accessibilityHint(isOn ? "Shows every mood" : "Shows only these pages")
        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
    }
}

// MARK: - My Growth

/// Pages written, the writing streak, little wins and words written.
struct GrowthSummary: View {
    let entries: [JournalEntry]
    let today: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Look how I'm growing 🌱")
                .font(.rounded(.headline, weight: .heavy))
                .foregroundStyle(JournalStyle.plum)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                stat("📖", value: entries.count, label: entries.count == 1 ? "page written" : "pages written")
                stat("🔥", value: streak, label: streak == 1 ? "day in a row" : "days in a row")
                stat("🏆", value: entries.filter(\.hasLittleWin).count, label: "little wins")
                stat("✍️", value: words, label: "words written")
            }
        }
        .journalPagesCard()
    }

    /// Days in a row with a page, up to today (or yesterday, before today's is written).
    private var streak: Int {
        let days = Set(entries.map(\.date.startOfDay))
        var day = days.contains(today.startOfDay) ? today.startOfDay : today.adding(days: -1)
        var count = 0
        while days.contains(day) {
            count += 1
            day = day.adding(days: -1)
        }
        return count
    }

    private var words: Int {
        entries.reduce(0) { total, entry in
            total + entry.body.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        }
    }

    private func stat(_ emoji: String, value: Int, label: String) -> some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.system(size: 26))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(value.formatted())
                    .font(.rounded(.title2, weight: .heavy))
                    .foregroundStyle(JournalPagesStyle.heading)
                    .contentTransition(.numericText(value: Double(value)))
                Text(label)
                    .font(.rounded(.footnote, weight: .bold))
                    .foregroundStyle(JournalStyle.soft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(JournalStyle.fieldFill))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Trash

/// "Pages stay here for 30 days", and Empty Trash.
struct TrashNotice: View {
    let count: Int
    let onEmpty: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text("🗑️")
                    .font(.system(size: 28))
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(JournalStyle.pinkFill))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Trash")
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(JournalPagesStyle.heading)
                    Text("Pages stay here for \(JournalTrash.keepDays) days, then they're deleted for good. Tap a page to restore it.")
                        .font(.rounded(.subheadline, weight: .medium))
                        .foregroundStyle(JournalStyle.soft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
            if count > 0 {
                Button(action: onEmpty) {
                    Label("Empty Trash", systemImage: "trash.fill")
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(Color(hex: 0xE5484D))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Capsule().fill(Color(hex: 0xFFE9EC)))
                        .overlay(Capsule().strokeBorder(Color(hex: 0xF7B9C2), lineWidth: 1.5))
                }
                .buttonStyle(PressScaleStyle(scale: 0.97))
            }
        }
        .journalPagesCard()
    }
}

// MARK: - Filter

/// Filter: favourites, photos, voice notes and little wins, the dates, moods and the order.
struct JournalFilterSheet: View {
    @Binding var filter: JournalFilter
    @Binding var period: JournalPeriod
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    section("Show only") {
                        VStack(spacing: 0) {
                            toggle("💗", "Favorites", isOn: $filter.favoritesOnly)
                            Divider().padding(.leading, 52)
                            toggle("📸", "With photos", isOn: $filter.withPhotos)
                            Divider().padding(.leading, 52)
                            toggle("🎙️", "With voice notes", isOn: $filter.withVoiceNotes)
                            Divider().padding(.leading, 52)
                            toggle("🏆", "With a little win", isOn: $filter.withLittleWin)
                        }
                        .journalPagesCard(padding: 6, radius: 22)
                    }
                    section("Dates") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8),
                                                 count: typeSize.isAccessibilitySize ? 2 : 3), spacing: 8) {
                            ForEach(JournalPeriod.allCases) { option in
                                chip(option.label, isOn: period == option) {
                                    period = option
                                }
                            }
                        }
                    }
                    section("Order") {
                        HStack(spacing: 8) {
                            chip("Newest first", isOn: !filter.oldestFirst) { filter.oldestFirst = false }
                            chip("Oldest first", isOn: filter.oldestFirst) { filter.oldestFirst = true }
                        }
                    }
                    section("Moods") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6),
                                                 count: typeSize.isAccessibilitySize ? 3 : 5), spacing: 8) {
                            ForEach(Mood.chooserMoods) { mood in
                                moodTile(mood)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(MoodChooserStyle.background.ignoresSafeArea())
            .navigationTitle("Filter Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        withAnimation(.snappy) {
                            filter = JournalFilter()
                            period = .allTime
                        }
                    }
                    .disabled(filter == JournalFilter() && period == .allTime)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
        .tint(JournalStyle.pink)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.rounded(.headline, weight: .heavy))
                .foregroundStyle(JournalStyle.plum)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func toggle(_ emoji: String, _ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn.animation(.snappy)) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 22))
                    .frame(width: 34)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.rounded(.body, weight: .semibold))
                    .foregroundStyle(JournalPagesStyle.heading)
            }
        }
        .tint(JournalStyle.pink)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy) { action() }
            Haptics.tap()
        } label: {
            Text(title)
                .font(.rounded(.subheadline, weight: .bold))
                .foregroundStyle(isOn ? Color.white : JournalPagesStyle.heading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Capsule().fill(isOn ? AnyShapeStyle(JournalPagesStyle.writeButton)
                                                : AnyShapeStyle(Color.white.opacity(0.92))))
                .overlay(Capsule().strokeBorder(Color.white, lineWidth: 1.5))
                .shadow(color: JournalStyle.pink.opacity(isOn ? 0.3 : 0.08), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
    }

    private func moodTile(_ mood: Mood) -> some View {
        let isOn = filter.moods.contains(mood)
        let colors = mood.chooserColors
        return Button {
            withAnimation(.snappy) {
                if isOn { filter.moods.remove(mood) } else { filter.moods.insert(mood) }
            }
            Haptics.tap()
        } label: {
            VStack(spacing: 3) {
                Image(mood.artName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                Text(mood.label)
                    .font(.rounded(.caption, weight: .bold))
                    .foregroundStyle(colors.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 1)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(colors.tile))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isOn ? JournalStyle.selectedMoodEdge : Color.white.opacity(0.9), lineWidth: isOn ? 2.5 : 1.5)
            )
            .overlay(alignment: .topTrailing) {
                if isOn {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, JournalStyle.selectedMoodEdge)
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mood.label)
        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
    }
}
