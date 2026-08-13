import AppKit

// Renders a 1024x1024 PNG of the orange outline circle used as the
// menu bar icon, for use as the base image when building AppIcon.icns.
// Usage: swift Scripts/generate_app_icon.swift <output-png-path>

let size = 1024

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

let lineWidth = CGFloat(size) * 0.075
let inset = lineWidth / 2 + CGFloat(size) * 0.08
let circleRect = NSRect(x: inset, y: inset, width: CGFloat(size) - inset * 2, height: CGFloat(size) - inset * 2)
let path = NSBezierPath(ovalIn: circleRect)
path.lineWidth = lineWidth
NSColor.systemOrange.setStroke()
path.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to encode PNG")
}

let outputPath = CommandLine.arguments[1]
try png.write(to: URL(fileURLWithPath: outputPath))
