import AppKit
import CoreMedia
import CoreVideo
import ScreenCaptureKit

@MainActor
final class CaptureManager {
    private struct ActiveDisplay {
        let window: OverlayWindow
        let session: DisplayCaptureSession
    }

    private var activeDisplays: [ActiveDisplay] = []
    private var pendingWindows: [OverlayWindow] = []
    private var operationGeneration = 0
    var onError: ((Error) -> Void)?

    var isRunning: Bool { !activeDisplays.isEmpty }

    func start(settings: AppSettings) async throws {
        await stop()
        operationGeneration += 1
        let generation = operationGeneration

        let prepared: [(displayID: CGDirectDisplayID, window: OverlayWindow)] =
            NSScreen.screens.compactMap { screen in
                guard let number = screen.deviceDescription[
                    NSDeviceDescriptionKey("NSScreenNumber")
                ] as? NSNumber else { return nil }
                let pixelSize = CGSize(
                    width: screen.frame.width * screen.backingScaleFactor,
                    height: screen.frame.height * screen.backingScaleFactor
                )
                let window = OverlayWindow(screen: screen, pixelSize: pixelSize)
                window.updateMask(mode: settings.mode, selections: settings.selections)
                return (number.uint32Value, window)
            }
        pendingWindows = prepared.map(\.window)

        do {
            // Exclude this process at the application level. Transparent overlay
            // windows are not guaranteed to appear in SCShareableContent's window
            // list, so relying on per-window discovery can create a feedback loop
            // or prevent capture from starting. Add the app's ordinary windows
            // back as exceptions so its settings UI remains visible through the
            // full-screen effect.
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: false
            )
            guard generation == operationGeneration else { throw CancellationError() }
            let overlayIDs = Set(prepared.map { CGWindowID($0.window.windowNumber) })
            let processID = ProcessInfo.processInfo.processIdentifier
            guard let ownApplication = content.applications.first(where: {
                $0.processID == processID
            }) else {
                throw CaptureError.cannotExcludeOverlays
            }
            let ordinaryAppWindows = content.windows.filter { window in
                window.owningApplication?.processID == processID
                    && !overlayIDs.contains(window.windowID)
            }
            prepared.forEach { $0.window.setCaptureVisible(false) }
            let availableDisplayIDs = Set(content.displays.map(\.displayID))
            guard
                prepared.count == NSScreen.screens.count,
                prepared.allSatisfy({ availableDisplayIDs.contains($0.displayID) })
            else {
                throw CaptureError.noDisplays
            }

            for item in prepared {
                guard let display = content.displays.first(where: { $0.displayID == item.displayID })
                else { throw CaptureError.noDisplays }
                let window = item.window

                let filter = SCContentFilter(
                    display: display,
                    excludingApplications: [ownApplication],
                    exceptingWindows: ordinaryAppWindows
                )
                let contentPixelSize = CGSize(
                    width: filter.contentRect.width * CGFloat(filter.pointPixelScale),
                    height: filter.contentRect.height * CGFloat(filter.pointPixelScale)
                )
                window.renderer.setPixelSize(contentPixelSize)

                let configuration = SCStreamConfiguration()
                configuration.width = Int(contentPixelSize.width)
                configuration.height = Int(contentPixelSize.height)
                configuration.minimumFrameInterval = CMTime(
                    value: 1,
                    timescale: CMTimeScale(max(settings.frameRate, 1))
                )
                configuration.queueDepth = 2
                configuration.pixelFormat = kCVPixelFormatType_32BGRA
                configuration.colorSpaceName = CGColorSpace.sRGB as CFString
                configuration.showsCursor = false
                configuration.capturesAudio = false
                configuration.scalesToFit = true
                configuration.preservesAspectRatio = true
                configuration.captureResolution = .best

                let session = DisplayCaptureSession(
                    displayID: display.displayID,
                    renderer: window.renderer
                )
                session.onError = { [weak self] error in
                    Task { @MainActor in self?.onError?(error) }
                }
                session.onVisibilityChanged = { [weak window] visible in
                    Task { @MainActor in
                        window?.setCaptureVisible(visible)
                    }
                }
                try await session.start(filter: filter, configuration: configuration)
                guard generation == operationGeneration else {
                    session.prepareForStop()
                    await session.stop()
                    throw CancellationError()
                }
                activeDisplays.append(ActiveDisplay(window: window, session: session))
                pendingWindows.removeAll { $0 === window }
            }

            guard !activeDisplays.isEmpty else {
                throw CaptureError.noDisplays
            }
        } catch {
            if generation == operationGeneration {
                await stop()
            }
            prepared.forEach {
                $0.window.disablePresentation()
                $0.window.close()
            }
            throw error
        }
    }

    func update(settings: AppSettings) {
        activeDisplays.forEach {
            $0.window.updateMask(mode: settings.mode, selections: settings.selections)
        }
    }

    func hideOverlays() {
        activeDisplays.forEach {
            $0.session.prepareForStop()
            $0.window.disablePresentation()
        }
        pendingWindows.forEach {
            $0.disablePresentation()
        }
    }

    func setPeekActive(_ isActive: Bool, settings: AppSettings) {
        activeDisplays.forEach {
            $0.window.updateMask(
                mode: isActive ? .grayFocus : settings.mode,
                selections: isActive ? [] : settings.selections
            )
        }
    }

    func stop() async {
        operationGeneration += 1
        let displays = activeDisplays
        let windows = pendingWindows
        activeDisplays.removeAll()
        pendingWindows.removeAll()
        // Fail open: remove every visual overlay before waiting for a capture
        // service that may be stalled during sleep, revocation, or logout.
        displays.forEach {
            $0.session.prepareForStop()
            $0.window.disablePresentation()
            $0.window.close()
        }
        windows.forEach {
            $0.disablePresentation()
            $0.close()
        }
        for display in displays {
            await display.session.stop()
        }
    }
}

enum CaptureError: LocalizedError {
    case noDisplays
    case cannotExcludeOverlays

    var errorDescription: String? {
        switch self {
        case .noDisplays: "No display is available for capture."
        case .cannotExcludeOverlays:
            "Irodake could not safely exclude its overlays from capture."
        }
    }
}
