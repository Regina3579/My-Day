import PhotosUI
import SwiftData
import SwiftUI

/// Which part of the task sheet opens first.
enum TaskSheetFocus: String {
    case title, when, reminder, repeatRule, photo, note
}

/// The pastel bottom sheet for adding a to-do, or seeing and changing one.
/// Only the title is required; category, date, time, reminder, repeat, photo and note are optional.
struct NewTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    private let task: TaskItem?
    private let focus: TaskSheetFocus?
    private let onSaved: ((TaskItem) -> Void)?

    @State private var title: String
    @State private var notes: String
    @State private var category: CategoryChoice
    @State private var date: Date
    @State private var hasTime: Bool
    @State private var time: Date
    @State private var reminderEnabled: Bool
    @State private var reminderDate: Date
    @State private var repeatOption: RepeatOption
    /// Small preview of the photo (the saved one, or a newly picked one).
    @State private var thumbnail: Data?
    /// Full-size photo picked in this sheet.
    @State private var newPhoto: Data?
    @State private var photoChanged: Bool
    @State private var expanded: TaskSheetFocus?
    @State private var detent: PresentationDetent

    @State private var showsTitleHint = false
    @State private var showsNotificationAlert = false
    @State private var showsCameraAlert = false
    @State private var showsPhotoError = false
    @State private var confirmDelete = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showsLibrary = false
    @State private var showsCamera = false
    @State private var showsViewer = false
    @State private var isLoadingPhoto = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case title, note
    }

    /// A new to-do on `date`.
    init(date: Date, category: CategoryChoice = .builtIn(.personal), focus: TaskSheetFocus? = nil,
         onSaved: ((TaskItem) -> Void)? = nil) {
        self.init(existing: nil, draft: TaskDraft(day: date, choice: category), focus: focus, onSaved: onSaved)
    }

    /// A new to-do filled in from Voice Add (or anything else), for the person to check.
    init(draft: TaskDraft, focus: TaskSheetFocus? = nil, onSaved: ((TaskItem) -> Void)? = nil) {
        self.init(existing: nil, draft: draft, focus: focus, onSaved: onSaved)
    }

    /// An existing to-do.
    init(task: TaskItem, focus: TaskSheetFocus? = nil) {
        var draft = TaskDraft(day: task.date, choice: task.choice)
        draft.title = task.title
        draft.notes = task.notes
        draft.time = task.time
        draft.reminderEnabled = task.reminderEnabled
        draft.reminderDate = task.reminderDate
        draft.repeatOption = task.repeatOption
        self.init(existing: task, draft: draft, focus: focus, onSaved: nil)
    }

    private init(existing: TaskItem?, draft: TaskDraft, focus: TaskSheetFocus?, onSaved: ((TaskItem) -> Void)?) {
        task = existing
        self.focus = focus
        self.onSaved = onSaved
        let nextHour = Self.nextHour(on: draft.day)
        _title = State(initialValue: draft.title)
        _notes = State(initialValue: draft.notes)
        _category = State(initialValue: draft.choice)
        _date = State(initialValue: draft.day)
        _hasTime = State(initialValue: draft.time != nil)
        _time = State(initialValue: draft.time ?? nextHour)
        _reminderEnabled = State(initialValue: draft.reminderEnabled)
        _reminderDate = State(initialValue: draft.reminderDate ?? draft.time ?? nextHour)
        _repeatOption = State(initialValue: draft.repeatOption)
        _thumbnail = State(initialValue: existing?.photoThumbnail ?? draft.photo?.thumbnail)
        _newPhoto = State(initialValue: draft.photo?.photo)
        _photoChanged = State(initialValue: draft.photo != nil)
        _expanded = State(initialValue: focus == .title ? nil : focus)
        _detent = State(initialValue: existing != nil && focus == nil ? .medium : .large)
    }

    /// The next full hour on `day` (or today's next hour when `day` is today).
    private static func nextHour(on day: Date) -> Date {
        let now = Date()
        let base = day.isToday ? now : day.atTime(of: now)
        return Calendar.current.nextDate(after: base, matching: DateComponents(minute: 0),
                                         matchingPolicy: .nextTime) ?? base
    }

    /// In photo mode (the Photo button) the photo comes first.
    private var photoFirst: Bool { task == nil && focus == .photo }

    // The body is split into small steps so the compiler can type-check each one quickly.
    var body: some View {
        withDialogs
            .presentationDetents([.medium, .large], selection: $detent)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            .presentationBackground(Self.background)
            .task { focusTitleIfNeeded() }
    }

    private static let background = LinearGradient(
        colors: [Color(hex: 0xFFF5FA), Color(hex: 0xF7F0FF)], startPoint: .top, endPoint: .bottom
    )

    /// The scrolling form with the save button pinned to the bottom.
    private var form: some View {
        ScrollViewReader { scroller in
            ScrollView {
                formContent
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                saveBar
            }
            .task {
                await scrollToFocus(with: scroller)
            }
        }
    }

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            if photoFirst {
                photoSection
            }
            titleField
            categorySection
            options
            if task != nil {
                deleteButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }

    /// Keeps the reminder and the title hint in step, and loads a picked photo.
    private var withChangeHandlers: some View {
        form
            .onChange(of: reminderEnabled) { _, isOn in
                if isOn { askForNotifications() }
            }
            .onChange(of: time) { _, newTime in
                // Keep the reminder in step with the task time until the person turns it on.
                if !reminderEnabled { reminderDate = date.startOfDay.atTime(of: newTime) }
            }
            .onChange(of: title) { _, newTitle in
                hideTitleHint(for: newTitle)
            }
            .onChange(of: pickerItem) { _, item in
                loadPicked(item)
            }
    }

    /// The photo library, the camera and the full-size photo.
    private var withPhotoScreens: some View {
        withChangeHandlers
            .photosPicker(isPresented: $showsLibrary, selection: $pickerItem, matching: .images)
            .fullScreenCover(isPresented: $showsCamera) {
                cameraScreen
            }
            .fullScreenCover(isPresented: $showsViewer) {
                PhotoViewer(image: viewerImage)
            }
    }

    private var cameraScreen: some View {
        CameraPicker { image in usePhoto(image) }
            .ignoresSafeArea()
    }

    private var withDialogs: some View {
        withPhotoScreens
            .alert("Notifications are off", isPresented: $showsNotificationAlert) {
                settingsButtons
            } message: {
                Text("Allow notifications for My Day in Settings to get reminders.")
            }
            .alert("Camera access is off", isPresented: $showsCameraAlert) {
                settingsButtons
            } message: {
                Text("Allow camera access for My Day in Settings, or choose a photo from your library.")
            }
            .alert("That photo couldn't be added", isPresented: $showsPhotoError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please try another photo.")
            }
            .confirmationDialog("Delete this to-do?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { deleteTask() }
            }
    }

    private func focusTitleIfNeeded() {
        let isNewTask = task == nil && !photoFirst && focus == nil
        if isNewTask || focus == .title {
            focusedField = .title
        }
    }

    /// Opens at the section asked for (Change date/time, Add reminder, Repeat).
    private func scrollToFocus(with scroller: ScrollViewProxy) async {
        guard let focus, focus != .title, focus != .photo else { return }
        try? await Task.sleep(for: .milliseconds(300))
        withAnimation { scroller.scrollTo(focus, anchor: .center) }
    }

    private func hideTitleHint(for newTitle: String) {
        guard showsTitleHint, !newTitle.trimmed.isEmpty else { return }
        withAnimation { showsTitleHint = false }
    }

    // MARK: Sections

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(task == nil ? "New Task ✨" : "Task Details")
                    .font(.rounded(.title2, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(task == nil ? "What would you like to do?" : "Change anything you like 💕")
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(Palette.inkSoft)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Palette.inkSoft)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel("Close")
        }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            SheetLabel(text: "Task")
            TextField("", text: $title)
                .font(.rounded(.title3, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .submitLabel(.done)
                .focused($focusedField, equals: .title)
                .onSubmit { focusedField = nil }
                .padding(.horizontal, 16)
                .frame(minHeight: 54)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(titleBorder, lineWidth: 1.5)
                )
                .accessibilityLabel("Task name")
            if showsTitleHint {
                Text("Please give your task a name 💕")
                    .font(.rounded(.caption, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xD7263D))
                    .transition(.opacity)
            }
        }
    }

    private var titleBorder: Color {
        if showsTitleHint { return Color(hex: 0xD7263D) }
        return focusedField == .title ? Palette.hotPink.opacity(0.6) : Palette.bubblegum.opacity(0.25)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SheetLabel(text: "Category")
            CategoryPicker(selection: $category)
        }
    }

    private var options: some View {
        VStack(spacing: 10) {
            whenRow
            reminderRow
            repeatRow
            if !photoFirst {
                photoRow
            }
            noteRow
        }
    }

    private var whenRow: some View {
        OptionRow(emoji: "📅", title: "Date & Time", value: whenSummary, isExpanded: expanded == .when) {
            toggle(.when)
        } panel: {
            whenPanel
        }
        .id(TaskSheetFocus.when)
    }

    private var reminderRow: some View {
        OptionRow(emoji: "🔔", title: "Reminder", value: reminderSummary, isExpanded: expanded == .reminder) {
            toggle(.reminder)
        } panel: {
            reminderPanel
        }
        .id(TaskSheetFocus.reminder)
    }

    private var repeatRow: some View {
        OptionRow(emoji: "🔁", title: "Repeat", value: repeatOption.label, isExpanded: expanded == .repeatRule) {
            toggle(.repeatRule)
        } panel: {
            repeatPanel
        }
        .id(TaskSheetFocus.repeatRule)
    }

    private var photoRow: some View {
        let value = thumbnail == nil ? "None" : "Added"
        return OptionRow(emoji: "📷", title: "Photo", value: value, thumbnail: thumbnailImage,
                         isExpanded: expanded == .photo) {
            toggle(.photo)
        } panel: {
            photoPanel
        }
        .id(TaskSheetFocus.photo)
    }

    private var noteRow: some View {
        let value = notes.trimmed.isEmpty ? "None" : notes.trimmed
        return OptionRow(emoji: "📝", title: "Note", value: value, isExpanded: expanded == .note) {
            toggle(.note)
        } panel: {
            noteField
        }
        .id(TaskSheetFocus.note)
    }

    private var noteField: some View {
        TextField("Add a little note…", text: $notes, axis: .vertical)
            .font(.rounded(.body))
            .lineLimit(2...6)
            .focused($focusedField, equals: .note)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white))
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SheetLabel(text: "Photo")
            photoPanel
        }
    }

    private var photoPanel: some View {
        TaskPhotoPanel(
            image: thumbnailImage,
            isLoading: isLoadingPhoto,
            onTake: { takePhoto() },
            onChoose: { showsLibrary = true },
            onView: { showsViewer = true },
            onRemove: { removePhoto() }
        )
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            confirmDelete = true
        } label: {
            Label("Delete Task", systemImage: "trash")
                .font(.rounded(.subheadline, weight: .bold))
                .foregroundStyle(Color(hex: 0xD7263D))
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Capsule().fill(Color.white.opacity(0.7)))
        }
        .buttonStyle(PressScaleStyle())
        .padding(.top, 4)
    }

    private static let saveBarFade = LinearGradient(
        colors: [Color(hex: 0xF7F0FF).opacity(0), Color(hex: 0xF7F0FF)], startPoint: .top, endPoint: .center
    )

    private var saveBar: some View {
        Button(action: save) {
            Text(task == nil ? "Add Task ✨" : "Save Changes ✨")
        }
        .buttonStyle(PillButtonStyle())
        .opacity(title.trimmed.isEmpty ? 0.6 : 1)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Self.saveBarFade)
    }

    // MARK: Panels

    private var whenPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                DayChip(title: "Today", isOn: date.isToday) { date = Date().startOfDay }
                DayChip(title: "Tomorrow", isOn: date.isSameDay(as: Date().adding(days: 1))) {
                    date = Date().adding(days: 1)
                }
                Spacer(minLength: 0)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .labelsHidden()
            }
            Toggle(isOn: $hasTime.animation()) {
                Label("Add a time", systemImage: "clock.fill")
                    .font(.rounded(.subheadline, weight: .semibold))
            }
            .tint(Palette.hotPink)
            if hasTime {
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    .font(.rounded(.subheadline, weight: .semibold))
            }
        }
    }

    private var reminderPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $reminderEnabled.animation()) {
                Label("Remind me", systemImage: "bell.fill")
                    .font(.rounded(.subheadline, weight: .semibold))
            }
            .tint(Palette.hotPink)
            if reminderEnabled {
                DatePicker("Alert", selection: $reminderDate, in: Date()...)
                    .font(.rounded(.subheadline, weight: .semibold))
                if hasTime, reminderDate != date.startOfDay.atTime(of: time) {
                    Button("Use the task time") {
                        reminderDate = date.startOfDay.atTime(of: time)
                    }
                    .font(.rounded(.caption, weight: .bold))
                }
            }
            Text("My Day sends a gentle notification at this time.")
                .font(.rounded(.caption))
                .foregroundStyle(Palette.inkSoft)
        }
    }

    private var repeatPanel: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
            ForEach(RepeatOption.allCases) { option in
                DayChip(title: option.label, isOn: repeatOption == option) {
                    repeatOption = option
                }
            }
        }
    }

    // MARK: Summaries

    private var whenSummary: String {
        let day: String
        if date.isToday {
            day = "Today"
        } else if date.isSameDay(as: Date().adding(days: 1)) {
            day = "Tomorrow"
        } else {
            day = date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        }
        guard hasTime else { return day }
        return day + " · " + time.formatted(date: .omitted, time: .shortened)
    }

    private var reminderSummary: String {
        guard reminderEnabled else { return "Off" }
        if reminderDate.isSameDay(as: date) {
            return reminderDate.formatted(date: .omitted, time: .shortened)
        }
        return reminderDate.formatted(.dateTime.day().month(.abbreviated).hour().minute())
    }

    private var thumbnailImage: UIImage? {
        thumbnail.flatMap(UIImage.init(data:))
    }

    private var viewerImage: UIImage? {
        let full = newPhoto ?? (photoChanged ? nil : task?.photoData)
        return (full ?? thumbnail).flatMap(UIImage.init(data:))
    }

    // MARK: Actions

    private func toggle(_ section: TaskSheetFocus) {
        Haptics.tap()
        focusedField = nil
        withAnimation(.snappy) {
            expanded = expanded == section ? nil : section
        }
    }

    @ViewBuilder
    private var settingsButtons: some View {
        Button("Open Settings") {
            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
        }
        Button("Not Now", role: .cancel) {}
    }

    /// Asks for notification permission the first time a reminder is switched on.
    private func askForNotifications() {
        Task {
            if !(await ReminderCenter.requestPermission()) {
                reminderEnabled = false
                showsNotificationAlert = true
            }
        }
    }

    private func takePhoto() {
        Task {
            if await CameraAccess.request() {
                showsCamera = true
            } else {
                showsCameraAlert = true
            }
        }
    }

    private func loadPicked(_ item: PhotosPickerItem?) {
        guard let item else { return }
        isLoadingPhoto = true
        Task {
            let raw = try? await item.loadTransferable(type: Data.self)
            let prepared = await Task.detached(priority: .userInitiated) {
                raw.flatMap(PhotoProcessor.prepare)
            }.value
            finishPhoto(prepared)
            pickerItem = nil
        }
    }

    private func usePhoto(_ image: UIImage) {
        isLoadingPhoto = true
        let raw = image.jpegData(compressionQuality: 0.92)
        Task {
            let prepared = await Task.detached(priority: .userInitiated) {
                raw.flatMap(PhotoProcessor.prepare)
            }.value
            finishPhoto(prepared)
        }
    }

    private func finishPhoto(_ prepared: PhotoProcessor.Output?) {
        isLoadingPhoto = false
        guard let prepared else {
            showsPhotoError = true
            return
        }
        withAnimation(.snappy) {
            thumbnail = prepared.thumbnail
            newPhoto = prepared.photo
            photoChanged = true
        }
        Haptics.tap()
    }

    private func removePhoto() {
        withAnimation(.snappy) {
            thumbnail = nil
            newPhoto = nil
            photoChanged = true
        }
    }

    private func save() {
        let cleanTitle = title.trimmed
        guard !cleanTitle.isEmpty else {
            withAnimation { showsTitleHint = true }
            focusedField = .title
            Haptics.tap()
            return
        }
        let day = date.startOfDay
        let taskTime = hasTime ? day.atTime(of: time) : nil

        let saved: TaskItem
        if let task {
            task.title = cleanTitle
            task.notes = notes.trimmed
            task.choice = category
            task.date = day
            task.time = taskTime
            task.reminderEnabled = reminderEnabled
            task.reminderDate = reminderEnabled ? reminderDate : nil
            task.repeatOption = repeatOption
            saved = task
        } else {
            saved = TaskItem(title: cleanTitle, notes: notes.trimmed, date: day,
                             time: taskTime, reminderEnabled: reminderEnabled, reminderDate: reminderDate,
                             repeatOption: repeatOption)
            context.insert(saved)
            saved.choice = category
        }
        if photoChanged {
            saved.photoData = newPhoto
            saved.photoThumbnail = thumbnail
        }

        ReminderCenter.sync(saved)
        if saved.activeReminder != nil {
            // A reminder that came from Voice Add has not asked for permission yet.
            Task {
                if await ReminderCenter.requestPermission() { ReminderCenter.sync(saved) }
            }
        }
        Haptics.success()
        onSaved?(saved)
        dismiss()
    }

    private func deleteTask() {
        guard let task else { return }
        dismiss()
        // Delete after the sheet has gone, so no view reads the removed model.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            TaskActions.delete(task, in: context)
        }
    }
}

// MARK: - Pieces

/// Small caps label above a section of the task and category sheets.
struct SheetLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.rounded(.footnote, weight: .heavy))
            .foregroundStyle(Palette.berry.opacity(0.8))
            .textCase(.uppercase)
            .accessibilityAddTraits(.isHeader)
    }
}

/// A row that opens a small panel: "📅 Date & Time · Today ⌄".
private struct OptionRow<Panel: View>: View {
    let emoji: String
    let title: String
    let value: String
    var thumbnail: UIImage?
    let isExpanded: Bool
    let toggle: () -> Void
    @ViewBuilder let panel: () -> Panel

    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggle) {
                HStack(spacing: 12) {
                    Text(emoji)
                        .font(.system(size: 19))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white))
                        .accessibilityHidden(true)
                    Text(title)
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(Palette.ink)
                    Spacer(minLength: 8)
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 34, height: 34)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .accessibilityHidden(true)
                    } else {
                        Text(value)
                            .font(.rounded(.subheadline, weight: .medium))
                            .foregroundStyle(Palette.inkSoft)
                            .lineLimit(1)
                    }
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Palette.inkSoft)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(value)
            .accessibilityHint(isExpanded ? "Hides the options" : "Shows the options")
            .accessibilityAddTraits(.isButton)

            if isExpanded {
                panel()
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                    .transition(.opacity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white, lineWidth: 1.2)
        )
    }
}

/// Small pill for quick choices (Today, Tomorrow, repeat options).
private struct DayChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            withAnimation(.snappy) { action() }
        } label: {
            Text(title)
                .font(.rounded(.subheadline, weight: .bold))
                .foregroundStyle(isOn ? Color.white : Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 14)
                .frame(minHeight: 38)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(isOn ? AnyShapeStyle(Palette.hotPink.gradient)
                                               : AnyShapeStyle(Color(hex: 0xFFF1F7))))
                .contentShape(Capsule())
        }
        .buttonStyle(PressScaleStyle())
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
    }
}

/// Personal · Work · Health · Learning · Shopping, then the categories the person added.
struct CategoryPicker: View {
    @Binding var selection: CategoryChoice
    /// Templates use only the five built-in categories.
    var includesCustom = true
    @Query(sort: \CustomCategory.createdAt) private var customs: [CustomCategory]

    private var choices: [CategoryChoice] {
        let builtIn = TaskCategory.allCases.map(CategoryChoice.builtIn)
        return includesCustom ? builtIn + customs.map(CategoryChoice.custom) : builtIn
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
            ForEach(choices, id: \.key) { choice in
                option(choice)
            }
        }
    }

    private func option(_ choice: CategoryChoice) -> some View {
        let isOn = selection == choice
        return Button {
            withAnimation(.snappy) { selection = choice }
            Haptics.tap()
        } label: {
            HStack(spacing: 5) {
                Text(choice.emoji)
                Text(choice.label)
                    .foregroundStyle(isOn ? Color.white : Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.rounded(.subheadline, weight: .bold))
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(
                Capsule().fill(isOn ? AnyShapeStyle(choice.color.gradient)
                                    : AnyShapeStyle(Color.white.opacity(0.85)))
            )
            .overlay(Capsule().strokeBorder(choice.color.opacity(isOn ? 0 : 0.25), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(choice.label)
        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
    }
}

extension CategoryPicker {
    /// Only the five built-in categories (for templates).
    init(builtIn selection: Binding<TaskCategory>) {
        self.init(
            selection: Binding(
                get: { CategoryChoice.builtIn(selection.wrappedValue) },
                set: { choice in
                    if case .builtIn(let category) = choice {
                        selection.wrappedValue = category
                    }
                }
            ),
            includesCustom: false
        )
    }
}
