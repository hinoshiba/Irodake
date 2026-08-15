import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: swift Scripts/MakeIcon.swift <output-directory>\n", stderr)
    exit(1)
}

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let iconset = output.appendingPathComponent("Irodake.iconset", isDirectory: true)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let variants: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for variant in variants {
    let size = variant.pixels
    guard let bitmap = NSBitmapImageRep(
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
    ) else { fatalError("Unable to create icon bitmap") }

    bitmap.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high

    let inset = CGFloat(size) * 0.055
    let rect = CGRect(x: inset, y: inset, width: CGFloat(size) - inset * 2, height: CGFloat(size) - inset * 2)
    let background = NSBezierPath(roundedRect: rect, xRadius: CGFloat(size) * 0.22, yRadius: CGFloat(size) * 0.22)
    NSGradient(colors: [
        NSColor(calibratedWhite: 0.11, alpha: 1),
        NSColor(calibratedWhite: 0.24, alpha: 1),
    ])!.draw(in: background, angle: -70)

    NSGraphicsContext.saveGraphicsState()
    background.addClip()
    let stripeWidth = CGFloat(size) * 0.17
    let stripe = CGRect(
        x: CGFloat(size) * 0.53 - stripeWidth / 2,
        y: CGFloat(size) * 0.16,
        width: stripeWidth,
        height: CGFloat(size) * 0.68
    )
    let transform = NSAffineTransform()
    transform.translateX(by: stripe.midX, yBy: stripe.midY)
    transform.rotate(byDegrees: 7)
    transform.translateX(by: -stripe.midX, yBy: -stripe.midY)
    transform.concat()
    let slit = NSBezierPath(roundedRect: stripe, xRadius: stripeWidth * 0.34, yRadius: stripeWidth * 0.34)
    NSGradient(colorsAndLocations:
        (NSColor.systemCyan, 0.0),
        (NSColor.systemIndigo, 0.34),
        (NSColor.systemPink, 0.68),
        (NSColor.systemOrange, 1.0)
    )!.draw(in: slit, angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.14).setStroke()
    background.lineWidth = max(1, CGFloat(size) * 0.012)
    background.stroke()

    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Unable to encode icon")
    }
    try data.write(to: iconset.appendingPathComponent(variant.name))
}

print("Created \(iconset.path)")
