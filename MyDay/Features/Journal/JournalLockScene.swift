import SwiftUI

/// The pink lock screens from their designs ("Enter Your Passcode", "Draw Your Pattern"): the
/// pink journal with its gold heart lock and the puppy with a pink bow among hearts on a cloud at
/// the top, the title in bold berry between little hearts, a line under it, then the pad (the
/// passcode's keys or the pattern's hearts), with flowers, hearts and sparkles in the bottom
/// corners on soft clouds. The pictures are the designs' own (enlarged 4× with Real-ESRGAN, their
/// words and buttons taken out); the words, keys and buttons are drawn here.
///
/// Used by the lock in front of the journal, and by Settings' Lock My Journal while a pattern or
/// passcode is chosen or checked.
struct JournalLockScene<Content: View>: View {
    /// The little pictures on each side of the title.
    enum Ornament {
        /// Two glossy pink hearts (the passcode's design).
        case hearts
        /// Outlined hearts with little sparkle strokes (the pattern's design).
        case sparkHearts
    }

    let title: String
    let subtitle: String
    var ornament: Ornament = .hearts
    /// The ‹ in the top corner; none when nil.
    var onBack: (() -> Void)?
    @ViewBuilder let content: () -> Content

    static var background: LinearGradient {
        LinearGradient(colors: [Color(hex: 0xFDD9EB), Color(hex: 0xFEE6F0), Color(hex: 0xFEE2EE), Color(hex: 0xFDDCEC)],
                       startPoint: .top, endPoint: .bottom)
    }

    static var berry: Color { Color(hex: 0xA80B55) }
    static var lilac: Color { Color(hex: 0x8E6CAA) }

    /// The picture at the top: 1290 × 560 pixels.
    private static let heroAspect: CGFloat = 1290.0 / 560.0

    var body: some View {
        ZStack(alignment: .topLeading) {
            Self.background.ignoresSafeArea()
            corners
            ScrollView {
                VStack(spacing: 0) {
                    Image("LockPadHero")
                        .resizable()
                        .aspectRatio(Self.heroAspect, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                    titleRow
                        .padding(.top, 4)
                    Text(subtitle)
                        .font(.rounded(size: 16, weight: .medium))
                        .foregroundStyle(Self.lilac)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 40)
                        .padding(.top, 6)
                    content()
                        .padding(.top, 18)
                }
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(Self.berry)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Color.white.opacity(0.85)))
                        .shadow(color: Color(hex: 0xE58AAE).opacity(0.25), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PressScaleStyle())
                .padding(.leading, 14)
                .padding(.top, 8)
                .accessibilityLabel("Back")
            }
        }
    }

    private var titleRow: some View {
        HStack(spacing: 10) {
            ornamentImage(left: true)
            Text(title)
                .font(.rounded(size: 27, weight: .heavy))
                .foregroundStyle(Self.berry)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
            ornamentImage(left: false)
        }
        .padding(.horizontal, 20)
    }

    private func ornamentImage(left: Bool) -> some View {
        let name: String
        let height: CGFloat
        switch ornament {
        case .hearts:
            name = left ? "LockOrnHeartL" : "LockOrnHeartR"
            height = 26
        case .sparkHearts:
            name = left ? "LockOrnSparkL" : "LockOrnSparkR"
            height = 23
        }
        return Image(name)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .accessibilityHidden(true)
    }

    /// Soft clouds along the bottom, with the designs' flowers, hearts and sparkles in the corners.
    private var corners: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            ZStack(alignment: .bottom) {
                ForEach(Self.clouds.indices, id: \.self) { index in
                    let cloud = Self.clouds[index]
                    Ellipse()
                        .fill(Color.white.opacity(cloud.opacity))
                        .frame(width: w * cloud.width, height: w * cloud.width * 0.55)
                        .blur(radius: 10)
                        .position(x: w * cloud.x, y: proxy.size.height - w * cloud.lift)
                }
                HStack(alignment: .bottom, spacing: 0) {
                    Image("LockCornerLeft")
                        .resizable()
                        .scaledToFit()
                        .frame(width: w * 0.3)
                    Spacer(minLength: 0)
                    Image("LockCornerRight")
                        .resizable()
                        .scaledToFit()
                        .frame(width: w * 0.31)
                }
                .padding(.bottom, -w * 0.02)
            }
            .frame(width: w, height: proxy.size.height, alignment: .bottom)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static let clouds: [(x: CGFloat, lift: CGFloat, width: CGFloat, opacity: Double)] = [
        (0.08, 0.04, 0.42, 0.75), (0.3, 0.0, 0.4, 0.6), (0.55, 0.01, 0.42, 0.55),
        (0.78, 0.03, 0.42, 0.65), (0.98, 0.06, 0.4, 0.75),
    ]
}

/// "Forgot Passcode?" and the like: a soft white pill with a pink edge.
struct JournalLockPillButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.rounded(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: 0xD6247A))
                .padding(.horizontal, 30)
                .frame(minWidth: 190, minHeight: 44)
                .background(Capsule().fill(Color.white.opacity(0.7)))
                .overlay(Capsule().strokeBorder(Color(hex: 0xF6C3D8), lineWidth: 1.5))
                .shadow(color: Color(hex: 0xE58AAE).opacity(0.15), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PressScaleStyle(scale: 0.95))
    }
}
