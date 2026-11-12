import UIKit

/// UIKit-level styling that SwiftUI does not expose directly:
/// rounded navigation titles and pink segmented controls.
@MainActor
enum Appearance {
    static func configure() {
        let ink = UIColor(red: 0x1B / 255, green: 0x14 / 255, blue: 0x46 / 255, alpha: 1)
        let pink = UIColor(red: 0xF8 / 255, green: 0x1C / 255, blue: 0x7A / 255, alpha: 1)

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: rounded(size: 17, weight: .bold),
            .foregroundColor: ink
        ]
        let largeTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: rounded(size: 34, weight: .heavy),
            .foregroundColor: ink
        ]

        let standard = UINavigationBarAppearance()
        standard.configureWithDefaultBackground()
        standard.titleTextAttributes = titleAttributes
        standard.largeTitleTextAttributes = largeTitleAttributes

        let edge = UINavigationBarAppearance()
        edge.configureWithTransparentBackground()
        edge.titleTextAttributes = titleAttributes
        edge.largeTitleTextAttributes = largeTitleAttributes

        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = standard
        navigationBar.compactAppearance = standard
        navigationBar.scrollEdgeAppearance = edge

        let segmented = UISegmentedControl.appearance()
        segmented.selectedSegmentTintColor = pink
        segmented.setTitleTextAttributes(
            [.foregroundColor: UIColor.white, .font: rounded(size: 14, weight: .bold)], for: .selected)
        segmented.setTitleTextAttributes(
            [.foregroundColor: ink, .font: rounded(size: 14, weight: .semibold)], for: .normal)
    }

    private static func rounded(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}
