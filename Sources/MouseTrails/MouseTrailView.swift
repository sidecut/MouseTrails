import AppKit

final class MouseTrailView: NSView {
    var color: NSColor = .systemOrange
    /// Points in the view's own local coordinate space, oldest first, newest last.
    var points: [NSPoint] = []

    private let ghostHeight: CGFloat = 18

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()

        let count = points.count
        guard count > 0 else { return }

        for (index, point) in points.enumerated() {
            let progress = CGFloat(index + 1) / CGFloat(count)
            let alpha = progress * progress * 0.7
            let path = GhostCursorShape.path(tip: point, height: ghostHeight)

            // A light-then-dark double outline, same trick as the menu bar icon:
            // a solid color fill alone can vanish against a similarly-bright
            // background (e.g. a magenta trail on a blue window), so at least
            // one ring needs to contrast with whatever's behind it. The white
            // stroke is drawn first and wider; filling over it leaves only its
            // outer half showing as a light halo, then a thin dark stroke on
            // top adds a crisp edge for light backgrounds.
            path.lineWidth = 2.5
            NSColor.white.withAlphaComponent(alpha * 0.9).setStroke()
            path.stroke()

            color.withAlphaComponent(alpha).setFill()
            path.fill()

            path.lineWidth = 1
            NSColor.black.withAlphaComponent(alpha * 0.55).setStroke()
            path.stroke()
        }
    }
}
