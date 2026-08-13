import AppKit

final class CircleOverlayController {
    private let baseDiameter: CGFloat = 10
    private let maxDiameter: CGFloat = 120
    private let totalDuration: TimeInterval = 0.25
    private let steps = 12

    private let window: NSWindow
    private var animationTimer: Timer?
    private var center: NSPoint = .zero
    private var currentStep = 0

    init() {
        let size = NSSize(width: maxDiameter, height: maxDiameter)
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

        let view = CircleOverlayView(frame: NSRect(origin: .zero, size: size))
        view.autoresizingMask = [.width, .height]
        window.contentView = view
    }

    func flash(at point: NSPoint) {
        center = point
        currentStep = 0
        animationTimer?.invalidate()
        applyFrame(forStep: 0)
        window.orderFront(nil)

        let interval = totalDuration / Double(steps)
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            self?.advanceAnimation(timer: timer)
        }
    }

    func cancel() {
        animationTimer?.invalidate()
        animationTimer = nil
        window.orderOut(nil)
    }

    private func advanceAnimation(timer: Timer) {
        currentStep += 1
        guard currentStep < steps else {
            timer.invalidate()
            window.orderOut(nil)
            return
        }
        applyFrame(forStep: currentStep)
    }

    private func applyFrame(forStep step: Int) {
        let progress = CGFloat(step) / CGFloat(steps - 1)
        let diameter = baseDiameter + (maxDiameter - baseDiameter) * progress
        let origin = NSPoint(x: center.x - diameter / 2, y: center.y - diameter / 2)
        window.setFrame(NSRect(origin: origin, size: NSSize(width: diameter, height: diameter)), display: true)
    }
}
