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

/// The Journal Lock tip: the page softens and dims, and a pink card rises with the girl and her
/// puppy resting on its edge, a pink lock, "Keep your journal private 🔒" and a line on Journal
/// Lock (Face ID, a pattern or a passcode, in Settings → Journal → Lock My Journal), with
/// **Got it** and **Maybe Later**.
struct JournalLockTip: View {
    let onGotIt: () -> Void
    let onLater: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var floating = false

    private static let plum = Color(hex: 0x6B1442)
    private static let ink = Color(hex: 0x4A3150)

    var body: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width * 0.86, 350)
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
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) { shown = true }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { floating = true }
            }
            UIAccessibility.post(notification: .screenChanged, argument: "Tip: keep your journal private with Journal Lock.")
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
        let shape = RoundedRectangle(cornerRadius: 30, style: .continuous)
        let artHeight = width * 484 / 1024
        return VStack(spacing: 12) {
            // The pink lock, on a soft white badge.
            Image(systemName: "lock.heart.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFF8AC4), Palette.hotPink],
                                                startPoint: .top, endPoint: .bottom))
                .frame(width: 62, height: 62)
                .background(Circle().fill(Color.white))
                .overlay(Circle().strokeBorder(Color(hex: 0xF9C6DC), lineWidth: 1.5))
                .shadow(color: Palette.hotPink.opacity(0.25), radius: 8, x: 0, y: 3)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: 0xFFC94A))
                        .offset(x: 8, y: -4)
                }
                .accessibilityHidden(true)
            Text("Keep your journal private 🔒")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(Self.plum)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("Your thoughts are just for you. Turn on Journal Lock in Settings → Journal → Lock My Journal, and open it with Face ID, a pattern or a passcode. 💕")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Self.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) {
                Button { close(then: onGotIt) } label: {
                    Text("Got it 💗")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Capsule().fill(JournalPagesStyle.writeButton))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.6), lineWidth: 1.5))
                        .shadow(color: Palette.hotPink.opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PressScaleStyle(scale: 0.96))
                Button { close(then: onLater) } label: {
                    Text("Maybe Later")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.hotPink)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Capsule().fill(Color.white))
                        .overlay(Capsule().strokeBorder(Color(hex: 0xF7C3D9), lineWidth: 1.5))
                }
                .buttonStyle(PressScaleStyle(scale: 0.96))
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 20)
        .frame(width: width)
        .background(
            shape
                .fill(LinearGradient(colors: [Color(hex: 0xFFF5F9), Color(hex: 0xFDE3EE)], startPoint: .top, endPoint: .bottom))
                .overlay(shape.strokeBorder(Color.white, lineWidth: 3))
                .shadow(color: Palette.hotPink.opacity(0.35), radius: 22)
        )
        .padding(.top, artHeight * 0.62)
        .overlay(alignment: .top) {
            // The girl and her puppy resting on the card's top edge.
            Image("RatingArt")
                .resizable()
                .scaledToFit()
                .frame(width: width, height: artHeight)
                .offset(y: floating ? -3 : 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
