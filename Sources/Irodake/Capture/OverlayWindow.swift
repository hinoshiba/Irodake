import AppKit

@MainActor
final class OverlayWindow: NSWindow {
    let renderer: MetalFrameView
    private(set) var screenFrame: CGRect
    private var presentationEnabled = true

    init(screen: NSScreen, pixelSize: CGSize) {
        screenFrame = screen.frame
        renderer = MetalFrameView(frame: CGRect(origin: .zero, size: screen.frame.size))

        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        contentView = renderer
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        acceptsMouseMovedEvents = false
        level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue - 1)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        animationBehavior = .none
        isReleasedWhenClosed = false
        renderer.setPixelSize(pixelSize)
    }

    func setCaptureVisible(_ visible: Bool) {
        guard presentationEnabled else { return }
        if visible {
            orderFrontRegardless()
        } else {
            orderOut(nil)
        }
    }

    func prepareForCaptureDiscovery() {
        guard presentationEnabled else { return }
        orderFrontRegardless()
    }

    func disablePresentation() {
        presentationEnabled = false
        orderOut(nil)
    }

    func updateMask(mode: FilterMode, selections: [RegionSelection]) {
        renderer.updateMask(
            mode: mode,
            localRects: DesktopGeometry.localRects(for: selections, in: screenFrame)
        )
    }
}
