import SwiftUI

/// Shown instead of the journal while it is locked.
struct JournalLockView: View {
    @Environment(AppState.self) private var appState
    @State private var failed = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.75))
                    .frame(width: 150, height: 150)
                    .shadow(color: Palette.hotPink.opacity(0.3), radius: 20)
                Image(systemName: "lock.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFD66B), Color(hex: 0xE8A21C)],
                                                    startPoint: .top, endPoint: .bottom))
                Image(systemName: "heart.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Palette.hotPink)
                    .offset(y: 12)
            }
            .accessibilityHidden(true)

            Text("My Journal is locked")
                .font(.rounded(.title2, weight: .heavy))
                .foregroundStyle(Palette.berry)
            Text("Your thoughts are safe and private. 💖")
                .font(.rounded(.subheadline, weight: .medium))
                .foregroundStyle(Palette.inkSoft)

            Button(action: unlock) {
                Label("Unlock with \(JournalLock.methodName)", systemImage: JournalLock.symbolName)
            }
            .buttonStyle(PillButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 8)

            if failed {
                Text("Couldn't unlock. Please try again.")
                    .font(.rounded(.footnote, weight: .medium))
                    .foregroundStyle(Palette.hotPink)
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .task { unlock() }
    }

    private func unlock() {
        // Without a passcode there is nothing to check against.
        guard JournalLock.canAuthenticate else {
            appState.isJournalUnlocked = true
            return
        }
        Task {
            let success = await JournalLock.authenticate(reason: "Unlock your journal")
            withAnimation { appState.isJournalUnlocked = success }
            failed = !success
        }
    }
}
