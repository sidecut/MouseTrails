import AppKit

final class MouseTrailView: NSView {
    var color: NSColor = .systemOrange
    /// Points in the view's own local coordinate space, oldest first, newest last.
    var points: [NSPoint] = []

    private let ghostHeight: CGFloat = 22

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()

        let count = points.count
        guard count > 0 else { return }

        for (index, point) in points.enumerated() {
            let progress = CGFloat(index + 1) / CGFloat(count)
            let alpha = progress * progress * 0.85
            let path = GhostCursorShape.path(tip: point, height: ghostHeight)
            color.withAlphaComponent(alpha).setFill()
            path.fill()
        }
    }
}
