import AppKit

final class MouseTrailController {
    var settings = MouseTrailSettings.default {
        didSet { trimBuffer() }
    }
    var color: NSColor = .systemOrange {
        didSet { view.color = color }
    }

    private let window: NSWindow
    private let view: MouseTrailView
    private var points: [NSPoint] = []
    private var idleTimer: Timer?

    // Trail clears this long after the last recorded sample.
    private let idleClearInterval: TimeInterval = 0.2

    // Minimum spacing between recorded points, in both time and distance, so a
    // fast move across the screen still produces discrete ghosts rather than one
    // per pixel.
    private let minSampleInterval: TimeInterval = 0.02
    private let minSampleDistance: CGFloat = 8
    private var lastSampleTime: TimeInterval = 0
    private var lastSamplePoint: NSPoint?

    init() {
        let frame = Self.screensUnionFrame()
        window = NSWindow(
            contentRect: frame,
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

        let view = MouseTrailView(frame: NSRect(origin: .zero, size: frame.size))
        view.autoresizingMask = [.width, .height]
        window.contentView = view
        self.view = view

        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    func recordSample(at screenPoint: NSPoint) {
        let now = ProcessInfo.processInfo.systemUptime
        if let last = lastSamplePoint {
            let dx = screenPoint.x - last.x
            let dy = screenPoint.y - last.y
            let movedEnough = (dx * dx + dy * dy) >= minSampleDistance * minSampleDistance
            let enoughTime = (now - lastSampleTime) >= minSampleInterval
            guard movedEnough, enoughTime else { return }
        }
        lastSampleTime = now
        lastSamplePoint = screenPoint

        points.append(screenPoint)
        trimBuffer()
        updateView()
        window.orderFront(nil)

        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: idleClearInterval, repeats: false) {
            [weak self] _ in
            self?.clear()
        }
    }

    func clear() {
        idleTimer?.invalidate()
        idleTimer = nil
        points.removeAll()
        lastSamplePoint = nil
        view.points = []
        view.needsDisplay = true
        window.orderOut(nil)
    }

    private func trimBuffer() {
        let maxCount = max(2, settings.trailLength)
        if points.count > maxCount {
            points.removeFirst(points.count - maxCount)
        }
        updateView()
    }

    private func updateView() {
        let origin = window.frame.origin
        view.points = points.map { NSPoint(x: $0.x - origin.x, y: $0.y - origin.y) }
        view.needsDisplay = true
    }

    @objc private func screensChanged() {
        let frame = Self.screensUnionFrame()
        window.setFrame(frame, display: false)
        view.frame = NSRect(origin: .zero, size: frame.size)
        updateView()
    }

    private static func screensUnionFrame() -> NSRect {
        NSScreen.screens.reduce(NSRect.zero) { $0.union($1.frame) }
    }
}
