import SwiftUI
import SwiftData

/// Create or edit a to-do: title, note, day, priority star and reminder.
struct TaskEditorView: View {
    enum Mode {
        case new(day: Date, priority: Bool)
        case edit(TaskItem)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    private let mode: Mode
    @State private var title: String
    @State private var notes: String
    @State private var day: Date
    @State private var isPriority: Bool
    @State private var hasReminder: Bool
    @State private var reminderTime: Date
    @State private var confirmDelete = false
    @FocusState private var titleFocused: Bool

    init(mode: Mode) {
        self.mode = mode
        let nextHour = Calendar.current.nextDate(after: .now, matching: DateComponents(minute: 0),
                                                 matchingPolicy: .nextTime) ?? .now
        switch mode {
        case .new(let day, let priority):
            _title = State(initialValue: "")
            _notes = State(initialValue: "")
            _day = State(initialValue: day)
            _isPriority = State(initialValue: priority)
            _hasReminder = State(initialValue: false)
            _reminderTime = State(initialValue: nextHour)
        case .edit(let task):
            _title = State(initialValue: task.title)
            _notes = State(initialValue: task.notes)
            _day = State(initialValue: task.day)
            _isPriority = State(initialValue: task.isPriority)
            _hasReminder = State(initialValue: task.reminderAt != nil)
            _reminderTime = State(initialValue: task.reminderAt ?? nextHour)
        }
    }

    private var isNew: Bool {
        switch mode {
        case .new: true
        case .edit: false
        }
    }

    private var navigationTitle: String {
        if !isNew { return "Edit To-Do" }
        return isPriority ? "New Priority" : "New To-Do"
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

                Section {
                    DatePicker(selection: $day, displayedComponents: .date) {
                        Label("Day", systemImage: "calendar")
                    }
                    Toggle(isOn: $isPriority) {
                        Label("Today's Priority", systemImage: "star.fill")
                    }
                    .tint(Palette.honey)
                }

                Section {
                    Toggle(isOn: $hasReminder.animation()) {
                        Label("Remind me", systemImage: "bell.fill")
                    }
                    if hasReminder {
                        DatePicker(selection: $reminderTime, displayedComponents: .hourAndMinute) {
                            Label("Time", systemImage: "clock.fill")
                        }
                    }
                } footer: {
                    Text("A gentle notification arrives on the chosen day and time.")
                        .font(.rounded(.caption))
                }

                if !isNew {
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
            .background(DreamyBackground(theme: isPriority ? .priority : .todos))
            .navigationTitle(navigationTitle)
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
            .confirmationDialog("Delete this to-do?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive, action: deleteTask)
            }
            .task {
                if isNew { titleFocused = true }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func save() {
        let cleanTitle = title.trimmed
        guard !cleanTitle.isEmpty else { return }
        let reminder = hasReminder ? day.atTime(of: reminderTime) : nil

        let task: TaskItem
        switch mode {
        case .new:
            task = TaskItem(title: cleanTitle, notes: notes.trimmed, day: day,
                            isPriority: isPriority, reminderAt: reminder)
            context.insert(task)
        case .edit(let existing):
            existing.title = cleanTitle
            existing.notes = notes.trimmed
            existing.day = day.startOfDay
            existing.isPriority = isPriority
            existing.reminderAt = reminder
            task = existing
        }
        ReminderCenter.sync(task)
        Haptics.success()
        dismiss()
    }

    private func deleteTask() {
        guard case .edit(let task) = mode else { return }
        ReminderCenter.cancel(taskID: task.uuid)
        dismiss()
        // Delete after the sheet has gone, so no view reads the removed model.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            context.delete(task)
        }
    }
}
