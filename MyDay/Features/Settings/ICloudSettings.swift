import SwiftUI

/// Settings → iCloud: the Sync with iCloud switch (on from the start), what iCloud is doing, and
/// what is kept there.
struct ICloudSettingsSection: View {
    @Environment(DataStore.self) private var store
    @Environment(Router.self) private var router
    @State private var confirmTurnOff = false

    var body: some View {
        Section {
            Toggle(isOn: syncToggle) {
                Label("Sync with iCloud", systemImage: "icloud.fill")
            }
            .id("icloud")
            if store.syncsWithICloud, store.syncStatus.state != .idle {
                CloudSyncStatusRow(state: store.syncStatus.state)
            }
        } header: {
            Text("iCloud")
        } footer: {
            Text(footer)
        }
        .confirmationDialog("Stop syncing with iCloud?", isPresented: $confirmTurnOff, titleVisibility: .visible) {
            Button("Turn Off iCloud Sync", role: .destructive) { setSync(false) }
        } message: {
            Text("Everything stays on this iPhone, and what is already in iCloud stays there. New changes are kept only on this iPhone, so they would be lost if you delete My Day.")
        }
    }

    /// Turning it on happens straight away; turning it off asks first.
    private var syncToggle: Binding<Bool> {
        Binding(
            get: { store.syncsWithICloud },
            set: { isOn in
                if isOn { setSync(true) } else { confirmTurnOff = true }
            }
        )
    }

    private func setSync(_ isOn: Bool) {
        // The store closes for a moment: nothing open may hold one of its items.
        router.closeAll()
        Task { await store.setSyncsWithICloud(isOn) }
    }

    private var footer: String {
        store.syncsWithICloud
            ? "Your to-dos, priorities, templates and journal pages, with their photos and voice notes, are kept in your private iCloud. If you delete My Day or get a new iPhone, sign in with the same Apple ID and they all come back."
            : "Your data is kept only on this iPhone, and deleting My Day deletes it. Turn on Sync with iCloud to keep it safe."
    }
}

/// What iCloud is doing: syncing, up to date (and when it last synced), or why it can't sync.
struct CloudSyncStatusRow: View {
    let state: CloudSyncStatus.State

    var body: some View {
        HStack(spacing: 12) {
            icon
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                switch state {
                case .idle, .syncing:
                    title("Syncing with iCloud…")
                case .upToDate(let date):
                    title("Up to date")
                    // Kept current while Settings is open.
                    TimelineView(.periodic(from: .now, by: 30)) { _ in
                        detail("Last synced \(date.formatted(.relative(presentation: .named)))")
                    }
                case .problem(let message):
                    title("Not synced")
                    detail(message)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .idle, .syncing:
            ProgressView()
                .tint(Palette.hotPink)
        case .upToDate:
            Image(systemName: "checkmark.icloud.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Palette.mint)
        case .problem:
            Image(systemName: "exclamationmark.icloud.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Palette.honey)
        }
    }

    private func title(_ text: String) -> some View {
        Text(text)
            .font(.rounded(.subheadline, weight: .bold))
            .foregroundStyle(Palette.ink)
    }

    private func detail(_ text: String) -> some View {
        Text(text)
            .font(.rounded(.footnote, weight: .medium))
            .foregroundStyle(Palette.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Shown for the moment Sync with iCloud is switched, while the store closes and opens again.
struct StoreSwitchingView: View {
    let turningOn: Bool

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: turningOn ? "icloud.and.arrow.up.fill" : "iphone")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(Palette.hotPink)
                .symbolEffect(.pulse)
            Text(turningOn ? "Turning on iCloud sync…" : "Turning off iCloud sync…")
                .font(.rounded(.title3, weight: .bold))
                .foregroundStyle(Palette.ink)
            ProgressView()
                .tint(Palette.hotPink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DreamyBackground(theme: .garden).ignoresSafeArea())
        .accessibilityElement(children: .combine)
    }
}
