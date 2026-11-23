import SwiftUI

/// Daily Motivation: today's short quote, written by hand in the scene below the header.
/// It stays the same all day and changes after midnight (see `DailyMotivation`).
struct DailyQuoteView: View {
    let date: Date
    /// The widest the note may be; longer lines shrink a little to fit.
    var maxWidth: CGFloat = .infinity

    var body: some View {
        let quote = DailyMotivation.quote(for: date)
        VStack(alignment: .leading, spacing: -4) {
            Text(quote.firstLine)
            Text("\(quote.secondLine) \(quote.theme.emoji)")
        }
        .font(.custom("Noteworthy-Bold", size: 15, relativeTo: .headline))
        .foregroundStyle(Palette.berry)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .shadow(color: Color.white, radius: 0.5)
        .shadow(color: Color.white.opacity(0.9), radius: 5)
        .padding(4)
        .background(SoftGlow().padding(-10))
        .rotationEffect(.degrees(-10))
        .id(quote)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.4), value: quote)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today's motivation: \(quote.text)")
    }
}
