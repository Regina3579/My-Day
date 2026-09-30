import SwiftUI

/// "Choose your mood — How are you feeling today?", as in the design: the star hugging a
/// heart, then all thirty little stars on pastel tiles (the page's six everyday moods too).
/// Tap one, then Done.
struct MoodChooserSheet: View {
    @Binding var mood: Mood
    @Binding var moodPicked: Bool
    let isToday: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    /// The star tapped here; the page takes it with Done.
    @State private var choice: Mood?

    init(mood: Binding<Mood>, moodPicked: Binding<Bool>, isToday: Bool) {
        _mood = mood
        _moodPicked = moodPicked
        self.isToday = isToday
        _choice = State(initialValue: moodPicked.wrappedValue ? mood.wrappedValue : nil)
    }

    /// Five across, as in the design; three at the largest text sizes.
    private var columnCount: Int { typeSize.isAccessibilitySize ? 3 : 5 }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: columnCount),
                          spacing: 8) {
                    ForEach(Mood.chooserMoods) { option in
                        tile(option)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white.opacity(0.6))
                        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(Color.white, lineWidth: 1.5))
                )
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            }
            .scrollBounceBehavior(.basedOnSize)
            doneButton
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 10)
        }
        .background(MoodChooserStyle.background.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
    }

    // MARK: Header

    /// The star sits on the grid's panel; the title is centred beside it, clear of the ✕.
    private var header: some View {
        HStack(alignment: .bottom, spacing: 6) {
            Image("MoodChooserStar")
                .resizable()
                .scaledToFit()
                .frame(width: 94)
                .accessibilityHidden(true)
            VStack(spacing: 6) {
                Text("Choose your mood")
                    .font(.rounded(.title2, weight: .heavy))
                    .foregroundStyle(MoodChooserStyle.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: 8) {
                    line
                    Text(isToday ? "How are you feeling today?" : "How were you feeling?")
                        .font(.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(MoodChooserStyle.subtitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .layoutPriority(1)
                    line
                }
                HeartDivider(lineLength: 44, heartSize: 16)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .padding(.trailing, 50)
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .padding(.top, 14)
        .overlay(alignment: .topTrailing) {
            closeButton
                .padding(.top, 14)
                .padding(.trailing, 16)
        }
        .background(alignment: .topLeading) { sparkles }
    }

    private var line: some View {
        Capsule()
            .fill(MoodChooserStyle.subtitle.opacity(0.45))
            .frame(width: 16, height: 1.5)
            .accessibilityHidden(true)
    }

    /// Hearts, twinkles and two soft clouds around the header, as in the design.
    private var sparkles: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Color(hex: 0xEADCF8).opacity(0.8))
                    .position(x: w * 0.9, y: h * 0.86)
                Image(systemName: "cloud.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: 0xE6DDF9).opacity(0.7))
                    .position(x: w * 0.03, y: h * 0.84)
                Image(systemName: "heart.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(MoodChooserStyle.heart)
                    .rotationEffect(.degrees(-12))
                    .position(x: w * 0.95, y: h * 0.6)
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(MoodChooserStyle.heart.opacity(0.8))
                    .position(x: w * 0.035, y: h * 0.4)
                Image(systemName: "sparkle")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: 0xF7C548))
                    .position(x: w * 0.83, y: h * 0.18)
                Image(systemName: "sparkle")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white)
                    .position(x: w * 0.3, y: h * 0.12)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(MoodChooserStyle.close)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white))
                .shadow(color: MoodChooserStyle.close.opacity(0.18), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityLabel("Close")
    }

    // MARK: Moods

    private func tile(_ option: Mood) -> some View {
        let isOn = option == choice
        let colors = option.chooserColors
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { choice = option }
            Haptics.tap()
            SoundEffects.play(.moodStar)
        } label: {
            VStack(spacing: 3) {
                Image(option.artName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 48)
                    .scaleEffect(isOn ? 1.08 : 1)
                Text(option.label)
                    .font(.rounded(.footnote, weight: .bold))
                    .tracking(-0.2)
                    .foregroundStyle(colors.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.top, 8)
            .padding(.bottom, 7)
            .padding(.horizontal, 1)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [colors.tile, colors.tile.opacity(0.75)],
                                         startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isOn ? JournalStyle.selectedMoodEdge : Color.white.opacity(0.9),
                                  lineWidth: isOn ? 2.5 : 1.5)
            )
            .overlay(alignment: .topTrailing) {
                if isOn {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 17, weight: .bold))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, JournalStyle.selectedMoodEdge)
                        .offset(x: 4, y: -4)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .shadow(color: JournalStyle.pink.opacity(isOn ? 0.25 : 0.08), radius: isOn ? 8 : 4, x: 0, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.label)
        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
    }

    // MARK: Done

    private var doneButton: some View {
        Button {
            if let choice {
                mood = choice
                moodPicked = true
                Haptics.success()
            }
            dismiss()
        } label: {
            HStack(spacing: 18) {
                twinkle
                Text("Done")
                    .font(.rounded(.title2, weight: .heavy))
                twinkle
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, minHeight: 62)
            .background(Capsule().fill(MoodChooserStyle.done))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.6), lineWidth: 1.5))
            .shadow(color: JournalStyle.pink.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PressScaleStyle(scale: 0.97))
    }

    private var twinkle: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(Color(hex: 0xFFF3B0))
            .accessibilityHidden(true)
    }
}

/// Colours of "Choose your mood", sampled from the design.
enum MoodChooserStyle {
    static let title = Color(hex: 0xBF0C6E)
    static let subtitle = Color(hex: 0x9F599F)
    static let close = Color(hex: 0xFD40A4)
    static let heart = Color(hex: 0xFF7DB8)
    static let background = LinearGradient(colors: [Color(hex: 0xFEE5EC), Color(hex: 0xFEF5F8), Color(hex: 0xFEE8F3)],
                                           startPoint: .top, endPoint: .bottom)
    static let done = LinearGradient(colors: [Color(hex: 0xFD8CBF), Color(hex: 0xFE4FA1)],
                                     startPoint: .top, endPoint: .bottom)
}

extension Mood {
    /// The name's colour and the tile's pastel in "Choose your mood", sampled from the design.
    var chooserColors: (label: Color, tile: Color) {
        let hex: (label: UInt32, tile: UInt32) = switch self {
        case .amazing: (0x6A1289, 0xFEE9EF)
        case .happy: (0xA80981, 0xFCE8F5)
        case .calm: (0x341095, 0xF6ECFC)
        case .loved: (0xC10C84, 0xFEE9F4)
        case .excited: (0xE03E08, 0xFEEFE8)
        case .sad: (0x103FBD, 0xEEF1FD)
        case .stressed: (0xEA0509, 0xFEEAEB)
        case .tired: (0x9C0D7E, 0xFEECF4)
        case .grumpy: (0x2D0A8E, 0xF6E7FA)
        case .bored: (0x085C7B, 0xEBF6F3)
        case .anxious: (0x280A92, 0xF6EBFB)
        case .overwhelmed: (0xBA0411, 0xFEE9EF)
        case .motivated: (0xE34008, 0xFEF2E9)
        case .confident: (0xCE0B7B, 0xFEEDEE)
        case .peaceful: (0x0447C3, 0xF1EFFB)
        case .lonely: (0x2F1099, 0xF6EAFB)
        case .hopeful: (0xCE1F06, 0xFEF2EB)
        case .grateful: (0x94066C, 0xFEE7F3)
        case .energetic: (0x054F6E, 0xEBF5F2)
        case .creative: (0xEC2E0A, 0xFEEBEC)
        case .confused: (0x2426AF, 0xEFEFFD)
        case .emotional: (0xA2087E, 0xFEE8F5)
        case .proud: (0xEA440A, 0xFEEFE8)
        case .relaxed: (0x2A0892, 0xF6E5FB)
        case .blissful: (0xBB0A7B, 0xFEE5F3)
        case .angry: (0xBB060E, 0xFEE8EC)
        case .frustrated: (0xB80506, 0xFEEAEC)
        case .content: (0x056076, 0xEFF6F1)
        case .melancholy: (0x0F1CA6, 0xF1EEFB)
        case .playful: (0xC60D06, 0xFEEEE8)
        }
        return (Color(hex: hex.label), Color(hex: hex.tile))
    }
}
