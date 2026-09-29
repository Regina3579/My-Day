import SwiftUI
import UIKit

/// Speak instead of typing: a round 🎙 that types what you say into `text`, after anything
/// already written. Tap it again to stop (it also stops by itself after a short pause).
/// Uses the same speech recognition as Voice Add, on the device when the language allows.
struct DictationButton: View {
    @Binding var text: String
    var diameter: CGFloat = 40
    /// Set while it is listening, so the text field can say so.
    var isListening: Binding<Bool> = .constant(false)
    /// Called when listening starts (for example to put the keyboard away).
    var onStart: (() -> Void)?

    @State private var transcriber = SpeechTranscriber()
    /// What was written before listening started; the words heard go after it.
    @State private var base = ""
    @State private var problem: Problem?
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Problem {
        case denied(SpeechTranscriber.Permission)
        case failed(SpeechTranscriber.Failure)

        var title: String {
            switch self {
            case .denied(.microphone): "Microphone access is off"
            case .denied(.speech): "Speech recognition is off"
            case .failed(.noSpeech): "I didn't catch that"
            case .failed(.recognizerUnavailable): "Voice isn't available right now"
            case .failed(.microphoneUnavailable): "The microphone couldn't start"
            }
        }

        var message: String {
            switch self {
            case .denied(let permission):
                "To speak instead of typing, allow "
                    + (permission == .microphone ? "the microphone" : "speech recognition")
                    + " for My Day in Settings. You can also type it."
            case .failed(.noSpeech): "Try again in a quiet spot, and speak close to your phone."
            case .failed(.recognizerUnavailable):
                "Speech recognition needs a moment or an internet connection. Try again soon, or type it."
            case .failed(.microphoneUnavailable): "Another app may be using it. Try again, or type it."
            }
        }

        var showsSettings: Bool {
            if case .denied = self { return true }
            return false
        }
    }

    var body: some View {
        let active = transcriber.isActive
        Button(action: toggle) {
            Image(systemName: active ? "stop.fill" : "mic.fill")
                .font(.system(size: diameter * 0.42, weight: .bold))
                .foregroundStyle(active ? Color.white : Palette.hotPink)
                .symbolEffect(.pulse, isActive: active && !reduceMotion)
                .frame(width: diameter, height: diameter)
                .background(Circle().fill(active ? AnyShapeStyle(Color(hex: 0xE5484D).gradient)
                                                 : AnyShapeStyle(Color(hex: 0xFFE3F0))))
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 1.5))
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel(active ? "Stop listening" : "Speak instead of typing")
        .onChange(of: transcriber.transcript) { _, heard in
            guard !heard.isEmpty else { return }
            text = base.isEmpty ? heard : base + " " + heard
        }
        .onChange(of: transcriber.state) { _, state in
            isListening.wrappedValue = transcriber.isActive
            switch state {
            case .finished: Haptics.success()
            case .denied(let permission): problem = .denied(permission)
            case .failed(let failure): problem = .failed(failure)
            default: break
            }
        }
        .alert(problem?.title ?? "", isPresented: Binding(get: { problem != nil },
                                                           set: { if !$0 { problem = nil } })) {
            if problem?.showsSettings == true, let settings = URL(string: UIApplication.openSettingsURLString) {
                Button("Open Settings") { openURL(settings) }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(problem?.message ?? "")
        }
        .onDisappear { transcriber.cancel() }
    }

    private func toggle() {
        switch transcriber.state {
        case .listening:
            transcriber.stop()
        case .preparing:
            transcriber.cancel()
            isListening.wrappedValue = false
        case .finishing:
            break
        default:
            base = text.trimmed
            onStart?()
            Haptics.tap()
            Task { await transcriber.start() }
        }
    }
}
