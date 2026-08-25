import AppKit

final class MouseTrailController {
    var settings = MouseTrailSettings.default {
        didSet { trimBuffer() }
    }
    var color: NSColor = .systemOrange {
        didSet { overlays.forEach { $0.view.color = color } }
    }

    // One window per screen, not a single window spanning the union of all
    // screens: when "Displays have separate Spaces" is on (the default), a
    // window only appears on the screen whose space it was assigned to, so a
    // union window silently fails to show on every screen but one.
    private var overlays: [(window: NSWindow, view: MouseTrailView)] = []
    private var points: [NSPoint] = []
    private var idleTimer: Timer?
    private var decayTimer: Timer?

    // Once the mouse has been still this long, the trail starts shedding its
    // oldest ghost every decayStepInterval, so the ghosts peel off one at a time
    // instead of all vanishing together the instant the mouse stops.
    private let idleBeforeDecay: TimeInterval = 0.1
    private let decayStepInterval: TimeInterval = 0.05

    // Minimum spacing between recorded points, in both time and distance, so a
    // fast move across the screen still produces discrete ghosts rather than one
    // per pixel. The distance must be close to the ghost's own footprint
    // (MouseTrailView's ghostHeight) or consecutive ghosts overlap heavily and
    // their stacked alpha reads as one blob larger than the real cursor.
    private let minSampleInterval: TimeInterval = 0.02
    private let minSampleDistance: CGFloat = 12
    private var lastSampleTime: TimeInterval = 0
    private var lastSamplePoint: NSPoint?

    init() {
        rebuildOverlays()

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

        // New movement means the trail is alive again, so cancel any decay in
        // progress from a previous pause rather than let it keep shedding ghosts
        // out from under the fresh ones.
        decayTimer?.invalidate()
        decayTimer = nil

        points.append(screenPoint)
        trimBuffer()
        updateView()
        overlays.forEach { $0.window.orderFront(nil) }

        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: idleBeforeDecay, repeats: false) {
            [weak self] _ in
            self?.beginDecay()
        }
    }

    func clear() {
        idleTimer?.invalidate()
        idleTimer = nil
        decayTimer?.invalidate()
        decayTimer = nil
        points.removeAll()
        lastSamplePoint = nil
        for overlay in overlays {
            overlay.view.points = []
            overlay.view.needsDisplay = true
            overlay.window.orderOut(nil)
        }
    }

    private func beginDecay() {
        guard !points.isEmpty else { return }
        decayTimer?.invalidate()
        decayTimer = Timer.scheduledTimer(withTimeInterval: decayStepInterval, repeats: true) {
            [weak self] timer in
            guard let self, !self.points.isEmpty else {
                timer.invalidate()
                self?.decayTimer = nil
                return
            }
            self.points.removeFirst()
            self.updateView()
            if self.points.isEmpty {
                timer.invalidate()
                self.decayTimer = nil
                self.lastSamplePoint = nil
                self.overlays.forEach { $0.window.orderOut(nil) }
            }
        }
    }

    private func trimBuffer() {
        let maxCount = max(2, settings.trailLength)
        if points.count > maxCount {
            points.removeFirst(points.count - maxCount)
        }
        updateView()
    }

    private func updateView() {
        for overlay in overlays {
            let origin = overlay.window.frame.origin
            overlay.view.points = points.map { NSPoint(x: $0.x - origin.x, y: $0.y - origin.y) }
            overlay.view.needsDisplay = true
        }
    }

    @objc private func screensChanged() {
        rebuildOverlays()
        updateView()
        if !points.isEmpty {
            overlays.forEach { $0.window.orderFront(nil) }
        }
    }

    private func rebuildOverlays() {
        for overlay in overlays {
            overlay.window.orderOut(nil)
        }
        overlays = NSScreen.screens.map { screen in
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.level = .screenSaver
            window.collectionBehavior = [
                .canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle,
            ]

            let trailView = MouseTrailView(frame: NSRect(origin: .zero, size: screen.frame.size))
            trailView.autoresizingMask = [.width, .height]
            trailView.color = color
            window.contentView = trailView

            return (window, trailView)
        }
    }
}
