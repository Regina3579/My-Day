import SwiftUI

/// The floating glass tab bar from the design: My Day · Calendar · Insights · Settings.
struct MyDayTabBar: View {
    @Binding var selection: AppTab
    let metrics: TabBarMetrics
    var onReselect: (AppTab) -> Void = { _ in }

    @Namespace private var highlight

    var body: some View {
        let unit = metrics.unit
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                let isSelected = selection == tab
                Button {
                    if isSelected {
                        onReselect(tab)
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selection = tab
                        }
                        Haptics.tap()
                    }
                } label: {
                    VStack(spacing: 4 * unit) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 42 * unit, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 23 * unit, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(isSelected ? Palette.hotPink : Palette.inkSoft)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 40 * unit, style: .continuous)
                                .fill(Color.white.opacity(0.95))
                                .shadow(color: Palette.hotPink.opacity(0.18), radius: 6 * unit, x: 0, y: 2 * unit)
                                .padding(7 * unit)
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
        .padding(.horizontal, 8 * unit)
        .frame(width: metrics.width, height: metrics.height)
        .background {
            RoundedRectangle(cornerRadius: 50 * unit, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 50 * unit, style: .continuous)
                        .fill(Color.white.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 50 * unit, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.9), lineWidth: 1.2)
                )
                .shadow(color: Palette.hotPink.opacity(0.2), radius: 14 * unit, x: 0, y: 6 * unit)
        }
    }
}
