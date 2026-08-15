import SwiftUI

struct WindowPickerView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selection: UInt32?
    @State private var isLoading = true

    private var candidates: [WindowCandidate] {
        guard !query.isEmpty else { return model.windowCandidates }
        return model.windowCandidates.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.applicationName.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("ウインドウ領域を選択", "Choose a Window Area", language: model.language))
                        .font(.title2.bold())
                Text(L10n.text("移動に追従する矩形です。重なった別ウインドウにも同じ効果がかかります。", "A following rectangle; overlapping windows receive the same effect.", language: model.language))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text("閉じる", "Close", language: model.language))
            }
            .padding(22)

            TextField(L10n.text("アプリ名やタイトルを検索", "Search apps and titles", language: model.language), text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 22)
                .padding(.bottom, 12)

            List(candidates, selection: $selection) { candidate in
                HStack(spacing: 12) {
                    Image(systemName: "macwindow")
                        .foregroundStyle(.tint)
                        .frame(width: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(candidate.displayName).lineLimit(1)
                        Text("\(candidate.applicationName) · \(Int(candidate.frame.width)) × \(Int(candidate.frame.height))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 5)
                .tag(candidate.id)
            }
            .overlay {
                if isLoading {
                    ProgressView(L10n.text("ウインドウを読み込み中…", "Loading windows…", language: model.language))
                } else if candidates.isEmpty {
                    if query.isEmpty {
                        ContentUnavailableView(
                            L10n.text("選択できるウインドウがありません", "No Selectable Windows", language: model.language),
                            systemImage: "macwindow.badge.exclamationmark"
                        )
                    } else {
                        ContentUnavailableView.search(text: query)
                    }
                }
            }

            HStack {
                Button(L10n.text("再読み込み", "Refresh", language: model.language)) {
                    Task { await reload() }
                }
                Spacer()
                Button(L10n.text("キャンセル", "Cancel", language: model.language)) { dismiss() }
                Button(L10n.text("追加", "Add", language: model.language)) {
                    guard let selection, let candidate = model.windowCandidates.first(where: { $0.id == selection }) else { return }
                    model.addWindow(candidate)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selection == nil)
            }
            .padding(18)
        }
        .frame(width: 620, height: 520)
        .task { await reload() }
    }

    private func reload() async {
        isLoading = true
        await model.refreshWindowCandidates()
        isLoading = false
    }
}
