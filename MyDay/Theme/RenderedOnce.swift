import SwiftUI

extension View {
    /// Draws a decorative piece (a card's frame and glow, a tab, a date, a theme's sky) as one
    /// picture, made once, so a scrolling page only has to move it. Shadows, blurs and masks
    /// left as they are get painted again on every frame of a scroll, up to 120 times a second,
    /// and a page full of them stutters. `bleed` is the room a shadow or glow needs beyond the
    /// view's frame; the layout keeps the view's own size.
    ///
    /// Only for plain SwiftUI drawing: shapes, text, images, canvases and buttons made of them,
    /// never a text field, a picker or anything else UIKit draws.
    func renderedOnce(bleed: CGFloat = 0) -> some View {
        padding(bleed)
            .drawingGroup()
            .padding(-bleed)
    }
}
