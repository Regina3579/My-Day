import SwiftData
import SwiftUI

/// ▦ Templates: ready-made lists (the starters and the person's own) to add in one go. Every
/// template has ⋯ with Edit and Delete; the starters can be brought back if deleted.
struct TemplatePickerSheet: View {
    let day: Date
    /// Titles of the day's to-dos, offered when saving a new template.
    let currentTitles: [String]
    /// Called with the number of to-dos added.
    let onAdded: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskTemplate.createdAt) private var templates: [TaskTemplate]
    @State private var path: [TemplateRoute] = []
    @State private var pendingDelete: TaskTemplate?

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Pick a list and choose what to add ✨")
                        .font(.rounded(.subheadline, weight: .medium))
                        .foregroundStyle(Palette.inkSoft)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                              spacing: 12) {
                        ForEach(Array(templates.enumerated()), id: \.element.persistentModelID) { index, template in
                            card(template, tint: RowTint.at(index))
                        }

                        Button {
                            path.append(.create)
                        } label: {
                            NewTemplateCard()
                        }
                        .buttonStyle(PressScaleStyle())
                    }

                    if TemplateLibrary.isMissingStarters(among: templates) {
                        Button {
                            withAnimation(.snappy) { TemplateLibrary.restoreStarters(in: context) }
                            Haptics.tap()
                        } label: {
                            Label("Bring back the starter templates", systemImage: "arrow.counterclockwise")
                                .font(.rounded(.subheadline, weight: .bold))
                                .foregroundStyle(Palette.grape)
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
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
                destination(route)
            }
            .confirmationDialog("Delete this template?", isPresented: deleteBinding, titleVisibility: .visible,
                                presenting: pendingDelete) { template in
                Button("Delete “\(template.name)”", role: .destructive) { delete(template) }
            } message: { template in
                Text(template.starterID.isEmpty
                     ? "This can't be undone."
                     : "You can bring the starter templates back at the bottom of the list.")
            }
            #if DEBUG
            .task {
                // `todos-template-edit`: opens the first template's editor for the screenshot.
                guard DebugLaunchRoute.takeTemplateEdit() else { return }
                try? await Task.sleep(for: .seconds(0.5))
                if let first = templates.first { path = [.edit(first.id)] }
            }
            #endif
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .presentationBackground(
            LinearGradient(colors: [Color(hex: 0xF3F7FF), Color(hex: 0xFFF1F7)], startPoint: .top, endPoint: .bottom)
        )
    }

    /// A template's card: tap it to see its to-dos; ⋯ (or press and hold) to edit or delete it.
    private func card(_ template: TaskTemplate, tint: RowTint) -> some View {
        Button {
            path.append(.detail(template.id))
        } label: {
            TemplateCard(template: template, tint: tint)
        }
        .buttonStyle(PressScaleStyle())
        .overlay(alignment: .topTrailing) {
            Menu {
                actions(for: template)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Palette.berry)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.92)))
                    .shadow(color: tint.edge.opacity(0.6), radius: 3, x: 0, y: 1)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Edit or delete \(template.name)")
        }
        .contextMenu {
            actions(for: template)
        }
    }

    @ViewBuilder
    private func actions(for template: TaskTemplate) -> some View {
        Button("Edit Template", systemImage: "pencil") {
            path.append(.edit(template.id))
        }
        Button("Delete Template", systemImage: "trash", role: .destructive) {
            pendingDelete = template
        }
    }

    @ViewBuilder
    private func destination(_ route: TemplateRoute) -> some View {
        switch route {
        case .detail(let id):
            if let template = templates.first(where: { $0.id == id }) {
                TemplateDetailView(template: template,
                                   onAdd: { titles in add(titles, from: template) },
                                   onEdit: { path.append(.edit(id)) },
                                   onDelete: { delete(template) })
            }
        case .edit(let id):
            if let template = templates.first(where: { $0.id == id }) {
                TemplateEditorView(template: template) { path.removeLast() }
            }
        case .create:
            TemplateEditorView(currentTitles: currentTitles) { path.removeLast() }
        }
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }

    private func add(_ titles: [String], from template: TaskTemplate) {
        guard !titles.isEmpty else { return }
        TaskActions.add(titles: titles, category: template.category, to: day, in: context)
        Haptics.success()
        onAdded(titles.count)
        dismiss()
    }

    private func delete(_ template: TaskTemplate) {
        let id = template.id
        path.removeAll { $0 == .detail(id) || $0 == .edit(id) }
        withAnimation(.snappy) { context.delete(template) }
        Haptics.tap()
    }
}

enum TemplateRoute: Hashable {
    case detail(UUID)
    case edit(UUID)
    case create
}

// MARK: - Cards

private struct TemplateCard: View {
    let template: TaskTemplate
    let tint: RowTint

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(template.emoji)
                .font(.system(size: 34))
                .frame(width: 58, height: 58)
                .background(Circle().fill(Color.white.opacity(0.8)))
                .accessibilityHidden(true)
            Text(template.name)
                .font(.rounded(.headline, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Text("\(template.items.count) to-dos · \(template.category.label)")
                .font(.rounded(.caption, weight: .semibold))
                .foregroundStyle(tint.accent)
            if template.starterID.isEmpty {
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
/// Edit and Delete sit at the top.
private struct TemplateDetailView: View {
    let template: TaskTemplate
    let onAdd: ([String]) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var selected: Set<Int>
    @State private var confirmDelete = false

    init(template: TaskTemplate, onAdd: @escaping ([String]) -> Void, onEdit: @escaping () -> Void,
         onDelete: @escaping () -> Void) {
        self.template = template
        self.onAdd = onAdd
        self.onEdit = onEdit
        self.onDelete = onDelete
        _selected = State(initialValue: Set(template.items.indices))
    }

    private var chosenTitles: [String] {
        template.items.indices.filter { selected.contains($0) }.map { template.items[$0] }
    }

    private var allSelected: Bool { selected.count == template.items.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Text(template.emoji)
                        .font(.system(size: 40))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name)
                            .font(.rounded(.title2, weight: .heavy))
                            .foregroundStyle(Palette.ink)
                        Text("\(template.category.emoji) \(template.category.label)")
                            .font(.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(template.category.color)
                    }
                }
                .padding(.bottom, 6)

                HStack {
                    Text("\(selected.count) of \(template.items.count) selected")
                        .font(.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(Palette.inkSoft)
                    Spacer()
                    Button(allSelected ? "Select None" : "Select All") {
                        Haptics.tap()
                        withAnimation(.snappy) {
                            selected = allSelected ? [] : Set(template.items.indices)
                        }
                    }
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(Palette.hotPink)
                    .frame(minHeight: 44)
                }

                ForEach(Array(template.items.enumerated()), id: \.offset) { index, item in
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
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit Template", systemImage: "pencil", action: onEdit)
                Button("Delete Template", systemImage: "trash", role: .destructive) {
                    confirmDelete = true
                }
            }
        }
        // After an edit, every to-do starts ticked again.
        .onChange(of: template.items) { _, items in
            selected = Set(items.indices)
        }
        .confirmationDialog("Delete this template?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete “\(template.name)”", role: .destructive, action: onDelete)
        } message: {
            Text(template.starterID.isEmpty
                 ? "This can't be undone."
                 : "You can bring the starter templates back at the bottom of the list.")
        }
    }
}

// MARK: - Make or edit a template

/// Make a template, or edit one: its name, emoji, category and to-dos (each can be
/// rewritten, removed or added).
private struct TemplateEditorView: View {
    /// The template being edited (nil when making a new one).
    let template: TaskTemplate?
    let currentTitles: [String]
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @State private var name: String
    @State private var emoji: String
    @State private var category: TaskCategory
    @State private var items: [Item]
    @State private var newItem = ""
    @FocusState private var focus: Field?

    private struct Item: Identifiable {
        let id = UUID()
        var text: String
    }

    private enum Field: Hashable {
        case name, item(UUID), newItem
    }

    private static let emojis = ["✨", "🌸", "☀️", "🌅", "🏃‍♀️", "🏋️", "🧺", "🧹", "🛒", "📚", "💼", "🧳",
                                 "✈️", "🍳", "🐶", "💖"]

    /// Makes a new template (today's to-dos can be copied in).
    init(currentTitles: [String], onDone: @escaping () -> Void) {
        template = nil
        self.currentTitles = currentTitles
        self.onDone = onDone
        _name = State(initialValue: "")
        _emoji = State(initialValue: "✨")
        _category = State(initialValue: .personal)
        _items = State(initialValue: [])
    }

    /// Edits `template`.
    init(template: TaskTemplate, onDone: @escaping () -> Void) {
        self.template = template
        currentTitles = []
        self.onDone = onDone
        _name = State(initialValue: template.name)
        _emoji = State(initialValue: template.emoji)
        _category = State(initialValue: template.category)
        _items = State(initialValue: template.items.map { Item(text: $0) })
    }

    private var isEditing: Bool { template != nil }

    /// The emojis to pick from, with the template's own first when it isn't one of them.
    private var emojiOptions: [String] {
        guard let current = template?.emoji, !Self.emojis.contains(current) else { return Self.emojis }
        return [current] + Self.emojis
    }

    private var cleanItems: [String] {
        (items.map(\.text) + [newItem]).map(\.trimmed).filter { !$0.isEmpty }
    }

    private var canSave: Bool { !name.trimmed.isEmpty && !cleanItems.isEmpty }

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
                            ForEach(emojiOptions, id: \.self) { option in
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
                        ForEach($items) { $item in
                            HStack(spacing: 10) {
                                Text("•")
                                    .foregroundStyle(Palette.hotPink)
                                    .accessibilityHidden(true)
                                TextField("To-do", text: $item.text, axis: .vertical)
                                    .font(.rounded(.body, weight: .medium))
                                    .foregroundStyle(Palette.ink)
                                    .focused($focus, equals: .item(item.id))
                                    .padding(.vertical, 12)
                                Button {
                                    let id = item.id
                                    focus = nil
                                    withAnimation(.snappy) { items.removeAll { $0.id == id } }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color(hex: 0xE26D6D))
                                        .frame(width: 44, height: 44)
                                }
                                .accessibilityLabel("Remove \(item.text)")
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
                                    let present = Set(items.map(\.text))
                                    for title in currentTitles where !present.contains(title) {
                                        items.append(Item(text: title))
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
            Button(isEditing ? "Save Changes 💾" : "Save Template 💾", action: save)
                .buttonStyle(PillButtonStyle())
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.6)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
        }
        .navigationTitle(isEditing ? "Edit Template" : "Save as Template")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !isEditing { focus = .name }
        }
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
        withAnimation(.snappy) { items.append(Item(text: clean)) }
        newItem = ""
        focus = .newItem
    }

    private func save() {
        guard canSave else { return }
        let titles = cleanItems
        if let template {
            template.name = name.trimmed
            template.emoji = emoji
            template.category = category
            template.items = titles
        } else {
            context.insert(TaskTemplate(name: name.trimmed, emoji: emoji, category: category, items: titles))
        }
        Haptics.success()
        onDone()
    }
}
