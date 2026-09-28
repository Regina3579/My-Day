import SwiftData
import SwiftUI

/// ▦ Templates: ready-made lists (plus the person's own) to add in one go.
struct TemplatePickerSheet: View {
    let day: Date
    /// Titles of the day's to-dos, offered when saving a new template.
    let currentTitles: [String]
    /// Called with the number of to-dos added.
    let onAdded: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskTemplate.createdAt) private var saved: [TaskTemplate]
    @State private var path: [TemplateRoute] = []
    @State private var pendingDelete: TemplateBlueprint?

    private var blueprints: [TemplateBlueprint] {
        TemplateBlueprint.starters + saved.map { TemplateBlueprint($0) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Pick a list and choose what to add ✨")
                        .font(.rounded(.subheadline, weight: .medium))
                        .foregroundStyle(Palette.inkSoft)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                              spacing: 12) {
                        ForEach(Array(blueprints.enumerated()), id: \.element.id) { index, blueprint in
                            Button {
                                path.append(.detail(blueprint))
                            } label: {
                                TemplateCard(blueprint: blueprint, tint: RowTint.at(index))
                            }
                            .buttonStyle(PressScaleStyle())
                            .contextMenu {
                                if blueprint.customID != nil {
                                    Button("Delete Template", systemImage: "trash", role: .destructive) {
                                        pendingDelete = blueprint
                                    }
                                }
                            }
                        }

                        Button {
                            path.append(.create)
                        } label: {
                            NewTemplateCard()
                        }
                        .buttonStyle(PressScaleStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .navigationDestination(for: TemplateRoute.self) { route in
                switch route {
                case .detail(let blueprint):
                    TemplateDetailView(blueprint: blueprint, day: day,
                                       onAdd: { titles in add(titles, from: blueprint) },
                                       onDelete: { delete(blueprint) })
                case .create:
                    SaveTemplateView(currentTitles: currentTitles) { path.removeLast() }
                }
            }
            .confirmationDialog("Delete this template?", isPresented: deleteBinding, titleVisibility: .visible,
                                presenting: pendingDelete) { blueprint in
                Button("Delete “\(blueprint.name)”", role: .destructive) { delete(blueprint) }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .presentationBackground(
            LinearGradient(colors: [Color(hex: 0xF3F7FF), Color(hex: 0xFFF1F7)], startPoint: .top, endPoint: .bottom)
        )
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }

    private func add(_ titles: [String], from blueprint: TemplateBlueprint) {
        guard !titles.isEmpty else { return }
        TaskActions.add(titles: titles, category: blueprint.category, to: day, in: context)
        Haptics.success()
        onAdded(titles.count)
        dismiss()
    }

    private func delete(_ blueprint: TemplateBlueprint) {
        guard let id = blueprint.customID, let template = saved.first(where: { $0.id == id }) else { return }
        if path.last == .detail(blueprint) {
            path.removeLast()
        }
        context.delete(template)
        Haptics.tap()
    }
}

enum TemplateRoute: Hashable {
    case detail(TemplateBlueprint)
    case create
}

// MARK: - Cards

private struct TemplateCard: View {
    let blueprint: TemplateBlueprint
    let tint: RowTint

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(blueprint.emoji)
                .font(.system(size: 34))
                .frame(width: 58, height: 58)
                .background(Circle().fill(Color.white.opacity(0.8)))
                .accessibilityHidden(true)
            Text(blueprint.name)
                .font(.rounded(.headline, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Text("\(blueprint.items.count) to-dos · \(blueprint.category.label)")
                .font(.rounded(.caption, weight: .semibold))
                .foregroundStyle(tint.accent)
            if blueprint.customID != nil {
                Text("My template")
                    .font(.rounded(.caption2, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(tint.accent))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [tint.fill.opacity(0.7), tint.fill],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(tint.edge, lineWidth: 1.2)
        )
        .shadow(color: tint.edge.opacity(0.5), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows the list")
    }
}

private struct NewTemplateCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(Palette.hotPink.gradient))
            Text("Save as Template")
                .font(.rounded(.headline, weight: .heavy))
                .foregroundStyle(Palette.berry)
                .multilineTextAlignment(.center)
            Text("Make your own list")
                .font(.rounded(.caption, weight: .semibold))
                .foregroundStyle(Palette.inkSoft)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 170)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Palette.bubblegum.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Checklist

/// A template's to-dos, each ticked on by default. Untick what you don't need, then add.
private struct TemplateDetailView: View {
    let blueprint: TemplateBlueprint
    let day: Date
    let onAdd: ([String]) -> Void
    let onDelete: () -> Void

    @State private var selected: Set<Int>
    @State private var confirmDelete = false

    init(blueprint: TemplateBlueprint, day: Date, onAdd: @escaping ([String]) -> Void, onDelete: @escaping () -> Void) {
        self.blueprint = blueprint
        self.day = day
        self.onAdd = onAdd
        self.onDelete = onDelete
        _selected = State(initialValue: Set(blueprint.items.indices))
    }

    private var chosenTitles: [String] {
        blueprint.items.indices.filter { selected.contains($0) }.map { blueprint.items[$0] }
    }

    private var allSelected: Bool { selected.count == blueprint.items.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Text(blueprint.emoji)
                        .font(.system(size: 40))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(blueprint.name)
                            .font(.rounded(.title2, weight: .heavy))
                            .foregroundStyle(Palette.ink)
                        Text("\(blueprint.category.emoji) \(blueprint.category.label)")
                            .font(.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(blueprint.category.color)
                    }
                }
                .padding(.bottom, 6)

                HStack {
                    Text("\(selected.count) of \(blueprint.items.count) selected")
                        .font(.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(Palette.inkSoft)
                    Spacer()
                    Button(allSelected ? "Select None" : "Select All") {
                        Haptics.tap()
                        withAnimation(.snappy) {
                            selected = allSelected ? [] : Set(blueprint.items.indices)
                        }
                    }
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(Palette.hotPink)
                    .frame(minHeight: 44)
                }

                ForEach(Array(blueprint.items.enumerated()), id: \.offset) { index, item in
                    let isOn = selected.contains(index)
                    let tint = RowTint.at(index)
                    Button {
                        Haptics.tap()
                        withAnimation(.snappy) {
                            if isOn { selected.remove(index) } else { selected.insert(index) }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            CheckBubble(isOn: isOn, tint: tint.accent, size: 26)
                            Text(item)
                                .font(.rounded(.body, weight: .semibold))
                                .foregroundStyle(isOn ? Palette.ink : Palette.inkSoft)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(isOn ? tint.fill : Color.white.opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(isOn ? tint.edge : Color.white, lineWidth: 1.2)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item)
                    .accessibilityValue(isOn ? "Selected" : "Not selected")
                    .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                onAdd(chosenTitles)
            } label: {
                Text(chosenTitles.isEmpty ? "Choose at least one" : "Add to My Day (\(chosenTitles.count)) ✨")
            }
            .buttonStyle(PillButtonStyle())
            .disabled(chosenTitles.isEmpty)
            .opacity(chosenTitles.isEmpty ? 0.6 : 1)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .navigationTitle(blueprint.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if blueprint.customID != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Delete Template", systemImage: "trash", role: .destructive) {
                        confirmDelete = true
                    }
                }
            }
        }
        .confirmationDialog("Delete this template?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}

// MARK: - Save as Template

/// Make a template: a name, an emoji, a category and its to-dos.
private struct SaveTemplateView: View {
    let currentTitles: [String]
    let onSaved: () -> Void

    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var emoji = "✨"
    @State private var category: TaskCategory = .personal
    @State private var items: [String] = []
    @State private var newItem = ""
    @FocusState private var focus: Field?

    private enum Field: Hashable {
        case name, newItem
    }

    private static let emojis = ["✨", "🌸", "☀️", "🏃‍♀️", "🧺", "🛒", "📚", "💼", "🧳", "🍳", "🐶", "💖"]

    private var canSave: Bool { !name.trimmed.isEmpty && !items.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                field(label: "Name") {
                    TextField("", text: $name)
                        .accessibilityLabel("Template name")
                        .font(.rounded(.title3, weight: .semibold))
                        .submitLabel(.next)
                        .focused($focus, equals: .name)
                        .onSubmit { focus = .newItem }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white))
                }

                field(label: "Emoji") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Self.emojis, id: \.self) { option in
                                Button {
                                    Haptics.tap()
                                    emoji = option
                                } label: {
                                    Text(option)
                                        .font(.system(size: 24))
                                        .frame(width: 46, height: 46)
                                        .background(Circle().fill(emoji == option ? Palette.blush : Color.white.opacity(0.7)))
                                        .overlay(Circle().strokeBorder(emoji == option ? Palette.hotPink : Color.clear,
                                                                       lineWidth: 2))
                                }
                                .buttonStyle(PressScaleStyle())
                                .accessibilityAddTraits(emoji == option ? AccessibilityTraits.isSelected : [])
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                field(label: "Category") {
                    CategoryPicker(builtIn: $category)
                }

                field(label: "To-dos") {
                    VStack(spacing: 8) {
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                            HStack(spacing: 10) {
                                Text("•")
                                    .foregroundStyle(Palette.hotPink)
                                    .accessibilityHidden(true)
                                Text(item)
                                    .font(.rounded(.body, weight: .medium))
                                    .foregroundStyle(Palette.ink)
                                Spacer(minLength: 0)
                                Button {
                                    withAnimation(.snappy) { _ = items.remove(at: index) }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color(hex: 0xE26D6D))
                                        .frame(width: 44, height: 44)
                                }
                                .accessibilityLabel("Remove \(item)")
                            }
                            .padding(.leading, 14)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.8)))
                        }

                        HStack(spacing: 8) {
                            TextField("Add a to-do", text: $newItem)
                                .font(.rounded(.body, weight: .medium))
                                .submitLabel(.done)
                                .focused($focus, equals: .newItem)
                                .onSubmit { addItem() }
                                .padding(.horizontal, 14)
                                .frame(minHeight: 48)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white))
                            Button {
                                addItem()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .frame(width: 48, height: 48)
                                    .background(Circle().fill(Palette.hotPink.gradient))
                            }
                            .buttonStyle(PressScaleStyle())
                            .disabled(newItem.trimmed.isEmpty)
                            .accessibilityLabel("Add to-do to template")
                        }

                        if !currentTitles.isEmpty {
                            Button {
                                Haptics.tap()
                                withAnimation(.snappy) {
                                    for title in currentTitles where !items.contains(title) {
                                        items.append(title)
                                    }
                                }
                            } label: {
                                Label("Use today's to-dos", systemImage: "square.and.arrow.down")
                                    .font(.rounded(.subheadline, weight: .bold))
                                    .foregroundStyle(Palette.grape)
                                    .frame(minHeight: 40)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("Save Template 💾", action: save)
                .buttonStyle(PillButtonStyle())
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.6)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
        }
        .navigationTitle("Save as Template")
        .navigationBarTitleDisplayMode(.inline)
        .task { focus = .name }
    }

    private func field<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.rounded(.footnote, weight: .heavy))
                .foregroundStyle(Palette.berry.opacity(0.8))
                .textCase(.uppercase)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func addItem() {
        let clean = newItem.trimmed
        guard !clean.isEmpty else { return }
        withAnimation(.snappy) { items.append(clean) }
        newItem = ""
        focus = .newItem
    }

    private func save() {
        let pending = newItem.trimmed
        if !pending.isEmpty { items.append(pending) }
        guard canSave else { return }
        context.insert(TaskTemplate(name: name.trimmed, emoji: emoji, category: category, items: items))
        Haptics.success()
        onSaved()
    }
}
