import SwiftUI

/// Size and placement of the floating tab bar.
enum TabBarLayout {
    static let height: CGFloat = 64

    /// Distance from the bottom of the screen: it sits just over the home indicator.
    static func bottomPadding(safeAreaBottom: CGFloat) -> CGFloat {
        max(10, safeAreaBottom - 12)
    }
}

/// The translucent, rounded, floating tab bar: My Day · Calendar · Insights · Settings.
struct BottomTabBar: View {
    @Binding var selection: AppTab
    var onReselect: (AppTab) -> Void = { _ in }

    @Namespace private var highlight

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                let isSelected = selection == tab
                Button {
                    if isSelected {
                        onReselect(tab)
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selection = tab }
                        Haptics.tap()
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(isSelected ? Palette.hotPink : Palette.inkSoft)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white.opacity(0.95))
                                .shadow(color: Palette.hotPink.opacity(0.18), radius: 6, x: 0, y: 2)
                                .padding(5)
                                .matchedGeometryEffect(id: "selected-tab", in: highlight)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isSelected ? AccessibilityTraits.isSelected : [])
            }
        }
        .padding(.horizontal, 6)
        .frame(height: TabBarLayout.height)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.9), lineWidth: 1.2)
                )
                .shadow(color: Palette.hotPink.opacity(0.2), radius: 14, x: 0, y: 6)
        }
    }
}
