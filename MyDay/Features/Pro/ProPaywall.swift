import SwiftUI
import StoreKit

/// Apple's subscription sheet for My Day Pro, under My Day's own header: the plans with their
/// prices and lengths straight from the App Store, Subscribe, Restore Purchases, the terms and
/// the privacy policy (the App Store's own wording, as Apple's guidelines ask). A purchase
/// unlocks Pro at once.
struct ProPaywall: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MyDayPro.self) private var pro

    /// Apple's standard licence agreement (the privacy policy link comes from App Store Connect).
    private static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    var body: some View {
        SubscriptionStoreView(productIDs: MyDayPro.productIDs) {
            ProPaywallHeader()
        }
        .subscriptionStoreControlStyle(.prominentPicker)
        .subscriptionStoreButtonLabel(.multiline)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.visible, for: .cancellation)
        .subscriptionStorePolicyDestination(url: Self.terms, for: .termsOfService)
        .onInAppPurchaseCompletion { _, result in
            if case .success(.success(let verification)) = result {
                await pro.purchased(verification)
                await MainActor.run { dismiss() }
            }
        }
        .containerBackground(ProStyle.card, for: .subscriptionStoreFullHeight)
        .tint(Palette.hotPink)
    }
}

/// The girl and her puppy, "My Day Pro" and what it unlocks.
private struct ProPaywallHeader: View {
    private struct Perk: Hashable {
        let emoji: String
        let text: String
    }

    private static let perks = [
        Perk(emoji: "💝", text: "Daily Reflections: gratitude, highlights, little wins and tomorrow"),
        Perk(emoji: "📸", text: "Photos on your to-dos and journal pages"),
        Perk(emoji: "🎙️", text: "Voice notes in your journal"),
        Perk(emoji: "⭐️", text: "All 30 moods and journal prompts"),
        Perk(emoji: "🎀", text: "Every sticker collection"),
        Perk(emoji: "🎵", text: "Beautiful reminder melodies"),
        Perk(emoji: "🦄", text: "Journal themes: angels, fairies, unicorns, rose gold, rainy days and more"),
    ]

    var body: some View {
        VStack(spacing: 12) {
            Image("ProUnlockArt")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 240)
                .accessibilityHidden(true)
            HStack(spacing: 8) {
                Text("👑")
                    .accessibilityHidden(true)
                Text("My Day Pro")
                    .foregroundStyle(ProStyle.title)
            }
            .font(.custom("ChalkboardSE-Bold", size: 30, relativeTo: .title))
            .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Self.perks, id: \.self) { perk in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(perk.emoji)
                            .accessibilityHidden(true)
                        Text(perk.text)
                            .foregroundStyle(ProStyle.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .font(.rounded(.subheadline, weight: .semibold))
            .padding(.horizontal, 24)
        }
        .padding(.top, 8)
    }
}
