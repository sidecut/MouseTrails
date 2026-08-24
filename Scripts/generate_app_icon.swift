import AppKit

// Renders a 1024x1024 PNG of a mouse pointer with a radiating
// black-and-white "click" burst around its tip, for use as the base
// image when building AppIcon.icns.
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

// "Click" burst: short black rays radiating from the pointer's tip,
// alternating long/short for a sparkle feel. Drawn before the pointer
// so the pointer sits cleanly on top near the tip, with the burst
// showing through on the side the pointer doesn't cover.
let rayInnerRadius = CGFloat(size) * 0.05
let rayLengthFractions: [CGFloat] = [0.22, 0.15, 0.22, 0.15, 0.22, 0.15, 0.22, 0.15]
let rayLineWidth = CGFloat(size) * 0.02

for (index, lengthFraction) in rayLengthFractions.enumerated() {
    let angle = CGFloat(index) * (.pi / 4)
    let outerRadius = CGFloat(size) * lengthFraction
    let start = NSPoint(
        x: center.x + cos(angle) * rayInnerRadius,
        y: center.y + sin(angle) * rayInnerRadius
    )
    let end = NSPoint(
        x: center.x + cos(angle) * outerRadius,
        y: center.y + sin(angle) * outerRadius
    )
    let ray = NSBezierPath()
    ray.move(to: start)
    ray.line(to: end)
    ray.lineWidth = rayLineWidth
    ray.lineCapStyle = .round
    NSColor.black.setStroke()
    ray.stroke()
}

// A filled pointer glyph with its tip at the exact center (the same
// point the click burst radiates from). Points are normalized to a
// unit box with the tip at the top-left (northwest corner), matching
// a classic arrow cursor's silhouette.
let cursorPoints: [(CGFloat, CGFloat)] = [
    (0.000, 1.000),
    (0.000, 0.111),
    (0.222, 0.306),
    (0.361, 0.000),
    (0.472, 0.056),
    (0.333, 0.361),
    (0.611, 0.361),
]
let cursorHeight = CGFloat(size) * 0.42
let cursorWidth = cursorHeight * 0.611
let cursorOrigin = NSPoint(x: center.x, y: center.y - cursorHeight)

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
NSColor.black.setFill()
cursorPath.fill()
cursorPath.lineWidth = CGFloat(size) * 0.014
NSColor.white.setStroke()
cursorPath.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}

let outputPath = CommandLine.arguments[1]
try png.write(to: URL(fileURLWithPath: outputPath))
