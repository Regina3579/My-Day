import PhotosUI
import SwiftData
import SwiftUI
import UserNotifications

// MARK: - The list

/// Important Days, from the side menu: birthdays, anniversaries and special days with their
/// photos and countdowns. Days still to come first (soonest first), then one-off days that
/// have passed. Two days are free; with more, the rest wait under Locked until My Day Pro.
struct ImportantDaysView: View {
    @Environment(MyDayPro.self) private var pro
    @Environment(AppState.self) private var appState
    @Query(sort: \ImportantDay.createdAt) private var days: [ImportantDay]
    @State private var isAdding = false
    @State private var proOffer: ProFeature?

    static let freeLimit = 2

    /// The days a free account can open: its first two.
    private var unlocked: [ImportantDay] {
        pro.isActive ? days : Array(days.prefix(Self.freeLimit))
    }

    private var locked: [ImportantDay] {
        pro.isActive ? [] : Array(days.dropFirst(Self.freeLimit))
    }

    private var coming: [ImportantDay] {
        unlocked.filter { $0.nextDate(from: appState.today) != nil }
            .sorted { ($0.nextDate(from: appState.today) ?? .distantFuture) < ($1.nextDate(from: appState.today) ?? .distantFuture) }
    }

    private var past: [ImportantDay] {
        unlocked.filter { $0.nextDate(from: appState.today) == nil }.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ImportantDayHeader(title: "Important Days",
                                   subtitle: "Birthdays, anniversaries and special days, with their countdowns.")
                if days.isEmpty {
                    emptyState
                } else {
                    if !coming.isEmpty { section("Coming", coming, isLocked: false) }
                    if !past.isEmpty { section("Past", past, isLocked: false) }
                    if !locked.isEmpty { section("Locked", locked, isLocked: true) }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(action: add) {
                Text("Add New Day")
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Capsule().fill(LinearGradient(colors: [Color(hex: 0xFF5FA8), Palette.hotPink],
                                                              startPoint: .top, endPoint: .bottom)))
                    .shadow(color: Palette.hotPink.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PressScaleStyle(scale: 0.97))
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
        }
        .background(ImportantDayBackground())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .tabBarSafeArea()
        .sheet(isPresented: $isAdding) {
            ImportantDayKindPicker()
        }
        .proOffer($proOffer)
        #if DEBUG
        .task {
            if DebugLaunchRoute.takeImportantDayAdd() {
                try? await Task.sleep(for: .seconds(0.6))
                isAdding = true
            }
        }
        #endif
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🎂 💞 ✈️")
                .font(.system(size: 34))
            Text("No important days yet")
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(ImportantDayStyle.berry)
            Text("Add a birthday, an anniversary or a trip, and see the countdown here.")
                .font(.rounded(.subheadline, weight: .medium))
                .foregroundStyle(ImportantDayStyle.plum)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white.opacity(0.7)))
    }

    private func section(_ title: String, _ list: [ImportantDay], isLocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.rounded(.title3, weight: .heavy))
                .foregroundStyle(ImportantDayStyle.berry)
                .padding(.leading, 6)
            VStack(spacing: 0) {
                ForEach(Array(list.enumerated()), id: \.element.persistentModelID) { index, day in
                    if index > 0 {
                        Divider().padding(.leading, 92)
                    }
                    if isLocked {
                        Button { proOffer = .importantDays } label: {
                            ImportantDayRow(day: day, today: appState.today, isLocked: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink {
                            ImportantDayDetailView(day: day)
                        } label: {
                            ImportantDayRow(day: day, today: appState.today, isLocked: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white.opacity(0.85)))
            .shadow(color: Palette.hotPink.opacity(0.08), radius: 8, x: 0, y: 3)
        }
    }

    private func add() {
        if pro.isActive || days.count < Self.freeLimit {
            isAdding = true
        } else {
            proOffer = .importantDays
        }
    }
}

/// A day in the list: its photo with a little badge, its name and its countdown.
struct ImportantDayRow: View {
    let day: ImportantDay
    let today: Date
    var isLocked = false

    var body: some View {
        HStack(spacing: 14) {
            ImportantDayPhoto(day: day, cornerRadius: 16)
                .frame(width: 70, height: 70)
                .overlay(alignment: .bottomTrailing) {
                    ImportantDayBadge(kind: day.kind, size: 28)
                        .offset(x: 6, y: 6)
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(day.title)
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(ImportantDayStyle.ink)
                    .lineLimit(2)
                if isLocked {
                    HStack(spacing: 8) {
                        Text(day.date.formatted(.dateTime.day().month(.abbreviated).year()))
                            .font(.rounded(.subheadline, weight: .medium))
                            .foregroundStyle(ImportantDayStyle.plum)
                        Label("PREMIUM", systemImage: "crown.fill")
                            .font(.rounded(.caption2, weight: .heavy))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Palette.hotPink))
                    }
                } else {
                    Text(ImportantDayText.countdown(day, today: today))
                        .font(.rounded(.subheadline, weight: .medium))
                        .foregroundStyle(ImportantDayStyle.plum)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ImportantDayStyle.plum.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Choosing a kind (the design)

/// Add New Day: the Important Day design: its title and words beside the girl, then the cards
/// (Birthday, Relationship, Family, Travel, Home, Work, Education, Create Your Own).
struct ImportantDayKindPicker: View {
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ImportantDayHeader(title: "Important Day",
                                       subtitle: "Add an important day to be reminded of it and see the countdown.")
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(ImportantDayKind.allCases) { kind in
                            NavigationLink {
                                ImportantDayEditor(kind: kind, onSaved: { dismiss() })
                            } label: {
                                ImportantDayKindCard(kind: kind)
                            }
                            .buttonStyle(PressScaleStyle(scale: 0.96))
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .background(ImportantDayBackground())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(ImportantDayStyle.berry)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
    }
}

/// A card of the design: the kind's picture, its name and a little › button.
struct ImportantDayKindCard: View {
    let kind: ImportantDayKind

    var body: some View {
        VStack(spacing: 6) {
            Image(kind.art)
                .resizable()
                .scaledToFit()
                .frame(height: 104)
                .accessibilityHidden(true)
            Text(kind.title)
                .font(.rounded(size: 17, weight: .heavy))
                .foregroundStyle(ImportantDayStyle.berry)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.trailing, 28)
        }
        .padding(.top, 12)
        .padding(.bottom, 14)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white.opacity(0.75)))
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Palette.hotPink)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color(hex: 0xFCE1EE)))
                .padding(10)
        }
        .shadow(color: Palette.hotPink.opacity(0.08), radius: 8, x: 0, y: 3)
        .accessibilityLabel(kind.title)
    }
}

// MARK: - Adding and editing

/// A day's details: its photo, name, date, whether it comes every year, and a reminder.
struct ImportantDayEditor: View {
    var day: ImportantDay?
    let kind: ImportantDayKind
    var onSaved: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var title: String
    @State private var date: Date
    @State private var repeatsYearly: Bool
    @State private var remindsMe: Bool
    @State private var note: String
    @State private var photo: Data?
    @State private var thumbnail: Data?
    @State private var pickerItem: PhotosPickerItem?
    @State private var confirmDelete = false
    @FocusState private var titleFocused: Bool

    init(day: ImportantDay? = nil, kind: ImportantDayKind, onSaved: @escaping () -> Void = {}) {
        self.day = day
        self.kind = day?.kind ?? kind
        self.onSaved = onSaved
        _title = State(initialValue: day?.title ?? "")
        _date = State(initialValue: day?.date ?? .now)
        _repeatsYearly = State(initialValue: day?.repeatsYearly ?? kind.repeatsByDefault)
        _remindsMe = State(initialValue: day?.remindsMe ?? true)
        _note = State(initialValue: day?.note ?? "")
        _photo = State(initialValue: day?.photoData)
        _thumbnail = State(initialValue: day?.thumbnailData)
    }

    private var canSave: Bool { !title.trimmed.isEmpty }

    var body: some View {
        Form {
            Section {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    ZStack {
                        if let thumbnail, let image = UIImage(data: thumbnail) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            LinearGradient(colors: [Color(hex: 0xFFE3F0), Color(hex: 0xFBC6DE)],
                                           startPoint: .top, endPoint: .bottom)
                            VStack(spacing: 6) {
                                Image(kind.art)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 90)
                                Label("Add a Photo", systemImage: "photo.badge.plus")
                                    .font(.rounded(.subheadline, weight: .bold))
                                    .foregroundStyle(Palette.hotPink)
                            }
                        }
                    }
                    .frame(height: 190)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(alignment: .bottomTrailing) {
                        if thumbnail != nil {
                            Label("Change", systemImage: "photo")
                                .font(.rounded(.caption, weight: .bold))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.black.opacity(0.45)))
                                .padding(10)
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Name") {
                TextField(kind.placeholder, text: $title)
                    .font(.rounded(.title3, weight: .semibold))
                    .focused($titleFocused)
                    .submitLabel(.done)
            }

            Section {
                DatePicker(kind == .birthday ? "Birthday" : "Date", selection: $date, displayedComponents: .date)
                Toggle("Every year", isOn: $repeatsYearly)
                    .tint(Palette.hotPink)
                Toggle("Remind me on the day", isOn: $remindsMe)
                    .tint(Palette.hotPink)
            } footer: {
                Text(kind == .birthday
                     ? "Use the day they were born, so My Day can count their age. 🎂"
                     : "A reminder comes at 9 in the morning on the day.")
            }

            Section("Note") {
                TextField("A little note (optional)", text: $note, axis: .vertical)
                    .lineLimit(2...5)
            }

            if day != nil {
                Section {
                    Button("Delete This Day", role: .destructive) { confirmDelete = true }
                }
            }
        }
        .font(.rounded(.body))
        .scrollContentBackground(.hidden)
        .background(ImportantDayBackground())
        .navigationTitle(day == nil ? kind.title : "Edit Day")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .fontWeight(.bold)
                    .disabled(!canSave)
            }
        }
        .onChange(of: pickerItem) { _, item in load(item) }
        .confirmationDialog("Delete “\(title)”?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: delete)
        }
        .task {
            guard day == nil else { return }
            await Opening.settle()
            titleFocused = true
        }
    }

    private func load(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            let raw = try? await item.loadTransferable(type: Data.self)
            let prepared = await Task.detached(priority: .userInitiated) {
                raw.flatMap(PhotoProcessor.prepare)
            }.value
            if let prepared {
                withAnimation(.snappy) {
                    photo = prepared.photo
                    thumbnail = prepared.thumbnail
                }
            }
            pickerItem = nil
        }
    }

    private func save() {
        guard canSave else { return }
        let target = day ?? {
            let new = ImportantDay(title: title.trimmed, kind: kind, date: date, repeatsYearly: repeatsYearly)
            context.insert(new)
            return new
        }()
        target.title = title.trimmed
        target.kind = kind
        target.date = Calendar.current.startOfDay(for: date)
        target.repeatsYearly = repeatsYearly
        target.remindsMe = remindsMe
        target.note = note.trimmed
        target.photoData = photo
        target.thumbnailData = thumbnail
        try? context.save()
        Task { await ImportantDayReminders.schedule(target) }
        Haptics.success()
        if day == nil {
            onSaved()
        } else {
            dismiss()
        }
    }

    private func delete() {
        guard let day else { return }
        ImportantDayReminders.cancel(day)
        context.delete(day)
        try? context.save()
        dismiss()
        onSaved()
    }
}

// MARK: - One day

/// A day on its own: its photo large, its countdown, its age or years, and its note.
struct ImportantDayDetailView: View {
    @Bindable var day: ImportantDay
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ImportantDayPhoto(day: day, cornerRadius: 28)
                    .frame(height: 280)
                    .overlay(alignment: .bottomLeading) {
                        HStack(spacing: 12) {
                            ImportantDayBadge(kind: day.kind, size: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(day.title)
                                    .font(.rounded(.title2, weight: .heavy))
                                Text(day.date.formatted(.dateTime.day().month(.wide).year()))
                                    .font(.rounded(.subheadline, weight: .bold))
                            }
                            .foregroundStyle(Color.white)
                            .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 1)
                        }
                        .padding(18)
                    }

                VStack(spacing: 6) {
                    Text(ImportantDayText.bigCountdown(day, today: appState.today))
                        .font(.rounded(size: 34, weight: .heavy))
                        .foregroundStyle(Palette.hotPink)
                        .multilineTextAlignment(.center)
                    Text(ImportantDayText.countdown(day, today: appState.today))
                        .font(.rounded(.headline, weight: .semibold))
                        .foregroundStyle(ImportantDayStyle.plum)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white.opacity(0.85)))

                if day.date <= appState.today {
                    ImportantDaySinceRow(day: day, on: appState.today)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white.opacity(0.85)))
                }

                if !day.note.isEmpty {
                    Text(day.note)
                        .font(.rounded(.body, weight: .medium))
                        .foregroundStyle(ImportantDayStyle.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white.opacity(0.85)))
                }
            }
            .padding(18)
        }
        .background(ImportantDayBackground())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .tabBarSafeArea()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { isEditing = true }
                    .fontWeight(.bold)
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                ImportantDayEditor(day: day, kind: day.kind, onSaved: { dismiss() })
            }
        }
    }
}

// MARK: - In the journal

/// The day in My Journal Pages, on the day it falls (as in the reference): its photo across the
/// card with its badge, name and date, and below how many years and days it has been.
struct ImportantDayJournalCard: View {
    let day: ImportantDay
    let on: Date

    var body: some View {
        VStack(spacing: 0) {
            ImportantDayPhoto(day: day, cornerRadius: 0)
                .frame(height: 210)
                .overlay {
                    LinearGradient(colors: [.clear, Color.black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                }
                .overlay(alignment: .bottomLeading) {
                    HStack(spacing: 12) {
                        ImportantDayBadge(kind: day.kind, size: 46)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(day.title)
                                .font(.rounded(.title3, weight: .heavy))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(on.formatted(.dateTime.day().month(.wide).year()))
                                .font(.rounded(.subheadline, weight: .bold))
                        }
                        .foregroundStyle(Color.white)
                        .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 1)
                    }
                    .padding(16)
                }
                .clipped()
            ImportantDaySinceRow(day: day, on: on)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Palette.hotPink.opacity(0.12), radius: 10, x: 0, y: 4)
        .accessibilityElement(children: .combine)
    }
}

/// "70 years · 25,567 days since", with a calendar badge.
struct ImportantDaySinceRow: View {
    let day: ImportantDay
    let on: Date

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "calendar")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Palette.hotPink)
                .frame(width: 46, height: 46)
                .background(Circle().fill(Palette.blush))
            VStack(alignment: .leading, spacing: 2) {
                Text(ImportantDayText.years(day, at: on))
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(ImportantDayStyle.ink)
                Text(ImportantDayText.daysSince(day, at: on))
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(ImportantDayStyle.plum)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Words

enum ImportantDayText {
    /// "71st Birthday in 164 days", "12 years together in 30 days", "Today! 🎉", "In 9 days".
    static func countdown(_ day: ImportantDay, today: Date) -> String {
        guard let next = day.nextDate(from: today) else {
            return "\(daysSince(day, at: today)) · \(day.date.formatted(.dateTime.day().month(.abbreviated).year()))"
        }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: today), to: next).day ?? 0
        let when = days == 0 ? "today! 🎉" : days == 1 ? "tomorrow" : "in \(days.formatted()) days"
        let years = day.years(at: next)
        guard day.repeatsYearly, years > 0 else {
            return days == 0 ? "Today! 🎉" : when.prefix(1).uppercased() + when.dropFirst()
        }
        switch day.kind {
        case .birthday: return "\(ordinal(years)) Birthday \(when)"
        case .relationship: return "\(years) \(years == 1 ? "year" : "years") together \(when)"
        default: return "\(ordinal(years)) anniversary \(when)"
        }
    }

    /// The big words on a day's own page: "164 days to go", "Today! 🎉".
    static func bigCountdown(_ day: ImportantDay, today: Date) -> String {
        guard let next = day.nextDate(from: today) else { return "A day to remember 💖" }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: today), to: next).day ?? 0
        switch days {
        case 0: return "Today! 🎉"
        case 1: return "Tomorrow! 🎈"
        default: return "\(days.formatted()) days to go"
        }
    }

    /// "70 years", or "The very first day" on the day itself.
    static func years(_ day: ImportantDay, at date: Date) -> String {
        let years = day.years(at: date)
        if years >= 1 { return "\(years) \(years == 1 ? "year" : "years")" }
        let days = day.daysSince(at: date)
        return days == 0 ? "The very first day 💖" : "\(days.formatted()) \(days == 1 ? "day" : "days")"
    }

    /// "25,567 days since".
    static func daysSince(_ day: ImportantDay, at date: Date) -> String {
        let days = day.daysSince(at: date)
        return days == 0 ? "Today" : "\(days.formatted()) \(days == 1 ? "day" : "days") since"
    }

    static func ordinal(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Reminders

/// A reminder at 9 in the morning on the day (every year when it repeats).
enum ImportantDayReminders {
    private static func id(_ day: ImportantDay) -> String { "important-day-\(day.id.uuidString)" }

    static func schedule(_ day: ImportantDay) async {
        cancel(day)
        guard day.remindsMe, await ReminderCenter.requestPermission() else { return }
        let calendar = Calendar.current
        var parts = calendar.dateComponents(day.repeatsYearly ? [.month, .day] : [.year, .month, .day], from: day.date)
        parts.hour = 9
        if !day.repeatsYearly, let fire = calendar.date(from: parts), fire < .now { return }
        let content = UNMutableNotificationContent()
        content.title = "\(day.title) 💖"
        content.body = day.kind == .birthday ? "It's \(day.title) today! Send some love. 🎂"
            : "Today is \(day.title). A day to remember! ✨"
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: day.repeatsYearly)
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id(day), content: content,
                                                                               trigger: trigger))
    }

    static func cancel(_ day: ImportantDay) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id(day)])
    }
}

// MARK: - Little pieces

enum ImportantDayStyle {
    static let berry = Color(hex: 0xC2126B)
    static let plum = Color(hex: 0x7A3A8C)
    static let ink = Color(hex: 0x3B1240)
}

/// The day's photo, or its kind's picture on soft pink when it has none.
struct ImportantDayPhoto: View {
    let day: ImportantDay
    let cornerRadius: CGFloat

    var body: some View {
        GeometryReader { proxy in
            Group {
                if let data = day.photoData ?? day.thumbnailData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        LinearGradient(colors: [Color(hex: 0xFFE3F0), Color(hex: 0xFBC6DE)],
                                       startPoint: .top, endPoint: .bottom)
                        Image(day.kind.art)
                            .resizable()
                            .scaledToFit()
                            .padding(proxy.size.height * 0.12)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}

/// The kind's symbol in a dark round badge (as in the reference).
struct ImportantDayBadge: View {
    let kind: ImportantDayKind
    let size: CGFloat

    var body: some View {
        Image(systemName: kind.symbol)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(Palette.hotPink)
            .frame(width: size, height: size)
            .background(Circle().fill(Color.white))
            .overlay(Circle().strokeBorder(Color(hex: 0xFCE1EE), lineWidth: 2))
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            .accessibilityHidden(true)
    }
}

/// The design's title and words in pink beside the girl.
struct ImportantDayHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("💗 " + title)
                    .font(.rounded(size: 32, weight: .heavy))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0xF0287F), Color(hex: 0xC2126B)],
                                                    startPoint: .top, endPoint: .bottom))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(ImportantDayStyle.plum)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image("ImportantDay/Girl")
                .resizable()
                .scaledToFit()
                .frame(width: 128)
                .accessibilityHidden(true)
        }
        .padding(.top, 4)
    }
}

/// The design's soft pink page with hearts.
struct ImportantDayBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(hex: 0xFDE4EF), Color(hex: 0xFCEAF3), Color(hex: 0xFBDDEB)],
                       startPoint: .top, endPoint: .bottom)
            .overlay(alignment: .topLeading) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: 0xF8B7D3).opacity(0.6))
                    .offset(x: 14, y: 260)
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(hex: 0xF8B7D3).opacity(0.6))
                    .offset(x: 10, y: -120)
            }
            .ignoresSafeArea()
    }
}
