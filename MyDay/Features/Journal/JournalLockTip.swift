import SwiftUI

/// When My Journal Pages offers the Journal Lock tip:
/// - never on the day the journal is first opened (let people look around first);
/// - the first time the journal opens on a later day (the next day, or whenever they come back),
///   once;
/// - Got it: never again; Maybe Later: once more, 7 days later, if the journal is still unlocked;
/// - once Lock My Journal is on, or the lock was looked at from the ⋮ menu, never again.
enum JournalLockTipSchedule {
    static let laterWait: TimeInterval = 7 * 24 * 60 * 60

    /// Counts this opening of the journal and says whether the tip is due.
    static func countOpeningAndCheck(lockEnabled: Bool, now: Date = .now) -> Bool {
        let defaults = UserDefaults.standard
        if lockEnabled { defaults.set(true, forKey: Prefs.journalLockTipDone) }
        let openings = defaults.integer(forKey: Prefs.journalOpenings) + 1
        defaults.set(openings, forKey: Prefs.journalOpenings)
        var firstOpened = defaults.double(forKey: Prefs.journalFirstOpened)
        if firstOpened == 0 {
            firstOpened = now.timeIntervalSince1970
            defaults.set(firstOpened, forKey: Prefs.journalFirstOpened)
        }
        let firstDay = Date(timeIntervalSince1970: firstOpened).startOfDay
        guard !defaults.bool(forKey: Prefs.journalLockTipDone), now.startOfDay > firstDay else { return false }
        let remindAt = defaults.double(forKey: Prefs.journalLockTipRemindAt)
        // Not seen yet (remindAt 0), or seen, put off, and the 7 days are over.
        return remindAt == 0 || now.timeIntervalSince1970 >= remindAt
    }

    /// Got it, or the second showing (whatever was tapped): never again.
    static func finish() {
        UserDefaults.standard.set(true, forKey: Prefs.journalLockTipDone)
    }

    /// Maybe Later the first time: once more in 7 days.
    static func later(now: Date = .now) {
        let defaults = UserDefaults.standard
        if defaults.double(forKey: Prefs.journalLockTipRemindAt) > 0 {
            finish()
        } else {
            defaults.set(now.timeIntervalSince1970 + laterWait, forKey: Prefs.journalLockTipRemindAt)
        }
    }
}

/// The Journal Lock tip, from its design: the page softens and dims, and a pink card rises
/// with a kitten with a pink bow hugging a pink journal with a gold heart lock among hearts,
/// sparkles and flowers, "Your Journal, Your Secret! 💗", "Your thoughts are precious! ✨ Keep
/// your journal private with Journal Lock.", "Go to Settings → Journal Lock to turn it on. 🔒",
/// **Maybe Later**, **Got it** and ✕. The whole card is the design's own picture (enlarged 4×
/// with Real-ESRGAN), so its lettering is the design's; ✕ and the two buttons are tappable
/// where the picture shows them (✕, like a tap outside, is Maybe Later).
///
/// From the ⋮ menu's Lock My Journal, the same card asks instead: its last line reads "Choose
/// Face ID, a pattern or a passcode. 🔒" and the pink button **Lock It** (both written by the
/// app on the picture, its own words taken out), which goes on to set the lock up.
struct JournalLockTip: View {
    enum Kind {
        /// On its own, a day after the journal first opened: Maybe Later and Got it.
        case tip
        /// From the ⋮ menu: Maybe Later and Lock It.
        case offer
    }

    var kind: Kind = .tip
    let onGotIt: () -> Void
    let onLater: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    /// The picture's grid (750 × 828 pixels of the design).
    private static let grid = CGSize(width: 750, height: 828)

    var body: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width * 0.84, 360)
            ZStack {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial).opacity(0.4)
                    Color(hex: 0x251622).opacity(0.38)
                }
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { close(then: onLater) }
                .opacity(shown ? 1 : 0)
                .accessibilityHidden(true)
                card(width: width)
                    .scaleEffect(shown ? 1 : 0.86)
                    .opacity(shown ? 1 : 0)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
        .onAppear {
            SoundEffects.play(.tip)
            withAnimation(.spring(response: reduceMotion ? 0.3 : 0.45, dampingFraction: 0.72)) { shown = true }
            UIAccessibility.post(notification: .screenChanged,
                                 argument: kind == .tip ? "Tip: your journal, your secret. Keep it private with Journal Lock."
                                                        : "Your journal, your secret. Lock your journal?")
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { close(then: onLater) }
    }

    private func close(then action: @escaping () -> Void) {
        withAnimation(.easeIn(duration: 0.18)) { shown = false }
        Task {
            try? await Task.sleep(for: .seconds(0.18))
            action()
        }
    }

    private func card(width: CGFloat) -> some View {
        let scale = width / Self.grid.width
        func spot(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat) -> CGRect {
            CGRect(x: x0 * scale, y: y0 * scale, width: (x1 - x0) * scale, height: (y1 - y0) * scale)
        }
        return Image(kind == .tip ? "JournalLockTipArt" : "JournalLockMenuArt")
            .resizable()
            .frame(width: width, height: Self.grid.height * scale)
            .overlay(alignment: .topLeading) {
                if kind == .offer {
                    ZStack(alignment: .topLeading) {
                        // In place of "Go to Settings → Journal Lock to turn it on. 🔒".
                        Text("Choose Face ID, a pattern or a passcode. 🔒")
                            .font(.rounded(size: 22.5 * scale, weight: .medium))
                            .foregroundStyle(Color(hex: 0x9A6BC9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(width: 640 * scale, height: 34 * scale)
                            .offset(x: 55 * scale, y: 621 * scale)
                        // In place of "Got it", between the button's two sparkles.
                        Text("Lock It")
                            .font(.rounded(size: 34 * scale, weight: .heavy))
                            .foregroundStyle(Color.white)
                            .shadow(color: Color(hex: 0xD81B78).opacity(0.35), radius: 1.5 * scale, x: 0, y: 1.5 * scale)
                            .lineLimit(1)
                            .frame(width: 170 * scale, height: 50 * scale)
                            .offset(x: 472 * scale, y: 707 * scale)
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(kind == .tip
                ? "Your Journal, Your Secret! Your thoughts are precious! Keep your journal private with Journal Lock. Go to Settings, Journal Lock, to turn it on."
                : "Your Journal, Your Secret! Your thoughts are precious! Keep your journal private with Journal Lock. Choose Face ID, a pattern or a passcode.")
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    pictureButton("Maybe Later", spot(41, 687, 374, 780), shape: Capsule()) { close(then: onLater) }
                    pictureButton(kind == .tip ? "Got it" : "Lock It", spot(399, 687, 712, 780), shape: Capsule()) {
                        close(then: onGotIt)
                    }
                    pictureButton("Close", spot(655, 31, 727, 103), shape: Circle()) { close(then: onLater) }
                }
            }
    }

    private func pictureButton<S: Shape>(_ label: String, _ frame: CGRect, shape: S,
                                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Color.clear
        }
        .buttonStyle(PictureButtonStyle(shape: shape))
        .frame(width: frame.width, height: frame.height)
        .offset(x: frame.minX, y: frame.minY)
        .accessibilityLabel(label)
    }
}

/// A button drawn in a picture: a soft white flash on it while it is pressed.
private struct PictureButtonStyle<S: Shape>: ButtonStyle {
    let shape: S

    func makeBody(configuration: Configuration) -> some View {
        shape
            .fill(Color.white.opacity(configuration.isPressed ? 0.28 : 0.001))
            .overlay(configuration.label)
            .contentShape(shape)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
