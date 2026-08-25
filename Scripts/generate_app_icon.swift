import AppKit

// Renders a 1024×1024 PNG for MouseTrails:
//   • Light gray background with rounded corners
//   • Two concentric 270° arcs centred on the cursor tip
//     (gap in the lower-right, where the cursor body points)
//   • White arrow cursor with a bold dark outline
//
// Usage:  swift Scripts/generate_app_icon.swift <output-png-path>

let size = 1024
let fSize = CGFloat(size)

// Cursor tip = arc centre.  Nudged NW of canvas centre so the cursor body
// (which extends SE) reads as optically centred.
let opticalOffset = fSize * 0.03
let anchor = NSPoint(
    x: fSize / 2 - opticalOffset,
    y: fSize / 2 + opticalOffset  // AppKit y-up: +offset = visually higher
)

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else { fatalError("Failed to create bitmap rep") }
rep.size = NSSize(width: fSize, height: fSize)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Background
NSColor(red: 0xF0 / 255, green: 0xF0 / 255, blue: 0xF0 / 255, alpha: 1).setFill()
NSBezierPath(
    roundedRect: NSRect(origin: .zero, size: NSSize(width: fSize, height: fSize)),
    xRadius: fSize * 0.225,
    yRadius: fSize * 0.225
).fill()

// Ink colour used for the cursor outline
let ink = NSColor(red: 0x3C / 255, green: 0x3C / 255, blue: 0x3C / 255, alpha: 1)

// Orange used for the two arcs
let orange = NSColor(red: 1.0, green: 0x9F / 255, blue: 0x0A / 255, alpha: 1)

// Cursor rotation about its tip, in degrees: 0° keeps its left edge vertical
// (matching the reference image exactly); 45° would fully bisect the SE gap.
// A small amount reads as more confidently "pointing" than a dead-vertical
// arrow, without losing the vertical-edge look.
let cursorRotationDegrees: CGFloat = 7

// Two arcs centred on the cursor tip, leaving a gap sized and positioned to
// bracket the cursor's own angular span (after rotation, below) with
// clearance on both sides, instead of touching one edge of it.
//
// AppKit angles (y-up): 0°=E, 90°=N, 180°=W, 270°=S. The cursor's own
// angular span, unrotated, is centred around 289°; rotating the cursor
// shifts that centre by the same amount.
let gapDegrees: CGFloat = 62
let gapCenter: CGFloat = 289 + cursorRotationDegrees
let arcStroke = fSize * 0.048
for radius in [fSize * 0.19, fSize * 0.27] {
    let arc = NSBezierPath()
    arc.appendArc(withCenter: anchor, radius: radius,
                  startAngle: gapCenter + gapDegrees / 2,
                  endAngle: gapCenter - gapDegrees / 2 + 360,
                  clockwise: false)
    arc.lineWidth = arcStroke
    arc.lineCapStyle = .round
    orange.setStroke()
    arc.stroke()
}

// Arrow cursor with tip at the anchor.
// Normalised coordinates: tip = (0, 1) in a bottom-up AppKit unit box;
// y=0 is the lowest point of the tail. Shape is built pointing straight
// down, then rotated by cursorRotationDegrees about the tip.
let cursorPoints: [(CGFloat, CGFloat)] = [
    (0.000, 1.000),  // tip
    (0.000, 0.111),  // bottom of left edge
    (0.222, 0.306),  // concave notch
    (0.361, 0.000),  // tail bottom
    (0.472, 0.056),  // tail right
    (0.333, 0.361),  // tail inner
    (0.611, 0.361),  // shoulder
]
let cursorHeight = fSize * 0.42
let cursorWidth = cursorHeight * 0.78
let cursorRotation = cursorRotationDegrees * CGFloat.pi / 180

let cursorPath = NSBezierPath()
for (i, pt) in cursorPoints.enumerated() {
    // Position relative to the tip, before rotation (shaft points straight down).
    let dx = pt.0 * cursorWidth
    let dy = (pt.1 - 1) * cursorHeight
    let rdx = dx * cos(cursorRotation) - dy * sin(cursorRotation)
    let rdy = dx * sin(cursorRotation) + dy * cos(cursorRotation)
    let p = NSPoint(x: anchor.x + rdx, y: anchor.y + rdy)
    if i == 0 { cursorPath.move(to: p) } else { cursorPath.line(to: p) }
}
cursorPath.close()
cursorPath.lineJoinStyle = .round
cursorPath.lineWidth = fSize * 0.030

// Fill then stroke: white interior with bold dark outline on all edges
NSColor.white.setFill()
cursorPath.fill()
ink.setStroke()
cursorPath.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
