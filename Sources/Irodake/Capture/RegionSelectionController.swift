import AppKit

@MainActor
final class RegionSelectionController {
    private var panels: [SelectionPanel] = []
    private var completion: ((CGRect?) -> Void)?

    func begin(instruction: String, completion: @escaping (CGRect?) -> Void) {
        cancel()
        self.completion = completion

        panels = NSScreen.screens.map { screen in
            let panel = SelectionPanel(screen: screen, instruction: instruction)
            panel.onSelection = { [weak self] frame in self?.finish(frame) }
            panel.onCancel = { [weak self] in self?.finish(nil) }
            panel.orderFrontRegardless()
            return panel
        }
        panels.first?.makeKey()
        NSCursor.crosshair.push()
    }

    func cancel() {
        guard !panels.isEmpty || completion != nil else { return }
        finish(nil)
    }

    private func finish(_ frame: CGRect?) {
        panels.forEach { $0.close() }
        panels.removeAll()
        NSCursor.pop()
        let callback = completion
        completion = nil
        callback?(frame)
    }
}

@MainActor
private final class SelectionPanel: NSPanel {
    var onSelection: ((CGRect) -> Void)? {
        didSet { selectionView.onSelection = onSelection }
    }
    var onCancel: (() -> Void)? {
        didSet { selectionView.onCancel = onCancel }
    }

    private let selectionView: SelectionCanvasView

    init(screen: NSScreen, instruction: String) {
        selectionView = SelectionCanvasView(
            frame: CGRect(origin: .zero, size: screen.frame.size),
            instruction: instruction
        )
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        contentView = selectionView
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        becomesKeyOnlyIfNeeded = false
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}

@MainActor
private final class SelectionCanvasView: NSView {
    var onSelection: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?
    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?
    private let label: NSTextField

    init(frame frameRect: NSRect, instruction: String) {
        label = NSTextField(labelWithString: instruction)
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.32).cgColor

        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white
        label.alignment = .center
        label.wantsLayer = true
        label.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.72).cgColor
        label.layer?.cornerRadius = 13
        label.sizeToFit()
        label.frame.size.width += 36
        label.frame.size.height = 40
        addSubview(label)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        label.frame.origin = CGPoint(
            x: (bounds.width - label.frame.width) / 2,
            y: bounds.height - label.frame.height - 44
        )
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        startPoint = point
        currentPoint = point
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        guard let rect = selectionRect, rect.width >= 24, rect.height >= 24 else {
            startPoint = nil
            currentPoint = nil
            needsDisplay = true
            return
        }
        let global = window?.convertToScreen(rect) ?? rect
        onSelection?(global)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let rect = selectionRect else { return }

        NSColor.clear.setFill()
        rect.fill(using: .copy)

        let border = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)
        border.lineWidth = 3
        NSColor.white.setStroke()
        border.stroke()

        let sizeText = "\(Int(rect.width)) × \(Int(rect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.7),
        ]
        sizeText.draw(at: CGPoint(x: rect.minX + 8, y: rect.minY + 8), withAttributes: attributes)
    }

    private var selectionRect: CGRect? {
        guard let startPoint, let currentPoint else { return nil }
        return CGRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
    }
}
