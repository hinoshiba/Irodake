import AppKit
import CoreGraphics

enum DesktopGeometry {
    static var primaryScreenHeight: CGFloat {
        NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.height
            ?? NSScreen.screens.first?.frame.height
            ?? 0
    }

    /// Converts ScreenCaptureKit/Quartz global coordinates (top-left origin)
    /// into AppKit global coordinates (bottom-left origin).
    static func appKitRect(fromQuartz rect: CGRect) -> CGRect {
        CGRect(
            x: rect.minX,
            y: primaryScreenHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    static func localRects(
        for selections: [RegionSelection],
        in screenFrame: CGRect
    ) -> [CGRect] {
        selections.compactMap { selection in
            guard selection.isVisible != false else { return nil }
            let intersection = selection.frame.intersection(screenFrame)
            guard !intersection.isNull, intersection.width > 1, intersection.height > 1 else {
                return nil
            }
            return CGRect(
                x: intersection.minX - screenFrame.minX,
                y: intersection.minY - screenFrame.minY,
                width: intersection.width,
                height: intersection.height
            )
        }
    }

    /// Returns a non-overlapping axis-aligned decomposition of the union.
    /// This avoids even-odd mask holes toggling back on where spots overlap.
    static func nonOverlappingUnion(of rects: [CGRect]) -> [CGRect] {
        let valid = rects.map(\.standardized).filter { !$0.isNull && $0.width > 0 && $0.height > 0 }
        let xEdges = Array(Set(valid.flatMap { [$0.minX, $0.maxX] })).sorted()
        guard xEdges.count >= 2 else { return [] }

        var result: [CGRect] = []
        for index in 0..<(xEdges.count - 1) {
            let minX = xEdges[index]
            let maxX = xEdges[index + 1]
            guard maxX > minX else { continue }

            let intervals = valid
                .filter { $0.minX < maxX && $0.maxX > minX }
                .map { ($0.minY, $0.maxY) }
                .sorted { $0.0 < $1.0 }

            var merged: [(CGFloat, CGFloat)] = []
            for interval in intervals {
                if let last = merged.last, interval.0 <= last.1 {
                    merged[merged.count - 1].1 = max(last.1, interval.1)
                } else {
                    merged.append(interval)
                }
            }

            result.append(contentsOf: merged.map { interval in
                CGRect(x: minX, y: interval.0, width: maxX - minX, height: interval.1 - interval.0)
            })
        }
        return result
    }
}
