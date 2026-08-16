#!/usr/bin/env swift

import AppKit
import Foundation

private struct ScreenshotSpec {
    let sourceName: String
    let outputName: String
    let kicker: String
    let title: String
    let detail: String
}

private struct LocaleSpec {
    let code: String
    let localeLabel: String
    let screenshots: [ScreenshotSpec]
}

private let locales = [
    LocaleSpec(
        code: "ja",
        localeLabel: "macOS 14+ · 日本語",
        screenshots: [
            ScreenshotSpec(
                sourceName: "01-dashboard.png",
                outputName: "01-keep-color.png",
                kicker: "01 — KEEP COLOR",
                title: "色は、\n必要な場所だけ。",
                detail: "画面全体をグレーに。\n選んだ場所はカラーのまま。"
            ),
            ScreenshotSpec(
                sourceName: "02-spots.png",
                outputName: "02-spots.png",
                kicker: "02 — SPOTS",
                title: "範囲でも、\nウインドウでも。",
                detail: "固定範囲とウインドウ領域を\nひとつの画面で管理。"
            ),
            ScreenshotSpec(
                sourceName: "04-inverse.png",
                outputName: "03-inverse.png",
                kicker: "03 — INVERSE",
                title: "逆向きにも、\nすぐ切り替え。",
                detail: "画面はカラーのまま、\n選んだ場所だけグレーに。"
            ),
            ScreenshotSpec(
                sourceName: "03-settings.png",
                outputName: "04-privacy.png",
                kicker: "04 — PRIVATE BY DESIGN",
                title: "保存しない。\n送信しない。",
                detail: "画面はMacの中だけで処理。\nアカウントも分析SDKもありません。"
            ),
        ]
    ),
    LocaleSpec(
        code: "en-US",
        localeLabel: "macOS 14+ · English",
        screenshots: [
            ScreenshotSpec(
                sourceName: "01-dashboard.png",
                outputName: "01-keep-color.png",
                kicker: "01 — KEEP COLOR",
                title: "Color only\nwhere it matters.",
                detail: "Gray the display.\nKeep chosen places in color."
            ),
            ScreenshotSpec(
                sourceName: "02-spots.png",
                outputName: "02-spots.png",
                kicker: "02 — SPOTS",
                title: "By region.\nOr by window.",
                detail: "Manage fixed and tracked areas\nfrom one quiet workspace."
            ),
            ScreenshotSpec(
                sourceName: "04-inverse.png",
                outputName: "03-inverse.png",
                kicker: "03 — INVERSE",
                title: "Flip the effect\nin a second.",
                detail: "Keep the display in color.\nGray only the places you choose."
            ),
            ScreenshotSpec(
                sourceName: "03-settings.png",
                outputName: "04-privacy.png",
                kicker: "04 — PRIVATE BY DESIGN",
                title: "Never saved.\nNever sent.",
                detail: "Processed only on your Mac.\nNo account. No analytics SDK."
            ),
        ]
    ),
]

private let canvasSize = NSSize(width: 2880, height: 1800)
private let outputPixelSize = NSSize(width: 1440, height: 900)
private let sourceCrop = NSEdgeInsets(top: 0, left: 0, bottom: 32, right: 32)

private func textAttributes(
    size: CGFloat,
    weight: NSFont.Weight,
    color: NSColor,
    lineHeight: CGFloat? = nil
) -> [NSAttributedString.Key: Any] {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byWordWrapping
    if let lineHeight {
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
    }
    return [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph,
    ]
}

private func drawGlow(center: NSPoint, radius: CGFloat, colors: [NSColor]) {
    guard let gradient = NSGradient(colors: colors) else { return }
    gradient.draw(
        fromCenter: center,
        radius: 0,
        toCenter: center,
        radius: radius,
        options: [.drawsBeforeStartingLocation]
    )
}

private func render(_ spec: ScreenshotSpec, locale: LocaleSpec, root: URL) throws {
    let sourceURL = root
        .appendingPathComponent("app-store/screenshots/source")
        .appendingPathComponent(locale.code)
        .appendingPathComponent(spec.sourceName)
    let outputDirectory = root
        .appendingPathComponent("app-store/screenshots")
        .appendingPathComponent(locale.code)
    let outputURL = outputDirectory.appendingPathComponent(spec.outputName)

    guard let sourceImage = NSImage(contentsOf: sourceURL) else {
        throw NSError(
            domain: "MakeStoreScreenshots",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Missing or invalid source image: \(sourceURL.path)"]
        )
    }

    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let bitmapContext = CGContext(
        data: nil,
        width: Int(outputPixelSize.width),
        height: Int(outputPixelSize.height),
        bitsPerComponent: 8,
        bytesPerRow: Int(outputPixelSize.width) * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else {
        throw NSError(domain: "MakeStoreScreenshots", code: 2)
    }
    let context = NSGraphicsContext(cgContext: bitmapContext, flipped: false)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    bitmapContext.scaleBy(
        x: outputPixelSize.width / canvasSize.width,
        y: outputPixelSize.height / canvasSize.height
    )

    NSColor(calibratedRed: 0.045, green: 0.049, blue: 0.063, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()

    drawGlow(
        center: NSPoint(x: 2620, y: 1570),
        radius: 920,
        colors: [
            NSColor(calibratedRed: 0.27, green: 0.84, blue: 1, alpha: 0.28),
            NSColor(calibratedRed: 0.42, green: 0.39, blue: 1, alpha: 0.12),
            NSColor.clear,
        ]
    )
    drawGlow(
        center: NSPoint(x: 570, y: 80),
        radius: 740,
        colors: [
            NSColor(calibratedRed: 0.96, green: 0.30, blue: 0.64, alpha: 0.18),
            NSColor(calibratedRed: 1, green: 0.60, blue: 0.27, alpha: 0.08),
            NSColor.clear,
        ]
    )

    let stripeRect = NSRect(x: 184, y: 1545, width: 14, height: 105)
    let stripePath = NSBezierPath(roundedRect: stripeRect, xRadius: 7, yRadius: 7)
    if let stripeGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.27, green: 0.85, blue: 1, alpha: 1),
        NSColor(calibratedRed: 0.96, green: 0.31, blue: 0.65, alpha: 1),
        NSColor(calibratedRed: 1, green: 0.61, blue: 0.28, alpha: 1),
    ]) {
        stripeGradient.draw(in: stripePath, angle: -90)
    }

    ("Irodake" as NSString).draw(
        in: NSRect(x: 230, y: 1570, width: 560, height: 80),
        withAttributes: textAttributes(size: 54, weight: .bold, color: .white)
    )
    (spec.kicker as NSString).draw(
        in: NSRect(x: 184, y: 1410, width: 610, height: 50),
        withAttributes: textAttributes(
            size: 24,
            weight: .semibold,
            color: NSColor(calibratedWhite: 0.66, alpha: 1)
        )
    )
    (spec.title as NSString).draw(
        in: NSRect(x: 176, y: 910, width: 700, height: 420),
        withAttributes: textAttributes(size: 98, weight: .bold, color: .white, lineHeight: 116)
    )
    (spec.detail as NSString).draw(
        in: NSRect(x: 184, y: 640, width: 650, height: 190),
        withAttributes: textAttributes(
            size: 38,
            weight: .regular,
            color: NSColor(calibratedWhite: 0.72, alpha: 1),
            lineHeight: 58
        )
    )

    let badgeRect = NSRect(x: 184, y: 250, width: 420, height: 74)
    NSColor(calibratedWhite: 1, alpha: 0.07).setFill()
    NSBezierPath(roundedRect: badgeRect, xRadius: 37, yRadius: 37).fill()
    NSColor(calibratedWhite: 1, alpha: 0.15).setStroke()
    let badgeBorder = NSBezierPath(roundedRect: badgeRect, xRadius: 37, yRadius: 37)
    badgeBorder.lineWidth = 2
    badgeBorder.stroke()
    (locale.localeLabel as NSString).draw(
        in: NSRect(x: 220, y: 270, width: 360, height: 38),
        withAttributes: textAttributes(
            size: 25,
            weight: .medium,
            color: NSColor(calibratedWhite: 0.88, alpha: 1)
        )
    )

    let cardRect = NSRect(x: 900, y: 190, width: 1800, height: 1290)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.58)
    shadow.shadowBlurRadius = 70
    shadow.shadowOffset = NSSize(width: 0, height: -24)
    shadow.set()
    NSColor(calibratedWhite: 1, alpha: 0.09).setFill()
    NSBezierPath(roundedRect: cardRect, xRadius: 38, yRadius: 38).fill()
    NSShadow().set()

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: cardRect, xRadius: 38, yRadius: 38).addClip()
    let sourceRect = NSRect(
        x: sourceCrop.left,
        y: sourceCrop.bottom,
        width: sourceImage.size.width - sourceCrop.left - sourceCrop.right,
        height: sourceImage.size.height - sourceCrop.top - sourceCrop.bottom
    )
    sourceImage.draw(
        in: cardRect,
        from: sourceRect,
        operation: .sourceOver,
        fraction: 1,
        respectFlipped: true,
        hints: [.interpolation: NSImageInterpolation.high]
    )
    NSGraphicsContext.restoreGraphicsState()

    NSColor(calibratedWhite: 1, alpha: 0.18).setStroke()
    let border = NSBezierPath(roundedRect: cardRect, xRadius: 38, yRadius: 38)
    border.lineWidth = 2
    border.stroke()

    NSGraphicsContext.restoreGraphicsState()

    guard let image = bitmapContext.makeImage() else {
        throw NSError(domain: "MakeStoreScreenshots", code: 3)
    }
    let bitmap = NSBitmapImageRep(cgImage: image)
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "MakeStoreScreenshots", code: 4)
    }
    try png.write(to: outputURL, options: .atomic)
    print("Wrote \(outputURL.path)")
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
do {
    for locale in locales {
        for screenshot in locale.screenshots {
            try render(screenshot, locale: locale, root: root)
        }
    }
} catch {
    FileHandle.standardError.write(Data("error: \(error.localizedDescription)\n".utf8))
    exit(1)
}
