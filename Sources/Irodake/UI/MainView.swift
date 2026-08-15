import SwiftUI

enum MainSection: String, CaseIterable, Identifiable {
    case dashboard
    case spots
    case settings
    case about

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.dashboard, .japanese): "ホーム"
        case (.dashboard, .english): "Home"
        case (.spots, .japanese): "スポット"
        case (.spots, .english): "Spots"
        case (.settings, .japanese): "設定"
        case (.settings, .english): "Settings"
        case (.about, .japanese): "このアプリについて"
        case (.about, .english): "About"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "circle.grid.2x2.fill"
        case .spots: "viewfinder"
        case .settings: "gearshape.fill"
        case .about: "info.circle.fill"
        }
    }
}

struct MainView: View {
    @EnvironmentObject private var model: AppModel
    @State private var section: MainSection = .dashboard

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                HStack(spacing: 11) {
                    BrandMark(size: 34)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Irodake")
                            .font(.headline)
                        Text(model.settings.isEnabled
                             ? L10n.text("効果はONです", "Effect is on", language: model.language)
                             : L10n.text("効果はOFFです", "Effect is off", language: model.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)

                List(MainSection.allCases, selection: $section) { item in
                    Label(item.title(model.language), systemImage: item.icon)
                        .tag(item)
                }
                .listStyle(.sidebar)

                HStack {
                    Circle()
                        .fill(model.settings.isEnabled ? Color.green : Color.secondary.opacity(0.5))
                        .frame(width: 8, height: 8)
                    Text(model.settings.isEnabled ? "ON" : "OFF")
                        .font(.caption.bold())
                    Spacer()
                    Text("⌥⌘G")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 240)
        } detail: {
            Group {
                switch section {
                case .dashboard: DashboardView(section: $section)
                case .spots: SpotsView()
                case .settings: SettingsView()
                case .about: AboutView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .navigationSplitViewStyle(.balanced)
    }
}
