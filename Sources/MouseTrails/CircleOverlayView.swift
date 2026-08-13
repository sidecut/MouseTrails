import AppKit

final class CircleOverlayView: NSView {
    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()

        let lineWidth: CGFloat = 3
        let inset = lineWidth / 2 + 1
        let circleRect = bounds.insetBy(dx: inset, dy: inset)
        let path = NSBezierPath(ovalIn: circleRect)
        path.lineWidth = lineWidth

        NSColor.systemOrange.setStroke()
        path.stroke()
    }
}
