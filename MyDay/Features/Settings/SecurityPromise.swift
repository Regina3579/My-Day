import SwiftUI

/// "Security Promise", as in the design: a green shield with a lock and the title, the promise in
/// white under it, and a large faint shield with a lock behind, on black. My Day has no servers of
/// its own: pages stay on the iPhone and, with Sync on, in the person's own private iCloud.
struct SecurityPromise: View {
    static let green = Color(hex: 0x4FBF8F)
    static let text = "We don't send your data to our servers, and we don't have access to your entries. Everything stays on your iPhone and, if you turn on Sync, in your own private iCloud. No third-party app can read your data."

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 26, weight: .semibold))
                Text("Security Promise")
                    .font(.system(.title2, design: .default, weight: .bold))
            }
            .foregroundStyle(Self.green)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Text(Self.text)
                .font(.system(.body))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 34)
        .frame(maxWidth: .infinity)
        .background {
            // The faint shield and lock behind the words.
            Image(systemName: "lock.shield")
                .resizable()
                .scaledToFit()
                .fontWeight(.light)
                .foregroundStyle(Self.green.opacity(0.12))
                .padding(.vertical, 6)
                .accessibilityHidden(true)
        }
        .background(Color.black, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

/// The promise as a row of its own in a Form or List.
struct SecurityPromiseSection: View {
    var body: some View {
        Section {
            SecurityPromise()
                .listRowInsets(EdgeInsets())
        }
        .listRowBackground(Color.clear)
    }
}
