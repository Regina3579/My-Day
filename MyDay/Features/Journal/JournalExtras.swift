import AVFoundation
import CoreLocation
import SwiftUI

// MARK: - Presets

enum JournalPresets {
    static let stickers = [
        "💖", "🌸", "⭐️", "🌈", "🦋", "🍓", "🧁", "🎀",
        "🌷", "☀️", "🌙", "✨", "🐶", "🐱", "🐰", "🍰",
        "☕️", "🎈", "🌻", "🍀", "💌", "🎵", "📚", "🏆"
    ]
    static let maxStickers = 12

    static let tags = [
        "Good Vibes", "Happy Thoughts", "Better Me", "Grateful", "Self-Care", "Family",
        "Friends", "Love", "Cozy", "Proud", "Adventure", "Learning", "Work", "Health", "Dreams"
    ]

    static let prompts = [
        "Today I'm grateful for…",
        "A beautiful moment today…",
        "Something that made me smile…",
        "Something I learned today…",
        "A kind thing someone did…",
        "I felt proud when…",
        "Something I want to remember…",
        "A small joy today…",
        "What I did for myself today…",
        "Tomorrow I want to…"
    ]
}

// MARK: - Sheet chrome

/// A soft pink sheet with a title and a Done button, used by every extra.
private struct ExtraSheet<Content: View>: View {
    let title: String
    let content: Content
    @Environment(\.dismiss) private var dismiss

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding(20)
            }
            .background(Color(hex: 0xFFF3F8))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}

// MARK: - Stickers

struct StickerPickerSheet: View {
    @Binding var stickers: String

    private var isFull: Bool { stickers.count >= JournalPresets.maxStickers }

    var body: some View {
        ExtraSheet(title: "Add Stickers") {
            VStack(alignment: .leading, spacing: 18) {
                if !stickers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("On your page (tap one to take it off)")
                            .font(.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(JournalStyle.soft)
                        StickerRow(stickers: stickers, size: 34) { index in
                            var characters = Array(stickers)
                            characters.remove(at: index)
                            stickers = String(characters)
                        }
                    }
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                    ForEach(JournalPresets.stickers, id: \.self) { sticker in
                        Button {
                            guard !isFull else { return }
                            stickers.append(sticker)
                            Haptics.tap()
                        } label: {
                            Text(sticker)
                                .font(.system(size: 32))
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white))
                        }
                        .buttonStyle(PressScaleStyle())
                        .accessibilityLabel("Add \(sticker)")
                    }
                }
                .opacity(isFull ? 0.5 : 1)
                if isFull {
                    Text("That's \(JournalPresets.maxStickers) stickers, the most for one page.")
                        .font(.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(JournalStyle.soft)
                }
            }
        }
    }
}

/// Stickers in a row; tapping one calls `onTap` with its position.
struct StickerRow: View {
    let stickers: String
    var size: CGFloat = 30
    var onTap: ((Int) -> Void)?

    var body: some View {
        let items = Array(stickers)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items.indices, id: \.self) { index in
                    Text(String(items[index]))
                        .font(.system(size: size))
                        .rotationEffect(.degrees(index.isMultiple(of: 2) ? -8 : 8))
                        .onTapGesture { onTap?(index) }
                        .accessibilityLabel(String(items[index]))
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Tags

struct TagPickerSheet: View {
    @Binding var tags: [String]

    var body: some View {
        ExtraSheet(title: "Tag Your Mood") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Pick the words that fit your day.")
                    .font(.rounded(.body, weight: .semibold))
                    .foregroundStyle(JournalStyle.soft)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                    ForEach(JournalPresets.tags, id: \.self) { tag in
                        let isOn = tags.contains(tag)
                        Button {
                            if isOn { tags.removeAll { $0 == tag } } else { tags.append(tag) }
                            Haptics.tap()
                        } label: {
                            Text(tag)
                                .font(.rounded(.body, weight: .bold))
                                .foregroundStyle(isOn ? Color.white : JournalStyle.plum)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity, minHeight: 46)
                                .background(
                                    Capsule().fill(isOn ? AnyShapeStyle(JournalStyle.pinkGradient)
                                                        : AnyShapeStyle(Color.white))
                                )
                        }
                        .buttonStyle(PressScaleStyle())
                        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
                    }
                }
            }
        }
    }
}

/// Tags as small pink pills.
struct TagChips: View {
    let tags: [String]
    var onRemove: ((String) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text("#" + tag)
                        if onRemove != nil {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .heavy))
                        }
                    }
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(JournalStyle.pink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(JournalStyle.pinkFill))
                    .onTapGesture { onRemove?(tag) }
                    .accessibilityLabel(onRemove == nil ? tag : "Remove \(tag)")
                }
            }
        }
    }
}

// MARK: - Weather

struct WeatherSheet: View {
    @Binding var weather: JournalWeather?
    @Binding var temperature: String

    @State private var degrees: Int
    @State private var addsTemperature: Bool

    /// °F where the person's region uses it, °C elsewhere.
    private static var unit: String { Locale.current.measurementSystem == .us ? "°F" : "°C" }

    init(weather: Binding<JournalWeather?>, temperature: Binding<String>) {
        _weather = weather
        _temperature = temperature
        let number = Int(temperature.wrappedValue.filter { $0.isNumber || $0 == "-" })
        _degrees = State(initialValue: number ?? (Locale.current.measurementSystem == .us ? 72 : 22))
        _addsTemperature = State(initialValue: number != nil)
    }

    var body: some View {
        ExtraSheet(title: "Today's Weather") {
            VStack(alignment: .leading, spacing: 18) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    ForEach(JournalWeather.allCases) { option in
                        let isOn = option == weather
                        Button {
                            weather = isOn ? nil : option
                            Haptics.tap()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: option.symbol)
                                    .symbolRenderingMode(.multicolor)
                                    .font(.system(size: 28))
                                    .frame(height: 32)
                                Text(option.label)
                                    .font(.rounded(.caption, weight: .bold))
                                    .foregroundStyle(JournalStyle.ink)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity, minHeight: 78)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(isOn ? JournalStyle.pinkFill : Color.white))
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(isOn ? JournalStyle.pink : Color.clear, lineWidth: 2))
                        }
                        .buttonStyle(PressScaleStyle())
                        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $addsTemperature) {
                        Label("Temperature", systemImage: "thermometer.medium")
                            .font(.rounded(.body, weight: .bold))
                            .foregroundStyle(JournalStyle.ink)
                    }
                    .tint(JournalStyle.pink)
                    if addsTemperature {
                        Stepper(value: $degrees, in: -40...130) {
                            Text("\(degrees)\(Self.unit)")
                                .font(.rounded(.title2, weight: .heavy))
                                .foregroundStyle(JournalStyle.ink)
                                .contentTransition(.numericText())
                        }
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white))
            }
            .onChange(of: addsTemperature) { _, _ in syncTemperature() }
            .onChange(of: degrees) { _, _ in syncTemperature() }
        }
    }

    private func syncTemperature() {
        temperature = addsTemperature ? "\(degrees)\(Self.unit)" : ""
    }
}

// MARK: - Place

struct PlaceSheet: View {
    @Binding var place: String
    @State private var finder = PlaceFinder()
    @State private var isFinding = false
    @State private var message: String?
    @FocusState private var focused: Bool

    var body: some View {
        ExtraSheet(title: "Location") {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Where were you today?", text: $place)
                    .font(.rounded(.title3, weight: .semibold))
                    .foregroundStyle(JournalStyle.ink)
                    .focused($focused)
                    .submitLabel(.done)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 56)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(JournalStyle.pink.opacity(focused ? 0.6 : 0.25), lineWidth: 1.5))

                Button {
                    findPlace()
                } label: {
                    HStack(spacing: 8) {
                        if isFinding {
                            ProgressView().tint(Color.white)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text("Use My Location")
                    }
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Capsule().fill(JournalStyle.pinkGradient))
                }
                .buttonStyle(PressScaleStyle())
                .disabled(isFinding)

                if let message {
                    Text(message)
                        .font(.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(JournalStyle.soft)
                }
            }
        }
    }

    private func findPlace() {
        isFinding = true
        message = nil
        Task {
            if let name = await finder.placeName() {
                place = name
                Haptics.success()
            } else {
                message = "My Day couldn't find where you are. Check that Location is on for My Day in Settings, or type the place."
            }
            isFinding = false
        }
    }
}

/// Finds the name of the place you are (your neighbourhood and town), once.
@MainActor
final class PlaceFinder: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var pending: CheckedContinuation<CLLocation?, Never>?

    /// nil when location is off, not allowed or not found.
    func placeName() async -> String? {
        guard let location = await currentLocation(),
              let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first
        else { return nil }
        var parts: [String] = []
        for part in [placemark.subLocality ?? placemark.name, placemark.locality].compactMap({ $0 })
            where !parts.contains(part) {
            parts.append(part)
        }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private func currentLocation() async -> CLLocation? {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        switch manager.authorizationStatus {
        case .denied, .restricted:
            return nil
        default:
            break
        }
        pending?.resume(returning: nil)
        return await withCheckedContinuation { continuation in
            pending = continuation
            if manager.authorizationStatus == .notDetermined {
                manager.requestWhenInUseAuthorization()
            } else {
                manager.requestLocation()
            }
        }
    }

    private func authorizationChanged() {
        guard pending != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        case .denied, .restricted: finish(nil)
        default: break
        }
    }

    private func finish(_ location: CLLocation?) {
        pending?.resume(returning: location)
        pending = nil
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in self.authorizationChanged() }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        Task { @MainActor in self.finish(location) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish(nil) }
    }
}

// MARK: - Voice note

/// Records and plays a journal voice note (AAC, mono, up to five minutes).
@MainActor
final class VoiceNoteRecorder {
    static let maxDuration: TimeInterval = 300

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("journal-voice-note.m4a")

    // Not observed: views read these from a TimelineView.
    var isRecording: Bool { recorder?.isRecording ?? false }
    var isPlaying: Bool { player?.isPlaying ?? false }
    var recordedTime: TimeInterval { recorder?.currentTime ?? 0 }
    var playedTime: TimeInterval { player?.currentTime ?? 0 }

    /// false when the microphone isn't allowed or can't start.
    func startRecording() async -> Bool {
        stopPlaying()
        guard await AVAudioApplication.requestRecordPermission() else { return false }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            guard recorder.record(forDuration: Self.maxDuration) else { return false }
            self.recorder = recorder
            SoundEffects.isRecording = true
            return true
        } catch {
            return false
        }
    }

    /// Stops recording and returns the note.
    func stopRecording() -> Data? {
        recorder?.stop()
        recorder = nil
        SoundEffects.isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        let data = try? Data(contentsOf: fileURL)
        try? FileManager.default.removeItem(at: fileURL)
        return data
    }

    func play(_ data: Data) {
        stopPlaying()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        player = try? AVAudioPlayer(data: data)
        player?.play()
    }

    func stopPlaying() {
        player?.stop()
        player = nil
    }

    static func duration(of data: Data) -> TimeInterval {
        (try? AVAudioPlayer(data: data))?.duration ?? 0
    }

    static func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

/// Joins two voice notes into one, the second after the first (to record more onto a note).
enum VoiceNoteJoiner {
    /// nil when the audio can't be read or written.
    static func join(_ first: Data, _ second: Data) async -> Data? {
        let folder = FileManager.default.temporaryDirectory
        let name = UUID().uuidString
        let firstURL = folder.appendingPathComponent("\(name)-1.m4a")
        let secondURL = folder.appendingPathComponent("\(name)-2.m4a")
        let outputURL = folder.appendingPathComponent("\(name)-joined.m4a")
        defer {
            for url in [firstURL, secondURL, outputURL] {
                try? FileManager.default.removeItem(at: url)
            }
        }
        do {
            try first.write(to: firstURL)
            try second.write(to: secondURL)
            let composition = AVMutableComposition()
            guard let track = composition.addMutableTrack(withMediaType: .audio,
                                                          preferredTrackID: kCMPersistentTrackID_Invalid)
            else { return nil }
            var cursor = CMTime.zero
            for url in [firstURL, secondURL] {
                guard let source = try await AVURLAsset(url: url).loadTracks(withMediaType: .audio).first
                else { return nil }
                let range = try await source.load(.timeRange)
                try track.insertTimeRange(range, of: source, at: cursor)
                cursor = CMTimeAdd(cursor, range.duration)
            }
            guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
            else { return nil }
            if #available(iOS 18, *) {
                try await export.export(to: outputURL, as: .m4a)
            } else {
                export.outputURL = outputURL
                export.outputFileType = .m4a
                await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
                    export.exportAsynchronously { done.resume() }
                }
                guard export.status == .completed else { return nil }
            }
            return try Data(contentsOf: outputURL)
        } catch {
            return nil
        }
    }
}

/// A voice note on the page being written: already saved, or just recorded.
struct VoiceNoteDraft: Identifiable {
    let id = UUID()
    /// The saved note (nil until the page is saved).
    var existing: JournalVoiceNote?
    var audio: Data
    var duration: TimeInterval
    var recordedAt: Date
    /// More was recorded onto it since it was saved.
    var isChanged = false

    init(audio: Data, duration: TimeInterval, recordedAt: Date = .now) {
        self.audio = audio
        self.duration = duration
        self.recordedAt = recordedAt
    }

    init(saved note: JournalVoiceNote) {
        existing = note
        audio = note.audio
        duration = note.duration
        recordedAt = note.createdAt
    }

    /// The page's voice notes, the one from before a page could hold several first.
    @MainActor
    static func drafts(of entry: JournalEntry?) -> [VoiceNoteDraft] {
        guard let entry else { return [] }
        var drafts: [VoiceNoteDraft] = []
        if let earlier = entry.voiceNote {
            drafts.append(VoiceNoteDraft(audio: earlier, duration: VoiceNoteRecorder.duration(of: earlier),
                                         recordedAt: entry.createdAt))
        }
        drafts += entry.sortedVoiceNotes.map(VoiceNoteDraft.init(saved:))
        return drafts
    }

    /// "Voice note", or "Voice note 2" when the page has several.
    static func title(index: Int, count: Int) -> String {
        count > 1 ? "Voice note \(index + 1)" : "Voice note"
    }
}

/// "Voice Notes": record a new note as often as you like, or tap Continue on one to record
/// more onto its end (in the morning, then again in the afternoon).
struct VoiceNoteSheet: View {
    @Binding var notes: [VoiceNoteDraft]
    /// Starts recording onto this note when the sheet opens (its Continue button on the page).
    let continuing: VoiceNoteDraft.ID?

    @State private var recorder = VoiceNoteRecorder()
    /// The note being recorded onto (nil while recording a new one).
    @State private var target: VoiceNoteDraft.ID?
    @State private var playing: VoiceNoteDraft.ID?
    @State private var isJoining = false
    @State private var isDenied = false

    init(notes: Binding<[VoiceNoteDraft]>, continuing: VoiceNoteDraft.ID? = nil) {
        _notes = notes
        self.continuing = continuing
    }

    var body: some View {
        ExtraSheet(title: "Voice Notes") {
            TimelineView(.periodic(from: .now, by: 0.2)) { _ in
                VStack(spacing: 18) {
                    recorderPanel
                    if !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("My voice notes")
                                .font(.rounded(.headline, weight: .heavy))
                                .foregroundStyle(JournalStyle.plum)
                            ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                                row(note, index: index)
                            }
                        }
                    }
                    if isDenied {
                        Text("Please allow the microphone for My Day in Settings to record a voice note.")
                            .font(.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(JournalStyle.soft)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .task {
            if let continuing, notes.contains(where: { $0.id == continuing }) {
                start(onto: continuing)
            }
        }
        .onDisappear {
            if recorder.isRecording { stop() }
            recorder.stopPlaying()
        }
    }

    // MARK: Recorder

    private var targetIndex: Int? {
        target.flatMap { id in notes.firstIndex { $0.id == id } }
    }

    private var targetName: String {
        guard let index = targetIndex else { return "Voice note" }
        return VoiceNoteDraft.title(index: index, count: notes.count)
    }

    private var recorderPanel: some View {
        let isRecording = recorder.isRecording
        let earlier = targetIndex.map { notes[$0].duration } ?? 0
        return VStack(spacing: 14) {
            Text(VoiceNoteRecorder.format(isRecording ? earlier + recorder.recordedTime : 0))
                .font(.rounded(size: 44, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(JournalStyle.ink)

            Button {
                if isRecording { stop() } else { start(onto: nil) }
            } label: {
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 92, height: 92)
                    .background(Circle().fill(isRecording ? AnyShapeStyle(Color(hex: 0xE5484D).gradient)
                                                          : AnyShapeStyle(JournalStyle.purpleGradient)))
                    .shadow(color: JournalStyle.purple.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(PressScaleStyle())
            .disabled(isJoining)
            .accessibilityLabel(isRecording ? "Stop recording" : "Record a new voice note")

            HStack(spacing: 8) {
                if isJoining {
                    ProgressView()
                        .tint(JournalStyle.purple)
                }
                Text(status(isRecording: isRecording))
                    .font(.rounded(.body, weight: .semibold))
                    .foregroundStyle(JournalStyle.soft)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.white))
    }

    private func status(isRecording: Bool) -> String {
        if isJoining { return "Adding it to \(targetName)…" }
        if isRecording {
            return target == nil ? "Recording… tap to stop" : "Adding to \(targetName)… tap to stop"
        }
        return notes.isEmpty ? "Tap to record (up to 5 minutes)" : "Tap to record a new voice note"
    }

    private func row(_ note: VoiceNoteDraft, index: Int) -> some View {
        let isPlaying = recorder.isPlaying && playing == note.id
        let isTarget = target == note.id && (recorder.isRecording || isJoining)
        return HStack(spacing: 10) {
            Button {
                if isPlaying {
                    recorder.stopPlaying()
                } else {
                    playing = note.id
                    recorder.play(note.audio)
                }
            } label: {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(JournalStyle.purpleGradient))
            }
            .buttonStyle(PressScaleStyle())
            .disabled(recorder.isRecording || isJoining)
            .accessibilityLabel(isPlaying ? "Stop" : "Play")

            VStack(alignment: .leading, spacing: 2) {
                Text(VoiceNoteDraft.title(index: index, count: notes.count))
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(JournalStyle.ink)
                    .lineLimit(1)
                Text("\(VoiceNoteRecorder.format(note.duration)) · \(note.recordedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.rounded(.subheadline, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(JournalStyle.soft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)

            Button {
                start(onto: note.id)
            } label: {
                Label("Continue", systemImage: "mic.badge.plus")
                    .font(.rounded(.subheadline, weight: .heavy))
                    .foregroundStyle(JournalStyle.pink)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 12)
                    .frame(minHeight: 40)
                    .background(Capsule().fill(JournalStyle.pinkFill))
            }
            .buttonStyle(PressScaleStyle())
            .disabled(recorder.isRecording || isJoining)
            .accessibilityLabel("Continue recording \(VoiceNoteDraft.title(index: index, count: notes.count))")

            Button {
                if playing == note.id { recorder.stopPlaying() }
                withAnimation(.snappy) { notes.removeAll { $0.id == note.id } }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(JournalStyle.soft)
                    .frame(width: 36, height: 44)
            }
            .disabled(recorder.isRecording || isJoining)
            .accessibilityLabel("Delete \(VoiceNoteDraft.title(index: index, count: notes.count))")
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(isTarget ? JournalStyle.pinkFill : Color(hex: 0xF3EBFF)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(isTarget ? JournalStyle.pink.opacity(0.6) : Color.clear, lineWidth: 1.5))
    }

    // MARK: Actions

    /// Records a new note (`id` nil) or more onto the note `id`.
    private func start(onto id: VoiceNoteDraft.ID?) {
        recorder.stopPlaying()
        target = id
        Task {
            let started = await recorder.startRecording()
            isDenied = !started
            if started {
                Haptics.tap()
            } else {
                target = nil
            }
        }
    }

    private func stop() {
        guard let recording = recorder.stopRecording(), !recording.isEmpty else {
            target = nil
            return
        }
        Haptics.success()
        let length = VoiceNoteRecorder.duration(of: recording)
        guard let id = target, let index = notes.firstIndex(where: { $0.id == id }) else {
            withAnimation(.snappy) { notes.append(VoiceNoteDraft(audio: recording, duration: length)) }
            target = nil
            return
        }
        isJoining = true
        let earlier = notes[index].audio
        Task {
            let joined = await VoiceNoteJoiner.join(earlier, recording)
            if let joined, let index = notes.firstIndex(where: { $0.id == id }) {
                notes[index].audio = joined
                notes[index].duration = VoiceNoteRecorder.duration(of: joined)
                notes[index].isChanged = true
            } else {
                // It couldn't be added on, so it's kept as a note of its own.
                notes.append(VoiceNoteDraft(audio: recording, duration: length))
            }
            isJoining = false
            target = nil
        }
    }
}

/// A voice note on a page: play or stop, with its length and when it was recorded. On the
/// page being written it can also be continued or deleted.
struct VoiceNotePlayer: View {
    let data: Data
    var title = "Voice note"
    /// Its length in seconds (worked out from the audio when nil).
    var duration: TimeInterval?
    var recordedAt: Date?
    var onContinue: (() -> Void)?
    var onDelete: (() -> Void)?
    @State private var recorder = VoiceNoteRecorder()

    var body: some View {
        let length = VoiceNoteRecorder.format(duration ?? VoiceNoteRecorder.duration(of: data))
        let time = recordedAt.map { " · " + $0.formatted(date: .omitted, time: .shortened) } ?? ""
        TimelineView(.periodic(from: .now, by: 0.25)) { _ in
            HStack(spacing: 12) {
                Button {
                    if recorder.isPlaying { recorder.stopPlaying() } else { recorder.play(data) }
                } label: {
                    Image(systemName: recorder.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(JournalStyle.purpleGradient))
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityLabel(recorder.isPlaying ? "Stop \(title)" : "Play \(title)")

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(JournalStyle.ink)
                        .lineLimit(1)
                    Text(recorder.isPlaying ? "\(VoiceNoteRecorder.format(recorder.playedTime)) / \(length)" : length + time)
                        .font(.rounded(.subheadline, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(JournalStyle.soft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
                if let onContinue {
                    Button {
                        recorder.stopPlaying()
                        onContinue()
                    } label: {
                        Image(systemName: "mic.badge.plus")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(JournalStyle.pink)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(JournalStyle.pinkFill))
                    }
                    .buttonStyle(PressScaleStyle())
                    .accessibilityLabel("Continue recording \(title)")
                }
                if let onDelete {
                    Button {
                        recorder.stopPlaying()
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(JournalStyle.soft)
                            .frame(width: 40, height: 44)
                    }
                    .accessibilityLabel("Delete \(title)")
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(hex: 0xF3EBFF)))
        }
        .onDisappear { recorder.stopPlaying() }
    }
}
