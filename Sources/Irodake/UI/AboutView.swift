import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            BrandMark(size: 82)
            VStack(spacing: 5) {
                Text("Irodake").font(.largeTitle.bold())
                Text(L10n.text(
                    "バージョン \(version)",
                    "Version \(version)",
                    language: model.language
                ))
                .foregroundStyle(.secondary)
            }
            Text(L10n.text("色は、必要な場所だけ。", "Color only where it matters.", language: model.language))
                .font(.title3.weight(.medium))
            Text(L10n.text(
                "オープンソースの、プライベートなmacOS画面ユーティリティ。\n外部依存・テレメトリ・広告はありません。",
                "An open-source, private macOS display utility.\nNo external dependencies, telemetry, or ads.",
                language: model.language
            ))
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Link(destination: URL(string: "https://github.com/hinoshiba/Irodake")!) {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://github.com/hinoshiba/Irodake/blob/main/LICENSE")!) {
                    Label("MIT License", systemImage: "doc.text")
                }
                Link(destination: privacyURL) {
                    Label(L10n.text("プライバシー", "Privacy", language: model.language), systemImage: "hand.raised")
                }
                Link(destination: URL(string: "https://github.com/hinoshiba/Irodake/security")!) {
                    Label(L10n.text("セキュリティ", "Security", language: model.language), systemImage: "lock.shield")
                }
            }
            .buttonStyle(.bordered)
            Spacer()
            Text("© 2026 hinoshiba")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.2"
    }

    private var privacyURL: URL {
        let path = model.language == .japanese ? "#privacy" : "en/#privacy"
        return URL(string: "https://irodake.hinoshiba.com/\(path)")!
    }
}
