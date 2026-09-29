import AVFoundation
import Observation
import Speech

/// Live speech-to-text for Voice Add, built on Apple's Speech framework.
///
/// Permissions are requested only when listening starts. Recognition runs on
/// the device whenever the language supports it.
@MainActor
@Observable
final class SpeechTranscriber {
    enum Permission: Equatable {
        case speech, microphone
    }

    enum Failure: Equatable {
        case noSpeech, microphoneUnavailable, recognizerUnavailable
    }

    enum State: Equatable {
        case idle
        case preparing
        case listening
        case finishing
        case finished
        case denied(Permission)
        case failed(Failure)
    }

    private(set) var state: State = .idle
    /// The words heard so far.
    private(set) var transcript = ""

    private struct Update: Sendable {
        let text: String?
        let isFinal: Bool
        let failed: Bool
    }

    /// Lets the audio tap feed the request from the audio thread.
    private final class RequestBox: @unchecked Sendable {
        let request: SFSpeechAudioBufferRecognitionRequest
        init(_ request: SFSpeechAudioBufferRecognitionRequest) { self.request = request }
    }

    private var recognizer: SFSpeechRecognizer?
    private var engine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var updates: AsyncStream<Update>.Continuation?
    private var listenTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var limitTask: Task<Void, Never>?
    /// Bumped by `cancel()`, so a start that is still waiting for permission gives up.
    private var generation = 0

    /// Stops by itself after this much quiet.
    private static let pauseAfterSpeech: Duration = .seconds(2)
    private static let waitForFirstWord: Duration = .seconds(8)
    private static let longest: Duration = .seconds(50)

    var isActive: Bool {
        state == .preparing || state == .listening || state == .finishing
    }

    // MARK: Control

    /// Asks for permission if needed, then starts listening.
    func start() async {
        guard !isActive else { return }
        generation += 1
        let current = generation
        transcript = ""
        state = .preparing

        guard await Self.speechAuthorization() == .authorized else {
            if current == generation { state = .denied(.speech) }
            return
        }
        guard await Self.microphoneAllowed() else {
            if current == generation { state = .denied(.microphone) }
            return
        }
        guard current == generation else { return }

        guard let recognizer = recognizer ?? Self.makeRecognizer(), recognizer.isAvailable else {
            state = .failed(.recognizerUnavailable)
            return
        }
        self.recognizer = recognizer

        do {
            try beginListening(with: recognizer)
            SoundEffects.isRecording = true
            state = .listening
            restartTimer(after: Self.waitForFirstWord)
            limitTask = Task { [weak self] in
                try? await Task.sleep(for: Self.longest)
                guard !Task.isCancelled else { return }
                self?.stop()
            }
        } catch {
            teardown()
            state = .failed(.microphoneUnavailable)
        }
    }

    /// Stops listening and keeps what was heard.
    func stop() {
        guard state == .listening else { return }
        state = .finishing
        stopAudio()
        request?.endAudio()
        // The final result usually arrives at once; don't wait for it forever.
        restartTimer(after: .seconds(1.5), finish: true)
    }

    /// Stops everything without keeping a result (for example when the sheet closes).
    func cancel() {
        generation += 1
        teardown()
        state = .idle
    }

    // MARK: Listening

    private func beginListening(with recognizer: SFSpeechRecognizer) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        request.addsPunctuation = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw CocoaError(.featureUnsupported)
        }
        Self.installTap(on: input, format: format, feeding: RequestBox(request))
        engine.prepare()
        try engine.start()

        let (stream, continuation) = AsyncStream.makeStream(of: Update.self)
        recognitionTask = Self.recognize(with: recognizer, request: request) { update in
            continuation.yield(update)
        }
        listenTask = Task { [weak self] in
            for await update in stream {
                guard let self else { return }
                self.receive(update)
            }
        }
        self.engine = engine
        self.request = request
        self.updates = continuation
    }

    private func receive(_ update: Update) {
        guard state == .listening || state == .finishing else { return }
        if let text = update.text, text != transcript {
            transcript = text
            if state == .listening {
                restartTimer(after: Self.pauseAfterSpeech)
            }
        }
        if update.isFinal || update.failed {
            complete()
        }
    }

    /// After `delay`, stops listening — or, when `finish` is set, wraps up.
    private func restartTimer(after delay: Duration, finish: Bool = false) {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self else { return }
            if finish {
                self.complete()
            } else {
                self.stop()
            }
        }
    }

    private func complete() {
        guard state == .listening || state == .finishing else { return }
        teardown()
        state = transcript.trimmed.isEmpty ? .failed(.noSpeech) : .finished
    }

    private func stopAudio() {
        guard let engine else { return }
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        self.engine = nil
    }

    private func teardown() {
        SoundEffects.isRecording = false
        timerTask?.cancel()
        timerTask = nil
        limitTask?.cancel()
        limitTask = nil
        stopAudio()
        request?.endAudio()
        request = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        updates?.finish()
        updates = nil
        listenTask?.cancel()
        listenTask = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: Helpers that run off the main actor

    private static func makeRecognizer() -> SFSpeechRecognizer? {
        SFSpeechRecognizer() ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    nonisolated private static func speechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        let current = SFSpeechRecognizer.authorizationStatus()
        guard current == .notDetermined else { return current }
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    nonisolated private static func microphoneAllowed() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return true
        case .denied: return false
        default: return await AVAudioApplication.requestRecordPermission()
        }
    }

    /// The tap runs on the audio thread, so it is created outside the main actor.
    nonisolated private static func installTap(on node: AVAudioInputNode, format: AVAudioFormat,
                                               feeding box: RequestBox) {
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            box.request.append(buffer)
        }
    }

    /// Results arrive on a background queue and are passed on as plain values.
    nonisolated private static func recognize(
        with recognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest,
        deliver: @escaping @Sendable (Update) -> Void
    ) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { result, error in
            deliver(Update(text: result?.bestTranscription.formattedString,
                           isFinal: result?.isFinal ?? false,
                           failed: error != nil))
        }
    }
}
