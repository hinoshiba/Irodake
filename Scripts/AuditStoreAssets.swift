#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

private let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
private let fileManager = FileManager.default
private let canonicalBundleIdentifier = "com.hinoshiba.irodake"
private var failures: [String] = []

private func fail(_ message: String) {
    failures.append(message)
}

private func fileURL(_ path: String) -> URL {
    root.appendingPathComponent(path)
}

private func text(at path: String) -> String? {
    do {
        return try String(contentsOf: fileURL(path), encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
        fail("Missing or unreadable text file: \(path)")
        return nil
    }
}

private let requiredFiles = [
    "app-store/app.json",
    "app-store/app-privacy.md",
    "app-store/app-review-notes.txt",
    "app-store/asset-manifest.json",
    "app-store/review-contact.template.json",
    "app-store/versions/0.1.2/ja/whats_new.txt",
    "app-store/versions/0.1.2/en-US/whats_new.txt",
    "http_dist/index.html",
    "http_dist/en/index.html",
    "http_dist/assets/site.css",
    "http_dist/assets/favicon.png",
    "http_dist/assets/og.png",
    "http_dist/assets/sample-keep-color-ja.png",
    "http_dist/assets/sample-spots-ja.png",
    "http_dist/assets/sample-inverse-ja.png",
    "http_dist/assets/sample-privacy-ja.png",
    "http_dist/assets/sample-keep-color-en.png",
    "http_dist/assets/sample-spots-en.png",
    "http_dist/assets/sample-inverse-en.png",
    "http_dist/assets/sample-privacy-en.png",
    "http_dist/robots.txt",
    "http_dist/sitemap.xml",
]

for path in requiredFiles where !fileManager.fileExists(atPath: fileURL(path).path) {
    fail("Missing required submission resource: \(path)")
}

let legacyStandalonePages = [
    "http_dist/privacy.html",
    "http_dist/en/privacy.html",
    "http_dist/support.html",
    "http_dist/en/support.html",
    "http_dist/terms.html",
    "http_dist/en/terms.html",
]
for path in legacyStandalonePages where fileManager.fileExists(atPath: fileURL(path).path) {
    fail("Content must remain on the localized index page, not in: \(path)")
}

for path in [
    "app-store/app.json",
    "app-store/asset-manifest.json",
    "app-store/review-contact.template.json",
] {
    do {
        let data = try Data(contentsOf: fileURL(path))
        _ = try JSONSerialization.jsonObject(with: data)
    } catch {
        fail("Invalid JSON in \(path): \(error.localizedDescription)")
    }
}

if let data = try? Data(contentsOf: fileURL("app-store/app.json")),
   let app = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
   app["bundleIdentifier"] as? String != canonicalBundleIdentifier {
    fail("app-store/app.json must use bundle identifier \(canonicalBundleIdentifier)")
}

let characterLimits: [(field: String, limit: Int)] = [
    ("name", 30),
    ("subtitle", 30),
    ("promotional_text", 170),
    ("description", 4_000),
]
let locales = ["ja", "en-US"]

for locale in locales {
    let directory = "app-store/metadata/\(locale)"
    for item in characterLimits {
        let path = "\(directory)/\(item.field).txt"
        if let value = text(at: path), value.count > item.limit {
            fail("\(path) exceeds \(item.limit) characters (\(value.count))")
        }
    }

    let keywordPath = "\(directory)/keywords.txt"
    if let keywords = text(at: keywordPath), keywords.utf8.count > 100 {
        fail("\(keywordPath) exceeds 100 UTF-8 bytes (\(keywords.utf8.count))")
    }

    for field in ["support_url", "marketing_url", "privacy_policy_url"] {
        let path = "\(directory)/\(field).txt"
        if let value = text(at: path), URL(string: value)?.scheme != "https" {
            fail("\(path) must contain one HTTPS URL")
        }
    }

    let whatsNewPath = "app-store/versions/0.1.2/\(locale)/whats_new.txt"
    if let value = text(at: whatsNewPath), value.count > 4_000 {
        fail("\(whatsNewPath) exceeds 4,000 characters")
    }
}

let expectedURLs: [String: String] = [
    "app-store/metadata/ja/marketing_url.txt": "https://www.hinoshiba.com/Irodake/",
    "app-store/metadata/ja/support_url.txt": "https://www.hinoshiba.com/Irodake/#support",
    "app-store/metadata/ja/privacy_policy_url.txt": "https://www.hinoshiba.com/Irodake/#privacy",
    "app-store/metadata/en-US/marketing_url.txt": "https://www.hinoshiba.com/Irodake/en/",
    "app-store/metadata/en-US/support_url.txt": "https://www.hinoshiba.com/Irodake/en/#support",
    "app-store/metadata/en-US/privacy_policy_url.txt": "https://www.hinoshiba.com/Irodake/en/#privacy",
]
for (path, expected) in expectedURLs where text(at: path) != expected {
    fail("Unexpected public URL in \(path)")
}

let allowedScreenshotSizes = [
    CGSize(width: 1280, height: 800),
    CGSize(width: 1440, height: 900),
    CGSize(width: 2560, height: 1600),
    CGSize(width: 2880, height: 1800),
]
var namesByLocale: [String: [String]] = [:]

for locale in locales {
    let directory = fileURL("app-store/screenshots/\(locale)")
    let names: [String]
    do {
        names = try fileManager.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasSuffix(".png") }
            .sorted()
    } catch {
        fail("Missing screenshot directory: app-store/screenshots/\(locale)")
        continue
    }
    namesByLocale[locale] = names
    if names.isEmpty || names.count > 10 {
        fail("\(locale) must contain 1–10 screenshots")
    }

    for name in names {
        let url = directory.appendingPathComponent(name)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            fail("Unreadable screenshot: \(url.path)")
            continue
        }
        if CGImageSourceGetType(source) as String? != UTType.png.identifier {
            fail("Screenshot is not a real PNG: \(url.path)")
        }
        guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            fail("Cannot decode screenshot: \(url.path)")
            continue
        }
        let size = CGSize(width: image.width, height: image.height)
        if !allowedScreenshotSizes.contains(size) {
            fail("Unsupported screenshot size \(image.width)x\(image.height): \(url.path)")
        }
        switch image.alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast:
            break
        default:
            fail("Screenshot must not have alpha: \(url.path)")
        }
    }
}

if let japanese = namesByLocale["ja"], let english = namesByLocale["en-US"], japanese != english {
    fail("Japanese and English screenshots must have identical filenames and order")
}

let htmlEnumerator = fileManager.enumerator(
    at: fileURL("http_dist"),
    includingPropertiesForKeys: [.isRegularFileKey],
    options: [.skipsHiddenFiles]
)
let linkPattern = try! NSRegularExpression(pattern: #"(?:href|src)="([^"]+)""#)

while let url = htmlEnumerator?.nextObject() as? URL {
    guard url.pathExtension == "html", let html = try? String(contentsOf: url, encoding: .utf8) else { continue }
    let range = NSRange(html.startIndex..<html.endIndex, in: html)
    for match in linkPattern.matches(in: html, range: range) {
        guard let valueRange = Range(match.range(at: 1), in: html) else { continue }
        var value = String(html[valueRange])
        if value.hasPrefix("#") {
            let id = String(value.dropFirst())
            if !id.isEmpty, !html.contains("id=\"\(id)\"") {
                fail("Broken page anchor in \(url.lastPathComponent): \(value)")
            }
            continue
        }
        if value.hasPrefix("mailto:") || value.contains("://") { continue }
        value = value.components(separatedBy: "#")[0]
        value = value.components(separatedBy: "?")[0]
        if value.isEmpty { continue }

        var target: URL
        if value.hasPrefix("/Irodake/") {
            target = fileURL("http_dist/\(String(value.dropFirst("/Irodake/".count)))")
        } else {
            target = URL(fileURLWithPath: value, relativeTo: url.deletingLastPathComponent()).standardizedFileURL
        }
        if value.hasSuffix("/") || target.pathExtension.isEmpty {
            target.appendPathComponent("index.html")
        }
        if !fileManager.fileExists(atPath: target.path) {
            fail("Broken local link in \(url.lastPathComponent): \(value)")
        }
    }
}

if failures.isEmpty {
    print("Store assets passed: Japanese primary, English localized, screenshots and site validated")
} else {
    for failure in failures {
        FileHandle.standardError.write(Data("error: \(failure)\n".utf8))
    }
    exit(1)
}
