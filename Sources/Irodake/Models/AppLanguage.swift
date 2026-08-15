import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case japanese = "ja"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .japanese: "日本語"
        case .english: "English"
        }
    }

    static var systemDefault: AppLanguage {
        Locale.preferredLanguages.first?.hasPrefix("ja") == true ? .japanese : .english
    }
}

enum L10n {
    static func text(_ ja: String, _ en: String, language: AppLanguage) -> String {
        language == .japanese ? ja : en
    }
}
