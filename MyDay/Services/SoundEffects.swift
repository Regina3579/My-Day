import AVFoundation

/// My Day's little sounds, bundled with the app (`scripts/make_sounds.py` made them):
/// a soft crystal "ting" (0.4 s) when a to-do or priority is ticked, a slightly more
/// magical chime (1.2 s) when the day's last one is done, and the discovery sound
/// ("Ting… twinkle!", 0.7 s) when a first-time tip pops up.
///
/// They are loaded at launch, so they play at once. They play gently, mix with other audio
/// (music keeps playing), follow the Silent switch and never play while My Day is
/// recording. Settings → Sounds & Haptics → Task Completion Sound turns off the ticking ones.
@MainActor
enum SoundEffects {
    enum Sound: String, CaseIterable {
        case ting = "task_complete_ting"
        case allDone = "all_done_chime"
        /// Every first-time tip: one crystal "ting", then three tiny rising sparkles.
        case tip = "tip_discovery"
        /// The quote tip's version, ending dreamier: "ting ✨ ting-ling ✨".
        case quoteTip = "tip_discovery_dreamy"

        var volume: Float {
            switch self {
            case .ting: 0.5
            case .allDone: 0.55
            case .tip, .quoteTip: 0.45
            }
        }

        /// Only the ticking sounds follow Task Completion Sound; a tip shows only once.
        var isTaskSound: Bool {
            self == .ting || self == .allDone
        }
    }

    /// Set while a voice note or spoken to-do or priority is being recorded.
    static var isRecording = false

    private static var players: [Sound: AVAudioPlayer] = [:]

    /// Settings → Sounds & Haptics → Task Completion Sound (on unless turned off).
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Prefs.taskCompletionSound) as? Bool ?? true
    }

    /// Loads every sound, so the first one plays without a delay.
    static func preload() {
        for sound in Sound.allCases where players[sound] == nil {
            let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav")
                ?? Bundle.main.url(forResource: sound.rawValue, withExtension: "wav", subdirectory: "Sounds")
            guard let url, let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.volume = sound.volume
            player.prepareToPlay()
            players[sound] = player
        }
    }

    static func play(_ sound: Sound) {
        guard !sound.isTaskSound || isEnabled, !isRecording else { return }
        let session = AVAudioSession.sharedInstance()
        // Ambient: mixes with music and podcasts instead of stopping them, and stays quiet
        // when the Silent switch is on.
        if session.category != .ambient {
            try? session.setCategory(.ambient, mode: .default)
        }
        try? session.setActive(true)
        preload()
        guard let player = players[sound] else { return }
        player.currentTime = 0
        player.play()
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
