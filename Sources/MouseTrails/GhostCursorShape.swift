import AppKit

enum GhostCursorShape {
    // Normalized unit-box coordinates, tip at (0,1), bottom-up (AppKit) space.
    // Ported from Scripts/generate_app_icon.swift's cursorPoints.
    private static let points: [(CGFloat, CGFloat)] = [
        (0.000, 1.000),  // tip
        (0.000, 0.111),  // bottom of left edge
        (0.222, 0.306),  // concave notch
        (0.361, 0.000),  // tail bottom
        (0.472, 0.056),  // tail right
        (0.333, 0.361),  // tail inner
        (0.611, 0.361),  // shoulder
    ]

    static func path(tip: NSPoint, height: CGFloat) -> NSBezierPath {
        let width = height * 0.78
        let path = NSBezierPath()
        for (i, pt) in points.enumerated() {
            let dx = pt.0 * width
            let dy = (pt.1 - 1) * height
            let p = NSPoint(x: tip.x + dx, y: tip.y + dy)
            if i == 0 { path.move(to: p) } else { path.line(to: p) }
        }
        path.close()
        path.lineJoinStyle = .round
        return path
    }
}
