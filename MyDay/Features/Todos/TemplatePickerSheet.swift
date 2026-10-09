import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// ▦ Templates: ready-made lists (the starters and the person's own) whose to-dos can be ticked
/// off right there, like the day's list, or added to the day. Every template has ⋯ with Edit
/// and Delete, and can be pressed and held to move it around; the starters can be brought back
/// if deleted.
struct TemplatePickerSheet: View {
    let day: Date
    /// Titles of the day's to-dos, offered when saving a new template.
    let currentTitles: [String]
    /// Called with the number of to-dos added.
    let onAdded: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\TaskTemplate.sortOrder), SortDescriptor(\TaskTemplate.createdAt)])
    private var templates: [TaskTemplate]
    @State private var path: [TemplateRoute] = []
    @State private var pendingDelete: TaskTemplate?
    /// The card being moved (press and hold, then drag).
    @State private var dragging: TaskTemplate?

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open a list to tick off its to-dos or add them to My Day ✨")
                        if templates.count > 1 {
                            Label("Press and hold a card to move it around.", systemImage: "hand.draw.fill")
                                .foregroundStyle(Palette.grape)
                        }
                    }
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
            // Letting go anywhere else ends the move.
            .onDrop(of: [.text], isTargeted: nil) { _ in
                dragging = nil
                return true
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
                // `todos-template-move`: the last template moves to the front.
                if DebugLaunchRoute.takeTemplateMove(), let last = templates.last, let first = templates.first {
                    try? await Task.sleep(for: .seconds(0.8))
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        TemplateLibrary.move(last, to: first, in: templates)
                    }
                }
                // `todos-template-checklist`: the first template with its first two to-dos
                // ticked and Completed open, for the screenshot.
                if DebugLaunchRoute.takeTemplateChecklist(), let first = templates.first {
                    first.untickAll()
                    first.setDone(0, true)
                    first.setDone(1, true)
                    UserDefaults.standard.set(true, forKey: Prefs.showCompletedTemplateItems)
                    try? await Task.sleep(for: .seconds(0.5))
                    path = [.detail(first.id)]
                    return
                }
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

    /// A template's card: tap it to see its to-dos, ⋯ to edit or delete it, or press and
    /// hold to pick it up and move it; the other cards make room as it passes over them.
    private func card(_ template: TaskTemplate, tint: RowTint) -> some View {
        Button {
            path.append(.detail(template.id))
        } label: {
            TemplateCard(template: template, tint: tint)
        }
        .buttonStyle(PressScaleStyle())
        .opacity(dragging == template ? 0.35 : 1)
        .onDrag {
            dragging = template
            Haptics.tap()
            return NSItemProvider(object: template.id.uuidString as NSString)
        } preview: {
            TemplateCard(template: template, tint: tint)
                .frame(width: 170)
                .scaleEffect(1.04)
        }
        .onDrop(of: [.text], delegate: TemplateDropDelegate(target: template, templates: templates,
                                                            dragging: $dragging))
        .accessibilityAction(named: "Move earlier") { move(template, by: -1) }
        .accessibilityAction(named: "Move later") { move(template, by: 1) }
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
    }

    /// VoiceOver's Move earlier and Move later.
    private func move(_ template: TaskTemplate, by step: Int) {
        guard let index = templates.firstIndex(of: template) else { return }
        let target = index + step
        guard templates.indices.contains(target) else { return }
        withAnimation(.snappy) { TemplateLibrary.move(template, to: templates[target], in: templates) }
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
                                   onAddOne: { title in addOne(title, from: template) },
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

    /// ＋ on one of a template's to-dos: it is added to the day and Templates stays open.
    private func addOne(_ title: String, from template: TaskTemplate) {
        TaskActions.add(titles: [title], category: template.category, to: day, in: context)
    }

    private func delete(_ template: TaskTemplate) {
        let id = template.id
        path.removeAll { $0 == .detail(id) || $0 == .edit(id) }
        withAnimation(.snappy) { context.delete(template) }
        Haptics.tap()
    }
}

/// While a card is dragged, passing over another card moves it there.
private struct TemplateDropDelegate: DropDelegate {
    let target: TaskTemplate
    let templates: [TaskTemplate]
    @Binding var dragging: TaskTemplate?

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging != target else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            TemplateLibrary.move(dragging, to: target, in: templates)
        }
        Haptics.selection()
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        Haptics.tap()
        return true
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
            Text(template.doneCount > 0
                 ? "\(template.doneCount) of \(template.items.count) done · \(template.category.label)"
                 : "\(template.items.count) to-dos · \(template.category.label)")
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

/// A template's to-dos, like the day's list: tick a to-do done (two little hearts pop) and it
/// moves under "› Completed"; tap it there to untick it. ＋ on a row adds that to-do to My Day,
/// and the button at the bottom adds every one not done yet. Edit and Delete sit at the top.
private struct TemplateDetailView: View {
    let template: TaskTemplate
    /// Adds these to-dos to the day and closes Templates.
    let onAdd: ([String]) -> Void
    /// Adds one to-do to the day; Templates stays open.
    let onAddOne: (String) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @AppStorage(Prefs.showCompletedTemplateItems) private var showCompleted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confirmDelete = false
    /// Just-ticked to-dos stay in place for a moment (so their hearts can pop) before they
    /// move down to Completed.
    @State private var settling: Set<Int> = []
    /// Goes up each time a to-do is ticked; every change pops its two little hearts.
    @State private var tickPops: [Int: Int] = [:]
    /// To-dos just added to My Day with ＋ (their ＋ shows a tick for a moment).
    @State private var added: Set<Int> = []

    /// To-dos not done yet, in the template's order (a just-ticked one still sits here).
    private var openIndices: [Int] {
        template.items.indices.filter { !template.isDone($0) || settling.contains($0) }
    }

    private var doneIndices: [Int] {
        template.items.indices.filter { template.isDone($0) && !settling.contains($0) }
    }

    /// What the button at the bottom adds: every to-do not ticked done.
    private var titlesToAdd: [String] {
        template.items.indices.filter { !template.isDone($0) }.map { template.items[$0] }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                header
                progressLine
                ForEach(openIndices, id: \.self) { index in
                    row(index)
                }
                if openIndices.isEmpty && !template.items.isEmpty {
                    allDoneNote
                }
                let done = doneIndices
                if !done.isEmpty {
                    CompletedHeader(count: done.count, isOpen: showCompleted) {
                        withAnimation(.snappy) { showCompleted.toggle() }
                    }
                    .padding(.top, openIndices.isEmpty ? 0 : 6)
                    if showCompleted {
                        ForEach(done, id: \.self) { index in
                            row(index)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            addButton
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
        // After an edit the rows may have moved: nothing is mid-tick any more.
        .onChange(of: template.items) { _, _ in
            settling = []
            tickPops = [:]
            added = []
        }
        .confirmationDialog("Delete this template?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete “\(template.name)”", role: .destructive, action: onDelete)
        } message: {
            Text(template.starterID.isEmpty
                 ? "This can't be undone."
                 : "You can bring the starter templates back at the bottom of the list.")
        }
    }

    private var header: some View {
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
    }

    /// "2 of 5 completed", with Untick All once something is ticked.
    private var progressLine: some View {
        HStack {
            Text("\(template.doneCount) of \(template.items.count) completed")
                .font(.rounded(.subheadline, weight: .semibold))
                .foregroundStyle(Palette.inkSoft)
                .contentTransition(.numericText(value: Double(template.doneCount)))
            Spacer()
            if template.doneCount > 0 {
                Button {
                    Haptics.tap()
                    settling = []
                    tickPops = [:]
                    withAnimation(.snappy) { template.untickAll() }
                } label: {
                    Label("Untick All", systemImage: "arrow.counterclockwise")
                }
                .font(.rounded(.subheadline, weight: .bold))
                .foregroundStyle(Palette.hotPink)
                .frame(minHeight: 44)
                .accessibilityHint("Marks every to-do in this list as not done")
            }
        }
        .animation(.snappy, value: template.doneCount)
    }

    private var allDoneNote: some View {
        Text("✨ All done! Every to-do in this list is ticked.")
            .font(.rounded(.subheadline, weight: .heavy))
            .foregroundStyle(Palette.berry)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(Capsule().fill(Color.white.opacity(0.72)))
            .overlay(Capsule().strokeBorder(Palette.hotPink.opacity(0.14), lineWidth: 1))
            .transition(.scale(scale: 0.9).combined(with: .opacity))
    }

    /// One to-do: tap it to tick it done (or not done); ＋ adds it to My Day.
    private func row(_ index: Int) -> some View {
        let item = template.items[index]
        let isDone = template.isDone(index)
        let tint = RowTint.at(index)
        return HStack(spacing: 4) {
            Button {
                toggle(index)
            } label: {
                HStack(spacing: 4) {
                    CheckBubble(isOn: isDone, tint: tint.accent, size: 26)
                        .frame(width: 44, height: 44)
                    Text(item)
                        .font(.rounded(.body, weight: .semibold))
                        .foregroundStyle(isDone ? Palette.inkSoft.opacity(0.75) : Palette.ink)
                        .strikethrough(isDone, color: tint.accent.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 12)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item)
            .accessibilityValue(isDone ? "Done" : "Not done")
            .accessibilityHint(isDone ? "Marks the to-do as not done" : "Marks the to-do as done")

            if !isDone {
                addOneButton(index, item: item, tint: tint)
            }
        }
        .padding(.leading, 4)
        .padding(.trailing, 2)
        .frame(minHeight: 52)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [tint.fill.opacity(0.75), tint.fill],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(tint.edge, lineWidth: 1.2)
        )
        .shadow(color: tint.edge.opacity(0.45), radius: 6, x: 0, y: 3)
        .opacity(isDone ? 0.8 : 1)
        .overlay(alignment: .leading) {
            // Over the tick box (after the fade above, so the hearts stay bright).
            if let pops = tickPops[index] {
                TickPop()
                    .id(pops)
                    .frame(width: 44, height: 44)
                    .padding(.leading, 4)
            }
        }
    }

    /// ＋: adds this one to-do to My Day (a tick shows for a moment).
    private func addOneButton(_ index: Int, item: String, tint: RowTint) -> some View {
        let isAdded = added.contains(index)
        return Button {
            addOne(index)
        } label: {
            Image(systemName: isAdded ? "checkmark" : "plus")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isAdded ? Color.white : tint.accent)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 30, height: 30)
                .background(Circle().fill(isAdded ? AnyShapeStyle(tint.accent) : AnyShapeStyle(Color.white.opacity(0.85))))
                .overlay(Circle().strokeBorder(tint.edge, lineWidth: 1))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle(scale: 0.86))
        .disabled(isAdded)
        .accessibilityLabel("Add “\(item)” to My Day")
    }

    private var addButton: some View {
        let titles = titlesToAdd
        return Button {
            onAdd(titles)
        } label: {
            Text(titles.isEmpty ? "All done ✨" : "Add to My Day (\(titles.count)) ✨")
        }
        .buttonStyle(PillButtonStyle())
        .disabled(titles.isEmpty)
        .opacity(titles.isEmpty ? 0.6 : 1)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .accessibilityHint(titles.isEmpty ? "" : "Adds the to-dos not done yet")
    }

    // MARK: Actions

    /// Ticks a to-do done, with the soft "ting" (the all-done chime for the last one), or
    /// unticks it.
    private func toggle(_ index: Int) {
        let isFinishing = !template.isDone(index)
        let pops = isFinishing && !reduceMotion
        if pops {
            // It stays in place while its hearts pop.
            settling.insert(index)
            tickPops[index, default: 0] += 1
        } else {
            settling.remove(index)
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            template.setDone(index, isFinishing)
        }
        if isFinishing {
            CompletionFeedback.completed(finishingAll: template.doneCount == template.items.count)
        } else {
            Haptics.tap()
        }
        guard pops else { return }
        // Let the tick and its hearts show, then move it down to Completed. (The hearts go
        // too, so they don't pop again when Completed is opened.)
        let settle = TickPop.settleDelay
        Task {
            try? await Task.sleep(for: .seconds(settle))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                _ = settling.remove(index)
            }
            tickPops[index] = nil
        }
    }

    private func addOne(_ index: Int) {
        let item = template.items[index]
        onAddOne(item)
        Haptics.success()
        AccessibilityNotification.Announcement("Added “\(item)” to My Day").post()
        withAnimation(.snappy) { _ = added.insert(index) }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.snappy) { _ = added.remove(index) }
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
        /// Ticked done in the template (kept through the edit).
        var isDone = false
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
        _items = State(initialValue: template.items.indices.map {
            Item(text: template.items[$0], isDone: template.isDone($0))
        })
    }

    private var isEditing: Bool { template != nil }

    /// The emojis to pick from, with the template's own first when it isn't one of them.
    private var emojiOptions: [String] {
        guard let current = template?.emoji, !Self.emojis.contains(current) else { return Self.emojis }
        return [current] + Self.emojis
    }

    /// The to-dos to save (blank ones left out), each with whether it is ticked done.
    private var cleanItems: [Item] {
        (items + [Item(text: newItem)])
            .map { Item(text: $0.text.trimmed, isDone: $0.isDone) }
            .filter { !$0.text.isEmpty }
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
        let titles = cleanItems.map(\.text)
        if let template {
            template.name = name.trimmed
            template.emoji = emoji
            template.category = category
            template.items = titles
            template.itemsDone = cleanItems.map(\.isDone)
        } else {
            let template = TaskTemplate(name: name.trimmed, emoji: emoji, category: category, items: titles)
            // A new template goes at the end.
            template.sortOrder = TemplateLibrary.nextSortOrder(in: context)
            context.insert(template)
        }
        Haptics.success()
        onDone()
    }
}
