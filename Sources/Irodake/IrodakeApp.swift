import AppKit
import SwiftUI

@main
struct IrodakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Irodake", id: "main") {
            RootView()
                .environmentObject(model)
                .background(WindowLevelAccessor())
                .frame(minWidth: 820, minHeight: 580)
        }
        .defaultSize(width: 960, height: 680)
        .commands {
            CommandGroup(after: .appInfo) {
                Button(
                    L10n.text(
                        model.settings.isEnabled ? "IrodakeをOFF" : "IrodakeをON",
                        model.settings.isEnabled ? "Turn Irodake Off" : "Turn Irodake On",
                        language: model.language
                    )
                ) {
                    model.toggleEnabled()
                }
                .keyboardShortcut("g", modifiers: [.command, .option])
            }
        }

        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(model)
        } label: {
            Label(
                model.settings.isEnabled ? "Irodake: ON" : "Irodake: OFF",
                systemImage: model.settings.isEnabled
                    ? "circle.lefthalf.filled"
                    : "circle.slash"
            )
        }
        .menuBarExtraStyle(.menu)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

private struct WindowLevelAccessor: NSViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { context.coordinator.attach(to: view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { context.coordinator.attach(to: nsView.window) }
    }

    final class Coordinator {
        private weak var window: NSWindow?
        private var tokens: [NSObjectProtocol] = []

        deinit {
            tokens.forEach(NotificationCenter.default.removeObserver)
        }

        func attach(to window: NSWindow?) {
            guard let window, self.window !== window else { return }
            tokens.forEach(NotificationCenter.default.removeObserver)
            tokens.removeAll()
            self.window = window
            window.collectionBehavior.insert(.fullScreenAuxiliary)
            window.titlebarAppearsTransparent = true
            updateLevel(isKey: window.isKeyWindow)

            let center = NotificationCenter.default
            tokens.append(center.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main) { [weak self] _ in
                self?.updateLevel(isKey: true)
            })
            tokens.append(center.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { [weak self] _ in
                self?.updateLevel(isKey: false)
            })
        }

        private func updateLevel(isKey: Bool) {
            window?.level = isKey
                ? NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 1)
                : .normal
        }
    }
}
