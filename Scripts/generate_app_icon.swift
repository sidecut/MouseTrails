import AppKit

// Renders a 1024x1024 PNG of a mouse pointer with a single bold ripple
// ring around it, for use as the base image when building AppIcon.icns.
// Kept deliberately simple (one ring, no outline, no extra strokes) so
// it stays legible at menu bar / Dock sizes.
// Usage: swift Scripts/generate_app_icon.swift <output-png-path>

let size = 1024
let canvasCenter = NSPoint(x: CGFloat(size) / 2, y: CGFloat(size) / 2)

// The pointer's black silhouette extends down and to the right from
// its tip, which visually pulls the whole icon south-east. Nudge the
// shared anchor for the tip and ring north-west of the canvas center
// so the pointer reads as optically centered.
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

// A single bold ripple ring, on top of the pointer, standing in for
// the app's flash animation.
let ringRadius = CGFloat(size) * 0.38
let ringLineWidth = CGFloat(size) * 0.05
let circleRect = NSRect(
    x: anchor.x - ringRadius, y: anchor.y - ringRadius,
    width: ringRadius * 2, height: ringRadius * 2
)
let ringPath = NSBezierPath(ovalIn: circleRect)
ringPath.lineWidth = ringLineWidth
NSColor.systemOrange.setStroke()
ringPath.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}

let outputPath = CommandLine.arguments[1]
try png.write(to: URL(fileURLWithPath: outputPath))
