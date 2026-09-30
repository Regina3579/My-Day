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
    @State private var text = ""
    @State private var isReviewing = false

    private var result: VoiceTaskParser.Result {
        VoiceTaskParser.parse(text, defaultDay: day)
    }

    /// What was understood, in the category being viewed unless another was named.
    private var draft: TaskDraft {
        var draft = result.draft
        if let selectedCategory, result.categorySource != .named {
            draft.choice = selectedCategory
        }
        return draft
    }

    private var categoryText: String {
        let label = draft.choice.label
        if result.categorySource == .named || selectedCategory != nil { return label }
        return label + " (you can change it)"
    }

    private var canAdd: Bool { !text.trimmed.isEmpty }

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
                text = transcriber.transcript
                withAnimation(.snappy) { isReviewing = true }
                Haptics.tap()
            }
        }
        .task {
            if let sample {
                text = sample
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
                    onEdit(TaskDraft(day: day))
                }
                .buttonStyle(PillButtonStyle(tint: Palette.grape))
            }
            .frame(maxWidth: 280)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Review

    private var review: some View {
        let draft = self.draft
        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                VoiceLabel(text: "I heard")
                TextField("What should I add?", text: $text, axis: .vertical)
                    .font(.rounded(.body, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1...4)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white))
                    .accessibilityLabel("What I heard")
                    .accessibilityHint("You can correct it")
                Button {
                    isReviewing = false
                    Task { await transcriber.start() }
                } label: {
                    Label("Say it again", systemImage: "mic.fill")
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(Palette.hotPink)
                        .frame(minHeight: 36)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                VoiceLabel(text: "Your new to-do")
                VStack(spacing: 0) {
                    PreviewRow(emoji: "✏️", title: "Task", value: draft.title.isEmpty ? "—" : draft.title)
                    PreviewRow(emoji: draft.choice.emoji, title: "Category", value: categoryText)
                    PreviewRow(emoji: "📅", title: "Date", value: dayText(draft.day))
                    PreviewRow(emoji: "⏰", title: "Time",
                               value: draft.time?.formatted(date: .omitted, time: .shortened) ?? "No time")
                    PreviewRow(emoji: "🔔", title: "Reminder",
                               value: draft.reminderDate.map { "On · " + $0.formatted(date: .omitted, time: .shortened) }
                                   ?? "Off",
                               isLast: draft.repeatOption == .never)
                    if draft.repeatOption != .never {
                        PreviewRow(emoji: "🔁", title: "Repeat", value: draft.repeatOption.label, isLast: true)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(0.85)))
            }

            if !result.notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(result.notes, id: \.self) { note in
                        Text("💡 " + note)
                    }
                    Text("Tap Edit to change anything before adding.")
                        .foregroundStyle(Palette.inkSoft)
                }
                .font(.rounded(.footnote, weight: .semibold))
                .foregroundStyle(Palette.cocoa)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.cream))
            }
        }
    }

    private var reviewButtons: some View {
        HStack(spacing: 10) {
            Button("Cancel") { dismiss() }
                .buttonStyle(SoftButtonStyle(tint: Palette.inkSoft))
            Button("Edit") {
                transcriber.cancel()
                onEdit(draft)
            }
            .buttonStyle(SoftButtonStyle(tint: Palette.grape))
            .disabled(!canAdd)
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
        return date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    private func addTask() {
        let draft = self.draft
        guard !draft.title.trimmed.isEmpty else { return }
        let task = draft.insertTask(into: context)
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

private struct PreviewRow: View {
    let emoji: String
    let title: String
    let value: String
    var isLast = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(emoji)
                    .frame(width: 26)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(Palette.inkSoft)
                    .frame(width: 80, alignment: .leading)
                Text(value)
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            if !isLast {
                Divider().padding(.leading, 50)
            }
        }
        .accessibilityElement(children: .combine)
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
