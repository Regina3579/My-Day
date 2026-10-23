import SwiftUI
import StoreKit

/// "Unlock My Day Pro", from its two designs, as one page: the girl with her puppy and kitten
/// and the six key features, then (scrolling on) every Pro feature in detail ("My Day Pro
/// Features"). The plans (Annual, Monthly, Lifetime) and Subscribe Now stay fixed at the bottom
/// the whole time, with Cancel anytime, Terms of Use, Restore Purchases and the privacy policy,
/// as Apple's guidelines ask. Prices come from the App Store, in the person's own currency.
struct ProPaywall: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(MyDayPro.self) private var pro

    @State private var products: [String: Product] = [:]
    @State private var loadFailed = false
    @State private var selected = MyDayPro.yearlyID
    @State private var isBuying = false
    @State private var note: String?

    /// Apple's standard licence agreement, unless My Day has its own.
    private static let appleTerms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    var body: some View {
        ScrollViewReader { reader in
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                Image("ProPaywallTop")
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("Unlock My Day Pro. More cute tools for your happiest planning and journaling: unlimited writing, all 30 moods, journal prompts, task and journal photos, voice notes and stickers, beautiful themes and journal lock.")
                Image("ProPaywallFeatures")
                    .resizable()
                    .scaledToFit()
                    // Flows on from the panel above.
                    .mask(LinearGradient(stops: [.init(color: .black.opacity(0), location: 0),
                                                 .init(color: .black, location: 0.025)],
                                         startPoint: .top, endPoint: .bottom))
                    .padding(.top, -12)
                    .id("features")
                    .accessibilityLabel(Self.featuresDescription)
            }
        }
        #if DEBUG
        .task {
            if DebugLaunchRoute.paywall == "pro-paywall-features" {
                try? await Task.sleep(for: .seconds(1.2))
                reader.scrollTo("features", anchor: .top)
            }
        }
        #endif
        }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topLeading) { closeButton }
        .safeAreaInset(edge: .bottom, spacing: 0) { plans }
        .background(Color(hex: 0xFFEFF5).ignoresSafeArea())
        .task { await loadProducts() }
        .onChange(of: pro.isActive) { _, isActive in
            if isActive { dismiss() }
        }
    }

    private static let featuresDescription = """
        My Day Pro features. To-Dos: task photos, sharing categories with friends, 8 reminder sounds. \
        Journal writing: unlimited writing, Daily Reflections, journal prompts, up to 6 photos per page, \
        voice notes, all 30 moods. Journal look and privacy: 6 premium themes, Journal Lock. \
        Journal extras: export a page as PDF, export your journal, On This Day, all stickers. \
        More to unlock: unlimited Important Days and Shared Lists.
        """

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(hex: 0x6B2150))
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.white.opacity(0.85)))
                .shadow(color: Palette.hotPink.opacity(0.2), radius: 4, y: 2)
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle())
        .padding(.leading, 12)
        .accessibilityLabel("Close")
    }

    // MARK: Plans (fixed at the bottom)

    private var plans: some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom, spacing: 8) {
                PlanCard(plan: .annual, price: price(MyDayPro.yearlyID), detail: monthlyEquivalent,
                         isSelected: selected == MyDayPro.yearlyID) { selected = MyDayPro.yearlyID }
                PlanCard(plan: .monthly, price: price(MyDayPro.monthlyID), detail: nil,
                         isSelected: selected == MyDayPro.monthlyID) { selected = MyDayPro.monthlyID }
                PlanCard(plan: .lifetime, price: price(MyDayPro.lifetimeID), detail: nil,
                         isSelected: selected == MyDayPro.lifetimeID) { selected = MyDayPro.lifetimeID }
            }
            subscribeButton
            if let note {
                Text(note)
                    .font(.rounded(.caption, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xC2185B))
                    .multilineTextAlignment(.center)
            }
            footer
        }
        .padding(.horizontal, 14)
        .padding(.top, 22)
        .padding(.bottom, 4)
        .background(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [Color.white.opacity(0.97), Color(hex: 0xFFE9F2)],
                                     startPoint: .top, endPoint: .bottom))
                .shadow(color: Palette.hotPink.opacity(0.18), radius: 14, y: -4)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var subscribeButton: some View {
        Button(action: buy) {
            HStack(spacing: 12) {
                CrownArt(height: 22)
                Spacer(minLength: 0)
                if isBuying {
                    ProgressView().tint(.white)
                } else {
                    Text(selected == MyDayPro.lifetimeID ? "Unlock Forever" : "Subscribe Now")
                        .font(.rounded(.title3, weight: .heavy))
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .bold))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(
                Capsule().fill(LinearGradient(colors: [Color(hex: 0xFF5FA8), Color(hex: 0xEC1C7C)],
                                              startPoint: .top, endPoint: .bottom))
            )
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.7), lineWidth: 2))
            .shadow(color: Palette.hotPink.opacity(0.4), radius: 10, y: 5)
        }
        .buttonStyle(PressScaleStyle())
        .disabled(isBuying || products[selected] == nil)
        .accessibilityHint(selectedSummary)
    }

    private var footer: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Palette.hotPink)
                Text(selected == MyDayPro.lifetimeID ? "Pay once, yours forever" : "Cancel anytime")
            }
            .font(.rounded(.footnote, weight: .medium))
            .foregroundStyle(Color(hex: 0x6B2150))
            HStack(spacing: 10) {
                link("Terms of Use") { openURL(MoreLinks.terms ?? Self.appleTerms) }
                Text("|").foregroundStyle(Palette.inkSoft.opacity(0.5))
                link("Restore Purchases") {
                    Task {
                        await pro.restore()
                        note = pro.isActive ? nil : "No My Day Pro purchase was found for this Apple ID."
                    }
                }
                if let privacy = MoreLinks.privacy {
                    Text("|").foregroundStyle(Palette.inkSoft.opacity(0.5))
                    link("Privacy") { openURL(privacy) }
                }
            }
            .font(.rounded(.caption, weight: .semibold))
        }
    }

    private func link(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .underline()
                .foregroundStyle(Color(hex: 0x4A3A8C))
                .frame(minHeight: 30)
        }
        .buttonStyle(.plain)
    }

    // MARK: Prices and buying

    private func price(_ id: String) -> String? {
        if let product = products[id] { return product.displayPrice }
        #if DEBUG
        // Screenshot runs have no App Store: the design's prices.
        if DebugLaunchRoute.isScreenshotRun {
            return ["com.regina3579.myday.pro.yearly": "₹899.00", "com.regina3579.myday.pro.monthly": "₹99.00",
                    "com.regina3579.myday.pro.lifetime": "₹2,499.00"][id]
        }
        #endif
        return nil
    }

    /// The year's price a month ("₹74.92/mo").
    private var monthlyEquivalent: String? {
        if let yearly = products[MyDayPro.yearlyID] {
            return (yearly.price / 12).formatted(yearly.priceFormatStyle) + "/mo"
        }
        #if DEBUG
        if DebugLaunchRoute.isScreenshotRun { return "₹74.92/mo" }
        #endif
        return nil
    }

    private var selectedSummary: String {
        switch selected {
        case MyDayPro.lifetimeID: "Lifetime, \(price(selected) ?? ""), paid once"
        case MyDayPro.monthlyID: "Monthly, \(price(selected) ?? "") per month"
        default: "Annual, \(price(selected) ?? "") per year"
        }
    }

    private func loadProducts() async {
        do {
            let found = try await Product.products(for: MyDayPro.allProductIDs)
            products = Dictionary(found.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            loadFailed = found.isEmpty
        } catch {
            loadFailed = true
        }
        if loadFailed { note = "Prices couldn't load. Check your connection and try again." }
    }

    private func buy() {
        guard let product = products[selected] else { return }
        isBuying = true
        note = nil
        Task {
            defer { isBuying = false }
            do {
                switch try await product.purchase() {
                case .success(let verification):
                    await pro.purchased(verification)
                    Haptics.success()
                    dismiss()
                case .pending:
                    note = "Waiting for approval. My Day Pro unlocks as soon as it's approved."
                case .userCancelled:
                    break
                @unknown default:
                    break
                }
            } catch {
                note = "The purchase didn't go through. Please try again."
            }
        }
    }
}

/// One plan, as in the design: its name, its price in big pink, and what the price is for.
private struct PlanCard: View {
    enum Plan {
        case annual, monthly, lifetime

        var title: String {
            switch self {
            case .annual: "Annual"
            case .monthly: "Monthly"
            case .lifetime: "Lifetime"
            }
        }

        var per: String {
            switch self {
            case .annual: "per year"
            case .monthly: "per month"
            case .lifetime: "Pay once"
            }
        }
    }

    let plan: Plan
    let price: String?
    /// Under Annual: the year's price a month.
    let detail: String?
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            withAnimation(.snappy) { onSelect() }
        } label: {
            VStack(spacing: 2) {
                Text(plan.title)
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(Color(hex: 0x3B1240))
                Group {
                    if let price {
                        Text(price)
                    } else {
                        ProgressView().tint(Palette.hotPink)
                    }
                }
                .font(.rounded(.title3, weight: .heavy))
                .foregroundStyle(Color(hex: 0xEC1C7C))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(minHeight: 30)
                Text(plan.per)
                    .font(.rounded(.caption, weight: .medium))
                    .foregroundStyle(Color(hex: 0x3B1240))
                footer
                    .padding(.top, 4)
            }
            .padding(.horizontal, 6)
            .padding(.top, plan == .annual ? 18 : 12)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected
                          ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFFF3F8), Color(hex: 0xFFE0EE)],
                                                         startPoint: .top, endPoint: .bottom))
                          : AnyShapeStyle(Color.white.opacity(0.92)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(isSelected ? Color(hex: 0xF0287F) : Color(hex: 0xF6C3D8),
                                  lineWidth: isSelected ? 2.5 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color(hex: 0xEC1C7C)))
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 1.5))
                        .offset(x: 4, y: -4)
                }
            }
            .overlay(alignment: .top) {
                if plan == .annual { bestValue.offset(y: -12) }
            }
            .shadow(color: Palette.hotPink.opacity(isSelected ? 0.25 : 0.08), radius: 8, y: 3)
        }
        .buttonStyle(PressScaleStyle(scale: 0.97))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(plan.title), \(price ?? "loading"), \(plan.per)\(plan == .annual ? ", best value" : "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private var footer: some View {
        switch plan {
        case .annual:
            Text(detail ?? " ")
                .font(.rounded(.caption2, weight: .bold))
                .foregroundStyle(Color(hex: 0xC2126B))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color(hex: 0xFCD3E5)))
        case .monthly:
            Image(systemName: "heart.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: 0xF9A8CB))
                .frame(height: 18)
        case .lifetime:
            Image(systemName: "infinity")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0xB18CF0), Color(hex: 0x7FA6F5)],
                                                startPoint: .leading, endPoint: .trailing))
                .frame(height: 18)
        }
    }

    private var bestValue: some View {
        HStack(spacing: 4) {
            CrownArt(height: 12)
            Text("Best Value")
                .font(.rounded(.caption, weight: .heavy))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(LinearGradient(colors: [Color(hex: 0xFF5FA8), Color(hex: 0xEC1C7C)],
                                                  startPoint: .top, endPoint: .bottom)))
        .fixedSize()
    }
}
