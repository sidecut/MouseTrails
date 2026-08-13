import AppKit

final class CircleOverlayController {
    private let diameter: CGFloat = 40
    private let displayDuration: TimeInterval = 1.0

    private let window: NSWindow
    private var hideTimer: Timer?

    init() {
        let size = NSSize(width: diameter, height: diameter)
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        window.contentView = CircleOverlayView(frame: NSRect(origin: .zero, size: size))
    }

    func flash(at point: NSPoint) {
        let origin = NSPoint(x: point.x - diameter / 2, y: point.y - diameter / 2)
        window.setFrameOrigin(origin)
        window.orderFront(nil)

        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false) { [weak self] _ in
            self?.window.orderOut(nil)
        }
    }
}
