import CoreMedia
import ScreenCaptureKit

final class DisplayCaptureSession: NSObject, SCStreamOutput, SCStreamDelegate {
    let displayID: CGDirectDisplayID
    private let renderer: MetalFrameView
    private let outputQueue: DispatchQueue
    private let stateLock = NSLock()
    private var stream: SCStream?
    private var captureIsVisible = false
    private var errorHandler: ((Error) -> Void)?
    private var visibilityHandler: ((Bool) -> Void)?
    var onError: ((Error) -> Void)? {
        get { withStateLock { errorHandler } }
        set { withStateLock { errorHandler = newValue } }
    }
    var onVisibilityChanged: ((Bool) -> Void)? {
        get { withStateLock { visibilityHandler } }
        set { withStateLock { visibilityHandler = newValue } }
    }

    init(displayID: CGDirectDisplayID, renderer: MetalFrameView) {
        self.displayID = displayID
        self.renderer = renderer
        self.outputQueue = DispatchQueue(
            label: "irodake.hinoshiba.com.capture.\(displayID)",
            qos: .userInteractive
        )
        super.init()
    }

    func start(filter: SCContentFilter, configuration: SCStreamConfiguration) async throws {
        let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: outputQueue)
        self.stream = stream
        try await stream.startCapture()
    }

    func stop() async {
        guard let stream else { return }
        prepareForStop()
        try? await stream.stopCapture()
        try? stream.removeStreamOutput(self, type: .screen)
        self.stream = nil
    }

    func prepareForStop() {
        withStateLock {
            errorHandler = nil
            visibilityHandler = nil
        }
    }

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard
            outputType == .screen,
            sampleBuffer.isValid,
            let attachments = CMSampleBufferGetSampleAttachmentsArray(
                sampleBuffer,
                createIfNecessary: false
            ) as? [[SCStreamFrameInfo: Any]],
            let statusRawValue = attachments.first?[.status] as? Int,
            let status = SCFrameStatus(rawValue: statusRawValue)
        else { return }

        switch status {
        case .complete, .started:
            guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
            reportVisibility(true)
            renderer.render(pixelBuffer: pixelBuffer)
        case .idle:
            break
        case .blank, .suspended, .stopped:
            reportVisibility(false)
        @unknown default:
            reportVisibility(false)
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        let handler = withStateLock { errorHandler }
        handler?(error)
    }

    private func reportVisibility(_ visible: Bool) {
        let handler: ((Bool) -> Void)? = withStateLock {
            guard captureIsVisible != visible else { return nil }
            captureIsVisible = visible
            return visibilityHandler
        }
        handler?(visible)
    }

    private func withStateLock<T>(_ body: () -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return body()
    }
}
