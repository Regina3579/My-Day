import SwiftData
import SwiftUI

// MARK: - Header scene

/// The compact band of the To-Dos header scene (the image is 853 × 482 px).
///
/// Only the lower part is shown: the girl's face sits just below the status bar and the band
/// ends under the puppy. The picture is drawn a little narrower than the screen, against its
/// right edge, so the "Today's To-Dos" sign stays clear of the back button.
enum TodosScene {
    static let imageSize = CGSize(width: 853, height: 482)
    static let widthFraction: CGFloat = 0.88
    /// Image rows (px): the girl's eyes, and the last row shown.
    static let eyesRow: CGFloat = 300
    static let bottomRow: CGFloat = 452

    /// Points per image pixel.
    static func scale(width: CGFloat) -> CGFloat {
        width * widthFraction / imageSize.width
    }

    /// The first image row shown: the girl's eyes sit just below the status bar.
    static func topRow(width: CGFloat, statusBar: CGFloat) -> CGFloat {
        max(0, eyesRow - (statusBar + 4) / scale(width: width))
    }

    static func height(width: CGFloat, statusBar: CGFloat) -> CGFloat {
        (bottomRow - topRow(width: width, statusBar: statusBar)) * scale(width: width)
    }
}

/// The illustrated header band: the "Today's To-Dos" sign, the girl and her puppy.
struct TodosHero: View {
    let width: CGFloat
    /// Height of the status bar (not counting the navigation bar).
    let statusBar: CGFloat

    var body: some View {
        let scale = TodosScene.scale(width: width)
        let top = TodosScene.topRow(width: width, statusBar: statusBar)
        let height = TodosScene.height(width: width, statusBar: statusBar)
        let imageWidth = width * TodosScene.widthFraction
        ZStack(alignment: .topTrailing) {
            // A soft, blurred copy fills the strip on the left.
            Image("TodosScene")
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .blur(radius: 16, opaque: true)
                .clipped()
            Image("TodosScene")
                .resizable()
                .frame(width: imageWidth, height: TodosScene.imageSize.height * scale)
                .offset(y: -top * scale)
                .frame(width: imageWidth, height: height, alignment: .top)
                .clipped()
                .mask(Self.edgeFade)
        }
        .frame(width: width, height: height)
        .clipped()
        .accessibilityHidden(true)
    }

    /// Blends the picture's left edge into the blurred strip.
    private static let edgeFade = LinearGradient(
        stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.1)],
        startPoint: .leading, endPoint: .trailing
    )
}

// MARK: - Date and quote

/// "Today ♥ · 27 May 2025" with the day's gentle quote, in one slim card.
struct TodayHeaderCard: View {
    let day: Date

    var body: some View {
        HStack(spacing: 10) {
            DateBadge(date: day)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(day.isToday ? "Today" : day.formatted(.dateTime.weekday(.wide)))
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Palette.hotPink)
                        .accessibilityHidden(true)
                }
                Text(day.formatted(.dateTime.day().month(.abbreviated).year()))
                    .font(.rounded(.caption, weight: .medium))
                    .foregroundStyle(Palette.inkSoft)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: true, vertical: false)

            Capsule()
                .fill(Palette.hotPink.opacity(0.25))
                .frame(width: 1.5, height: 32)
                .accessibilityHidden(true)

            HStack(spacing: 5) {
                Text("☀️")
                    .font(.system(size: 18))
                    .accessibilityHidden(true)
                Text("“\(TodoQuotes.quote(for: day))”")
                    .font(.custom("Noteworthy-Bold", size: 13, relativeTo: .footnote))
                    .foregroundStyle(Palette.berry)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [Color.white, Color(hex: 0xFFF1F7)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Palette.hotPink.opacity(0.12), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white, lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Category filter

/// "All · Personal · Work · Health · Learning · Shopping", then the categories the person
/// added, then ＋ to add one. Press and hold an added category to delete it.
struct CategoryChipBar: View {
    @Binding var selection: CategoryChoice?

    @Environment(\.modelContext) private var context
    @Query(sort: \CustomCategory.createdAt) private var customs: [CustomCategory]
    @State private var showsNewCategory = false
    @State private var pendingDelete: CustomCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(title: "All", icon: nil, tint: Palette.hotPink, isOn: selection == nil) {
                    selection = nil
                }
                ForEach(TaskCategory.allCases) { category in
                    chip(.builtIn(category))
                }
                ForEach(customs) { custom in
                    chip(.custom(custom))
                        .contextMenu {
                            Button(role: .destructive) {
                                pendingDelete = custom
                            } label: {
                                Label("Delete Category", systemImage: "trash")
                            }
                        }
                }
                addChip
            }
            .padding(.horizontal, 16)
            .padding(.top, 2)
            .padding(.bottom, 10)
        }
        .sheet(isPresented: $showsNewCategory) {
            NewCategorySheet { added in
                withAnimation(.snappy) { selection = .custom(added) }
            }
        }
        .confirmationDialog("Delete this category?", isPresented: deleteBinding, titleVisibility: .visible,
                            presenting: pendingDelete) { custom in
            Button("Delete “\(custom.name)”", role: .destructive) { delete(custom) }
        } message: { _ in
            Text("Its to-dos stay, in Personal.")
        }
    }

    private func chip(_ choice: CategoryChoice) -> some View {
        CategoryChip(title: choice.label, icon: choice.emoji, tint: choice.color, textTint: choice.textColor,
                     isOn: selection == choice) {
            selection = selection == choice ? nil : choice
        }
    }

    private var addChip: some View {
        Button {
            Haptics.tap()
            showsNewCategory = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.hotPink)
                .frame(width: 44, height: 34)
                .background(Capsule().fill(Color.white.opacity(0.85)))
                .overlay(
                    Capsule().strokeBorder(Palette.hotPink.opacity(0.4), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                )
                .padding(.vertical, 3)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel("Add a category")
    }

    private func delete(_ custom: CustomCategory) {
        if selection == .custom(custom) {
            selection = nil
        }
        withAnimation(.snappy) { context.delete(custom) }
        Haptics.success()
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }
}

/// A category chip in its category's colour: a soft tint with the name in colour, or filled
/// with white text when chosen.
struct CategoryChip: View {
    let title: String
    /// An emoji; `nil` shows a heart (used by "All").
    let icon: String?
    let tint: Color
    /// The colour for the name when not chosen (`tint` if nil).
    var textTint: Color?
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            withAnimation(.snappy) { action() }
        } label: {
            HStack(spacing: 5) {
                if let icon {
                    Text(icon)
                } else {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(isOn ? Color.white : tint)
                }
                Text(title)
                    .foregroundStyle(isOn ? Color.white : (textTint ?? tint))
            }
            .font(.rounded(.subheadline, weight: isOn ? .bold : .semibold))
            .padding(.horizontal, 12)
            .frame(minHeight: 34)
            .background {
                ZStack {
                    Capsule().fill(Color.white)
                    Capsule().fill(isOn ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(tint.opacity(0.14)))
                }
            }
            .overlay(Capsule().strokeBorder(isOn ? Color.white.opacity(0.7) : tint.opacity(0.4), lineWidth: 1))
            .shadow(color: tint.opacity(isOn ? 0.35 : 0.12), radius: 6, x: 0, y: 3)
            .overlay(alignment: .bottom) {
                if isOn {
                    Circle()
                        .fill(tint)
                        .frame(width: 7, height: 7)
                        .offset(y: 10)
                        .transition(.scale)
                }
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
    }
}

// MARK: - Rows

/// What the little ✏️ menu on a to-do can do.
enum TaskMenuAction: String, CaseIterable, Identifiable {
    case edit, changeDate, reminder, repeatRule, moveToPriority, delete

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .edit: "✏️"
        case .changeDate: "📅"
        case .reminder: "🔔"
        case .repeatRule: "🔁"
        case .moveToPriority: "⭐"
        case .delete: "🗑️"
        }
    }

    func title(for task: TaskItem) -> String {
        switch self {
        case .edit: "Edit"
        case .changeDate: "Change date/time"
        case .reminder: task.reminderEnabled ? "Change reminder" : "Add reminder"
        case .repeatRule: task.repeatOption == .never ? "Repeat" : "Repeat · \(task.repeatOption.label)"
        case .moveToPriority: "Move to Priority"
        case .delete: "Delete"
        }
    }
}

/// One to-do: tick box on the left, title and details, the ☆ that marks it important and
/// the ✏️ that manages it.
struct TodoRow: View {
    let task: TaskItem
    let tint: RowTint
    let onToggle: () -> Void
    let onImportant: () -> Void
    let onOpen: () -> Void
    let onAction: (TaskMenuAction) -> Void

    @State private var showsMenu = false
    @State private var chosen: TaskMenuAction?
    /// Goes up each time the to-do is ticked; every change pops two little hearts.
    @State private var tickPops = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onToggle) {
                CheckBubble(isOn: task.isCompleted, tint: tint.accent, size: 26)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressScaleStyle(scale: 0.85))
            .accessibilityLabel(task.title)
            .accessibilityValue(task.isCompleted ? "Done" : "Not done")
            .accessibilityHint(task.isCompleted ? "Marks the to-do as not done" : "Marks the to-do as done")

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.rounded(.body, weight: .semibold))
                        .foregroundStyle(task.isCompleted ? Palette.inkSoft.opacity(0.75) : Palette.ink)
                        .strikethrough(task.isCompleted, color: tint.accent.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    TodoMetaLine(task: task)
                }
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows the details")

            importantButton

            Button {
                Haptics.tap()
                showsMenu = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tint.accent)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.85)))
                    .overlay(Circle().strokeBorder(tint.edge, lineWidth: 1))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressScaleStyle(scale: 0.86))
            .accessibilityLabel("Manage \(task.title)")
            .popover(isPresented: $showsMenu) {
                TaskManageMenu(task: task, tint: tint) { action in
                    chosen = action
                    showsMenu = false
                }
                .presentationCompactAdaptation(.popover)
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
        .opacity(task.isCompleted ? 0.8 : 1)
        .overlay(alignment: .leading) {
            // Over the tick box (after the fade above, so the hearts stay bright).
            if tickPops > 0 {
                TickPop()
                    .id(tickPops)
                    .frame(width: 44, height: 44)
                    .padding(.leading, 4)
            }
        }
        .onChange(of: task.isCompleted) { wasDone, isDone in
            if isDone && !wasDone && !reduceMotion {
                tickPops += 1
            }
        }
        .onChange(of: showsMenu) { _, isShowing in
            guard !isShowing, let action = chosen else { return }
            chosen = nil
            // Let the menu finish closing before a sheet or dialog opens.
            Task {
                try? await Task.sleep(for: .milliseconds(350))
                onAction(action)
            }
        }
    }

    /// ☆ / ★: important to-dos move to the top of the list.
    private var importantButton: some View {
        Button {
            Haptics.tap()
            onImportant()
        } label: {
            Image(systemName: task.isImportant ? "star.fill" : "star")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(task.isImportant ? AnyShapeStyle(Self.importantFill)
                                                  : AnyShapeStyle(tint.accent.opacity(0.5)))
                .shadow(color: Color(hex: 0xFFB800).opacity(task.isImportant ? 0.45 : 0), radius: 3, x: 0, y: 1)
                .symbolEffect(.bounce, value: task.isImportant)
                .frame(width: 32, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle(scale: 0.85))
        .accessibilityLabel("Important")
        .accessibilityValue(task.isImportant ? "On" : "Off")
        .accessibilityHint(task.isImportant ? "Stops listing it first" : "Lists it first")
    }

    private static let importantFill = LinearGradient(colors: [Color(hex: 0xFFD84D), Color(hex: 0xFFA800)],
                                                      startPoint: .top, endPoint: .bottom)
}

/// The cute pop-up behind a to-do's ✏️.
struct TaskManageMenu: View {
    let task: TaskItem
    let tint: RowTint
    let choose: (TaskMenuAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(task.title)
                .font(.rounded(.caption, weight: .bold))
                .foregroundStyle(Palette.inkSoft)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 6)
                .accessibilityAddTraits(.isHeader)

            ForEach(TaskMenuAction.allCases) { action in
                if action == .delete {
                    Divider().padding(.horizontal, 12).padding(.vertical, 4)
                }
                Button {
                    Haptics.tap()
                    choose(action)
                } label: {
                    HStack(spacing: 10) {
                        Text(action.emoji)
                            .font(.system(size: 18))
                            .frame(width: 26)
                            .accessibilityHidden(true)
                        Text(action.title(for: task))
                            .font(.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(action == .delete ? Color(hex: 0xD7263D) : Palette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(MenuRowStyle(tint: tint.fill))
            }
        }
        .padding(.bottom, 8)
        .frame(width: 240)
        .presentationBackground(
            LinearGradient(colors: [Color.white, tint.fill], startPoint: .top, endPoint: .bottom)
        )
    }
}

private struct MenuRowStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(configuration.isPressed ? tint : Color.clear)
                    .padding(.horizontal, 6)
            )
    }
}

/// "Health · 5:00 PM 🔔" — the category in its colour, then time, reminder, repeat and photo.
struct TodoMetaLine: View {
    let task: TaskItem

    private var details: String {
        var line = ""
        if let time = task.time {
            line += " · " + time.formatted(date: .omitted, time: .shortened)
        }
        if let reminder = task.activeReminder, !task.isCompleted {
            if let time = task.time, time == reminder {
                line += " 🔔"
            } else if reminder.isSameDay(as: task.date) {
                line += " · 🔔 " + reminder.formatted(date: .omitted, time: .shortened)
            } else {
                line += " · 🔔 " + reminder.formatted(.dateTime.weekday(.abbreviated).hour().minute())
            }
        }
        if task.repeatOption != .never {
            line += " 🔁"
        }
        if task.photoThumbnail != nil {
            line += " 📷"
        }
        return line
    }

    var body: some View {
        let category = Text(task.choice.label).foregroundStyle(task.choice.textColor)
        let rest = Text(details).foregroundStyle(Palette.inkSoft)
        Text("\(category)\(rest)")
            .font(.rounded(.caption, weight: .semibold))
            .lineLimit(1)
            .accessibilityLabel(spokenText)
    }

    private var spokenText: String {
        var parts = [task.choice.label]
        if let time = task.time {
            parts.append("at " + time.formatted(date: .omitted, time: .shortened))
        }
        if task.activeReminder != nil, !task.isCompleted {
            parts.append("reminder on")
        }
        if task.repeatOption != .never {
            parts.append("repeats " + task.repeatOption.label.lowercased())
        }
        if task.photoThumbnail != nil {
            parts.append("has a photo")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Actions

/// The ways to add a to-do, pinned at the bottom of the To-Dos screen. The two fastest are
/// bright and glowing: the long ＋ Add Task button and the 🎙 microphone ("Speak a Task").
/// Photo and Template are smaller and softer, underneath:
///
///     [ ＋ Add Task                  ]  ( 🎙 )
///     [ 📷 Photo    ]  [ ▦ Template   ]  Speak a Task
struct TodosActionBar: View {
    let onAdd: () -> Void
    let onVoice: () -> Void
    let onPhoto: () -> Void
    let onTemplate: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Width of the microphone column, so the rows line up.
    private static let micColumn: CGFloat = 80

    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(spacing: 12) {
                addButton
                HStack(spacing: 12) {
                    VoiceMicButton(action: onVoice)
                    micLabel
                    Spacer(minLength: 0)
                }
                photoButton
                templateButton
            }
        } else {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    addButton
                    VoiceMicButton(action: onVoice)
                        .frame(width: Self.micColumn)
                }
                HStack(alignment: .top, spacing: 8) {
                    photoButton
                    templateButton
                    micLabel
                        .frame(width: Self.micColumn)
                }
            }
        }
    }

    private var addButton: some View {
        BigActionButton(title: "Add Task", symbol: "plus",
                        colors: [Color(hex: 0xFF6FB0), Palette.hotPink], glow: Palette.hotPink,
                        action: onAdd)
            .accessibilityHint("Opens the full to-do form")
    }

    /// "Speak a Task" under the microphone (tapping it listens too).
    private var micLabel: some View {
        Button {
            Haptics.tap()
            onVoice()
        } label: {
            Text("Speak a Task")
                .font(.rounded(.caption, weight: .heavy))
                .foregroundStyle(Color(hex: 0xB86E00))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
    }

    private var photoButton: some View {
        SoftActionButton(title: "Photo", symbol: "camera.fill", tint: Color(hex: 0x7A4FE0), action: onPhoto)
    }

    private var templateButton: some View {
        SoftActionButton(title: "Template", symbol: "square.grid.2x2.fill", tint: Color(hex: 0x3F63DC),
                         action: onTemplate)
    }
}

/// A large, glossy, glowing button: the pink "＋ Add Task".
private struct BigActionButton: View {
    let title: String
    let symbol: String
    /// The fill, from the top-leading corner to the bottom-trailing one.
    let colors: [Color]
    let glow: Color
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .black))
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.white.opacity(0.28)))
                Text(title)
                    .font(.rounded(.subheadline, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(Color.white)
            .shadow(color: Color.black.opacity(0.12), radius: 1, x: 0, y: 1)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(background)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(title)
    }

    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return shape
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                // A soft shine on the top half, so the button looks raised.
                shape
                    .fill(LinearGradient(colors: [Color.white.opacity(0.4), Color.white.opacity(0)],
                                         startPoint: .top, endPoint: .center))
                    .padding(2)
            )
            .overlay(shape.strokeBorder(Color.white.opacity(0.7), lineWidth: 1.5))
            .shadow(color: glow.opacity(0.45), radius: 8, x: 0, y: 4)
            .shadow(color: glow.opacity(0.25), radius: 2, x: 0, y: 1)
    }
}

/// The round yellow microphone with a gently glowing halo.
private struct VoiceMicButton: View {
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let fill = LinearGradient(colors: [Color(hex: 0xFFDA4D), Color(hex: 0xFFA800)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
    private static let halo = RadialGradient(colors: [Color(hex: 0xFFC83D).opacity(0.6), Color(hex: 0xFFDA4D).opacity(0)],
                                             center: .center, startRadius: 19, endRadius: 31)

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            ZStack {
                haloView
                Circle()
                    .fill(Self.fill)
                    .overlay(
                        Circle()
                            .fill(LinearGradient(colors: [Color.white.opacity(0.4), Color.white.opacity(0)],
                                                 startPoint: .top, endPoint: .center))
                            .padding(3)
                    )
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.8), lineWidth: 2))
                    .shadow(color: Palette.honey.opacity(0.55), radius: 8, x: 0, y: 4)
                    .frame(width: 48, height: 48)
                Image(systemName: "mic.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color(hex: 0xB86E00).opacity(0.55), radius: 1.5, x: 0, y: 1)
            }
            .frame(width: 48, height: 48)
            .contentShape(Circle())
        }
        .buttonStyle(PressScaleStyle(scale: 0.9))
        .accessibilityLabel("Speak a task")
        .accessibilityHint("Add a to-do with your voice")
    }

    /// The glow behind the microphone; it breathes slowly unless Reduce Motion is on.
    @ViewBuilder
    private var haloView: some View {
        let glow = Circle().fill(Self.halo).frame(width: 62, height: 62)
        if reduceMotion {
            glow
        } else {
            glow.phaseAnimator([false, true]) { content, isBig in
                content
                    .scaleEffect(isBig ? 1.1 : 0.9)
                    .opacity(isBig ? 0.6 : 1)
            } animation: { _ in
                .easeInOut(duration: 1.4)
            }
        }
    }
}

/// A small, soft secondary button: "📷 Photo", "▦ Template".
private struct SoftActionButton: View {
    let title: String
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.rounded(.footnote, weight: .bold))
                    .foregroundStyle(Palette.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(Capsule().fill(Color.white.opacity(0.75)))
            .overlay(Capsule().strokeBorder(tint.opacity(0.22), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(PressScaleStyle(scale: 0.95))
        .accessibilityLabel(title)
    }
}

// MARK: - Progress

/// Daily Progress at the top of the list: "Today ✨ 3 of 5 completed ● ● ● ○ ○".
/// When every to-do is done it says "✨ All done for today!" (the To-Dos screen then plays
/// the big confetti, `ConfettiCelebration`).
struct DailyProgressLine: View {
    let day: Date
    let done: Int
    let total: Int

    private var allDone: Bool { total > 0 && done == total }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                message
                Spacer(minLength: 0)
                ProgressDots(done: done, total: total)
            }
            // Very large text: the dots go under the words.
            VStack(alignment: .leading, spacing: 6) {
                message
                ProgressDots(done: done, total: total)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
        .background(Capsule().fill(Color.white.opacity(0.72)))
        .overlay(Capsule().strokeBorder(Palette.hotPink.opacity(0.14), lineWidth: 1))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: allDone)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: done)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var message: some View {
        if allDone {
            Text("✨ All done for \(day.isToday ? "today" : "the day")!")
                .font(.rounded(.subheadline, weight: .heavy))
                .foregroundStyle(Palette.berry)
                .transition(.scale(scale: 0.85).combined(with: .opacity))
        } else {
            HStack(spacing: 5) {
                Text("\(day.isToday ? "Today" : day.formatted(.dateTime.weekday(.wide))) ✨")
                    .font(.rounded(.subheadline, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                Text("\(done) of \(total) completed")
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(Palette.inkSoft)
                    .contentTransition(.numericText(value: Double(done)))
            }
            .transition(.opacity)
        }
    }

    private var accessibilityText: String {
        if allDone { return "All done for \(day.isToday ? "today" : "the day")! \(total) of \(total) completed" }
        return "\(day.isToday ? "Today" : day.formatted(.dateTime.weekday(.wide))): \(done) of \(total) completed"
    }
}

/// "● ● ● ○ ○": a dot for every to-do, filled when done. More than ten are shown in tenths.
struct ProgressDots: View {
    let done: Int
    let total: Int
    @ScaledMetric(relativeTo: .subheadline) private var size: CGFloat = 8

    private var slots: Int { min(max(total, 1), 10) }
    private var filled: Int {
        guard total > 0 else { return 0 }
        if done == total { return slots }
        return total <= 10 ? done : Int((Double(done) / Double(total) * 10).rounded(.down))
    }

    var body: some View {
        HStack(spacing: size * 0.6) {
            ForEach(0..<slots, id: \.self) { index in
                let isOn = index < filled
                Circle()
                    .fill(isOn ? AnyShapeStyle(Self.onFill) : AnyShapeStyle(Color.white))
                    .overlay(Circle().strokeBorder(Palette.hotPink.opacity(isOn ? 0 : 0.4), lineWidth: 1.2))
                    .frame(width: size, height: size)
                    .scaleEffect(isOn ? 1.1 : 1)
            }
        }
        .fixedSize()
        .accessibilityHidden(true)
    }

    private static let onFill = LinearGradient(colors: [Color(hex: 0xFF7EB6), Palette.hotPink],
                                               startPoint: .top, endPoint: .bottom)
}

/// The slim "Today's Progress" pinned under the add buttons: the counts, a heart for every
/// to-do and the kitten's cheer, in about half the height of `TodosProgressCard`.
struct TodosProgressStrip: View {
    let done: Int
    let total: Int

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [Palette.lavender, Palette.grape],
                                                        startPoint: .top, endPoint: .bottom))
                        .accessibilityHidden(true)
                    Text("Today's Progress")
                        .font(.rounded(.footnote, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                    Spacer(minLength: 4)
                    Text(total == 0 ? "No to-dos yet" : "\(done) of \(total) completed")
                        .font(.rounded(.caption, weight: .semibold))
                        .foregroundStyle(Palette.inkSoft)
                        .contentTransition(.numericText(value: Double(done)))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                HStack(spacing: 8) {
                    HeartTrack(done: done, total: total, maxSize: 14)
                        .frame(height: 16)
                    Text(TodosProgressCard.cheer(done: done, total: total))
                        .font(.rounded(.caption, weight: .heavy))
                        .foregroundStyle(Palette.berry)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .fixedSize()
                        .contentTransition(.opacity)
                }
            }
            Image("ProgressKitten")
                .resizable()
                .scaledToFit()
                .frame(width: 34)
                .accessibilityHidden(true)
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [Color.white.opacity(0.92), Color(hex: 0xFFF0F6)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Palette.hotPink.opacity(0.12), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white, lineWidth: 1.5)
        )
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: done)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(total == 0
            ? "Today's Progress: no to-dos yet"
            : "Today's Progress: \(done) of \(total) completed. \(TodosProgressCard.cheer(done: done, total: total))")
    }
}

/// "Today's Progress · 3 of 8 completed" with a heart for every to-do and the kitten's cheer.
/// (At the largest text sizes, where the add buttons are not pinned, it ends the list.)
struct TodosProgressCard: View {
    let done: Int
    let total: Int

    /// The kitten's cheer for this much progress.
    static func cheer(done: Int, total: Int) -> String {
        if total == 0 { return "Let's Plan!" }
        if done == total { return "All Done!" }
        if done == 0 { return "You Can Do It!" }
        return Double(done) / Double(total) < 0.5 ? "Great Start!" : "You're Doing Great!"
    }

    private var cheer: String { Self.cheer(done: done, total: total) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [Palette.lavender, Palette.grape],
                                                        startPoint: .top, endPoint: .bottom))
                        .accessibilityHidden(true)
                    Text("Today's Progress")
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                }
                Text("\(done) of \(total) completed")
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(Palette.inkSoft)
                    .contentTransition(.numericText())
                HeartTrack(done: done, total: total)
                    .frame(height: 24)
                    .padding(.top, 2)
            }
            .padding(16)
            .padding(.trailing, 150)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.92), Color(hex: 0xFFF0F6)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: Palette.hotPink.opacity(0.14), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white, lineWidth: 1.5)
            )
            .accessibilityElement(children: .combine)

            HStack(alignment: .bottom, spacing: -6) {
                Image("ProgressKitten")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64)
                    .accessibilityHidden(true)
                CheerBadge(text: cheer)
                    .frame(width: 96, height: 96)
            }
            .padding(.trailing, 2)
            .padding(.bottom, 4)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: done)
    }
}

/// A heart for every to-do on a thin ribbon: pink when done. Long lists are shown in tenths.
struct HeartTrack: View {
    let done: Int
    let total: Int
    /// The largest a heart may be (they shrink to fit long lists).
    var maxSize: CGFloat = 22

    private var slots: Int { total == 0 ? 5 : min(total, 10) }
    private var filled: Int {
        guard total > 0 else { return 0 }
        return total <= 10 ? done : Int((Double(done) / Double(total) * 10).rounded(.down))
    }

    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 4
            let size = min(maxSize, (proxy.size.width - spacing * CGFloat(slots - 1)) / CGFloat(slots))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(hex: 0xEBD9E2))
                    .frame(width: max(0, CGFloat(slots) * (size + spacing) - spacing - size), height: 3)
                    .padding(.leading, size / 2)
                HStack(spacing: spacing) {
                    ForEach(0..<slots, id: \.self) { index in
                        let isOn = index < filled
                        Image(systemName: "heart.fill")
                            .font(.system(size: size * 0.9))
                            .foregroundStyle(isOn ? AnyShapeStyle(LinearGradient(
                                colors: [Color(hex: 0xFF7EB6), Palette.hotPink], startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(Color(hex: 0xE6D6DE)))
                            .overlay(
                                Image(systemName: "heart")
                                    .font(.system(size: size * 0.9))
                                    .foregroundStyle(isOn ? Color.white.opacity(0.6) : Color(hex: 0xD2BCC8))
                            )
                            .frame(width: size, height: size)
                            .scaleEffect(isOn ? 1.08 : 1)
                            .symbolEffect(.bounce, value: isOn)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(done) of \(total) completed")
    }
}

/// The scalloped "You're Doing Great!" badge with a bow.
struct CheerBadge: View {
    let text: String

    var body: some View {
        ZStack {
            Scallop(bumps: 14)
                .fill(RadialGradient(colors: [Color.white, Color(hex: 0xFFE2EF)],
                                     center: .center, startRadius: 4, endRadius: 50))
                .shadow(color: Palette.hotPink.opacity(0.3), radius: 6, x: 0, y: 3)
            Scallop(bumps: 14)
                .stroke(Color(hex: 0xF7B3D1), style: StrokeStyle(lineWidth: 1.2, dash: [3, 2.5]))
                .padding(5)
            Text(text)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.berry)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .padding(16)
                .contentTransition(.opacity)
        }
        .overlay(alignment: .top) {
            Text("🎀")
                .font(.system(size: 24))
                .offset(y: -12)
                .accessibilityHidden(true)
        }
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "heart.fill")
                .font(.system(size: 13))
                .foregroundStyle(Palette.hotPink)
                .offset(x: -6, y: -8)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

/// A circle with a scalloped edge.
struct Scallop: Shape {
    var bumps: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let steps = bumps * 16
        var path = Path()
        for step in 0...steps {
            let angle = Double(step) / Double(steps) * 2 * Double.pi
            let bump = abs(cos(Double(bumps) * angle / 2))
            let r = radius * CGFloat(0.88 + 0.12 * bump)
            let point = CGPoint(x: center.x + r * CGFloat(cos(angle)), y: center.y + r * CGFloat(sin(angle)))
            if step == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Completed

/// "› Completed  4": finished to-dos wait under this button; tap it to show or hide them.
struct CompletedHeader: View {
    let count: Int
    let isOpen: Bool
    let action: () -> Void

    private static let fill = LinearGradient(colors: [Color(hex: 0xFFE1EF), Color(hex: 0xECE3FF)],
                                             startPoint: .leading, endPoint: .trailing)

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Palette.hotPink)
                    .rotationEffect(.degrees(isOpen ? 90 : 0))
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.mint)
                Text("Completed")
                    .font(.rounded(.subheadline, weight: .heavy))
                    .foregroundStyle(Palette.berry)
                Text("\(count)")
                    .font(.rounded(.caption, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Palette.hotPink.gradient))
                    .contentTransition(.numericText(value: Double(count)))
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 38)
            .background(Capsule().fill(Self.fill))
            .overlay(Capsule().strokeBorder(Color.white, lineWidth: 1.5))
            .shadow(color: Palette.hotPink.opacity(0.15), radius: 6, x: 0, y: 3)
            .contentShape(Capsule())
        }
        .buttonStyle(PressScaleStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isOpen)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: count)
        .accessibilityLabel("Completed, \(count)")
        .accessibilityValue(isOpen ? "Shown" : "Hidden")
        .accessibilityHint(isOpen ? "Hides the finished to-dos" : "Shows the finished to-dos")
    }
}

// MARK: - Feedback

/// A short message that floats above the tab bar.
struct TodoToast: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.rounded(.subheadline, weight: .bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Capsule().fill(Palette.ink.opacity(0.88)))
            .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 5)
    }
}

/// Shown when the list (or the chosen category) has no to-dos.
struct TodosEmptyCard: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("📝")
                .font(.system(size: 38))
                .accessibilityHidden(true)
            Text(title)
                .font(.rounded(.headline, weight: .heavy))
                .foregroundStyle(Palette.ink)
            Text(message)
                .font(.rounded(.subheadline))
                .foregroundStyle(Palette.inkSoft)
                .multilineTextAlignment(.center)
            Button(actionTitle, action: action)
                .buttonStyle(PillButtonStyle())
                .frame(maxWidth: 240)
                .padding(.top, 6)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Palette.bubblegum.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        )
    }
}
