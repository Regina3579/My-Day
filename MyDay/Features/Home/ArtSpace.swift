import SwiftUI

/// Maps pixel coordinates of the 853 × 1844 home artwork onto the screen, so
/// native controls sit exactly on top of the painted scene on every iPhone.
///
/// The artwork is scaled to fill the screen. On modern iPhones (≈ 9 : 19.5)
/// it fits with less than a point cropped at each side; on shorter screens
/// such as iPhone SE it keeps its full width and the home screen scrolls.
struct ArtSpace {
    static let pixelSize = CGSize(width: 853, height: 1844)

    let container: CGSize
    let scale: CGFloat
    let originX: CGFloat

    init(container: CGSize) {
        self.container = container
        let fill = max(container.width / Self.pixelSize.width, container.height / Self.pixelSize.height)
        scale = fill.isFinite && fill > 0 ? fill : 0.46
        originX = (container.width - Self.pixelSize.width * scale) / 2
    }

    var artWidth: CGFloat { Self.pixelSize.width * scale }
    var artHeight: CGFloat { Self.pixelSize.height * scale }
    var needsScroll: Bool { artHeight > container.height + 1 }

    func x(_ px: CGFloat) -> CGFloat { originX + px * scale }
    func y(_ px: CGFloat) -> CGFloat { px * scale }
    func len(_ px: CGFloat) -> CGFloat { px * scale }
    func point(_ px: CGFloat, _ py: CGFloat) -> CGPoint { CGPoint(x: x(px), y: y(py)) }

    func rect(_ px: CGFloat, _ py: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        CGRect(x: x(px), y: y(py), width: len(width), height: len(height))
    }
}

/// Size and placement of the floating tab bar, taken from the artwork.
struct TabBarMetrics {
    let width: CGFloat
    let height: CGFloat
    let bottomPadding: CGFloat
    let unit: CGFloat

    init(space: ArtSpace) {
        unit = space.scale
        width = min(space.container.width - 16, space.len(813))
        height = space.len(116)
        bottomPadding = space.len(30)
    }
}

private struct ArtSpaceKey: EnvironmentKey {
    static let defaultValue = ArtSpace(container: CGSize(width: 393, height: 852))
}

extension EnvironmentValues {
    var artSpace: ArtSpace {
        get { self[ArtSpaceKey.self] }
        set { self[ArtSpaceKey.self] = newValue }
    }
}
