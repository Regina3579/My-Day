import SwiftUI

/// The ⋮ menu of My Journal Pages, as in its design: a cream card in a gold frame with little
/// flowers and sparkles, a pink heart bow on top, and a row for each choice (its picture in a
/// soft round badge, pink hearts at the end, a thin line between rows). The card, bow, pictures
/// and hearts are the design's own picture (enlarged 4× with Real-ESRGAN, its words taken out);
/// the names are written here in thick dark navy, so they stay sharp and easy to read. The
/// Lock My Journal row (its gold heart lock is the one on the kitten's journal in the Journal
/// Lock tip) is a copy of the Journal Theme row, added above Trash.
///
/// Everything is placed on the design's grid: the card picture is 520 × 680 pixels of a design
/// 941 pixels across the screen.
struct JournalPagesMenu: View {
    struct Item: Identifiable {
        let title: String
        /// A row with a switch at its end (Lock My Journal): on or off.
        var isOn: Bool?
        let action: () -> Void
        var id: String { title }
    }

    /// The six choices, top to bottom, as the picture shows them.
    let items: [Item]
    /// Points per pixel of the design.
    let scale: CGFloat
    /// Where Journal Theme is on screen (for its first-time tip).
    var onThemeRowFrame: ((CGRect) -> Void)?

    /// The picture's size, in pixels of the design.
    static let grid = CGSize(width: 520, height: 680)
    /// Where ⋮'s middle is on the picture's grid (the menu hangs from it).
    static let moreButton = CGPoint(x: 468, y: 52)

    private static let ink = Color(hex: 0x0A0A48)
    /// Each row's top and bottom, and where its name starts and must end.
    private static let rows: [(top: CGFloat, bottom: CGFloat)] = [
        (95, 200), (200, 292), (292, 385), (385, 475), (475, 567), (567, 662),
    ]
    private static let textStart: CGFloat = 160
    private static let textEnd: CGFloat = 402
    /// The names' size: 33 pixels of the design.
    private static let fontPixels: CGFloat = 33

    var body: some View {
        Image("JournalMenuCard")
            .resizable()
            .frame(width: Self.grid.width * scale, height: Self.grid.height * scale)
            // Only the rows take taps: ⋮ shows through the bite in the card's corner.
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    ForEach(Array(items.prefix(Self.rows.count).enumerated()), id: \.element.id) { index, item in
                        // Only the first (the tallest row) takes two lines, as in the design.
                        row(item, Self.rows[index], lines: index == 0 ? 2 : 1)
                    }
                }
            }
            .accessibilityElement(children: .contain)
    }

    private func row(_ item: Item, _ span: (top: CGFloat, bottom: CGFloat), lines: Int) -> some View {
        let frame = CGRect(x: 30 * scale, y: span.top * scale,
                           width: (Self.grid.width - 60) * scale, height: (span.bottom - span.top) * scale)
        return Button(action: item.action) {
            Text(crowned: item.title)
                .font(.system(size: Self.fontPixels * scale, weight: .heavy, design: .rounded))
                .foregroundStyle(Self.ink)
                .lineLimit(lines)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.leading)
                .lineSpacing(-2)
                .frame(width: (Self.textEnd - Self.textStart + (item.isOn == nil ? 0 : 6)) * scale,
                       alignment: .leading)
                .padding(.leading, (Self.textStart - 30) * scale)
                .frame(width: frame.width, height: frame.height, alignment: .leading)
                .overlay(alignment: .trailing) {
                    if let isOn = item.isOn {
                        // Over the row's hearts, where a switch belongs.
                        MenuSwitch(isOn: isOn, scale: scale)
                            .padding(.trailing, 2 * scale)
                    }
                }
        }
        .buttonStyle(MenuRowStyle())
        .frame(width: frame.width, height: frame.height)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { global in
            if item.title == "Journal Theme" { onThemeRowFrame?(global) }
        }
        .offset(x: frame.minX, y: frame.minY)
        .accessibilityLabel(item.title.replacingOccurrences(of: " 👑", with: ", My Day Pro"))
        .accessibilityValue(item.isOn.map { $0 ? "On" : "Off" } ?? "")
        .accessibilityAddTraits(item.isOn == nil ? [] : .isToggle)
    }
}

/// The pink switch on Lock My Journal: a glossy pink track with a white knob and a little heart
/// when on, soft lilac-grey when off.
private struct MenuSwitch: View {
    let isOn: Bool
    let scale: CGFloat

    var body: some View {
        let width = 76 * scale, height = 46 * scale
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn
                      ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFF8DC0), Color(hex: 0xF0569B)],
                                                     startPoint: .top, endPoint: .bottom))
                      : AnyShapeStyle(Color(hex: 0xEADDE6)))
                .overlay(Capsule().strokeBorder(isOn ? Color(hex: 0xE0418A).opacity(0.5) : Color(hex: 0xD9C5D2),
                                                lineWidth: 1.5))
            Circle()
                .fill(Color.white)
                .frame(width: height - 8 * scale, height: height - 8 * scale)
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                .overlay {
                    Image(systemName: isOn ? "heart.fill" : "lock.open.fill")
                        .font(.system(size: 18 * scale, weight: .bold))
                        .foregroundStyle(isOn ? Color(hex: 0xF0569B) : Color(hex: 0xB9A3B3))
                }
                .padding(4 * scale)
        }
        .frame(width: width, height: height)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isOn)
        .accessibilityHidden(true)
    }
}

/// A row of the menu: a soft pink wash while it is pressed.
private struct MenuRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: 0xF7B6CF).opacity(configuration.isPressed ? 0.35 : 0))
            )
            .contentShape(Rectangle())
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
