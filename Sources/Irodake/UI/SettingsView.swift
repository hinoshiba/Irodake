import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Section {
                Picker(L10n.text("表示言語", "Language", language: model.language), selection: $model.settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                Toggle(
                    L10n.text("ログイン時に開く", "Open at Login", language: model.language),
                    isOn: Binding(
                        get: { model.settings.launchAtLogin },
                        set: { model.setLaunchAtLogin($0) }
                    )
                )
            } header: {
                Text(L10n.text("一般", "General", language: model.language))
            }

            Section {
                Picker(L10n.text("フレームレート", "Frame Rate", language: model.language), selection: $model.settings.frameRate) {
                    Text(L10n.text("省電力 · 20 fps", "Energy Saver · 20 fps", language: model.language)).tag(20)
                    Text(L10n.text("バランス · 30 fps", "Balanced · 30 fps", language: model.language)).tag(30)
                    Text(L10n.text("なめらか · 60 fps", "Smooth · 60 fps", language: model.language)).tag(60)
                }
                Text(L10n.text(
                    "変更は次回ON時に反映されます。高解像度・複数画面では30 fpsを推奨します。",
                    "Changes apply the next time Irodake turns on. 30 fps is recommended for high-resolution or multiple displays.",
                    language: model.language
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            } header: {
                Text(L10n.text("パフォーマンス", "Performance", language: model.language))
            }

            Section {
                HStack {
                    Label(
                        model.permissionGranted
                            ? L10n.text("画面収録: 許可済み", "Screen Recording: Allowed", language: model.language)
                            : L10n.text("画面収録: 未許可", "Screen Recording: Not Allowed", language: model.language),
                        systemImage: model.permissionGranted ? "checkmark.shield.fill" : "exclamationmark.shield.fill"
                    )
                    .foregroundStyle(model.permissionGranted ? Color.green : Color.orange)
                    Spacer()
                    Button(L10n.text("システム設定", "System Settings", language: model.language)) {
                        model.openPermissionSettings()
                    }
                }
                Text(L10n.text(
                    "画面フレームをメモリ上でリアルタイム変換し、動画ファイルへの保存・通信・分析は行いません。",
                    "Screen frames are transformed live in memory, never saved to a recording, transmitted, or analyzed.",
                    language: model.language
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            } header: {
                Text(L10n.text("プライバシー", "Privacy", language: model.language))
            }

            Section {
                LabeledContent(L10n.text("一括ON / OFF", "Master On / Off", language: model.language), value: "⌥⌘G")
                LabeledContent(L10n.text("押している間だけ全カラー", "Hold to Peek Color", language: model.language), value: "⌥⌘C")
            } header: {
                Text(L10n.text("ショートカット", "Shortcuts", language: model.language))
            }
        }
        .formStyle(.grouped)
        .navigationTitle(L10n.text("設定", "Settings", language: model.language))
    }
}
