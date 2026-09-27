import SwiftUI

/// The hand-written three-line message. It changes every day; tapping shows another one.
struct DailyQuoteView: View {
    let date: Date
    @State private var offset = 0

    var body: some View {
        let lines = DailyQuotes.lines(for: date, offset: offset)
        Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { offset += 1 }
            Haptics.tap()
        } label: {
            VStack(alignment: .leading, spacing: -4) {
                ForEach(Array(lines.enumerated()), id: \.offset) { line in
                    Text(line.element)
                }
            }
            .font(.custom("Noteworthy-Bold", size: 16, relativeTo: .headline))
            .foregroundStyle(Palette.berry)
            .shadow(color: Color.white, radius: 0.5)
            .shadow(color: Color.white.opacity(0.9), radius: 5)
            .padding(6)
            .background(SoftGlow().padding(-10))
            .rotationEffect(.degrees(-8))
            .id(lines.joined())
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(lines.joined(separator: " "))
        .accessibilityHint("Shows another message")
    }
}
