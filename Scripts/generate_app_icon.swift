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

// Ink colour used for both arcs and cursor outline
let ink = NSColor(red: 0x3C / 255, green: 0x3C / 255, blue: 0x3C / 255, alpha: 1)

// Two 270° arcs centred on the cursor tip.
//
// appendArc CCW from 0° to 270° (AppKit y-up angles):
//   0° (E/right) → 90° (N/up) → 180° (W/left) → 270° (S/down)
// Covered arc: right side, top, left side, bottom.
// Gap: from 270° (bottom) to 0°/360° (right) = the lower-right (SE) area,
//   which is exactly where the cursor body extends. ✓
let arcStroke = fSize * 0.048
for radius in [fSize * 0.19, fSize * 0.27] {
    let arc = NSBezierPath()
    arc.appendArc(withCenter: anchor, radius: radius,
                  startAngle: 0, endAngle: 270, clockwise: false)
    arc.lineWidth = arcStroke
    arc.lineCapStyle = .round
    ink.setStroke()
    arc.stroke()
}

// Arrow cursor with tip at the anchor.
// Normalised coordinates: tip = (0, 1) in a bottom-up AppKit unit box;
// y=0 is the lowest point of the tail.
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
let cursorWidth = cursorHeight * 0.611
let cursorOrigin = NSPoint(x: anchor.x, y: anchor.y - cursorHeight)

let cursorPath = NSBezierPath()
for (i, pt) in cursorPoints.enumerated() {
    let p = NSPoint(
        x: cursorOrigin.x + pt.0 * cursorWidth,
        y: cursorOrigin.y + pt.1 * cursorHeight
    )
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
