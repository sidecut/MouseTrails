import AppKit

struct TrailSample {
    var location: NSPoint
    /// Snapshot of the system cursor at the time of the sample; nil means draw
    /// the built-in arrow ghost instead.
    var cursorImage: NSImage?
    var cursorHotSpot: NSPoint
}

final class MouseTrailView: NSView {
    var color: NSColor = .systemOrange
    /// Samples in the view's own local coordinate space, oldest first, newest last.
    var samples: [TrailSample] = []

    private let ghostHeight: CGFloat = 14

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()

        let count = samples.count
        guard count > 0 else { return }

        for (index, sample) in samples.enumerated() {
            let progress = CGFloat(index + 1) / CGFloat(count)
            let alpha = progress * progress * 0.7

            if let image = sample.cursorImage {
                // The recorded location is where the cursor's hotspot was, and the
                // hotspot is measured from the image's top-left corner, so in this
                // non-flipped view the image's origin sits below-left of it. Drawn
                // at natural size so ghosts match the real cursor exactly; system
                // cursors carry their own light/dark contrast, so no outline pass.
                let size = image.size
                let origin = NSPoint(
                    x: sample.location.x - sample.cursorHotSpot.x,
                    y: sample.location.y + sample.cursorHotSpot.y - size.height)
                image.draw(
                    in: NSRect(origin: origin, size: size), from: .zero,
                    operation: .sourceOver, fraction: alpha)
                continue
            }

            let path = GhostCursorShape.path(tip: sample.location, height: ghostHeight)

            // A light-then-dark double outline, same trick as the menu bar icon:
            // a solid color fill alone can vanish against a similarly-bright
            // background (e.g. a magenta trail on a blue window), so at least
            // one ring needs to contrast with whatever's behind it. The white
            // stroke is drawn first and wider; filling over it leaves only its
            // outer half showing as a light halo, then a thin dark stroke on
            // top adds a crisp edge for light backgrounds.
            path.lineWidth = 1.75
            NSColor.white.withAlphaComponent(alpha * 0.9).setStroke()
            path.stroke()

            color.withAlphaComponent(alpha).setFill()
            path.fill()

            path.lineWidth = 0.75
            NSColor.black.withAlphaComponent(alpha * 0.55).setStroke()
            path.stroke()
        }
    }
}
