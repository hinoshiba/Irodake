import AppKit
import CoreGraphics
import XCTest
@testable import Irodake

final class DesktopGeometryTests: XCTestCase {
    @MainActor
    func testWindowSubclassInitializersDoNotTrap() throws {
        guard let screen = NSScreen.main else {
            throw XCTSkip("A WindowServer display is required for this regression test.")
        }

        let overlay = OverlayWindow(
            screen: screen,
            pixelSize: CGSize(
                width: screen.frame.width * screen.backingScaleFactor,
                height: screen.frame.height * screen.backingScaleFactor
            )
        )
        XCTAssertEqual(overlay.screenFrame, screen.frame)
        overlay.disablePresentation()
        overlay.close()

        let selector = RegionSelectionController()
        selector.begin(instruction: "Test") { _ in }
        selector.cancel()
    }

    func testLocalRectsClipsAndOffsetsAcrossScreen() {
        let screen = CGRect(x: 100, y: 50, width: 500, height: 400)
        let selections = [
            RegionSelection(
                kind: .rectangle,
                frame: CGRect(x: 50, y: 100, width: 200, height: 100),
                name: "Clipped"
            ),
            RegionSelection(
                kind: .rectangle,
                frame: CGRect(x: 800, y: 800, width: 40, height: 40),
                name: "Outside"
            ),
        ]

        XCTAssertEqual(
            DesktopGeometry.localRects(for: selections, in: screen),
            [CGRect(x: 0, y: 50, width: 150, height: 100)]
        )
    }

    func testSettingsRoundTrip() throws {
        let suite = "IrodakeTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        var settings = AppSettings()
        settings.isEnabled = true
        settings.mode = .grayFocus
        settings.frameRate = 20
        settings.selections = [
            RegionSelection(
                kind: .rectangle,
                frame: CGRect(x: 10, y: 20, width: 100, height: 80),
                name: "Fixed"
            ),
            RegionSelection(
                kind: .window,
                frame: CGRect(x: 1, y: 2, width: 300, height: 200),
                name: "Preview",
                windowID: 42
            ),
        ]
        settings.save(to: defaults)

        let loaded = AppSettings.load(from: defaults)
        XCTAssertFalse(loaded.isEnabled)
        XCTAssertEqual(loaded.mode, .grayFocus)
        XCTAssertEqual(loaded.frameRate, 20)
        XCTAssertEqual(loaded.selections.count, 1)
        XCTAssertEqual(loaded.selections.first?.kind, .rectangle)
        XCTAssertEqual(loaded.selections.first?.name, "Fixed")
    }

    func testUnionProducesNonOverlappingCoverage() {
        let rects = [
            CGRect(x: 0, y: 0, width: 10, height: 10),
            CGRect(x: 5, y: 2, width: 10, height: 6),
        ]
        let union = DesktopGeometry.nonOverlappingUnion(of: rects)

        for first in union.indices {
            for second in union.indices where second > first {
                let intersection = union[first].intersection(union[second])
                XCTAssertTrue(
                    intersection.isNull || intersection.width == 0 || intersection.height == 0
                )
            }
        }
        let area = union.reduce(0) { $0 + $1.width * $1.height }
        XCTAssertEqual(area, 130)
    }
}
