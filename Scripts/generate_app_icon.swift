import AppKit

// Renders a 1024x1024 PNG of a mouse pointer with a radiating
// black-and-white "click" burst and orange ripple rings around its
// tip, for use as the base image when building AppIcon.icns.
// Usage: swift Scripts/generate_app_icon.swift <output-png-path>

let size = 1024
let canvasCenter = NSPoint(x: CGFloat(size) / 2, y: CGFloat(size) / 2)

// The pointer's black silhouette extends down and to the right from
// its tip, which visually pulls the whole icon south-east. Nudge the
// shared anchor for the tip, burst, and rings north-west of the
// canvas center so the pointer reads as optically centered.
let opticalOffset = CGFloat(size) * 0.03
let anchor = NSPoint(x: canvasCenter.x - opticalOffset, y: canvasCenter.y + opticalOffset)

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
        x: anchor.x + cos(angle) * rayInnerRadius,
        y: anchor.y + sin(angle) * rayInnerRadius
    )
    let end = NSPoint(
        x: anchor.x + cos(angle) * outerRadius,
        y: anchor.y + sin(angle) * outerRadius
    )
    let ray = NSBezierPath()
    ray.move(to: start)
    ray.line(to: end)
    ray.lineWidth = rayLineWidth
    ray.lineCapStyle = .round
    NSColor.black.setStroke()
    ray.stroke()
}

// A filled pointer glyph with its tip at the shared anchor. Points are
// normalized to a unit box with the tip at the top-left (northwest
// corner), matching a classic arrow cursor's silhouette.
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
let cursorOrigin = NSPoint(x: anchor.x, y: anchor.y - cursorHeight)

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

// Rings ripple outward from the anchor, on top of the pointer and
// burst: bold and opaque near the pointer, fading and thinning as
// they expand, mirroring the app's flash animation.
struct Ring {
    let radiusFraction: CGFloat
    let lineWidthFraction: CGFloat
    let alpha: CGFloat
}
let rings = [
    Ring(radiusFraction: 0.33, lineWidthFraction: 0.040, alpha: 0.65),
    Ring(radiusFraction: 0.45, lineWidthFraction: 0.028, alpha: 0.35),
]

for ring in rings {
    let radius = CGFloat(size) * ring.radiusFraction
    let lineWidth = CGFloat(size) * ring.lineWidthFraction
    let circleRect = NSRect(
        x: anchor.x - radius, y: anchor.y - radius,
        width: radius * 2, height: radius * 2
    )
    let path = NSBezierPath(ovalIn: circleRect)
    path.lineWidth = lineWidth
    NSColor.systemOrange.withAlphaComponent(ring.alpha).setStroke()
    path.stroke()
}

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}

let outputPath = CommandLine.arguments[1]
try png.write(to: URL(fileURLWithPath: outputPath))
