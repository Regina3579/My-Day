import SwiftUI

/// When My Journal Pages offers the Journal Lock tip:
/// - the first time the journal opens, never (let people look around first);
/// - the second time, once;
/// - Got it: never again; Maybe Later: once more, 7 days later, if the journal is still unlocked;
/// - once Lock My Journal is on, never again.
enum JournalLockTipSchedule {
    static let laterWait: TimeInterval = 7 * 24 * 60 * 60

    /// Counts this opening of the journal and says whether the tip is due.
    static func countOpeningAndCheck(lockEnabled: Bool, now: Date = .now) -> Bool {
        let defaults = UserDefaults.standard
        if lockEnabled { defaults.set(true, forKey: Prefs.journalLockTipDone) }
        let openings = defaults.integer(forKey: Prefs.journalOpenings) + 1
        defaults.set(openings, forKey: Prefs.journalOpenings)
        guard !defaults.bool(forKey: Prefs.journalLockTipDone), openings >= 2 else { return false }
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
struct JournalLockTip: View {
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
            UIAccessibility.post(notification: .screenChanged, argument: "Tip: your journal, your secret. Keep it private with Journal Lock.")
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
        return Image("JournalLockTipArt")
            .resizable()
            .frame(width: width, height: Self.grid.height * scale)
            .accessibilityElement()
            .accessibilityLabel("Your Journal, Your Secret! Your thoughts are precious! Keep your journal private with Journal Lock. Go to Settings, Journal Lock, to turn it on.")
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    pictureButton("Maybe Later", spot(41, 687, 374, 780), shape: Capsule()) { close(then: onLater) }
                    pictureButton("Got it", spot(399, 687, 712, 780), shape: Capsule()) { close(then: onGotIt) }
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
