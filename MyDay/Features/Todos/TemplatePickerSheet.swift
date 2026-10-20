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
    /// The page's width (everything is placed on the design's grid, 914 pixels across).
    @State private var width: CGFloat = 402

    /// Points per pixel of the design.
    private var k: CGFloat { width / 914 }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 0) {
                    TemplatesHeader(k: k) { dismiss() }
                        .padding(.top, 16)

                    LazyVGrid(columns: [GridItem(.fixed(420 * k), spacing: 22 * k, alignment: .top),
                                        GridItem(.fixed(420 * k), alignment: .top)],
                              spacing: 16 * k) {
                        ForEach(templates, id: \.persistentModelID) { template in
                            card(template)
                        }

                        Button {
                            path.append(.create)
                        } label: {
                            NewTemplateCard(k: k)
                        }
                        .buttonStyle(PressScaleStyle())
                    }
                    .padding(.top, 4 * k)

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
                .padding(.bottom, 24)
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            .background(TemplatesHeader.pageBackground.ignoresSafeArea())
            // Letting go anywhere else ends the move.
            .onDrop(of: [.text], isTargeted: nil) { _ in
                dragging = nil
                return true
            }
            .navigationTitle("Templates")
            // The page draws its own heading (with Close) from its design.
            .toolbar(.hidden, for: .navigationBar)
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
    private func card(_ template: TaskTemplate) -> some View {
        Button {
            path.append(.detail(template.id))
        } label: {
            TemplateCard(template: template, k: k)
        }
        .buttonStyle(PressScaleStyle())
        .opacity(dragging == template ? 0.35 : 1)
        .onDrag {
            dragging = template
            Haptics.tap()
            return NSItemProvider(object: template.id.uuidString as NSString)
        } preview: {
            TemplateCard(template: template, k: k)
                .scaleEffect(1.04)
        }
        .onDrop(of: [.text], delegate: TemplateDropDelegate(target: template, templates: templates,
                                                            dragging: $dragging))
        .accessibilityAction(named: "Move earlier") { move(template, by: -1) }
        .accessibilityAction(named: "Move later") { move(template, by: 1) }
        .overlay(alignment: .topLeading) {
            // Over the card's own ⋯ (its middle is 367 × 53 pixels into the card).
            let side = max(44, 76 * k)
            Menu {
                actions(for: template)
            } label: {
                Color.clear
                    .frame(width: side, height: side)
                    .contentShape(Circle())
            }
            .offset(x: 367 * k - side / 2, y: 53 * k - side / 2)
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

/// The heading of Templates, from its design: a soft lilac strip with stars, hearts and clouds,
/// a pink-edged **Close**, "Templates" in thick navy, a line on what the page is for and the
/// purple "Press and hold a card to move it around." with its pointing hand. The strip is the
/// design's own picture (enlarged 4× with Real-ESRGAN, its words taken out); the words are
/// written here. Placed on the design's grid (913 × 236 pixels).
private struct TemplatesHeader: View {
    let k: CGFloat
    let onClose: () -> Void

    static let pageBackground = LinearGradient(
        colors: [Color(hex: 0xF9F9FE), Color(hex: 0xFEFCFD), Color(hex: 0xFEF1F6)],
        startPoint: .top, endPoint: .bottom
    )

    var body: some View {
        Image("TemplatesHeader")
            .resizable()
            .frame(width: 913 * k, height: 236 * k)
            .accessibilityHidden(true)
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    Button(action: onClose) {
                        Text("Close")
                            .font(.system(size: 34 * k, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: 0xF2087F))
                            .frame(width: 160 * k, height: 77 * k)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(PressScaleStyle())
                    .frame(minHeight: 44)
                    .offset(x: 41 * k, y: 13 * k)

                    Text("Templates")
                        .font(.system(size: 76 * k, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: 0x08053A))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(width: 370 * k, height: 84 * k, alignment: .leading)
                        .offset(x: 226 * k, y: 12 * k)
                        .accessibilityAddTraits(.isHeader)

                    Text("Open a list to tick off its to-dos or add them to My Day")
                        .font(.system(size: 31 * k, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: 0x6860A0))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: 790 * k, height: 42 * k, alignment: .leading)
                        .offset(x: 46 * k, y: 107 * k)

                    Text("Press and hold a card to move it around.")
                        .font(.system(size: 31 * k, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: 0x7A34F5))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: 550 * k, height: 42 * k, alignment: .leading)
                        .offset(x: 176 * k, y: 172 * k)
                }
            }
    }
}

/// A template's card, from the design: each starter has its own pastel card and picture
/// (sunrise, the weightlifting star, the plane, the books, the broom, the trolley); the person's
/// own templates are pink with a **👑 My template** badge, and pictures that match what the list
/// is about (books for a reading list, fruit for a market list; see `TemplateTopic`), or a few
/// pink hearts when nothing matches. The name is in
/// thick navy and "5 to-dos · Personal" (or "2 of 5 done") in the card's colour. A starter whose
/// emoji was changed shows that emoji in a white circle over its picture.
private struct TemplateCard: View {
    let template: TaskTemplate
    let k: CGFloat

    /// A card's picture: its asset, size (design pixels), where its round badge is, and its colour.
    struct Art {
        let image: String
        let size: CGSize
        let badge: CGPoint
        let tint: Color
    }

    static func art(for template: TaskTemplate) -> Art {
        switch template.starterID {
        case "morning": Art(image: "TemplateCardMorning", size: CGSize(width: 420, height: 282), badge: CGPoint(x: 99, y: 90), tint: Color(hex: 0xF2078A))
        case "workout": Art(image: "TemplateCardWorkout", size: CGSize(width: 420, height: 282), badge: CGPoint(x: 103, y: 90), tint: Color(hex: 0x7440F2))
        case "travel": Art(image: "TemplateCardTravel", size: CGSize(width: 420, height: 286), badge: CGPoint(x: 98, y: 82), tint: Color(hex: 0xEE8A00))
        case "study": Art(image: "TemplateCardStudy", size: CGSize(width: 420, height: 286), badge: CGPoint(x: 102, y: 82), tint: Color(hex: 0x0A5CF2))
        case "cleaning": Art(image: "TemplateCardCleaning", size: CGSize(width: 420, height: 284), badge: CGPoint(x: 98, y: 89), tint: Color(hex: 0x0FA70F))
        case "grocery": Art(image: "TemplateCardGrocery", size: CGSize(width: 420, height: 284), badge: CGPoint(x: 102, y: 89), tint: Color(hex: 0xF24E05))
        default: Art(image: "TemplateCardCustom", size: CGSize(width: 420, height: 354), badge: CGPoint(x: 98, y: 88), tint: Color(hex: 0xF20694))
        }
    }

    private var isOwn: Bool { template.starterID.isEmpty }

    /// The picture's own badge fits unless the emoji was changed (or it is the person's own).
    private var drawsEmoji: Bool {
        isOwn || TemplateBlueprint.starters.first { $0.id == template.starterID }?.emoji != template.emoji
    }

    /// For the person's own template: what it is about, for its pictures (nil: pink hearts).
    private var topic: TemplateTopic? {
        isOwn ? TemplateTopic.match(name: template.name, items: template.items) : nil
    }

    var body: some View {
        let art = Self.art(for: template)
        let topic = topic
        ZStack(alignment: .bottomLeading) {
            Image(topic == nil ? art.image : "TemplateCardCustomPlain")
                .resizable()
                .frame(width: art.size.width * k, height: art.size.height * k)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3 * k) {
                Text(template.name)
                    .font(.system(size: 38 * k, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0x08053A))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                Text(template.doneCount > 0
                     ? "\(template.doneCount) of \(template.items.count) done · \(template.category.label)"
                     : "\(template.items.count) to-dos · \(template.category.label)")
                    .font(.system(size: 28 * k, weight: .semibold, design: .rounded))
                    .foregroundStyle(art.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if isOwn {
                    HStack(spacing: 6 * k) {
                        Text("👑")
                        Text("My template")
                    }
                    .font(.system(size: 26 * k, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16 * k)
                    .padding(.vertical, 6 * k)
                    .background(Capsule().fill(LinearGradient(colors: [Color(hex: 0xF94FB0), Color(hex: 0xEE1388)],
                                                              startPoint: .top, endPoint: .bottom)))
                    .padding(.top, 6 * k)
                }
            }
            .frame(width: 350 * k, alignment: .leading)
            .padding(.leading, 39 * k)
            .padding(.bottom, (isOwn ? 24 : 34) * k)
        }
        .overlay(alignment: .topLeading) {
            if let topic {
                decorations(topic.decorations)
            }
        }
        .overlay(alignment: .topLeading) {
            if drawsEmoji {
                Text(template.emoji)
                    .font(.system(size: 72 * k))
                    .frame(width: 128 * k, height: 128 * k)
                    .background(
                        Circle()
                            .fill(RadialGradient(colors: [Color.white, Color(hex: 0xF8F4FB)], center: .center,
                                                 startRadius: 10 * k, endRadius: 66 * k))
                            .shadow(color: art.tint.opacity(0.18), radius: 4, x: 0, y: 2)
                    )
                    .offset(x: (art.badge.x - 64) * k, y: (art.badge.y - 64) * k)
                    .accessibilityHidden(true)
            }
        }
        .shadow(color: art.tint.opacity(0.12), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows the list")
    }
}

extension TemplateCard {
    /// The topic's three pictures down the card's right side, clear of its words: a big one under
    /// ⋯, a middle one at the edge and a small one lower down, each tilted a little.
    private func decorations(_ pictures: [String]) -> some View {
        let spots: [(x: CGFloat, y: CGFloat, size: CGFloat, tilt: Double)] = [
            (330, 148, 68, -10), (376, 222, 50, 12), (372, 292, 40, -6),
        ]
        return ZStack(alignment: .topLeading) {
            ForEach(Array(zip(pictures, spots).enumerated()), id: \.offset) { _, pair in
                let (picture, spot) = pair
                Text(picture)
                    .font(.system(size: spot.size * k))
                    .rotationEffect(.degrees(spot.tilt))
                    .shadow(color: Color(hex: 0xF20694).opacity(0.18), radius: 3, x: 0, y: 2)
                    .frame(width: spot.size * 1.4 * k, height: spot.size * 1.4 * k)
                    .offset(x: (spot.x - spot.size * 0.7) * k, y: (spot.y - spot.size * 0.7) * k)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Save as Template, from the design: a dashed pink card with hearts, stars and a smiling
/// cloud, a big pink ＋, "Save as Template" in deep berry and "Make your own list".
private struct NewTemplateCard: View {
    let k: CGFloat

    var body: some View {
        Image("TemplateCardSave")
            .resizable()
            .frame(width: 420 * k, height: 354 * k)
            .accessibilityHidden(true)
            .overlay(alignment: .top) {
                VStack(spacing: 6 * k) {
                    Text("Save as Template")
                        .font(.system(size: 38 * k, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: 0x880035))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("Make your own list")
                        .font(.system(size: 28 * k, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: 0x6860A0))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(width: 380 * k)
                .padding(.top, 196 * k)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Save as Template. Make your own list")
    }
}

// MARK: - Checklist

/// A template's to-dos, like the day's list: tick a to-do done (two little hearts pop) and it
/// moves under "› Completed"; tap it there to untick it. ＋ on a row adds that to-do to My Day.
/// At the bottom, Add Task writes a new to-do into the list, and Add to My Day adds every one
/// not done yet. Edit and Delete sit at the top.
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
    /// Add Task was tapped: a new row waits at the end of the list for its words.
    @State private var isAddingItem = false
    @State private var newItem = ""
    @FocusState private var newItemFocused: Bool

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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    header
                    progressLine
                    ForEach(openIndices, id: \.self) { index in
                        row(index)
                    }
                    if isAddingItem {
                        newItemRow
                            .id(Self.newItemID)
                            .transition(.scale(scale: 0.95, anchor: .top).combined(with: .opacity))
                    } else if openIndices.isEmpty && !template.items.isEmpty {
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
                VStack(spacing: 10) {
                    addTaskButton(proxy)
                    addButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
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

    private static let newItemID = "newItem"

    /// The new to-do's row: type it, and Return (or ＋) puts it in the list; the row stays
    /// open for the next one. Return on an empty row closes it.
    private var newItemRow: some View {
        let tint = RowTint.at(template.items.count)
        return HStack(spacing: 4) {
            CheckBubble(isOn: false, tint: tint.accent, size: 26)
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
            TextField("New to-do", text: $newItem)
                .font(.rounded(.body, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .focused($newItemFocused)
                .submitLabel(.done)
                .onSubmit(addItem)
                .padding(.vertical, 12)
            Button(action: addItem) {
                Image(systemName: newItem.trimmed.isEmpty ? "xmark" : "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tint.accent)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.85)))
                    .overlay(Circle().strokeBorder(tint.edge, lineWidth: 1))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressScaleStyle(scale: 0.86))
            .accessibilityLabel(newItem.trimmed.isEmpty ? "Cancel" : "Add to the list")
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
                .strokeBorder(tint.accent.opacity(0.6), style: StrokeStyle(lineWidth: 1.4, dash: [6, 4]))
        )
    }

    /// Add Task: white with a pink edge, above Add to My Day; opens the new to-do's row.
    private func addTaskButton(_ proxy: ScrollViewProxy) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.snappy) { isAddingItem = true }
            newItemFocused = true
            Task {
                try? await Task.sleep(for: .seconds(0.35))
                withAnimation(.snappy) { proxy.scrollTo(Self.newItemID, anchor: .bottom) }
            }
        } label: {
            Label("Add Task", systemImage: "plus")
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(Palette.hotPink)
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(Color.white))
                .overlay(Capsule().strokeBorder(Palette.hotPink.opacity(0.55), lineWidth: 1.5))
                .shadow(color: Palette.hotPink.opacity(0.18), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PressScaleStyle(scale: 0.97))
        .accessibilityHint("Adds a new to-do to this list")
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

    private func addItem() {
        let clean = newItem.trimmed
        guard !clean.isEmpty else {
            newItemFocused = false
            withAnimation(.snappy) { isAddingItem = false }
            return
        }
        withAnimation(.snappy) { template.items.append(clean) }
        newItem = ""
        newItemFocused = true
        Haptics.success()
        AccessibilityNotification.Announcement("Added “\(clean)” to the list").post()
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
