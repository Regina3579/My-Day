import SwiftUI
import SwiftData

/// Create a new priority, or edit an existing one (type it, or tap 🎙 and say it).
struct NewPrioritySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    private let priority: Priority?
    @State private var title: String
    @State private var date: Date
    @State private var confirmDelete = false
    @State private var isListening = false
    @FocusState private var titleFocused: Bool

    init(date: Date) {
        priority = nil
        _title = State(initialValue: "")
        _date = State(initialValue: date.startOfDay)
    }

    init(priority: Priority) {
        self.priority = priority
        _title = State(initialValue: priority.title)
        _date = State(initialValue: priority.date)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        TextField(isListening ? "Listening… say your priority" : "What matters most?",
                                  text: $title, axis: .vertical)
                            .font(.rounded(.title3, weight: .semibold))
                            .focused($titleFocused)
                        DictationButton(text: $title, diameter: 36, isListening: $isListening) {
                            titleFocused = false
                        }
                    }
                } footer: {
                    Text("Tip: pick one to three priorities a day. ⭐")
                }

                Section {
                    DatePicker(selection: $date, displayedComponents: .date) {
                        Label("Day", systemImage: "calendar")
                    }
                }

                if priority != nil {
                    Section {
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Label("Delete Priority", systemImage: "trash")
                        }
                    }
                }
            }
            .font(.rounded(.body))
            .scrollContentBackground(.hidden)
            .background(DreamyBackground(theme: .priority))
            .navigationTitle(priority == nil ? "New Priority" : "Edit Priority")
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
            .confirmationDialog("Delete this priority?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive, action: deletePriority)
            }
            .task {
                if priority == nil { titleFocused = true }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        let cleanTitle = title.trimmed
        guard !cleanTitle.isEmpty else { return }
        let day = date.startOfDay

        if let priority {
            if !priority.date.isSameDay(as: day) {
                priority.order = nextOrder(on: day)
            }
            priority.title = cleanTitle
            priority.date = day
        } else {
            context.insert(Priority(title: cleanTitle, date: day, order: nextOrder(on: day)))
        }
        Haptics.success()
        dismiss()
    }

    /// One past the highest position already used on `day`.
    private func nextOrder(on day: Date) -> Int {
        let start = day.startOfDay
        let end = start.nextDay
        let descriptor = FetchDescriptor<Priority>(predicate: #Predicate { $0.date >= start && $0.date < end })
        let orders = ((try? context.fetch(descriptor)) ?? []).map(\.order)
        return (orders.max() ?? -1) + 1
    }

    private func deletePriority() {
        guard let priority else { return }
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            context.delete(priority)
        }
    }
}
