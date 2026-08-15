import Foundation

struct AppSettings: Codable, Equatable {
    var isEnabled = false
    var mode: FilterMode = .colorFocus
    var selections: [RegionSelection] = []
    var frameRate = 30
    var launchAtLogin = false
    var hasCompletedOnboarding = false
    var language = AppLanguage.systemDefault

    static let defaultsKey = "irodake.settings.v1"

    static func load(from defaults: UserDefaults = .standard) -> AppSettings {
        guard
            let data = defaults.data(forKey: defaultsKey),
            var value = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return AppSettings() }
        // CGWindowID values are only valid for the current login session and
        // can be reused. Never restore a stale tracked-window rule.
        value.selections.removeAll { $0.kind == .window }
        value.isEnabled = false
        return value
    }

    func save(to defaults: UserDefaults = .standard) {
        var value = self
        // Window IDs and titles are ephemeral and potentially sensitive.
        // Tracked window areas intentionally live only for this app session.
        value.selections.removeAll { $0.kind == .window }
        guard let data = try? JSONEncoder().encode(value) else { return }
        guard defaults.data(forKey: Self.defaultsKey) != data else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }
}
