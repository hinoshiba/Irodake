import SwiftUI

struct SpotsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingWindowPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.text("スポット", "Spots", language: model.language))
                        .font(.largeTitle.bold())
                    Text(L10n.text(
                        "選んだウインドウ領域や固定範囲を管理します。",
                        "Manage tracked window areas and fixed regions.",
                        language: model.language
                    ))
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Button(L10n.text("固定範囲", "Fixed Region", language: model.language), systemImage: "rectangle.dashed") {
                        model.beginRegionSelection()
                    }
                    Button(L10n.text("ウインドウ領域", "Window Area", language: model.language), systemImage: "macwindow") {
                        showingWindowPicker = true
                    }
                } label: {
                    Label(L10n.text("追加", "Add", language: model.language), systemImage: "plus")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            if model.settings.selections.isEmpty {
                ContentUnavailableView {
                    Label(L10n.text("スポットはまだありません", "No spots yet", language: model.language), systemImage: "viewfinder")
                } description: {
                    Text(L10n.text("範囲またはウインドウ領域を追加してください。", "Add a region or tracked window area.", language: model.language))
                } actions: {
                    Button(L10n.text("範囲を選択", "Select Region", language: model.language)) {
                        model.beginRegionSelection()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(model.settings.selections) { selection in
                        SelectionRow(selection: selection)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                HStack {
                    Text(L10n.text(
                        "ウインドウ領域は移動・リサイズに追従し、アプリ終了時に破棄されます。重なった他のウインドウも矩形内では同じ効果になります。",
                        "Window areas follow movement and resizing and reset when the app quits. Overlapping windows receive the same effect inside the rectangle.",
                        language: model.language
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Spacer()
                    Button(L10n.text("すべて削除", "Remove All", language: model.language), role: .destructive) {
                        model.clearSelections()
                    }
                }
            }
        }
        .padding(30)
        .sheet(isPresented: $showingWindowPicker) {
            WindowPickerView().environmentObject(model)
        }
    }
}
