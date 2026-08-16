import AppKit
import CoreImage
import CoreVideo
import Metal
import QuartzCore

final class MetalFrameView: NSView {
    private let metalLayer = CAMetalLayer()
    private let renderQueue = DispatchQueue(label: "irodake.hinoshiba.com.render", qos: .userInteractive)
    private let ciContext: CIContext
    private let commandQueue: MTLCommandQueue
    private let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    private let stateLock = NSLock()
    private var renderPending = false
    private var latestBuffer: CVPixelBuffer?

    override var isFlipped: Bool { false }

    override init(frame frameRect: NSRect) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue()
        else {
            fatalError("Irodake requires a Metal-capable Mac")
        }

        self.commandQueue = commandQueue
        self.ciContext = CIContext(
            mtlDevice: device,
            options: [
                .cacheIntermediates: false,
                .workingColorSpace: colorSpace,
                .outputColorSpace: colorSpace,
            ]
        )
        super.init(frame: frameRect)

        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = false
        metalLayer.maximumDrawableCount = 2
        metalLayer.presentsWithTransaction = false
        metalLayer.colorspace = colorSpace
        metalLayer.isOpaque = false
        metalLayer.backgroundColor = NSColor.clear.cgColor
        metalLayer.contentsGravity = .resize
        wantsLayer = true
        layer = metalLayer
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPixelSize(_ size: CGSize) {
        metalLayer.drawableSize = size
    }

    func render(pixelBuffer: CVPixelBuffer) {
        stateLock.lock()
        latestBuffer = pixelBuffer
        guard !renderPending else {
            stateLock.unlock()
            return
        }
        renderPending = true
        stateLock.unlock()

        renderQueue.async { [weak self] in
            self?.renderLatestFrame()
        }
    }

    private func renderLatestFrame() {
        stateLock.lock()
        guard let retainedBuffer = latestBuffer else {
            renderPending = false
            stateLock.unlock()
            return
        }
        latestBuffer = nil
        stateLock.unlock()

        autoreleasepool {
            guard
                let drawable = metalLayer.nextDrawable(),
                let commandBuffer = commandQueue.makeCommandBuffer()
            else {
                renderQueue.async { [weak self] in self?.renderLatestFrame() }
                return
            }

                let source = CIImage(cvPixelBuffer: retainedBuffer)
                let gray = source.applyingFilter(
                    "CIColorControls",
                    parameters: [
                        kCIInputSaturationKey: 0.0,
                        kCIInputContrastKey: 1.0,
                        kCIInputBrightnessKey: 0.0,
                    ]
                )
                let target = CGRect(
                    x: 0,
                    y: 0,
                    width: drawable.texture.width,
                    height: drawable.texture.height
                )
                let transform = CGAffineTransform(
                    scaleX: target.width / max(gray.extent.width, 1),
                    y: target.height / max(gray.extent.height, 1)
                )
                ciContext.render(
                    gray.transformed(by: transform),
                    to: drawable.texture,
                    commandBuffer: commandBuffer,
                    bounds: target,
                    colorSpace: colorSpace
                )
                commandBuffer.addCompletedHandler { [weak self] _ in
                    self?.renderQueue.async { [weak self] in self?.renderLatestFrame() }
                }
                commandBuffer.present(drawable)
                commandBuffer.commit()
        }
    }

    @MainActor
    func updateMask(mode: FilterMode, localRects: [CGRect]) {
        let mask = CAShapeLayer()
        mask.frame = bounds
        mask.contentsScale = window?.backingScaleFactor ?? 2
        mask.fillColor = NSColor.white.cgColor

        let path = CGMutablePath()
        switch mode {
        case .colorFocus:
            path.addRect(bounds)
            DesktopGeometry.nonOverlappingUnion(of: localRects).forEach { path.addRect($0) }
            mask.fillRule = .evenOdd
        case .grayFocus:
            localRects.forEach { path.addRoundedRect(in: $0, cornerWidth: 10, cornerHeight: 10) }
            mask.fillRule = .nonZero
        }

        mask.path = path
        metalLayer.mask = mask
    }
}
