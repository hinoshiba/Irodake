import AppKit
import ScreenCaptureKit
import ServiceManagement

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            settings.save()
            if captureManager.isRunning, !isPeeking {
                if settings.isEnabled,
                   settings.mode == .grayFocus,
                   !hasEffectiveGrayFocusTarget
                {
                    lastError = L10n.text(
                        "表示できるスポットがなくなったため、IrodakeをOFFにしました。",
                        "Irodake was turned off because no visible spot remains.",
                        language: language
                    )
                    Task { await setEnabled(false) }
                } else {
                    captureManager.update(settings: settings)
                }
            }
        }
    }
    @Published private(set) var permissionGranted = ScreenPermission.isGranted
    @Published private(set) var isBusy = false
    @Published private(set) var isPeeking = false
    @Published private(set) var windowCandidates: [WindowCandidate] = []
    @Published var lastError: String?

    private let captureManager = CaptureManager()
    private let selectionController = RegionSelectionController()
    private let hotKeys: HotKeyManager
    private var trackingTimer: Timer?
    private var displayRebuildTask: Task<Void, Never>?
    private var notificationTokens: [NSObjectProtocol] = []
    private var captureGeneration = 0
    private var resumeAfterSystemTransition = false

    init() {
        settings = AppSettings.load()
        hotKeys = HotKeyManager()

        captureManager.onError = { [weak self] error in
            self?.handleCaptureError(error)
        }
        hotKeys.onToggle = { [weak self] in self?.toggleEnabled() }
        hotKeys.onPeekChanged = { [weak self] active in self?.setPeekActive(active) }
        if !hotKeys.registrationSucceeded {
            lastError = L10n.text(
                "グローバルショートカットを登録できませんでした。ほかのアプリとの競合を確認してください。",
                "Global shortcuts could not be registered. Check for a conflict with another app.",
                language: language
            )
        }

        trackingTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshTrackedFrames() }
        }

        observeSystemChanges()
    }

    deinit {
        trackingTimer?.invalidate()
        displayRebuildTask?.cancel()
        notificationTokens.forEach {
            NotificationCenter.default.removeObserver($0)
            NSWorkspace.shared.notificationCenter.removeObserver($0)
        }
    }

    var language: AppLanguage { settings.language }

    func toggleEnabled() {
        Task { await setEnabled(!settings.isEnabled) }
    }

    func setEnabled(_ enabled: Bool) async {
        if !enabled {
            resumeAfterSystemTransition = false
            displayRebuildTask?.cancel()
            displayRebuildTask = nil
            captureGeneration += 1
            settings.isEnabled = false
            isPeeking = false
            captureManager.hideOverlays()
            await captureManager.stop()
            return
        }

        guard !isBusy else { return }
        captureGeneration += 1
        let generation = captureGeneration
        isBusy = true
        defer { isBusy = false }

        if enabled {
            guard settings.mode != .grayFocus || hasEffectiveGrayFocusTarget else {
                settings.isEnabled = false
                lastError = L10n.text(
                    "「ここだけグレー」を使うには、先にスポットを追加してください。",
                    "Add a spot before using Gray Selected mode.",
                    language: language
                )
                return
            }
            permissionGranted = ScreenPermission.isGranted
            if !permissionGranted {
                _ = ScreenPermission.request()
                permissionGranted = ScreenPermission.isGranted
                guard permissionGranted else {
                    settings.isEnabled = false
                    lastError = L10n.text(
                        "画面収録の許可後、もう一度ONにしてください。",
                        "After allowing Screen Recording, turn Irodake on again.",
                        language: language
                    )
                    return
                }
            }

            do {
                try await captureManager.start(settings: settings)
                guard generation == captureGeneration else {
                    await captureManager.stop()
                    return
                }
                settings.isEnabled = true
                lastError = nil
            } catch {
                guard generation == captureGeneration else { return }
                settings.isEnabled = false
                handleCaptureError(error)
            }
        }
    }

    func requestPermission() {
        _ = ScreenPermission.request()
        permissionGranted = ScreenPermission.isGranted
    }

    func openPermissionSettings() {
        ScreenPermission.openSystemSettings()
    }

    func beginRegionSelection() {
        let instruction = L10n.text(
            "ドラッグして範囲を選択  ·  Escでキャンセル",
            "Drag to select an area  ·  Esc to cancel",
            language: language
        )
        selectionController.begin(instruction: instruction) { [weak self] frame in
            guard let self, let frame else { return }
            let index = settings.selections.filter { $0.kind == .rectangle }.count + 1
            settings.selections.append(
                RegionSelection(
                    kind: .rectangle,
                    frame: frame,
                    name: L10n.text(
                        "固定範囲 \(index)",
                        "Fixed Region \(index)",
                        language: language
                    )
                )
            )
        }
    }

    func refreshWindowCandidates() async {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                true,
                onScreenWindowsOnly: true
            )
            windowCandidates = content.windows.compactMap { window in
                guard
                    window.windowLayer == 0,
                    window.owningApplication?.processID != ProcessInfo.processInfo.processIdentifier,
                    window.frame.width >= 120,
                    window.frame.height >= 80,
                    let app = window.owningApplication?.applicationName
                else { return nil }
                return WindowCandidate(
                    id: window.windowID,
                    title: window.title ?? "",
                    applicationName: app,
                    ownerPID: window.owningApplication?.processID ?? 0,
                    frame: DesktopGeometry.appKitRect(fromQuartz: window.frame)
                )
            }
            .sorted {
                ($0.applicationName.localizedCaseInsensitiveCompare($1.applicationName) == .orderedAscending)
            }
        } catch {
            handleCaptureError(error)
        }
    }

    func addWindow(_ candidate: WindowCandidate) {
        guard !settings.selections.contains(where: { $0.windowID == candidate.id }) else { return }
        settings.selections.append(
            RegionSelection(
                kind: .window,
                frame: candidate.frame,
                name: candidate.applicationName,
                applicationName: candidate.applicationName,
                ownerPID: candidate.ownerPID,
                windowID: candidate.id
            )
        )
    }

    func addFrontmostWindow() async {
        await refreshWindowCandidates()
        let frontPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let info = currentWindowInfo()
        guard let candidate = windowCandidates.first(where: { candidate in
            guard let window = info[candidate.id] else { return false }
            return (window[kCGWindowOwnerPID as String] as? pid_t) == frontPID
        }) else {
            lastError = L10n.text(
                "選択できるウインドウが見つかりませんでした。",
                "No selectable window was found.",
                language: language
            )
            return
        }
        addWindow(candidate)
    }

    func removeSelection(id: UUID) {
        settings.selections.removeAll { $0.id == id }
    }

    func clearSelections() {
        settings.selections.removeAll()
    }

    func completeOnboarding() {
        settings.hasCompletedOnboarding = true
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            settings.launchAtLogin = enabled
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func setPeekActive(_ active: Bool) {
        guard settings.isEnabled else { return }
        isPeeking = active
        captureManager.setPeekActive(active, settings: settings)
    }

    private func refreshTrackedFrames() {
        guard settings.isEnabled, settings.selections.contains(where: { $0.windowID != nil }) else { return }
        let windowIDs = settings.selections.compactMap(\.windowID)
        let info = currentWindowInfo(windowIDs: windowIDs)
        var next = settings
        var changed = false
        for index in next.selections.indices {
            guard let windowID = next.selections[index].windowID else { continue }
            guard
                let dictionary = info[windowID],
                next.selections[index].ownerPID
                    == (dictionary[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value,
                next.selections[index].applicationName
                    == dictionary[kCGWindowOwnerName as String] as? String,
                let bounds = dictionary[kCGWindowBounds as String] as? [String: CGFloat],
                let x = bounds["X"],
                let y = bounds["Y"],
                let width = bounds["Width"],
                let height = bounds["Height"]
            else {
                if next.selections[index].isVisible != false {
                    next.selections[index].isVisible = false
                    changed = true
                }
                continue
            }
            let frame = DesktopGeometry.appKitRect(
                fromQuartz: CGRect(x: x, y: y, width: width, height: height)
            )
            if next.selections[index].isVisible != true {
                next.selections[index].isVisible = true
                changed = true
            }
            if !next.selections[index].frame.approximatelyEquals(frame) {
                next.selections[index].frame = frame
                changed = true
            }
        }
        if changed { settings = next }
    }

    private func currentWindowInfo() -> [UInt32: [String: Any]] {
        guard let list = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else { return [:] }
        return Dictionary(uniqueKeysWithValues: list.compactMap { item in
            guard let number = item[kCGWindowNumber as String] as? NSNumber else { return nil }
            return (number.uint32Value, item)
        })
    }

    private func currentWindowInfo(windowIDs: [UInt32]) -> [UInt32: [String: Any]] {
        Dictionary(uniqueKeysWithValues: windowIDs.compactMap { windowID in
            guard
                let list = CGWindowListCopyWindowInfo(.optionIncludingWindow, windowID)
                    as? [[String: Any]],
                let item = list.first,
                let number = item[kCGWindowNumber as String] as? NSNumber,
                (item[kCGWindowIsOnscreen as String] as? Bool) != false
            else { return nil }
            return (number.uint32Value, item)
        })
    }

    private func observeSystemChanges() {
        let center = NotificationCenter.default
        notificationTokens.append(
            center.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.scheduleCaptureRebuild() }
            }
        )
        notificationTokens.append(
            center.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.refreshPermissionState() }
            }
        )

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        for name in [
            NSWorkspace.willSleepNotification,
            NSWorkspace.screensDidSleepNotification,
            NSWorkspace.sessionDidResignActiveNotification,
        ] {
            notificationTokens.append(
                workspaceCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    Task { @MainActor in await self?.stopForSystemTransition() }
                }
            )
        }
        for name in [
            NSWorkspace.didWakeNotification,
            NSWorkspace.screensDidWakeNotification,
            NSWorkspace.sessionDidBecomeActiveNotification,
        ] {
            notificationTokens.append(
                workspaceCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    Task { @MainActor in await self?.resumeCaptureAfterSystemTransitionIfNeeded() }
                }
            )
        }
    }

    private func scheduleCaptureRebuild() {
        displayRebuildTask?.cancel()
        displayRebuildTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                // macOS often emits several notifications for one topology
                // change. Wait for the screen list and capture service to settle.
                try await Task.sleep(for: .milliseconds(250))
                while isBusy {
                    try await Task.sleep(for: .milliseconds(50))
                }
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            displayRebuildTask = nil
            await rebuildCaptureAfterDisplayChange()
        }
    }

    private func rebuildCaptureAfterDisplayChange() async {
        guard settings.isEnabled, !isBusy else { return }
        guard settings.mode != .grayFocus || hasEffectiveGrayFocusTarget else {
            lastError = L10n.text(
                "表示できるスポットがなくなったため、IrodakeをOFFにしました。",
                "Irodake was turned off because no visible spot remains.",
                language: language
            )
            await setEnabled(false)
            return
        }
        let generation = captureGeneration
        isBusy = true
        defer { isBusy = false }
        do {
            try await captureManager.start(settings: settings)
            guard generation == captureGeneration, settings.isEnabled else {
                await captureManager.stop()
                return
            }
        } catch {
            guard generation == captureGeneration, settings.isEnabled else { return }
            handleCaptureError(error)
        }
    }

    private func stopForSystemTransition() async {
        guard settings.isEnabled || isBusy else { return }
        resumeAfterSystemTransition = true
        displayRebuildTask?.cancel()
        displayRebuildTask = nil
        captureGeneration += 1
        settings.isEnabled = false
        isPeeking = false
        captureManager.hideOverlays()
        await captureManager.stop()
    }

    private func resumeCaptureAfterSystemTransitionIfNeeded() async {
        guard resumeAfterSystemTransition, !settings.isEnabled else { return }
        while isBusy {
            do {
                try await Task.sleep(for: .milliseconds(50))
            } catch {
                return
            }
            guard resumeAfterSystemTransition, !settings.isEnabled else { return }
        }
        resumeAfterSystemTransition = false
        await setEnabled(true)
    }

    private func refreshPermissionState() {
        let granted = ScreenPermission.isGranted
        permissionGranted = granted
        guard !granted, settings.isEnabled else { return }
        lastError = L10n.text(
            "画面収録の許可が取り消されたため、IrodakeをOFFにしました。",
            "Irodake was turned off because Screen Recording permission was revoked.",
            language: language
        )
        Task { await setEnabled(false) }
    }

    private func handleCaptureError(_ error: Error) {
        displayRebuildTask?.cancel()
        displayRebuildTask = nil
        captureGeneration += 1
        resumeAfterSystemTransition = false
        if let error = error as? CaptureError {
            lastError = switch error {
            case .noDisplays:
                L10n.text(
                    "利用できるディスプレイがありません。",
                    "No display is available for capture.",
                    language: language
                )
            case .cannotExcludeOverlays:
                L10n.text(
                    "画面効果の再取り込みを安全に防止できませんでした。IrodakeをOFFにしました。",
                    "Irodake could not safely prevent its overlay from being recaptured, so it was turned off.",
                    language: language
                )
            }
        } else {
            lastError = error.localizedDescription
        }
        settings.isEnabled = false
        isPeeking = false
        captureManager.hideOverlays()
        Task { await captureManager.stop() }
    }

    private var hasEffectiveGrayFocusTarget: Bool {
        settings.selections.contains { selection in
            guard selection.isVisible != false else { return false }
            return NSScreen.screens.contains { screen in
                let intersection = screen.frame.intersection(selection.frame)
                return !intersection.isNull && intersection.width > 0 && intersection.height > 0
            }
        }
    }
}

private extension CGRect {
    func approximatelyEquals(_ other: CGRect, tolerance: CGFloat = 0.5) -> Bool {
        abs(minX - other.minX) <= tolerance
            && abs(minY - other.minY) <= tolerance
            && abs(width - other.width) <= tolerance
            && abs(height - other.height) <= tolerance
    }
}
