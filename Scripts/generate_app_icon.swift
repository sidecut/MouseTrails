import AppKit

// Renders a 1024×1024 PNG of the MouseTrails icon:
//   • Dark background with rounded corners
//   • Orange expanding ring centred on the cursor tip
//   • White arrow cursor with the tip at the ring's centre
//   • Small orange dot at the hotspot
//
// Usage:  swift Scripts/generate_app_icon.swift <output-png-path>

let size = 1024
let fSize = CGFloat(size)

// Anchor = cursor tip = ring centre.  Nudged slightly NW of the canvas
// centre so the cursor body (which extends SE) reads as optically centred.
let opticalOffset = fSize * 0.03
let anchor = NSPoint(
    x: fSize / 2 - opticalOffset,
    y: fSize / 2 + opticalOffset  // AppKit: y increases upward, so +offset is visually up
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
let background = NSColor(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255, alpha: 1)
background.setFill()
NSBezierPath(
    roundedRect: NSRect(origin: .zero, size: NSSize(width: fSize, height: fSize)),
    xRadius: fSize * 0.225,
    yRadius: fSize * 0.225
).fill()

// Orange expanding ring centred on the cursor tip
let orange = NSColor(red: 1.0, green: 0x9F / 255, blue: 0x0A / 255, alpha: 1)
let ringRadius = fSize * 0.234
let ringRect = NSRect(
    x: anchor.x - ringRadius, y: anchor.y - ringRadius,
    width: ringRadius * 2, height: ringRadius * 2
)
let ringPath = NSBezierPath(ovalIn: ringRect)
ringPath.lineWidth = fSize * 0.031
orange.setStroke()
ringPath.stroke()

// White arrow cursor with tip at the anchor.
// Normalized coordinates with tip at (0, 1) in AppKit's bottom-up unit box
// (y=0 is the lowest point of the tail, y=1 is the tip).
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

// Subtle drop shadow: offset dark copy drawn first
let shadowPath = cursorPath.copy() as! NSBezierPath
shadowPath.transform(using: AffineTransform(
    translationByX: fSize * 0.006, byY: -(fSize * 0.008)))
NSColor.black.withAlphaComponent(0.35).setFill()
shadowPath.fill()

// Cursor fill and hairline inner stroke for definition on dark background
NSColor.white.setFill()
cursorPath.fill()
cursorPath.lineWidth = fSize * 0.014
NSColor.black.withAlphaComponent(0.15).setStroke()
cursorPath.stroke()

// Orange hotspot dot at the tip, tying the cursor to the ring centre
let dotRadius = fSize * 0.018
let dotRect = NSRect(
    x: anchor.x - dotRadius, y: anchor.y - dotRadius,
    width: dotRadius * 2, height: dotRadius * 2
)
orange.setFill()
NSBezierPath(ovalIn: dotRect).fill()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
