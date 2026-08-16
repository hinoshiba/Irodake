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
        bestMatch(preferredLanguages: Locale.preferredLanguages)
    }

    static func bestMatch(preferredLanguages: [String]) -> AppLanguage {
        for identifier in preferredLanguages {
            if identifier.hasPrefix("ja") { return .japanese }
            if identifier.hasPrefix("en") { return .english }
        }
        return .japanese
    }
}

enum L10n {
    static func text(_ ja: String, _ en: String, language: AppLanguage) -> String {
        language == .japanese ? ja : en
    }
}
