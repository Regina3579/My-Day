import SwiftData
import SwiftUI

/// 🎤 Voice Add: listens, shows what it heard and what it understood, and adds
/// the to-do only when the person taps Add Task.
struct VoiceTaskSheet: View {
    let day: Date
    /// The category chip chosen on the To-Dos page (nil for All). A spoken to-do goes there,
    /// unless a category is named outright ("… in my shopping list").
    var selectedCategory: CategoryChoice?
    /// Opens the full task sheet with this draft.
    let onEdit: (TaskDraft) -> Void
    /// Called with the new to-do's title after it is added.
    let onAdded: (String) -> Void
    /// Debug screenshots only: review this sentence instead of listening.
    var sample: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @State private var transcriber = SpeechTranscriber()
    /// What was heard.
    @State private var text = ""
    @State private var isReviewing = false
    /// The new to-do, filled in from what was heard and changed right here before adding.
    @State private var draft = TaskDraft(day: .now)
    /// Things to double-check, like a guessed time.
    @State private var notes: [String] = []
    /// The reminder moves with the to-do's time until it is changed by hand.
    @State private var reminderFollowsTime = true
    @State private var expanded: TaskSheetFocus?
    @FocusState private var titleFocused: Bool

    private var canAdd: Bool { !draft.title.trimmed.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                Group {
                    if isReviewing {
                        review
                    } else {
                        status
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            if isReviewing {
                reviewButtons
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .presentationBackground(
            LinearGradient(colors: [Color(hex: 0xFFF8E8), Color(hex: 0xFFF1F7)], startPoint: .top, endPoint: .bottom)
        )
        .onChange(of: transcriber.state) { _, state in
            if state == .finished {
                understand(transcriber.transcript)
                withAnimation(.snappy) { isReviewing = true }
                Haptics.tap()
            }
        }
        .task {
            if let sample {
                understand(sample)
                isReviewing = true
            } else {
                await transcriber.start()
            }
        }
        .onDisappear { transcriber.cancel() }
    }

    private var header: some View {
        HStack {
            Text("🎤 Voice Add")
                .font(.rounded(.title3, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button("Cancel") { dismiss() }
                .font(.rounded(.body, weight: .bold))
                .foregroundStyle(Palette.hotPink)
                .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: Listening and problems

    @ViewBuilder
    private var status: some View {
        switch transcriber.state {
        case .idle, .preparing, .listening, .finishing, .finished:
            listening
        case .denied(let permission):
            problem(
                emoji: permission == .microphone ? "🎙️" : "💬",
                title: permission == .microphone ? "Microphone access is off" : "Speech recognition is off",
                message: "To add to-dos by voice, allow "
                    + (permission == .microphone ? "the microphone" : "speech recognition")
                    + " for My Day in Settings. You can also type your to-do.",
                showsSettings: true
            )
        case .failed(let failure):
            switch failure {
            case .noSpeech:
                problem(emoji: "🙈", title: "I didn't catch that",
                        message: "Try again in a quiet spot, and speak close to your phone.", showsSettings: false)
            case .recognizerUnavailable:
                problem(emoji: "🌙", title: "Voice isn't available right now",
                        message: "Speech recognition needs a moment or an internet connection. Try again soon, or type your to-do.",
                        showsSettings: false)
            case .microphoneUnavailable:
                problem(emoji: "🎧", title: "The microphone couldn't start",
                        message: "Another app may be using it. Try again, or type your to-do.", showsSettings: false)
            }
        }
    }

    private var listening: some View {
        let isListening = transcriber.state == .listening
        return VStack(spacing: 22) {
            ListeningBubble(isActive: isListening)
                .padding(.top, 20)

            VStack(spacing: 6) {
                Text(listeningTitle)
                    .font(.rounded(.title3, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                Text("Say your to-do. You can add a day and a time.")
                    .font(.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(Palette.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)

            Text(transcriber.transcript.isEmpty ? "…" : transcriber.transcript)
                .font(.rounded(.title3, weight: .semibold))
                .foregroundStyle(transcriber.transcript.isEmpty ? Palette.inkSoft.opacity(0.5) : Palette.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 90)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white.opacity(0.8)))
                .animation(.easeOut(duration: 0.15), value: transcriber.transcript)
                .accessibilityLabel(transcriber.transcript.isEmpty ? "Nothing heard yet" : transcriber.transcript)

            Button {
                transcriber.stop()
            } label: {
                Text("I'm Done ✓")
            }
            .buttonStyle(PillButtonStyle())
            .frame(maxWidth: 260)
            .disabled(!isListening)
            .opacity(isListening ? 1 : 0.5)
        }
        .frame(maxWidth: .infinity)
    }

    private var listeningTitle: String {
        switch transcriber.state {
        case .listening: "I'm listening…"
        case .finishing, .finished: "Got it! ✨"
        default: "Getting ready…"
        }
    }

    private func problem(emoji: String, title: String, message: String, showsSettings: Bool) -> some View {
        VStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 54))
                .padding(.top, 30)
                .accessibilityHidden(true)
            Text(title)
                .font(.rounded(.title3, weight: .heavy))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.rounded(.subheadline, weight: .medium))
                .foregroundStyle(Palette.inkSoft)
                .multilineTextAlignment(.center)
            VStack(spacing: 10) {
                if showsSettings {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                    .buttonStyle(PillButtonStyle())
                } else {
                    Button("Try Again 🎤") {
                        Task { await transcriber.start() }
                    }
                    .buttonStyle(PillButtonStyle())
                }
                Button("Type Instead") {
                    onEdit(TaskDraft(day: day, choice: selectedCategory ?? .builtIn(.personal)))
                }
                .buttonStyle(PillButtonStyle(tint: Palette.grape))
            }
            .frame(maxWidth: 280)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Understanding

    /// Fills in the new to-do from what was heard. It goes to the category chip chosen on
    /// the To-Dos page, unless a category was named outright.
    private func understand(_ heard: String) {
        text = heard
        let result = VoiceTaskParser.parse(heard, defaultDay: day)
        var understood = result.draft
        if let selectedCategory, result.categorySource != .named {
            understood.choice = selectedCategory
        }
        draft = understood
        notes = result.notes
        reminderFollowsTime = understood.reminderEnabled && understood.reminderDate == understood.time
        expanded = nil
    }

    // MARK: Review

    /// What was heard, then the new to-do with every part ready to change right here: the
    /// task, its category, the date and time, a reminder and repeat.
    private var review: some View {
        VStack(alignment: .leading, spacing: 18) {
            heardCard

            VStack(alignment: .leading, spacing: 8) {
                VoiceLabel(text: "Your new to-do")
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("✏️")
                        .accessibilityHidden(true)
                    TextField("What's the to-do?", text: $draft.title)
                        .font(.rounded(.headline, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .focused($titleFocused)
                        .submitLabel(.done)
                        .onSubmit { titleFocused = false }
                        .accessibilityLabel("Task")
                    if !draft.title.isEmpty && titleFocused {
                        Button {
                            draft.title = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Palette.inkSoft.opacity(0.5))
                        }
                        .accessibilityLabel("Clear the task")
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(titleFocused ? Palette.hotPink.opacity(0.6) : Palette.bubblegum.opacity(0.25),
                                      lineWidth: 1.5)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                VoiceLabel(text: "Category")
                CategoryPicker(selection: $draft.choice)
            }

            VStack(spacing: 10) {
                OptionRow(emoji: "📅", title: "Date & Time", value: whenSummary, isExpanded: expanded == .when) {
                    toggle(.when)
                } panel: {
                    whenPanel
                }
                OptionRow(emoji: "🔔", title: "Reminder", value: reminderSummary, isExpanded: expanded == .reminder) {
                    toggle(.reminder)
                } panel: {
                    reminderPanel
                }
                OptionRow(emoji: "🔁", title: "Repeat", value: draft.repeatOption.label,
                          isExpanded: expanded == .repeatRule) {
                    toggle(.repeatRule)
                } panel: {
                    repeatPanel
                }
            }

            if !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(notes, id: \.self) { note in
                        Text("💡 " + note)
                    }
                    Text("You can change anything above before adding.")
                        .foregroundStyle(Palette.inkSoft)
                }
                .font(.rounded(.footnote, weight: .semibold))
                .foregroundStyle(Palette.cocoa)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.cream))
            }

            Button {
                transcriber.cancel()
                onEdit(finishedDraft)
            } label: {
                Label("Add a photo or a note", systemImage: "photo.badge.plus")
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(Palette.grape)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .disabled(!canAdd)
            .opacity(canAdd ? 1 : 0.5)
        }
    }

    /// "I heard …" and Say it again.
    private var heardCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            VoiceLabel(text: "I heard")
            HStack(alignment: .top, spacing: 10) {
                Text(text.trimmed.isEmpty ? "Nothing yet. Type your to-do below." : "“\(text.trimmed)”")
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(Palette.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(text.trimmed.isEmpty ? "Nothing heard yet" : "I heard: \(text)")
                Button {
                    isReviewing = false
                    Task { await transcriber.start() }
                } label: {
                    Label("Say it again", systemImage: "mic.fill")
                        .font(.rounded(.footnote, weight: .bold))
                        .foregroundStyle(Palette.hotPink)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 36)
                        .background(Capsule().fill(Color(hex: 0xFFE3F0)))
                }
                .buttonStyle(PressScaleStyle())
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.6)))
        }
    }

    // MARK: Date, time, reminder and repeat

    private var whenPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                DayChip(title: "Today", isOn: draft.day.isToday) { setDay(Date()) }
                DayChip(title: "Tomorrow", isOn: draft.day.isSameDay(as: Date().adding(days: 1))) {
                    setDay(Date().adding(days: 1))
                }
                Spacer(minLength: 0)
                DatePicker("Date", selection: Binding(get: { draft.day }, set: { setDay($0) }),
                           displayedComponents: .date)
                    .labelsHidden()
            }
            Toggle(isOn: hasTime.animation()) {
                Label("Add a time", systemImage: "clock.fill")
                    .font(.rounded(.subheadline, weight: .semibold))
            }
            .tint(Palette.hotPink)
            if draft.time != nil {
                DatePicker("Time", selection: time, displayedComponents: .hourAndMinute)
                    .font(.rounded(.subheadline, weight: .semibold))
            }
        }
    }

    private var reminderPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: reminderOn.animation()) {
                Label("Remind me", systemImage: "bell.fill")
                    .font(.rounded(.subheadline, weight: .semibold))
            }
            .tint(Palette.hotPink)
            if draft.reminderEnabled {
                DatePicker("Alert", selection: reminderDate, in: Date()...)
                    .font(.rounded(.subheadline, weight: .semibold))
                if let taskTime = draft.time, taskTime > Date(), draft.reminderDate != taskTime {
                    Button("Use the task time") {
                        draft.reminderDate = taskTime
                        reminderFollowsTime = true
                    }
                    .font(.rounded(.caption, weight: .bold))
                }
            }
            Text("My Day sends a gentle notification at this time.")
                .font(.rounded(.caption))
                .foregroundStyle(Palette.inkSoft)
        }
    }

    private var repeatPanel: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
            ForEach(RepeatOption.allCases) { option in
                DayChip(title: option.label, isOn: draft.repeatOption == option) {
                    draft.repeatOption = option
                }
            }
        }
    }

    private func toggle(_ section: TaskSheetFocus) {
        titleFocused = false
        withAnimation(.snappy) { expanded = expanded == section ? nil : section }
        Haptics.tap()
    }

    /// Moves the to-do to `newDay`, keeping its time of day (and a reminder that follows it).
    private func setDay(_ newDay: Date) {
        let start = newDay.startOfDay
        draft.day = start
        if let clock = draft.time {
            setTime(start.atTime(of: clock))
        }
    }

    private func setTime(_ clock: Date?) {
        draft.time = clock.map { draft.day.atTime(of: $0) }
        guard draft.reminderEnabled, reminderFollowsTime, let newTime = draft.time else { return }
        if newTime > Date() {
            draft.reminderDate = newTime
        }
    }

    private var hasTime: Binding<Bool> {
        Binding(
            get: { draft.time != nil },
            set: { isOn in setTime(isOn ? (draft.time ?? NewTaskSheet.nextHour(on: draft.day)) : nil) }
        )
    }

    private var time: Binding<Date> {
        Binding(
            get: { draft.time ?? NewTaskSheet.nextHour(on: draft.day) },
            set: { setTime($0) }
        )
    }

    private var reminderOn: Binding<Bool> {
        Binding(
            get: { draft.reminderEnabled },
            set: { isOn in
                draft.reminderEnabled = isOn
                if isOn, (draft.reminderDate ?? .distantPast) <= Date() {
                    // The to-do's time when it is still ahead, or else the next hour.
                    if let taskTime = draft.time, taskTime > Date() {
                        draft.reminderDate = taskTime
                        reminderFollowsTime = true
                    } else {
                        draft.reminderDate = NewTaskSheet.nextHour(on: Date())
                        reminderFollowsTime = false
                    }
                }
            }
        )
    }

    private var reminderDate: Binding<Date> {
        Binding(
            get: { draft.reminderDate ?? draft.time ?? NewTaskSheet.nextHour(on: Date()) },
            set: { newDate in
                draft.reminderDate = newDate
                reminderFollowsTime = newDate == draft.time
            }
        )
    }

    private var whenSummary: String {
        let dayText = dayText(draft.day)
        guard let clock = draft.time else { return dayText }
        return dayText + " · " + clock.formatted(date: .omitted, time: .shortened)
    }

    private var reminderSummary: String {
        guard draft.reminderEnabled, let alert = draft.reminderDate else { return "Off" }
        if alert.isSameDay(as: draft.day) {
            return alert.formatted(date: .omitted, time: .shortened)
        }
        return alert.formatted(.dateTime.day().month(.abbreviated).hour().minute())
    }

    // MARK: Adding

    private var reviewButtons: some View {
        HStack(spacing: 10) {
            Button("Cancel") { dismiss() }
                .buttonStyle(SoftButtonStyle(tint: Palette.inkSoft))
            Button("Add Task ✨", action: addTask)
                .buttonStyle(PillButtonStyle())
                .disabled(!canAdd)
                .opacity(canAdd ? 1 : 0.6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func dayText(_ date: Date) -> String {
        if date.isToday { return "Today" }
        if date.isSameDay(as: Date().adding(days: 1)) { return "Tomorrow" }
        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    /// The to-do as it will be added: a reminder that is off keeps no time.
    private var finishedDraft: TaskDraft {
        var finished = draft
        finished.title = draft.title.trimmed
        if !finished.reminderEnabled {
            finished.reminderDate = nil
        }
        return finished
    }

    private func addTask() {
        let finished = finishedDraft
        guard !finished.title.isEmpty else {
            titleFocused = true
            return
        }
        let task = finished.insertTask(into: context)
        ReminderCenter.sync(task)
        if task.activeReminder != nil {
            // First reminder: this is when My Day asks for notification permission.
            Task {
                if await ReminderCenter.requestPermission() { ReminderCenter.sync(task) }
            }
        }
        Haptics.success()
        onAdded(task.title)
        dismiss()
    }
}

// MARK: - Pieces

/// The pulsing microphone.
private struct ListeningBubble: View {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .fill(Palette.hotPink.opacity(0.1))
                    .frame(width: 104 + CGFloat(ring) * 34, height: 104 + CGFloat(ring) * 34)
                    .scaleEffect(pulse && isActive ? 1.08 : 0.94)
                    .animation(
                        isActive && !reduceMotion
                            ? .easeInOut(duration: 1.1).repeatForever(autoreverses: true).delay(Double(ring) * 0.18)
                            : .default,
                        value: pulse && isActive
                    )
            }
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0xFF62A5), Palette.hotPink],
                                     center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: 60))
                .frame(width: 96, height: 96)
                .shadow(color: Palette.hotPink.opacity(0.45), radius: 14, x: 0, y: 6)
            Image(systemName: isActive ? "waveform" : "mic.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(Color.white)
                .symbolEffect(.variableColor.iterative, isActive: isActive && !reduceMotion)
        }
        .frame(height: 180)
        .onAppear { pulse = true }
        .accessibilityHidden(true)
    }
}

private struct VoiceLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.rounded(.footnote, weight: .heavy))
            .foregroundStyle(Palette.berry.opacity(0.8))
            .textCase(.uppercase)
            .accessibilityAddTraits(.isHeader)
    }
}

/// White capsule button for the secondary choices.
private struct SoftButtonStyle: ButtonStyle {
    var tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(.headline, weight: .bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Capsule().fill(Color.white))
            .overlay(Capsule().strokeBorder(tint.opacity(0.25), lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
