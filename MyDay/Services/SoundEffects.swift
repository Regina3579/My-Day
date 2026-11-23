import AVFoundation

/// My Day's little sounds, bundled with the app (`scripts/make_sounds.py` made them):
/// a soft crystal "ting" (0.4 s) when a to-do or priority is ticked, a slightly more
/// magical chime (1.2 s) when the day's last one is done, the discovery sound
/// ("Ting… twinkle!", 0.7 s) when a first-time tip pops up, and "pop… ting ✨" (0.4 s) when
/// a mood star is picked. They are loaded at launch, so they play at once.
///
/// The to-do reminders' sounds (`ReminderSound`) are played by iOS with the notification; here
/// they play only in Settings → Reminder Sound, so each can be heard before it is chosen.
///
/// Every sound plays gently, mixes with other audio (music keeps playing), follows the Silent
/// switch and never plays while My Day is recording. Settings → Sounds & Haptics turns off the
/// ticking ones and the mood one.
@MainActor
enum SoundEffects {
    enum Sound: String, CaseIterable {
        case ting = "task_complete_ting"
        case allDone = "all_done_chime"
        /// Every first-time tip: one crystal "ting", then three tiny rising sparkles.
        case tip = "tip_discovery"
        /// The quote tip's version, ending dreamier: "ting ✨ ting-ling ✨".
        case quoteTip = "tip_discovery_dreamy"
        /// Picking a mood star: a tiny, soft bubble pop, then one delicate crystal ting.
        case moodStar = "mood_pop_ting"

        var volume: Float {
            switch self {
            case .ting: 0.5
            case .allDone: 0.55
            case .tip, .quoteTip: 0.45
            // Very quiet: it plays on every tap of a star.
            case .moodStar: 0.35
            }
        }

        /// The Settings → Sounds & Haptics switch that turns this sound off. A tip has none,
        /// since each tip shows only once.
        var setting: String? {
            switch self {
            case .ting, .allDone: Prefs.taskCompletionSound
            case .moodStar: Prefs.moodStarSound
            case .tip, .quoteTip: nil
            }
        }
    }

    /// Set while a voice note or spoken to-do or priority is being recorded.
    static var isRecording = false

    /// Plays the sounds away from the main thread.
    private static let audio = SoundPlayer()

    /// Whether the sound's switch in Settings is on (every switch is on unless turned off).
    static func isEnabled(_ sound: Sound) -> Bool {
        guard let key = sound.setting else { return true }
        return UserDefaults.standard.object(forKey: key) as? Bool ?? true
    }

    /// Loads every sound, so the first one plays without a delay.
    static func preload() {
        audio.preload()
    }

    static func play(_ sound: Sound) {
        guard isEnabled(sound), !isRecording else { return }
        audio.play(sound)
    }

    /// Plays a reminder sound in Settings → Reminder Sound, stopping the one playing, if any.
    /// It is loaded only then: Settings is the one place it plays from My Day.
    static func preview(_ sound: ReminderSound) {
        guard !isRecording, let url = sound.bundleURL else {
            stopPreview()
            return
        }
        audio.preview(url)
    }

    static func stopPreview() {
        audio.stopPreview()
    }
}

/// Loading, preparing and playing the sounds, and setting up the audio session, can wait on the
/// audio hardware, so all of it runs in order on one background queue and the screen never waits
/// for it. Its players are used only on that queue.
private final class SoundPlayer: @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.regina3579.myday.sounds", qos: .userInitiated)
    private var players: [SoundEffects.Sound: AVAudioPlayer] = [:]
    /// The reminder sound playing in Settings → Reminder Sound.
    private var previewPlayer: AVAudioPlayer?

    func preload() {
        queue.async { self.loadAll() }
    }

    func play(_ sound: SoundEffects.Sound) {
        queue.async {
            self.activateSession()
            self.loadAll()
            guard let player = self.players[sound] else { return }
            player.currentTime = 0
            player.play()
        }
    }

    func preview(_ url: URL) {
        queue.async {
            self.endPreview()
            guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
            self.activateSession()
            // As loud as Gentle Bloom's preview always was: the sounds are matched to it.
            player.volume = 0.6
            player.play()
            self.previewPlayer = player
        }
    }

    func stopPreview() {
        queue.async { self.endPreview() }
    }

    private func endPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
    }

    private func loadAll() {
        for sound in SoundEffects.Sound.allCases where players[sound] == nil {
            let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav")
                ?? Bundle.main.url(forResource: sound.rawValue, withExtension: "wav", subdirectory: "Sounds")
            guard let url, let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.volume = sound.volume
            player.prepareToPlay()
            players[sound] = player
        }
    }

    /// Ambient: mixes with music and podcasts instead of stopping them, and stays quiet when the
    /// Silent switch is on.
    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        if session.category != .ambient {
            try? session.setCategory(.ambient, mode: .default)
        }
        try? session.setActive(true)
    }
}

/// How ticking something off feels: the soft "ting" with a very light tap, or, for the
/// day's last to-do or priority, the all-done chime. Nothing plays when a tick is undone.
@MainActor
enum CompletionFeedback {
    static func completed(finishingAll: Bool) {
        SoundEffects.play(finishingAll ? .allDone : .ting)
        Haptics.softTap()
    }
}
