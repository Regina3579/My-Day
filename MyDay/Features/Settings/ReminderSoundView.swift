import SwiftUI
import SwiftData

/// Settings → Sounds & Haptics → Reminder Sound: the nine sounds a to-do's reminder can arrive
/// with. Tapping one plays it and chooses it; the reminders already set are rescheduled with it.
/// Gentle Bloom is free; the other eight come with My Day Pro, so for a free account they wear
/// a crown, and tapping one plays it and offers Pro.
struct ReminderSoundView: View {
    @Environment(\.modelContext) private var context
    @Environment(MyDayPro.self) private var pro
    @AppStorage(Prefs.reminderSound) private var chosen: ReminderSound = .gentleBloom
    @State private var proOffer: ProFeature?
    /// The sound playing, for its row's moving speaker, and the taps so far (each tap starts it
    /// over, even on the same sound).
    @State private var playing: ReminderSound?
    @State private var taps = 0

    var body: some View {
        Form {
            Section {
                ForEach(ReminderSound.allCases) { sound in
                    Button {
                        choose(sound)
                    } label: {
                        ReminderSoundRow(sound: sound, isOn: sound == current, isPlaying: sound == playing,
                                         isLocked: sound.isPro && !pro.isActive)
                    }
                    .accessibilityHint("Plays the sound and chooses it")
                }
            } footer: {
                Text("Tap a sound to hear it and choose it. Your to-do reminders arrive with it, following your iPhone's notification settings. With Silent on, reminders and the sounds here stay quiet." + (pro.isActive ? "" : " The sounds with a crown come with My Day Pro."))
            }
        }
        .font(.rounded(.body))
        .scrollContentBackground(.hidden)
        .tabBarSafeArea()
        .background(DreamyBackground(theme: .garden))
        .navigationTitle("Reminder Sound")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: taps) {
            guard let sound = playing else { return }
            do {
                try await Task.sleep(for: .seconds(sound.seconds))
                playing = nil
            } catch {
                // Another tap: its own wait takes over.
            }
        }
        .onDisappear {
            SoundEffects.stopPreview()
        }
        .proOffer($proOffer)
    }

    /// The sound reminders arrive with now: Gentle Bloom while a Pro sound waits for Pro.
    private var current: ReminderSound { chosen.applying(pro: pro.isActive) }

    private func choose(_ sound: ReminderSound) {
        SoundEffects.preview(sound)
        playing = sound
        taps += 1
        if sound.isPro && !pro.isActive {
            proOffer = .reminderSounds
            return
        }
        guard sound != chosen else { return }
        chosen = sound
        // A reminder keeps the sound it was scheduled with.
        ReminderCenter.syncAll(in: context)
    }
}

/// One sound: its icon, name and what it sounds like, with a tick when it is the one chosen.
struct ReminderSoundRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let sound: ReminderSound
    var isOn = false
    var isPlaying = false
    /// A Pro sound, for a free account: a crown on its icon.
    var isLocked = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isPlaying ? "speaker.wave.2.fill" : sound.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white)
                .symbolEffect(.variableColor.iterative, isActive: isPlaying && !reduceMotion)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(sound.tint.gradient))
                .overlay(alignment: .topTrailing) {
                    if isLocked {
                        ProCrown(size: 18)
                            .offset(x: 6, y: -6)
                    }
                }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(sound.title)
                    .font(.rounded(.body, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(sound.detail)
                    .font(.rounded(.footnote, weight: .medium))
                    .foregroundStyle(Palette.inkSoft)
                    .accessibilityLabel("\(sound.kind), \(sound.seconds.formatted()) seconds")
            }
            Spacer(minLength: 0)
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isOn ? Palette.hotPink : Palette.inkSoft.opacity(0.35))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(isLocked ? "My Day Pro" : "")
        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
    }
}

extension ReminderSound {
    /// The row icon.
    var symbol: String {
        switch self {
        case .gentleBloom: "music.note"
        case .sparklingSunrise: "sun.max.fill"
        case .sparklingSunriseSoft: "sun.haze.fill"
        case .gentleFlute: "leaf.fill"
        case .softMelodicFlute: "music.quarternote.3"
        case .softTing: "bell.fill"
        case .morningHarp: "sunrise.fill"
        case .windChimes: "wind"
        case .happyMarimba: "face.smiling.fill"
        }
    }

    /// The row icon's colour.
    var tint: Color {
        switch self {
        case .gentleBloom: Palette.hotPink
        case .sparklingSunrise: Palette.honey
        case .sparklingSunriseSoft: Color(hex: 0xF7A35C)
        case .gentleFlute: Color(hex: 0x1FAE6A)
        case .softMelodicFlute: Palette.grape
        case .softTing: Color(hex: 0x3B9BF2)
        case .morningHarp: Palette.bubblegum
        case .windChimes: Color(hex: 0x14B8A6)
        case .happyMarimba: Color(hex: 0xF0646B)
        }
    }
}
