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
    private let minSampleDistance: CGFloat = 16
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

        // New movement means the trail is alive again, so cancel any decay in
        // progress from a previous pause rather than let it keep shedding ghosts
        // out from under the fresh ones.
        decayTimer?.invalidate()
        decayTimer = nil

        points.append(screenPoint)
        trimBuffer()
        updateView()
        window.orderFront(nil)

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
        view.points = []
        view.needsDisplay = true
        window.orderOut(nil)
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
                self.window.orderOut(nil)
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
