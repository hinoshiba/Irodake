import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(model.settings.isEnabled
               ? L10n.text("IrodakeをOFF", "Turn Irodake Off", language: model.language)
               : L10n.text("IrodakeをON", "Turn Irodake On", language: model.language)) {
            model.toggleEnabled()
        }
        .keyboardShortcut("g", modifiers: [.command, .option])

        if let error = model.lastError {
            Text("⚠︎ \(error)")
            Button(L10n.text("Irodakeを開いて確認…", "Open Irodake to Review…", language: model.language)) {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
        } else if !model.permissionGranted {
            Button(L10n.text("画面収録を許可…", "Allow Screen Recording…", language: model.language)) {
                model.requestPermission()
            }
        }

        Divider()

        Menu(L10n.text("表示モード", "Display Mode", language: model.language)) {
            ForEach(FilterMode.allCases) { mode in
                Button {
                    model.settings.mode = mode
                } label: {
                    if model.settings.mode == mode {
                        Label(mode.title(model.language), systemImage: "checkmark")
                    } else {
                        Text(mode.title(model.language))
                    }
                }
            }
        }

        Button(L10n.text("範囲を選択…", "Select Region…", language: model.language)) {
            model.beginRegionSelection()
        }
        Button(L10n.text("前面ウインドウ領域を追加", "Add Front Window Area", language: model.language)) {
            Task { await model.addFrontmostWindow() }
        }

        if !model.settings.selections.isEmpty {
            Menu(L10n.text("スポット", "Spots", language: model.language)) {
                ForEach(model.settings.selections) { selection in
                    Button(role: .destructive) {
                        model.removeSelection(id: selection.id)
                    } label: {
                        Label(selection.name, systemImage: "xmark")
                    }
                }
            }
        }

        Divider()

        Text(L10n.text("⌥⌘Cを押している間だけ全カラー", "Hold ⌥⌘C to peek at all colors", language: model.language))

        Button(L10n.text("Irodakeを開く…", "Open Irodake…", language: model.language)) {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }

        Divider()
        Button(L10n.text("終了", "Quit", language: model.language)) {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
