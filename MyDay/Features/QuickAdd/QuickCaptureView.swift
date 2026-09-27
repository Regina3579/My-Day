import SwiftUI
import SwiftData

/// Opened by the pink + button: jot down a to-do, a priority or a journal line in seconds.
struct QuickCaptureView: View {
    enum Kind: String, CaseIterable, Identifiable {
        case todo, priority, journal

        var id: String { rawValue }

        var title: String {
            switch self {
            case .todo: "To-Do"
            case .priority: "Priority"
            case .journal: "Journal"
            }
        }

        var icon: String {
            switch self {
            case .todo: "checkmark.square.fill"
            case .priority: "star.fill"
            case .journal: "book.closed.fill"
            }
        }

        var tint: Color {
            switch self {
            case .todo: Palette.grape
            case .priority: Palette.honey
            case .journal: Palette.hotPink
            }
        }

        var theme: SectionTheme {
            switch self {
            case .todo: .todos
            case .priority: .priority
            case .journal: .journal
            }
        }

        var placeholder: String {
            switch self {
            case .todo: "What do you want to do today?"
            case .priority: "What matters most today?"
            case .journal: "What's on your mind?"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @State private var kind: Kind = .todo
    @State private var text = ""
    @State private var mood: Mood = .happy
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                HStack(spacing: 10) {
                    ForEach(Kind.allCases) { option in
                        kindButton(option)
                    }
                }

                TextField(kind.placeholder, text: $text, axis: .vertical)
                    .font(.rounded(.title3, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(3...8)
                    .focused($focused)
                    .cuteCard(tint: kind.tint)

                if kind == .journal {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Mood.allCases) { option in
                                Button {
                                    mood = option
                                    Haptics.tap()
                                } label: {
                                    Text(option.emoji)
                                        .font(.system(size: 26))
                                        .frame(width: 46, height: 46)
                                        .background(Circle().fill(option == mood ? option.color.opacity(0.3) : Color.white.opacity(0.7)))
                                        .overlay(Circle().strokeBorder(option == mood ? option.color : Color.clear, lineWidth: 2))
                                }
                                .buttonStyle(PressScaleStyle())
                                .accessibilityLabel(option.label)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Button(action: save) {
                    Label("Save", systemImage: "heart.fill")
                }
                .buttonStyle(PillButtonStyle(tint: kind.tint))
                .disabled(text.trimmed.isEmpty)
                .opacity(text.trimmed.isEmpty ? 0.5 : 1)

                Spacer(minLength: 0)
            }
            .padding(20)
            .animation(.snappy, value: kind)
            .background(DreamyBackground(theme: kind.theme))
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                try? await Task.sleep(for: .milliseconds(350))
                focused = true
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func kindButton(_ option: Kind) -> some View {
        let isSelected = option == kind
        return Button {
            kind = option
            Haptics.tap()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.title2)
                Text(option.title)
                    .font(.rounded(.caption, weight: .bold))
            }
            .foregroundStyle(isSelected ? Color.white : option.tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(option.tint.gradient) : AnyShapeStyle(Color.white.opacity(0.85)))
            )
            .shadow(color: option.tint.opacity(isSelected ? 0.35 : 0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityAddTraits(isSelected ? AccessibilityTraits.isSelected : [])
    }

    private func save() {
        let clean = text.trimmed
        guard !clean.isEmpty else { return }
        switch kind {
        case .todo:
            context.insert(TaskItem(title: clean, day: appState.today))
        case .priority:
            context.insert(TaskItem(title: clean, day: appState.today, isPriority: true))
        case .journal:
            context.insert(JournalEntry(date: .now, body: clean, mood: mood))
        }
        Haptics.success()
        dismiss()
    }
}
