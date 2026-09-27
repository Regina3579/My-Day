import SwiftData
import SwiftUI

/// ⚡ Quick Add: type, press Add (or Return), done. The to-do goes on the day
/// with no time, reminder or repeat. The sheet stays open for the next one.
struct QuickAddTaskSheet: View {
    let day: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var title = ""
    @State private var category: TaskCategory?
    @State private var added: [String] = []
    @FocusState private var isFocused: Bool

    private var canAdd: Bool { !title.trimmed.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("⚡ Quick Add")
                    .font(.rounded(.title3, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Done") { dismiss() }
                    .font(.rounded(.body, weight: .bold))
                    .foregroundStyle(Palette.hotPink)
                    .frame(minWidth: 44, minHeight: 44)
            }

            HStack(spacing: 8) {
                TextField("What needs doing?", text: $title)
                    .font(.rounded(.body, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .submitLabel(.done)
                    .focused($isFocused)
                    .onSubmit { add() }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 50)
                    .background(Capsule().fill(Color.white))
                    .overlay(Capsule().strokeBorder(Palette.hotPink.opacity(isFocused ? 0.5 : 0.2), lineWidth: 1.5))

                Button(action: add) {
                    Text("Add")
                        .font(.rounded(.body, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 20)
                        .frame(minHeight: 50)
                        .background(Capsule().fill(Palette.hotPink.gradient))
                        .opacity(canAdd ? 1 : 0.5)
                }
                .buttonStyle(PressScaleStyle())
                .disabled(!canAdd)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(TaskCategory.allCases) { option in
                        let isOn = category == option
                        Button {
                            Haptics.tap()
                            withAnimation(.snappy) { category = isOn ? nil : option }
                        } label: {
                            Text("\(option.emoji) \(option.label)")
                                .font(.rounded(.caption, weight: .bold))
                                .foregroundStyle(isOn ? Color.white : Palette.ink)
                                .padding(.horizontal, 11)
                                .frame(minHeight: 34)
                                .background(Capsule().fill(isOn ? AnyShapeStyle(option.color.gradient)
                                                               : AnyShapeStyle(Color.white.opacity(0.8))))
                                .contentShape(Capsule())
                        }
                        .buttonStyle(PressScaleStyle())
                        .accessibilityLabel(option.label)
                        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
                    }
                }
                .padding(.vertical, 2)
            }

            Text(status)
                .font(.rounded(.caption, weight: .semibold))
                .foregroundStyle(added.isEmpty ? Palette.inkSoft : Palette.mint)
                .lineLimit(1)
                .contentTransition(.opacity)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .presentationDetents([.height(236)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
        .presentationBackground(
            LinearGradient(colors: [Color(hex: 0xFFF5FA), Color(hex: 0xFFEAF3)], startPoint: .top, endPoint: .bottom)
        )
        .task { isFocused = true }
    }

    private var status: String {
        if let last = added.last {
            return added.count == 1 ? "Added “\(last)” ✓" : "Added \(added.count) to-dos ✓ — keep going!"
        }
        let dayText = day.isToday ? "today" : day.formatted(.dateTime.weekday(.wide))
        return "Adds to \(dayText) · no time or reminder · category optional"
    }

    private func add() {
        let clean = title.trimmed
        guard !clean.isEmpty else { return }
        withAnimation(.snappy) {
            context.insert(TaskItem(title: clean, category: category ?? .personal, date: day))
            added.append(clean)
        }
        title = ""
        Haptics.success()
        // Stay ready for the next one.
        DispatchQueue.main.async { isFocused = true }
    }
}
