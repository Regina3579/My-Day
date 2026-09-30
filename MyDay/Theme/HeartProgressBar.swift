import SwiftUI

/// A loading bar, as in the opening designs: a white track with a pink edge, a glossy pink fill
/// and a heart riding on its end (the launch animation and the journal's opening).
struct HeartProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height
            let end = max(h, w * progress)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.92))
                    .overlay(Capsule().strokeBorder(Color(hex: 0xFF8FC2), lineWidth: 2))
                Capsule()
                    .fill(LinearGradient(colors: [Color(hex: 0xFF7DBA), Color(hex: 0xF0288C)],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(Color.white.opacity(0.35))
                            .frame(height: h * 0.3)
                            .padding(.horizontal, h * 0.4)
                            .padding(.top, h * 0.14)
                    }
                    .padding(3)
                    .frame(width: end)
                    .opacity(progress > 0 ? 1 : 0)
                ZStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: h * 1.9))
                        .foregroundStyle(Color.white)
                    ShinyHeart(size: h * 1.55)
                }
                .position(x: end - h * 0.35, y: h / 2)
                .opacity(progress > 0 ? 1 : 0)
            }
        }
        .accessibilityHidden(true)
    }
}
