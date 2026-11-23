import SwiftUI

// Vector illustrations for the three home cards, drawn natively so they stay
// crisp at every size. All positions are fractions of the card's width (w)
// and height (h).

extension View {
    /// Frames the view to `width × height` and centres it at `(x, y)`.
    func placed(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        frame(width: width, height: height).position(x: x, y: y)
    }
}

private enum Gold {
    static let fill = LinearGradient(colors: [Color(hex: 0xFFF0B5), Color(hex: 0xF5C451), Color(hex: 0xDB9A2E)],
                                     startPoint: .top, endPoint: .bottom)
}

// MARK: - Today's To-Dos notebook

struct NotebookArt: View {
    let size: CGSize

    var body: some View {
        let w = size.width, h = size.height
        let cover = RoundedRectangle(cornerRadius: w * 0.09, style: .continuous)
        ZStack {
            // Pages peeking out behind the cover.
            cover.fill(Color(hex: 0xB89DEB))
                .placed(x: w * 0.525, y: h * 0.53, width: w * 0.94, height: h * 0.93)
            cover.fill(Color(hex: 0xEDE4FD))
                .placed(x: w * 0.515, y: h * 0.52, width: w * 0.94, height: h * 0.93)

            coverFace(cover, width: w)
                .placed(x: w * 0.505, y: h * 0.51, width: w * 0.94, height: h * 0.93)

            // Spiral binding on the left edge.
            ForEach(0..<7, id: \.self) { index in
                let y = h * (0.25 + 0.115 * CGFloat(index))
                Circle()
                    .fill(Color(hex: 0x9C7FE0))
                    .placed(x: w * 0.08, y: y, width: w * 0.024, height: w * 0.024)
                Capsule()
                    .strokeBorder(Gold.fill, lineWidth: w * 0.017)
                    .placed(x: w * 0.042, y: y, width: w * 0.095, height: h * 0.034)
            }

            ChecklistPaper(size: CGSize(width: w * 0.52, height: h * 0.39))
                .rotationEffect(.degrees(-2))
                .placed(x: w * 0.46, y: h * 0.235, width: w * 0.52, height: h * 0.39)

            Image(systemName: "pencil")
                .font(.system(size: w * 0.2, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFF9CC8), Color(hex: 0xF0428A)],
                                                startPoint: .top, endPoint: .bottom))
                .rotationEffect(.degrees(6))
                .position(x: w * 0.76, y: h * 0.28)
            ShinyHeart(size: w * 0.14).position(x: w * 0.86, y: h * 0.155)

            ShinyHeart(size: w * 0.085).position(x: w * 0.13, y: h * 0.25)
            ShinyHeart(size: w * 0.075).position(x: w * 0.15, y: h * 0.34)
            Image(systemName: "sparkle")
                .font(.system(size: w * 0.06, weight: .bold))
                .foregroundStyle(Palette.bubblegum)
                .position(x: w * 0.15, y: h * 0.15)

            // Flowers down both sides.
            Leaves(size: w * 0.15).position(x: w * 0.15, y: h * 0.62)
            Daisy(petal: Color(hex: 0xFFE27A)).placed(x: w * 0.18, y: h * 0.56, width: w * 0.1, height: w * 0.1)
            Leaves(size: w * 0.17).rotationEffect(.degrees(20)).position(x: w * 0.19, y: h * 0.8)
            Daisy(petal: .white).placed(x: w * 0.14, y: h * 0.74, width: w * 0.19, height: w * 0.19)
            Daisy(petal: Color(hex: 0xFFE27A)).placed(x: w * 0.28, y: h * 0.84, width: w * 0.08, height: w * 0.08)
            Leaves(size: w * 0.14).rotationEffect(.degrees(160)).position(x: w * 0.87, y: h * 0.47)
            Daisy(petal: Color(hex: 0xFFE27A)).placed(x: w * 0.9, y: h * 0.42, width: w * 0.07, height: w * 0.07)
            Daisy(petal: .white).placed(x: w * 0.9, y: h * 0.53, width: w * 0.14, height: w * 0.14)
            Daisy(petal: Color(hex: 0xFFB8D6)).placed(x: w * 0.88, y: h * 0.64, width: w * 0.08, height: w * 0.08)
            ShinyHeart(size: w * 0.11).position(x: w * 0.86, y: h * 0.83)

            VStack(spacing: -w * 0.025) {
                Text("Today's")
                Text("To-Dos")
            }
            .font(.system(size: w * 0.125, weight: .heavy, design: .rounded))
            .foregroundStyle(Color(hex: 0x21185A))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .position(x: w * 0.55, y: h * 0.52)

            Swoosh().placed(x: w * 0.55, y: h * 0.645, width: w * 0.45, height: h * 0.022)

            Text("Plan • Do • Achieve")
                .font(.system(size: w * 0.058, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0x2B2266))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .placed(x: w * 0.56, y: h * 0.705, width: w * 0.6, height: h * 0.05)

            ArrowBubble(diameter: w * 0.2, colors: [Color(hex: 0xB892FF), Color(hex: 0x8B55E8)])
                .position(x: w * 0.585, y: h * 0.83)
        }
        .frame(width: w, height: h)
    }

    private static let coverFill = LinearGradient(colors: [Color(hex: 0xF7F2FF), Color(hex: 0xDCCBFB)],
                                                  startPoint: .top, endPoint: .bottom)

    /// The lilac cover with its outline, inner line and shine.
    private func coverFace(_ cover: RoundedRectangle, width w: CGFloat) -> some View {
        let outline: CGFloat = max(1, w * 0.008)
        let innerLine: CGFloat = max(1, w * 0.01)
        let inset: CGFloat = w * 0.028
        return cover
            .fill(Self.coverFill)
            .overlay(cover.strokeBorder(Color(hex: 0xBBA2F0), lineWidth: outline))
            .overlay(cover.inset(by: inset).strokeBorder(Color.white.opacity(0.85), lineWidth: innerLine))
            .overlay(GlossHighlight(cornerRadius: w * 0.09))
    }
}

/// The white sheet with a little checklist, clipped to the notebook with gold rings.
private struct ChecklistPaper: View {
    let size: CGSize

    var body: some View {
        let w = size.width, h = size.height
        ZStack {
            RoundedRectangle(cornerRadius: w * 0.06, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: w * 0.03, x: 0, y: w * 0.015)

            ForEach(0..<3, id: \.self) { row in
                let y = h * (0.36 + 0.195 * CGFloat(row))
                RoundedRectangle(cornerRadius: w * 0.03, style: .continuous)
                    .strokeBorder(Color(hex: 0x6E4FD0), lineWidth: max(1, w * 0.022))
                    .placed(x: w * 0.23, y: y, width: w * 0.15, height: w * 0.15)
                if row < 2 {
                    Image(systemName: "checkmark")
                        .font(.system(size: w * 0.17, weight: .black))
                        .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFF6FAE), Color(hex: 0xE8337E)],
                                                        startPoint: .top, endPoint: .bottom))
                        .position(x: w * 0.25, y: y - h * 0.03)
                }
                Capsule()
                    .fill(Color(hex: 0xDCCFF8))
                    .placed(x: w * 0.64, y: y - h * 0.035, width: w * 0.5, height: h * 0.04)
                Capsule()
                    .fill(Color(hex: 0xE9E1FB))
                    .placed(x: w * 0.56, y: y + h * 0.04, width: w * 0.34, height: h * 0.036)
            }

            // Binding rings along the top of the sheet.
            ForEach(0..<4, id: \.self) { index in
                let x = w * (0.17 + 0.22 * CGFloat(index))
                Circle()
                    .fill(Color(hex: 0x8E6FE0))
                    .placed(x: x, y: h * 0.11, width: w * 0.045, height: w * 0.045)
                Capsule()
                    .strokeBorder(Gold.fill, lineWidth: w * 0.025)
                    .placed(x: x, y: h * 0.02, width: w * 0.08, height: h * 0.22)
            }
        }
        .frame(width: w, height: h)
    }
}

// MARK: - Today's Priority card

struct PriorityArt: View {
    let size: CGSize

    private static let leftFlowers: [(y: CGFloat, size: CGFloat, hex: UInt32)] = [
        (0.46, 0.11, 0xFFB8D6), (0.56, 0.1, 0xFFFFFF), (0.66, 0.12, 0xFFB8D6), (0.77, 0.1, 0xFFFFFF), (0.88, 0.09, 0xFFE27A)
    ]
    private static let rightFlowers: [(y: CGFloat, size: CGFloat, hex: UInt32)] = [
        (0.47, 0.11, 0xFFFFFF), (0.57, 0.1, 0xFFB8D6), (0.69, 0.12, 0xFFFFFF), (0.8, 0.09, 0xFFE27A), (0.9, 0.1, 0xFFFFFF)
    ]

    var body: some View {
        let w = size.width, h = size.height
        let card = RoundedRectangle(cornerRadius: w * 0.13, style: .continuous)
        ZStack {
            card.fill(Color(hex: 0xEFA93A))
                .placed(x: w * 0.515, y: h * 0.51, width: w * 0.95, height: h * 0.97)

            card
                .fill(LinearGradient(colors: [Color(hex: 0xFFFAE6), Color(hex: 0xFFE8A0)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(card.strokeBorder(LinearGradient(colors: [Color(hex: 0xFFD978), Color(hex: 0xF0A33A)],
                                                          startPoint: .top, endPoint: .bottom),
                                           lineWidth: w * 0.035))
                .overlay(card.inset(by: w * 0.05).strokeBorder(Color.white.opacity(0.9), lineWidth: max(1, w * 0.012)))
                .overlay(GlossHighlight(cornerRadius: w * 0.13))
                .placed(x: w * 0.49, y: h * 0.49, width: w * 0.95, height: h * 0.97)

            // The big glossy star.
            Image(systemName: "star.fill")
                .font(.system(size: w * 0.46))
                .foregroundStyle(Color(hex: 0xF39A12))
                .position(x: w * 0.5, y: h * 0.19)
            Image(systemName: "star.fill")
                .font(.system(size: w * 0.41))
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFEE85), Color(hex: 0xFFC531), Color(hex: 0xFBA81B)],
                                                startPoint: .top, endPoint: .bottom))
                .shadow(color: Color(hex: 0xF59E0B).opacity(0.45), radius: w * 0.03, x: 0, y: w * 0.02)
                .position(x: w * 0.5, y: h * 0.188)
            Ellipse()
                .fill(Color.white.opacity(0.6))
                .rotationEffect(.degrees(-30))
                .placed(x: w * 0.44, y: h * 0.155, width: w * 0.1, height: w * 0.05)

            ShinyHeart(size: w * 0.15).position(x: w * 0.18, y: h * 0.14)
            ShinyHeart(size: w * 0.12).position(x: w * 0.82, y: h * 0.14)
            Image(systemName: "heart.fill")
                .font(.system(size: w * 0.13))
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFCF5C), Color(hex: 0xF7A21E)],
                                                startPoint: .top, endPoint: .bottom))
                .rotationEffect(.degrees(12))
                .position(x: w * 0.83, y: h * 0.28)
            Image(systemName: "sparkle")
                .font(.system(size: w * 0.07, weight: .bold))
                .foregroundStyle(Color(hex: 0xFFD35C))
                .position(x: w * 0.21, y: h * 0.26)
            Image(systemName: "sparkle")
                .font(.system(size: w * 0.055, weight: .bold))
                .foregroundStyle(Color(hex: 0xFFD35C))
                .position(x: w * 0.72, y: h * 0.07)

            Leaves(size: w * 0.14).rotationEffect(.degrees(-60)).position(x: w * 0.1, y: h * 0.38)
            Leaves(size: w * 0.14).rotationEffect(.degrees(60)).position(x: w * 0.9, y: h * 0.39)
            ForEach(Self.leftFlowers.indices, id: \.self) { index in
                let flower = Self.leftFlowers[index]
                Daisy(petal: Color(hex: flower.hex))
                    .placed(x: w * 0.1, y: h * flower.y, width: w * flower.size, height: w * flower.size)
            }
            ForEach(Self.rightFlowers.indices, id: \.self) { index in
                let flower = Self.rightFlowers[index]
                Daisy(petal: Color(hex: flower.hex))
                    .placed(x: w * 0.9, y: h * flower.y, width: w * flower.size, height: w * flower.size)
            }

            VStack(spacing: -w * 0.03) {
                Text("Today's")
                Text("Priority")
            }
            .font(.system(size: w * 0.14, weight: .heavy, design: .rounded))
            .foregroundStyle(Color(hex: 0x3B1305))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .position(x: w * 0.505, y: h * 0.45)

            Swoosh().placed(x: w * 0.505, y: h * 0.575, width: w * 0.5, height: h * 0.02)

            VStack(spacing: 0) {
                Text("Focus on what")
                Text("matters most")
            }
            .font(.system(size: w * 0.068, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(hex: 0x3B1305))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .position(x: w * 0.505, y: h * 0.655)

            ArrowBubble(diameter: w * 0.24, colors: [Color(hex: 0xFFC94D), Color(hex: 0xFB9A0E)])
                .position(x: w * 0.505, y: h * 0.81)
        }
        .frame(width: w, height: h)
    }
}

// MARK: - My Journal book

struct JournalBookArt: View {
    let size: CGSize

    var body: some View {
        let w = size.width, h = size.height
        let cover = RoundedRectangle(cornerRadius: w * 0.04, style: .continuous)
        ZStack {
            // Back cover and pages under the front cover.
            cover.fill(Color(hex: 0xD93F7C))
                .placed(x: w * 0.53, y: h * 0.52, width: w * 0.93, height: h * 0.95)
            RoundedRectangle(cornerRadius: w * 0.025, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xFFF8EE), Color(hex: 0xF1DFCB)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(alignment: .bottom) {
                    VStack(spacing: h * 0.012) {
                        ForEach(0..<3, id: \.self) { _ in
                            Rectangle().fill(Color(hex: 0xE3CCB4)).frame(height: max(0.5, h * 0.004))
                        }
                    }
                    .padding(.horizontal, w * 0.03)
                    .padding(.bottom, h * 0.015)
                }
                .placed(x: w * 0.53, y: h * 0.5, width: w * 0.88, height: h * 0.9)

            cover
                .fill(LinearGradient(colors: [Color(hex: 0xFFEAF2), Color(hex: 0xFFC3DB)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(cover.strokeBorder(Color(hex: 0xF0619B), lineWidth: max(1, w * 0.01)))
                .overlay(
                    cover.inset(by: w * 0.028)
                        .strokeBorder(Color(hex: 0xF7A3C6),
                                      style: StrokeStyle(lineWidth: max(0.8, w * 0.005), dash: [w * 0.018, w * 0.011]))
                )
                .overlay(GlossHighlight(cornerRadius: w * 0.04))
                .placed(x: w * 0.54, y: h * 0.455, width: w * 0.84, height: h * 0.89)

            // Spine with gold bands.
            RoundedRectangle(cornerRadius: w * 0.04, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xFF9CC8), Color(hex: 0xE8458A), Color(hex: 0xFF8FC0)],
                                     startPoint: .leading, endPoint: .trailing))
                .placed(x: w * 0.072, y: h * 0.485, width: w * 0.13, height: h * 0.95)
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Gold.fill)
                    .placed(x: w * 0.072, y: h * (0.175 + 0.28 * CGFloat(index)), width: w * 0.14, height: h * 0.03)
            }

            CornerFlourish()
                .fill(Gold.fill)
                .scaleEffect(x: -1, y: 1)
                .placed(x: w * 0.905, y: h * 0.06, width: w * 0.11, height: w * 0.11)
            CornerFlourish()
                .fill(Gold.fill)
                .scaleEffect(x: -1, y: -1)
                .placed(x: w * 0.89, y: h * 0.82, width: w * 0.15, height: w * 0.15)

            // Heart-shaped lock.
            Circle()
                .trim(from: 0.5, to: 1)
                .stroke(Gold.fill, style: StrokeStyle(lineWidth: w * 0.016, lineCap: .round))
                .placed(x: w * 0.875, y: h * 0.33, width: w * 0.085, height: w * 0.085)
            Image(systemName: "heart.fill")
                .font(.system(size: w * 0.15))
                .foregroundStyle(Gold.fill)
                .shadow(color: Color(hex: 0xB9771A).opacity(0.4), radius: w * 0.01, x: 0, y: w * 0.006)
                .position(x: w * 0.875, y: h * 0.39)
            Image(systemName: "heart.fill")
                .font(.system(size: w * 0.07))
                .foregroundStyle(Palette.hotPink)
                .position(x: w * 0.875, y: h * 0.38)

            Ribbon()
                .fill(LinearGradient(colors: [Color(hex: 0xFF7FB2), Color(hex: 0xE8458A)],
                                     startPoint: .top, endPoint: .bottom))
                .placed(x: w * 0.205, y: h * 0.95, width: w * 0.09, height: h * 0.18)

            // Flowers in the corners of the cover.
            Leaves(size: w * 0.12).position(x: w * 0.31, y: h * 0.15)
            Daisy(petal: Color(hex: 0xFFB8D6)).placed(x: w * 0.25, y: h * 0.1, width: w * 0.12, height: w * 0.12)
            Daisy(petal: .white).placed(x: w * 0.34, y: h * 0.07, width: w * 0.07, height: w * 0.07)
            Leaves(size: w * 0.11).rotationEffect(.degrees(150)).position(x: w * 0.7, y: h * 0.12)
            Daisy(petal: .white).placed(x: w * 0.76, y: h * 0.1, width: w * 0.1, height: w * 0.1)
            Daisy(petal: Color(hex: 0xFFB8D6)).placed(x: w * 0.68, y: h * 0.07, width: w * 0.06, height: w * 0.06)
            Leaves(size: w * 0.16).position(x: w * 0.25, y: h * 0.58)
            Daisy(petal: Color(hex: 0xFFB8D6)).placed(x: w * 0.23, y: h * 0.67, width: w * 0.15, height: w * 0.15)
            Daisy(petal: .white).placed(x: w * 0.33, y: h * 0.74, width: w * 0.07, height: w * 0.07)
            Leaves(size: w * 0.14).rotationEffect(.degrees(170)).position(x: w * 0.78, y: h * 0.66)
            Daisy(petal: Color(hex: 0xFFB8D6)).placed(x: w * 0.82, y: h * 0.72, width: w * 0.13, height: w * 0.13)
            Daisy(petal: .white).placed(x: w * 0.72, y: h * 0.76, width: w * 0.075, height: w * 0.075)

            VStack(spacing: -w * 0.025) {
                Text("My")
                Text("Journal")
            }
            .font(.system(size: w * 0.115, weight: .heavy, design: .rounded))
            .foregroundStyle(Color(hex: 0x7E0C33))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .position(x: w * 0.54, y: h * 0.19)

            VStack(spacing: 0) {
                Text("Capture your thoughts")
                Text("and beautiful moments")
            }
            .font(.system(size: w * 0.044, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(hex: 0x7E0C33))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .position(x: w * 0.54, y: h * 0.37)

            ArrowBubble(diameter: w * 0.17, colors: [Color(hex: 0xFF7FB2), Color(hex: 0xF0287A)])
                .position(x: w * 0.55, y: h * 0.55)
        }
        .frame(width: w, height: h)
    }
}

// MARK: - Decorative book stack

/// "Good Habits · Happy Mind · Bright Days" books beside the journal.
struct BookStackArt: View {
    private struct Book {
        let title: String
        let colors: [Color]
        let tilt: Double
    }

    private static let books = [
        Book(title: "Good Habits", colors: [Color(hex: 0x8ED8E0), Color(hex: 0x4FB3C3)], tilt: -14),
        Book(title: "Happy Mind", colors: [Color(hex: 0xFFA8CB), Color(hex: 0xF06B9F)], tilt: -11),
        Book(title: "Bright Days", colors: [Color(hex: 0xC3A8F5), Color(hex: 0x8E6BDD)], tilt: -8)
    ]

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height
            ZStack {
                ForEach(Self.books.indices, id: \.self) { index in
                    let book = Self.books[index]
                    let bookHeight = h * 0.27
                    RoundedRectangle(cornerRadius: bookHeight * 0.16, style: .continuous)
                        .fill(LinearGradient(colors: book.colors, startPoint: .top, endPoint: .bottom))
                        .overlay(alignment: .trailing) {
                            RoundedRectangle(cornerRadius: bookHeight * 0.1, style: .continuous)
                                .fill(Color(hex: 0xFFF6EA))
                                .frame(width: w * 0.06)
                                .padding(.vertical, bookHeight * 0.14)
                                .padding(.trailing, w * 0.02)
                        }
                        .overlay {
                            HStack(spacing: 0) {
                                Capsule().fill(Gold.fill).frame(width: max(1, w * 0.012))
                                Spacer()
                                Capsule().fill(Gold.fill).frame(width: max(1, w * 0.012))
                                    .padding(.trailing, w * 0.1)
                            }
                            .padding(.vertical, bookHeight * 0.12)
                            .padding(.leading, w * 0.2)
                        }
                        .overlay {
                            HStack(spacing: w * 0.02) {
                                Text(book.title)
                                Image(systemName: "heart.fill")
                                    .font(.system(size: bookHeight * 0.24))
                                    .foregroundStyle(Color(hex: 0xFFB35C))
                            }
                            .font(.system(size: bookHeight * 0.3, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                            .shadow(color: Color.black.opacity(0.18), radius: 1, x: 0, y: 1)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .padding(.leading, w * 0.24)
                            .padding(.trailing, w * 0.12)
                        }
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 3)
                        .rotationEffect(.degrees(book.tilt))
                        .placed(x: w * 0.38, y: h * (0.17 + 0.26 * CGFloat(index)),
                                width: w * 1.12, height: bookHeight)
                }
            }
        }
        .accessibilityHidden(true)
    }
}


// MARK: - Building blocks

/// A simple daisy: petals around a golden centre.
struct Daisy: View {
    var petal: Color = .white
    var petals = 8

    private static let petalEdge = Color(hex: 0xF4A7C6).opacity(0.45)
    private static let centreColors = [Color(hex: 0xFFE680), Color(hex: 0xFBB829), Color(hex: 0xE8960F)]

    var body: some View {
        GeometryReader { proxy in
            let s: CGFloat = min(proxy.size.width, proxy.size.height)
            ZStack {
                ForEach(0..<petals, id: \.self) { index in
                    petalShape(index: index, size: s)
                }
                centre(size: s)
            }
            .frame(width: s, height: s)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .accessibilityHidden(true)
    }

    // Sizes are worked out with explicit types first: mixing CGFloat and Double
    // literals in one long expression is very slow to type-check.
    private func petalShape(index: Int, size s: CGFloat) -> some View {
        let edge: CGFloat = max(0.4, s * 0.02)
        let width: CGFloat = s * 0.3
        let height: CGFloat = s * 0.5
        let lift: CGFloat = -s * 0.24
        let angle: Double = Double(index) / Double(petals) * 360
        return Ellipse()
            .fill(petal)
            .overlay(Ellipse().stroke(Self.petalEdge, lineWidth: edge))
            .frame(width: width, height: height)
            .offset(y: lift)
            .rotationEffect(.degrees(angle))
    }

    private func centre(size s: CGFloat) -> some View {
        let radius: CGFloat = s * 0.17
        let side: CGFloat = s * 0.32
        return Circle()
            .fill(RadialGradient(colors: Self.centreColors, center: .center, startRadius: 0, endRadius: radius))
            .frame(width: side, height: side)
    }
}

/// Two small green leaves.
struct Leaves: View {
    let size: CGFloat

    var body: some View {
        let green = LinearGradient(colors: [Color(hex: 0x9BDB7E), Color(hex: 0x4FA356)], startPoint: .top, endPoint: .bottom)
        ZStack {
            Ellipse().fill(green)
                .frame(width: size * 0.5, height: size * 0.22)
                .rotationEffect(.degrees(-35))
                .offset(x: -size * 0.18, y: size * 0.05)
            Ellipse().fill(green)
                .frame(width: size * 0.45, height: size * 0.2)
                .rotationEffect(.degrees(30))
                .offset(x: size * 0.18, y: size * 0.1)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A glossy pink heart.
struct ShinyHeart: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size))
            .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFF9CC8), Color(hex: 0xF0428A)],
                                            startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .topLeading) {
                Ellipse()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: size * 0.22, height: size * 0.14)
                    .rotationEffect(.degrees(-30))
                    .offset(x: size * 0.2, y: size * 0.18)
            }
            .shadow(color: Color(hex: 0xF0428A).opacity(0.3), radius: size * 0.08, x: 0, y: size * 0.05)
            .accessibilityHidden(true)
    }
}

/// The round arrow button printed on each card.
struct ArrowBubble: View {
    let diameter: CGFloat
    let colors: [Color]

    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            Circle().strokeBorder(Color.white.opacity(0.9), lineWidth: max(1, diameter * 0.07))
            Ellipse()
                .fill(Color.white.opacity(0.35))
                .frame(width: diameter * 0.5, height: diameter * 0.22)
                .offset(y: -diameter * 0.22)
            Image(systemName: "chevron.right")
                .font(.system(size: diameter * 0.4, weight: .heavy))
                .foregroundStyle(Color.white)
                .offset(x: diameter * 0.03)
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: (colors.last ?? .black).opacity(0.45), radius: diameter * 0.12, x: 0, y: diameter * 0.06)
        .accessibilityHidden(true)
    }
}

/// The pink brush-stroke under titles.
struct Swoosh: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height
            Path { path in
                path.move(to: CGPoint(x: 0, y: h * 0.65))
                path.addQuadCurve(to: CGPoint(x: w, y: h * 0.3), control: CGPoint(x: w * 0.45, y: h * 1.15))
            }
            .stroke(LinearGradient(colors: [Palette.hotPink, Palette.bubblegum.opacity(0.4)],
                                   startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: max(1.5, h * 0.4), lineCap: .round))
        }
        .accessibilityHidden(true)
    }
}

/// A soft white shine across the top of a card.
struct GlossHighlight: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(LinearGradient(stops: [.init(color: Color.white.opacity(0.55), location: 0),
                                         .init(color: Color.white.opacity(0), location: 0.45)],
                                 startPoint: .top, endPoint: .bottom))
            .allowsHitTesting(false)
    }
}

/// A curved golden corner piece (drawn for the top-left corner).
struct CornerFlourish: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY),
                          control: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY + rect.height * 0.28))
        path.closeSubpath()
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.12,
                                   width: rect.width * 0.16, height: rect.height * 0.16))
        return path
    }
}

/// A bookmark ribbon with a V-shaped end.
struct Ribbon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.width * 0.6))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
