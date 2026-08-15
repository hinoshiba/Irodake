import Foundation

enum FilterMode: String, Codable, CaseIterable, Identifiable {
    case colorFocus
    case grayFocus

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .colorFocus: "circle.lefthalf.filled"
        case .grayFocus: "square.dashed.inset.filled"
        }
    }

    func title(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.colorFocus, .japanese): "カラーを残す"
        case (.colorFocus, .english): "Keep Color"
        case (.grayFocus, .japanese): "ここだけグレー"
        case (.grayFocus, .english): "Gray Selected"
        }
    }

    func detail(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.colorFocus, .japanese): "画面全体をグレーにして、選択した場所だけ色を残します"
        case (.colorFocus, .english): "Gray the display and keep selected places in color"
        case (.grayFocus, .japanese): "画面はカラーのまま、選択した場所だけグレーにします"
        case (.grayFocus, .english): "Keep the display in color and gray selected places"
        }
    }
}
