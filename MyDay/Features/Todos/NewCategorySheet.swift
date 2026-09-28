import SwiftData
import SwiftUI

/// "New Category", from the ＋ chip on the To-Dos screen: a name, an emoji and a colour.
struct NewCategorySheet: View {
    /// Called with the new category once it is saved.
    let onAdded: (CustomCategory) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomCategory.createdAt) private var customs: [CustomCategory]
    @State private var name = ""
    @State private var emoji = "✨"
    /// `nil` until the person picks one: then the next colour not used yet.
    @State private var colorIndex: Int?
    @FocusState private var nameFocused: Bool

    private static let emojis = [
        "✨", "💖", "🏠", "🎨", "✈️", "🐶", "💰", "🎵",
        "🍳", "🧘‍♀️", "🎁", "🌱", "📌", "⚽️", "🎓", "🧺"
    ]

    private var trimmedName: String { name.trimmed }

    /// A built-in or added category already has this name.
    private var isTaken: Bool {
        let wanted = trimmedName.lowercased()
        return TaskCategory.allCases.contains { $0.label.lowercased() == wanted }
            || customs.contains { $0.name.trimmed.lowercased() == wanted }
    }

    private var canAdd: Bool { !trimmedName.isEmpty && !isTaken }

    private var chosenColor: Int {
        colorIndex ?? customs.count % CategoryPalette.colors.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    nameField
                    emojiGrid
                    colourRow
                    preview
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: add)
                        .fontWeight(.bold)
                        .disabled(!canAdd)
                }
            }
            .task { nameFocused = true }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(Color(hex: 0xFFF5F9))
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            SheetLabel(text: "Name")
            TextField("", text: $name)
                .font(.rounded(.title3, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .focused($nameFocused)
                .submitLabel(.done)
                .onSubmit { if canAdd { add() } }
                .padding(.horizontal, 16)
                .frame(minHeight: 52)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Palette.bubblegum.opacity(nameFocused ? 0.6 : 0.3), lineWidth: 1.5)
                )
                .accessibilityLabel("Category name")
            if isTaken {
                Text("You already have a category with this name.")
                    .font(.rounded(.caption, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xD7263D))
            }
        }
    }

    private var emojiGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            SheetLabel(text: "Emoji")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 8), spacing: 6) {
                ForEach(Self.emojis, id: \.self) { option in
                    let isOn = option == emoji
                    Button {
                        emoji = option
                        Haptics.tap()
                    } label: {
                        Text(option)
                            .font(.system(size: 22))
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isOn ? Palette.blush : Color.white.opacity(0.8))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(isOn ? Palette.hotPink : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(PressScaleStyle())
                    .accessibilityLabel(option)
                    .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
                }
            }
        }
    }

    private var colourRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            SheetLabel(text: "Colour")
            HStack(spacing: 10) {
                ForEach(CategoryPalette.colors.indices, id: \.self) { index in
                    let isOn = index == chosenColor
                    Button {
                        colorIndex = index
                        Haptics.tap()
                    } label: {
                        Circle()
                            .fill(CategoryPalette.color(at: index).gradient)
                            .frame(width: 30, height: 30)
                            .overlay {
                                if isOn {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .heavy))
                                        .foregroundStyle(Color.white)
                                }
                            }
                            .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                            .shadow(color: CategoryPalette.color(at: index).opacity(isOn ? 0.5 : 0.2), radius: 4, x: 0, y: 2)
                            .frame(width: 36, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressScaleStyle())
                    .accessibilityLabel("Colour \(index + 1)")
                    .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
                }
            }
        }
    }

    /// How the new chip will look.
    private var preview: some View {
        VStack(alignment: .leading, spacing: 8) {
            SheetLabel(text: "Preview")
            CategoryChip(title: trimmedName.isEmpty ? " " : trimmedName, icon: emoji,
                         tint: CategoryPalette.color(at: chosenColor), isOn: true) {}
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private func add() {
        guard canAdd else { return }
        let category = CustomCategory(name: trimmedName, emoji: emoji, colorIndex: chosenColor)
        context.insert(category)
        Haptics.success()
        onAdded(category)
        dismiss()
    }
}
