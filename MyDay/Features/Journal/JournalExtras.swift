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
        "Friends", "Love", "Cozy", "Proud", "Adventure", "Learning", "Work", "Health"
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
            return true
        } catch {
            return false
        }
    }

    /// Stops recording and returns the note.
    func stopRecording() -> Data? {
        recorder?.stop()
        recorder = nil
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

struct VoiceNoteSheet: View {
    @Binding var voiceNote: Data?
    @State private var recorder = VoiceNoteRecorder()
    @State private var isDenied = false

    var body: some View {
        // Worked out once per change, not on every tick.
        let length = voiceNote.map { VoiceNoteRecorder.format(VoiceNoteRecorder.duration(of: $0)) } ?? "0:00"
        ExtraSheet(title: "Voice Note") {
            TimelineView(.periodic(from: .now, by: 0.2)) { _ in
                VStack(spacing: 18) {
                    Text(recorder.isRecording ? VoiceNoteRecorder.format(recorder.recordedTime) : length)
                        .font(.rounded(size: 44, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(JournalStyle.ink)

                    Button {
                        toggleRecording()
                    } label: {
                        Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 92, height: 92)
                            .background(Circle().fill(recorder.isRecording
                                                      ? AnyShapeStyle(Color(hex: 0xE5484D).gradient)
                                                      : AnyShapeStyle(JournalStyle.purpleGradient)))
                            .shadow(color: JournalStyle.purple.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(PressScaleStyle())
                    .accessibilityLabel(recorder.isRecording ? "Stop recording" : "Record")

                    Text(recorder.isRecording ? "Recording… tap to stop"
                                              : (voiceNote == nil ? "Tap to record (up to 5 minutes)" : "Tap to record again"))
                        .font(.rounded(.body, weight: .semibold))
                        .foregroundStyle(JournalStyle.soft)

                    if let note = voiceNote, !recorder.isRecording {
                        HStack(spacing: 12) {
                            Button {
                                if recorder.isPlaying { recorder.stopPlaying() } else { recorder.play(note) }
                            } label: {
                                Label(recorder.isPlaying ? "Stop" : "Play", systemImage: recorder.isPlaying ? "stop.fill" : "play.fill")
                                    .font(.rounded(.headline, weight: .heavy))
                                    .foregroundStyle(JournalStyle.purple)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(Capsule().fill(Color.white))
                            }
                            .buttonStyle(PressScaleStyle())
                            Button(role: .destructive) {
                                recorder.stopPlaying()
                                voiceNote = nil
                            } label: {
                                Label("Delete", systemImage: "trash")
                                    .font(.rounded(.headline, weight: .heavy))
                                    .foregroundStyle(Color(hex: 0xD7263D))
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(Capsule().fill(Color.white))
                            }
                            .buttonStyle(PressScaleStyle())
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
        .onDisappear {
            if recorder.isRecording, let data = recorder.stopRecording() {
                voiceNote = data
            }
            recorder.stopPlaying()
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            if let data = recorder.stopRecording() {
                voiceNote = data
            }
            Haptics.success()
        } else {
            Task {
                isDenied = !(await recorder.startRecording())
                if !isDenied { Haptics.tap() }
            }
        }
    }
}

/// A voice note on a page: play or stop, with its length.
struct VoiceNotePlayer: View {
    let data: Data
    var onDelete: (() -> Void)?
    @State private var recorder = VoiceNoteRecorder()

    var body: some View {
        let length = VoiceNoteRecorder.format(VoiceNoteRecorder.duration(of: data))
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
                .accessibilityLabel(recorder.isPlaying ? "Stop voice note" : "Play voice note")

                VStack(alignment: .leading, spacing: 2) {
                    Text("Voice note")
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(JournalStyle.ink)
                    Text(recorder.isPlaying ? "\(VoiceNoteRecorder.format(recorder.playedTime)) / \(length)" : length)
                        .font(.rounded(.subheadline, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(JournalStyle.soft)
                }
                Spacer(minLength: 0)
                if let onDelete {
                    Button {
                        recorder.stopPlaying()
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(JournalStyle.soft)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Delete voice note")
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(hex: 0xF3EBFF)))
        }
        .onDisappear { recorder.stopPlaying() }
    }
}
