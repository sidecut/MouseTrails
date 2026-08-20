import AppKit

final class CircleOverlayView: NSView {
    var settings = OverlaySettings.default

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()

        let lineWidth = settings.lineWidth
        let inset = lineWidth / 2 + 1
        let circleRect = bounds.insetBy(dx: inset, dy: inset)
        let path = NSBezierPath(ovalIn: circleRect)
        path.lineWidth = lineWidth

        settings.color.setStroke()
        path.stroke()
    }
}
