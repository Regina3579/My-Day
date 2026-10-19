import SwiftUI

extension View {
    /// The My Day Pro pop-up for `feature` while it is set (a free account tapped a Pro feature),
    /// over the whole screen, sheets included; then, if Unlock Pro is tapped, Apple's
    /// subscription sheet. `feature` goes back to nil when it closes.
    func proOffer(_ feature: Binding<ProFeature?>) -> some View {
        modifier(ProOfferModifier(feature: feature))
    }
}

private struct ProOfferModifier: ViewModifier {
    @Binding var feature: ProFeature?
    @State private var shown: ProFeature?

    func body(content: Content) -> some View {
        content
            .onChange(of: feature) { _, offer in
                guard let offer, shown == nil else { return }
                // The pop-up brings its own entrance, so the cover appears at once.
                withoutAnimation { shown = offer }
            }
            .fullScreenCover(item: $shown) { offer in
                ProOfferScreen(feature: offer) {
                    withoutAnimation { shown = nil }
                    feature = nil
                }
                .presentationBackground(.clear)
            }
    }

    private func withoutAnimation(_ change: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, change)
    }
}

/// The pop-up, and the subscriptions behind Unlock Pro. Either way it closes afterwards: at once
/// on Maybe Later, or when the subscription sheet is closed (Pro or not).
private struct ProOfferScreen: View {
    let feature: ProFeature
    let onClose: () -> Void
    @State private var showsPaywall = false

    var body: some View {
        ProUnlockCard(feature: feature, onUnlock: { showsPaywall = true }, onLater: onClose)
            .sheet(isPresented: $showsPaywall, onDismiss: onClose) {
                ProPaywall()
            }
    }
}

/// The small gold crown on a Pro button, tile or row, shown to a free account.
struct ProCrown: View {
    var size: CGFloat = 18

    var body: some View {
        Image(systemName: "crown.fill")
            .font(.system(size: size * 0.55, weight: .bold))
            .foregroundStyle(ProStyle.crown)
            .frame(width: size, height: size)
            .background(Circle().fill(Color.white))
            .overlay(Circle().strokeBorder(ProStyle.badgeEdge.opacity(0.7), lineWidth: 1))
            .shadow(color: ProStyle.badgeEdge.opacity(0.45), radius: 2, y: 1)
            .accessibilityLabel("My Day Pro")
    }
}
