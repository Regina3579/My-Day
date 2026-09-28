import SwiftUI

// MARK: - Header scene

/// Proportions of the To-Dos header scene, as fractions of the screen width (853 px design).
enum TodosScene {
    /// Soft strip above the scenery, used when the status bar is taller than in the design.
    static let extensionHeight: CGFloat = 80.0 / 853.0
    static let imageHeight: CGFloat = 482.0 / 853.0
    /// The scenery itself (the design's top 402 px).
    static let bodyHeight: CGFloat = 402.0 / 853.0
    static let designStatusBar: CGFloat = 60.0 / 853.0

    /// How far the scenery moves down so the sign stays clear of the back button.
    static func shift(width: CGFloat, safeTop: CGFloat) -> CGFloat {
        min(max(0, safeTop - width * designStatusBar), width * extensionHeight)
    }
}

/// The illustrated header: the "Today's To-Dos" sign, the girl and her puppy.
struct TodosHero: View {
    let width: CGFloat
    let safeTop: CGFloat

    var body: some View {
        let shift = TodosScene.shift(width: width, safeTop: safeTop)
        Image("TodosScene")
            .resizable()
            .frame(width: width, height: width * TodosScene.imageHeight)
            .offset(y: shift - width * TodosScene.extensionHeight)
            .frame(width: width, height: shift + width * TodosScene.bodyHeight, alignment: .top)
            .clipped()
            .accessibilityHidden(true)
    }
}

// MARK: - Date and quote

/// "Today ♥ · 27 May 2025" with the day's gentle quote.
struct TodayHeaderCard: View {
    let day: Date

    var body: some View {
        HStack(spacing: 12) {
            DateBadge(date: day)
                .scaleEffect(1.25)
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(day.isToday ? "Today" : day.formatted(.dateTime.weekday(.wide)))
                        .font(.rounded(.title3, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Palette.hotPink)
                        .accessibilityHidden(true)
                }
                Text(day.formatted(.dateTime.day().month(.wide).year()))
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(Palette.inkSoft)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: true, vertical: false)

            Capsule()
                .fill(Palette.hotPink.opacity(0.25))
                .frame(width: 1.5, height: 44)
                .accessibilityHidden(true)

            HStack(spacing: 6) {
                Text("☀️")
                    .font(.system(size: 26))
                    .accessibilityHidden(true)
                Text("“\(TodoQuotes.quote(for: day))”")
                    .font(.custom("Noteworthy-Bold", size: 14, relativeTo: .subheadline))
                    .foregroundStyle(Palette.berry)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Color.white, Color(hex: 0xFFF1F7)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Palette.hotPink.opacity(0.14), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white, lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Category filter

/// "All · Personal · Work · Health · Learning · Shopping".
struct CategoryChipBar: View {
    @Binding var selection: TaskCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(title: "All", icon: nil, tint: Palette.hotPink, isOn: selection == nil) {
                    selection = nil
                }
                ForEach(TaskCategory.allCases) { category in
                    CategoryChip(title: category.label, icon: category.emoji, tint: category.color,
                                 isOn: selection == category) {
                        selection = selection == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
    }
}

struct CategoryChip: View {
    let title: String
    /// An emoji; `nil` shows a heart (used by "All").
    let icon: String?
    let tint: Color
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
                    .foregroundStyle(isOn ? Color.white : Palette.ink)
            }
            .font(.rounded(.subheadline, weight: .semibold))
            .padding(.horizontal, 13)
            .frame(minHeight: 38)
            .background(
                Capsule().fill(isOn ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(Color.white.opacity(0.85)))
            )
            .overlay(Capsule().strokeBorder(isOn ? Color.white.opacity(0.7) : tint.opacity(0.18), lineWidth: 1))
            .shadow(color: tint.opacity(isOn ? 0.35 : 0.1), radius: 6, x: 0, y: 3)
            .overlay(alignment: .bottom) {
                if isOn {
                    Circle()
                        .fill(tint)
                        .frame(width: 7, height: 7)
                        .offset(y: 11)
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

/// One to-do: tick box on the left, title and details, and the ✏️ that manages it.
struct TodoRow: View {
    let task: TaskItem
    let tint: RowTint
    let onToggle: () -> Void
    let onOpen: () -> Void
    let onAction: (TaskMenuAction) -> Void

    @State private var showsMenu = false
    @State private var chosen: TaskMenuAction?

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onToggle) {
                CheckBubble(isOn: task.isCompleted, tint: tint.accent, size: 28)
                    .frame(width: 48, height: 48)
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
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows the details")

            Button {
                Haptics.tap()
                showsMenu = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tint.accent)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.85)))
                    .overlay(Circle().strokeBorder(tint.edge, lineWidth: 1))
                    .frame(width: 46, height: 48)
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
        .frame(minHeight: 60)
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
        let category = Text(task.category.label).foregroundStyle(task.category.color)
        let rest = Text(details).foregroundStyle(Palette.inkSoft)
        Text("\(category)\(rest)")
            .font(.rounded(.caption, weight: .semibold))
            .lineLimit(1)
            .accessibilityLabel(spokenText)
    }

    private var spokenText: String {
        var parts = [task.category.label]
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

/// The ways to add a to-do, pinned at the bottom of the To-Dos screen. The three fastest
/// are big, bright and glowing: ＋ Add Task, ⚡ Quick Add and the 🎙 microphone
/// ("Speak a Task"). Photo and Template are smaller and softer, underneath:
///
///     [ ＋ Add Task ]  [ ⚡ Quick Add ]  ( 🎙 )
///     [ 📷 Photo    ]  [ ▦ Template   ]  Speak a Task
struct TodosActionBar: View {
    let onAdd: () -> Void
    let onQuickAdd: () -> Void
    let onVoice: () -> Void
    let onPhoto: () -> Void
    let onTemplate: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Width of the microphone column, so the rows line up.
    private static let micColumn: CGFloat = 86

    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(spacing: 12) {
                addButton
                quickAddButton
                HStack(spacing: 12) {
                    VoiceMicButton(action: onVoice)
                    micLabel
                    Spacer(minLength: 0)
                }
                photoButton
                templateButton
            }
        } else {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    addButton
                    quickAddButton
                    VoiceMicButton(action: onVoice)
                        .frame(width: Self.micColumn)
                }
                HStack(alignment: .top, spacing: 10) {
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

    private var quickAddButton: some View {
        BigActionButton(title: "Quick Add", symbol: "bolt.fill",
                        colors: [Color(hex: 0xC39BFF), Color(hex: 0x8A4DF0)], glow: Palette.grape,
                        action: onQuickAdd)
            .accessibilityHint("Type a title and save, nothing else")
    }

    /// "Speak a Task" under the microphone (tapping it listens too).
    private var micLabel: some View {
        Button {
            Haptics.tap()
            onVoice()
        } label: {
            Text("Speak a Task")
                .font(.rounded(.caption, weight: .heavy))
                .foregroundStyle(LinearGradient(colors: [Palette.hotPink, Palette.grape],
                                                startPoint: .leading, endPoint: .trailing))
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

/// A large, glossy, glowing button: "＋ Add Task" in pink, "⚡ Quick Add" in lilac.
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
                    .font(.system(size: 14, weight: .black))
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.white.opacity(0.28)))
                Text(title)
                    .font(.rounded(.subheadline, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(Color.white)
            .shadow(color: Color.black.opacity(0.12), radius: 1, x: 0, y: 1)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(background)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(title)
    }

    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
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
            .shadow(color: glow.opacity(0.5), radius: 12, x: 0, y: 6)
            .shadow(color: glow.opacity(0.25), radius: 3, x: 0, y: 1)
    }
}

/// The round pink-to-purple microphone with a gently glowing halo.
private struct VoiceMicButton: View {
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let fill = LinearGradient(colors: [Color(hex: 0xFF4FA0), Color(hex: 0x8A4DF0)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
    private static let halo = RadialGradient(colors: [Color(hex: 0xC06BFF).opacity(0.55), Color(hex: 0xFF4FA0).opacity(0)],
                                             center: .center, startRadius: 24, endRadius: 40)

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
                    .shadow(color: Palette.grape.opacity(0.5), radius: 10, x: 0, y: 5)
                    .frame(width: 62, height: 62)
                Image(systemName: "mic.fill")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.black.opacity(0.12), radius: 1, x: 0, y: 1)
            }
            .frame(width: 62, height: 62)
            .contentShape(Circle())
        }
        .buttonStyle(PressScaleStyle(scale: 0.9))
        .accessibilityLabel("Speak a task")
        .accessibilityHint("Say a to-do, like “Buy milk tomorrow at 6 PM”")
    }

    /// The glow behind the microphone; it breathes slowly unless Reduce Motion is on.
    @ViewBuilder
    private var haloView: some View {
        let glow = Circle().fill(Self.halo).frame(width: 80, height: 80)
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
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.rounded(.footnote, weight: .bold))
                    .foregroundStyle(Palette.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 44)
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
/// When every to-do is done it says "✨ All done for today!", and each time the last one is
/// ticked it plays a tiny sparkle burst.
struct DailyProgressLine: View {
    let day: Date
    let done: Int
    let total: Int
    /// Goes up each time the last to-do is ticked; every change plays the burst once.
    let celebration: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
        .background(Capsule().fill(Color.white.opacity(0.72)))
        .overlay(Capsule().strokeBorder(Palette.hotPink.opacity(0.14), lineWidth: 1))
        .overlay {
            if celebration > 0 && allDone && !reduceMotion {
                SparkleBurst()
                    .id(celebration)
            }
        }
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

/// A tiny burst of sparkles, hearts, stars and confetti that plays once when it appears.
struct SparkleBurst: View {
    @State private var isOut = false
    @State private var isFaded = false

    private struct Piece {
        let symbol: String
        let color: Color
        let size: CGFloat
        /// Where the piece ends up, from the centre: wide and low, so it stays around the line.
        let x: CGFloat
        let y: CGFloat
        let spin: Double
    }

    private static let colors = [Palette.hotPink, Palette.butter, Palette.grape, Palette.bubblegum,
                                 Palette.mint, Palette.honey, Palette.lavender]
    private static let symbols = ["sparkle", "heart.fill", "star.fill", "circle.fill"]

    /// Fourteen pieces around an ellipse, each a little different.
    private static let pieces: [Piece] = (0..<14).map { index in
        let angle: Double = Double(index) / 14 * 2 * Double.pi + 0.2
        let reach: Double = index.isMultiple(of: 2) ? 1.0 : 0.72
        let symbol: String = symbols[index % symbols.count]
        let size: CGFloat = symbol == "circle.fill" ? 5 : (index.isMultiple(of: 3) ? 11 : 9)
        let x: CGFloat = CGFloat(cos(angle) * 120 * reach)
        let y: CGFloat = CGFloat(sin(angle) * 26 * reach) - 6
        let spin: Double = index.isMultiple(of: 2) ? 140 : -110
        return Piece(symbol: symbol, color: colors[index % colors.count], size: size, x: x, y: y, spin: spin)
    }

    var body: some View {
        ZStack {
            ForEach(Self.pieces.indices, id: \.self) { index in
                let piece = Self.pieces[index]
                Image(systemName: piece.symbol)
                    .font(.system(size: piece.size, weight: .bold))
                    .foregroundStyle(piece.color)
                    .scaleEffect(isOut ? 1 : 0.3)
                    .rotationEffect(.degrees(isOut ? piece.spin : 0))
                    .offset(x: isOut ? piece.x : 0, y: isOut ? piece.y : 0)
            }
        }
        .opacity(isFaded ? 0 : 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) { isOut = true }
            withAnimation(.easeIn(duration: 0.45).delay(0.6)) { isFaded = true }
        }
    }
}

/// "Today's Progress · 3 of 8 completed" with a heart for every to-do and the kitten's cheer.
struct TodosProgressCard: View {
    let done: Int
    let total: Int

    private var cheer: String {
        if total == 0 { return "Let's Plan!" }
        if done == total { return "All Done!" }
        if done == 0 { return "You Can Do It!" }
        return Double(done) / Double(total) < 0.5 ? "Great Start!" : "You're Doing Great!"
    }

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

    private var slots: Int { total == 0 ? 5 : min(total, 10) }
    private var filled: Int {
        guard total > 0 else { return 0 }
        return total <= 10 ? done : Int((Double(done) / Double(total) * 10).rounded(.down))
    }

    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 4
            let size = min(22, (proxy.size.width - spacing * CGFloat(slots - 1)) / CGFloat(slots))
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
