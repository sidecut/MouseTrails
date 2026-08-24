import AppKit

// Renders a 1024x1024 PNG of three concentric orange rings, evoking the
// expanding ripple the app flashes around the mouse pointer, for use as
// the base image when building AppIcon.icns.
// Usage: swift Scripts/generate_app_icon.swift <output-png-path>

let size = 1024
let center = NSPoint(x: CGFloat(size) / 2, y: CGFloat(size) / 2)

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
) else {
    fatalError("Failed to create bitmap rep")
}
rep.size = NSSize(width: size, height: size)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

NSColor.white.setFill()
NSRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size)).fill()

// Rings ripple outward from the center: bold and opaque near the
// pointer, fading and thinning as they expand, mirroring the app's
// flash animation.
struct Ring {
    let radiusFraction: CGFloat
    let lineWidthFraction: CGFloat
    let alpha: CGFloat
}
let rings = [
    Ring(radiusFraction: 0.20, lineWidthFraction: 0.055, alpha: 1.0),
    Ring(radiusFraction: 0.33, lineWidthFraction: 0.040, alpha: 0.65),
    Ring(radiusFraction: 0.45, lineWidthFraction: 0.028, alpha: 0.35),
]

for ring in rings {
    let radius = CGFloat(size) * ring.radiusFraction
    let lineWidth = CGFloat(size) * ring.lineWidthFraction
    let circleRect = NSRect(
        x: center.x - radius, y: center.y - radius,
        width: radius * 2, height: radius * 2
    )
    let path = NSBezierPath(ovalIn: circleRect)
    path.lineWidth = lineWidth
    NSColor.systemOrange.withAlphaComponent(ring.alpha).setStroke()
    path.stroke()
}

// A filled pointer glyph centered in the ripple, standing in for the
// cursor the flash rings emanate from. Points are normalized to a
// unit box with the tip at the top-left, matching a classic arrow
// cursor's silhouette.
let cursorPoints: [(CGFloat, CGFloat)] = [
    (0.000, 1.000),
    (0.000, 0.111),
    (0.222, 0.306),
    (0.361, 0.000),
    (0.472, 0.056),
    (0.333, 0.361),
    (0.611, 0.361),
]
let cursorHeight = CGFloat(size) * 0.26
let cursorWidth = cursorHeight * 0.611
let cursorOrigin = NSPoint(x: center.x - cursorWidth / 2, y: center.y - cursorHeight / 2)

let cursorPath = NSBezierPath()
for (index, point) in cursorPoints.enumerated() {
    let mapped = NSPoint(
        x: cursorOrigin.x + point.0 * cursorWidth,
        y: cursorOrigin.y + point.1 * cursorHeight
    )
    if index == 0 {
        cursorPath.move(to: mapped)
    } else {
        cursorPath.line(to: mapped)
    }
}
cursorPath.close()
NSColor.systemOrange.setFill()
cursorPath.fill()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}

let outputPath = CommandLine.arguments[1]
try png.write(to: URL(fileURLWithPath: outputPath))
