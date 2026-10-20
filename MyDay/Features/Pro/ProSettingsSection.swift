import SwiftUI
import StoreKit

/// Settings → My Day Pro. A free account sees a pink "Unlock My Day Pro" row that opens the
/// subscriptions; a Pro one sees "You're a My Day Pro member" and Manage Subscription (Apple's
/// own sheet, to change plans or cancel). Restore Purchases is there for everyone, as Apple asks,
/// and Debug builds can pretend Pro is on or off.
struct ProSettingsSection: View {
    @Environment(MyDayPro.self) private var pro
    @State private var showsPaywall = false
    @State private var showsManage = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?
    #if DEBUG
    /// Pretend Pro: 0 the App Store's answer, 1 on, 2 off.
    @State private var pretend = 0
    #endif

    var body: some View {
        Section {
            if pro.isActive {
                memberRow
                Button {
                    showsManage = true
                } label: {
                    Label("Manage Subscription", systemImage: "creditcard.fill")
                        .foregroundStyle(Palette.hotPink)
                }
                .manageSubscriptionsSheet(isPresented: $showsManage)
            } else {
                unlockRow
            }
            Button(action: restore) {
                HStack {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")
                        .foregroundStyle(Palette.hotPink)
                    if isRestoring {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isRestoring)
            #if DEBUG
            Picker(selection: $pretend) {
                Text("App Store").tag(0)
                Text("On").tag(1)
                Text("Off").tag(2)
            } label: {
                Label("Pretend Pro (Debug)", systemImage: "hammer.fill")
            }
            .onAppear {
                switch UserDefaults.standard.object(forKey: Prefs.debugPretendPro) as? Bool {
                case true?: pretend = 1
                case false?: pretend = 2
                case nil: pretend = 0
                }
            }
            .onChange(of: pretend) { _, choice in
                if choice == 0 {
                    UserDefaults.standard.removeObject(forKey: Prefs.debugPretendPro)
                } else {
                    UserDefaults.standard.set(choice == 1, forKey: Prefs.debugPretendPro)
                }
                Task { await pro.refresh() }
            }
            #endif
        } header: {
            Text("My Day Pro")
        } footer: {
            if let message = restoreMessage ?? (pro.isActive ? "Thank you for supporting My Day! 💖" : nil) {
                Text(message)
            }
        }
        .id("pro")
    }

    /// For a free account: the pink row that opens the subscriptions.
    private var unlockRow: some View {
        Button {
            showsPaywall = true
        } label: {
            HStack(spacing: 14) {
                CrownArt(height: 25)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(ProStyle.badge))
                    .overlay(Circle().strokeBorder(ProStyle.badgeEdge, lineWidth: 1.5))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock My Day Pro")
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(ProStyle.title)
                    Text("Reflections, photos, voice notes and more")
                        .font(.rounded(.footnote, weight: .semibold))
                        .foregroundStyle(ProStyle.body)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Palette.hotPink)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(ProStyle.card)
        .sheet(isPresented: $showsPaywall) {
            ProPaywall()
        }
    }

    /// For a Pro account.
    private var memberRow: some View {
        HStack(spacing: 14) {
            CrownArt(height: 25)
                .frame(width: 44, height: 44)
                .background(Circle().fill(ProStyle.badge))
                .overlay(Circle().strokeBorder(ProStyle.badgeEdge, lineWidth: 1.5))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("You're a My Day Pro member")
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(ProStyle.title)
                Text("Every Pro feature is yours 💖")
                    .font(.rounded(.footnote, weight: .semibold))
                    .foregroundStyle(ProStyle.body)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func restore() {
        isRestoring = true
        restoreMessage = nil
        Task {
            await pro.restore()
            isRestoring = false
            restoreMessage = pro.isActive
                ? "Welcome back! My Day Pro is on. 💖"
                : "No My Day Pro subscription was found for this Apple Account."
        }
    }
}
