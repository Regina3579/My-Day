import SwiftUI
import SwiftData

/// Create a new to-do, or edit an existing one.
struct NewTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    private let task: TaskItem?

    @State private var title: String
    @State private var notes: String
    @State private var category: TaskCategory
    @State private var date: Date
    @State private var hasTime: Bool
    @State private var time: Date
    @State private var reminderEnabled: Bool
    @State private var reminderDate: Date
    @State private var repeatOption: RepeatOption
    @State private var showPermissionAlert = false
    @State private var confirmDelete = false
    @FocusState private var titleFocused: Bool

    /// A new to-do on `date`.
    init(date: Date, category: TaskCategory = .personal) {
        task = nil
        let nextHour = Self.nextHour(on: date)
        _title = State(initialValue: "")
        _notes = State(initialValue: "")
        _category = State(initialValue: category)
        _date = State(initialValue: date.startOfDay)
        _hasTime = State(initialValue: false)
        _time = State(initialValue: nextHour)
        _reminderEnabled = State(initialValue: false)
        _reminderDate = State(initialValue: nextHour)
        _repeatOption = State(initialValue: .never)
    }

    /// Edit an existing to-do.
    init(task: TaskItem) {
        self.task = task
        let nextHour = Self.nextHour(on: task.date)
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes)
        _category = State(initialValue: task.category)
        _date = State(initialValue: task.date)
        _hasTime = State(initialValue: task.time != nil)
        _time = State(initialValue: task.time ?? nextHour)
        _reminderEnabled = State(initialValue: task.reminderEnabled)
        _reminderDate = State(initialValue: task.reminderDate ?? task.time ?? nextHour)
        _repeatOption = State(initialValue: task.repeatOption)
    }

    /// The next full hour on `day` (or today's next hour when `day` is today).
    private static func nextHour(on day: Date) -> Date {
        let now = Date()
        let base = day.isToday ? now : day.atTime(of: now)
        return Calendar.current.nextDate(after: base, matching: DateComponents(minute: 0),
                                         matchingPolicy: .nextTime) ?? base
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What would you like to do?", text: $title, axis: .vertical)
                        .font(.rounded(.title3, weight: .semibold))
                        .focused($titleFocused)
                    TextField("Add a little note…", text: $notes, axis: .vertical)
                        .font(.rounded(.body))
                        .lineLimit(2...6)
                }

                Section("Category") {
                    CategoryPicker(selection: $category)
                        .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
                }

                Section("When") {
                    DatePicker(selection: $date, displayedComponents: .date) {
                        Label("Date", systemImage: "calendar")
                    }
                    Toggle(isOn: $hasTime.animation()) {
                        Label("Time", systemImage: "clock.fill")
                    }
                    if hasTime {
                        DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    }
                    Picker(selection: $repeatOption) {
                        ForEach(RepeatOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    } label: {
                        Label("Repeat", systemImage: "repeat")
                    }
                }

                Section {
                    Toggle(isOn: $reminderEnabled.animation()) {
                        Label("Remind me", systemImage: "bell.fill")
                    }
                    if reminderEnabled {
                        DatePicker("Alert", selection: $reminderDate, in: Date()...)
                    }
                } header: {
                    Text("Reminder")
                } footer: {
                    Text("My Day sends a gentle notification at the chosen time.")
                }

                if task != nil {
                    Section {
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Label("Delete To-Do", systemImage: "trash")
                        }
                    }
                }
            }
            .font(.rounded(.body))
            .scrollContentBackground(.hidden)
            .background(DreamyBackground(theme: .todos))
            .navigationTitle(task == nil ? "New To-Do" : "Edit To-Do")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.bold)
                        .disabled(title.trimmed.isEmpty)
                }
            }
            .onChange(of: reminderEnabled) { _, isOn in
                if isOn { askForNotifications() }
            }
            .onChange(of: time) { _, newTime in
                // Keep the reminder in step with the task time until the person changes it.
                if !reminderEnabled { reminderDate = date.atTime(of: newTime) }
            }
            .alert("Notifications are off", isPresented: $showPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                Button("Not Now", role: .cancel) {}
            } message: {
                Text("Allow notifications for My Day in Settings to get reminders.")
            }
            .confirmationDialog("Delete this to-do?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive, action: deleteTask)
            }
            .task {
                if task == nil { titleFocused = true }
            }
        }
        .presentationDragIndicator(.visible)
    }

    /// Asks for notification permission the first time a reminder is switched on.
    private func askForNotifications() {
        Task {
            if !(await ReminderCenter.requestPermission()) {
                reminderEnabled = false
                showPermissionAlert = true
            }
        }
    }

    private func save() {
        let cleanTitle = title.trimmed
        guard !cleanTitle.isEmpty else { return }
        let day = date.startOfDay
        let taskTime = hasTime ? day.atTime(of: time) : nil

        let saved: TaskItem
        if let task {
            task.title = cleanTitle
            task.notes = notes.trimmed
            task.category = category
            task.date = day
            task.time = taskTime
            task.reminderEnabled = reminderEnabled
            task.reminderDate = reminderEnabled ? reminderDate : nil
            task.repeatOption = repeatOption
            saved = task
        } else {
            saved = TaskItem(title: cleanTitle, notes: notes.trimmed, category: category, date: day,
                             time: taskTime, reminderEnabled: reminderEnabled, reminderDate: reminderDate,
                             repeatOption: repeatOption)
            context.insert(saved)
        }
        ReminderCenter.sync(saved)
        Haptics.success()
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

/// Colourful category chips.
struct CategoryPicker: View {
    @Binding var selection: TaskCategory

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
            ForEach(TaskCategory.allCases) { category in
                let isOn = selection == category
                Button {
                    withAnimation(.snappy) { selection = category }
                    Haptics.tap()
                } label: {
                    Label(category.label, systemImage: category.symbol)
                        .font(.rounded(.caption, weight: .bold))
                        .foregroundStyle(isOn ? Color.white : category.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            Capsule().fill(isOn ? AnyShapeStyle(category.color.gradient)
                                                : AnyShapeStyle(category.color.opacity(0.12)))
                        )
                }
                .buttonStyle(.borderless)
                .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
            }
        }
    }
}
