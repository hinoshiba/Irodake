import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    @Binding var section: MainSection
    @State private var showingWindowPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                masterCard
                modeSection
                quickActions
                currentSpots
            }
            .padding(30)
            .frame(maxWidth: 840, alignment: .leading)
        }
        .sheet(isPresented: $showingWindowPicker) {
            WindowPickerView()
                .environmentObject(model)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(L10n.text("色は、必要な場所だけ。", "Color only where it matters.", language: model.language))
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text(L10n.text(
                "刺激を静かにして、必要な色はすぐ取り戻せます。",
                "Quiet visual noise and bring back color whenever you need it.",
                language: model.language
            ))
            .foregroundStyle(.secondary)
        }
    }

    private var masterCard: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(model.settings.isEnabled ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.1))
                Image(systemName: model.settings.isEnabled ? "circle.lefthalf.filled" : "circle.slash")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(model.settings.isEnabled ? Color.accentColor : .secondary)
            }
            .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 5) {
                Text(model.settings.isEnabled
                     ? L10n.text("IrodakeはONです", "Irodake is on", language: model.language)
                     : L10n.text("IrodakeはOFFです", "Irodake is off", language: model.language))
                    .font(.title3.bold())
                Text(model.isPeeking
                     ? L10n.text("カラーピーク中", "Peeking at all colors", language: model.language)
                     : model.settings.mode.detail(model.language))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if model.isBusy {
                ProgressView().controlSize(.small)
            }
            Toggle("", isOn: Binding(
                get: { model.settings.isEnabled },
                set: { value in Task { await model.setEnabled(value) } }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.large)
            .disabled(model.isBusy)
            .accessibilityLabel(L10n.text("Irodakeの効果", "Irodake effect", language: model.language))
        }
        .padding(22)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    model.settings.isEnabled
                        ? Color.accentColor.opacity(0.28)
                        : Color(nsColor: .separatorColor).opacity(0.7),
                    lineWidth: 1
                )
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(L10n.text("表示モード", "Display mode", language: model.language))
            HStack(spacing: 14) {
                ForEach(FilterMode.allCases) { mode in
                    ModeCard(mode: mode, selected: model.settings.mode == mode) {
                        withAnimation(.easeOut(duration: 0.18)) { model.settings.mode = mode }
                    }
                }
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(L10n.text("スポットを追加", "Add a spot", language: model.language))
            HStack(spacing: 12) {
                QuickAction(
                    icon: "rectangle.dashed",
                    title: L10n.text("範囲を選択", "Select Region", language: model.language),
                    detail: L10n.text("ドラッグで固定", "Drag anywhere", language: model.language)
                ) { model.beginRegionSelection() }
                QuickAction(
                    icon: "macwindow",
                    title: L10n.text("ウインドウ領域", "Window Area", language: model.language),
                    detail: L10n.text("移動に追従", "Follows movement", language: model.language)
                ) { showingWindowPicker = true }
            }
        }
    }

    @ViewBuilder
    private var currentSpots: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(model.settings.mode == .colorFocus
                             ? L10n.text("カラーを残すスポット", "Color spots", language: model.language)
                             : L10n.text("グレーにするスポット", "Gray spots", language: model.language))
                Spacer()
                if !model.settings.selections.isEmpty {
                    Button(L10n.text("すべて表示", "View all", language: model.language)) {
                        section = .spots
                    }
                    .buttonStyle(.link)
                }
            }
            if model.settings.selections.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "viewfinder")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(model.settings.mode == .colorFocus
                         ? L10n.text("スポットがないため、画面全体がグレーになります。", "With no spots, the entire display becomes gray.", language: model.language)
                         : L10n.text("スポットを追加すると、その場所だけグレーになります。", "Add a spot to gray only that place.", language: model.language))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(18)
                .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
            } else {
                ForEach(model.settings.selections.prefix(3)) { selection in
                    SelectionRow(selection: selection)
                }
            }
        }
    }
}

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .tracking(0.6)
    }
}

private struct ModeCard: View {
    @EnvironmentObject private var model: AppModel
    let mode: FilterMode
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: mode.systemImage)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(selected ? Color.accentColor : .secondary)
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 3) {
                    Text(mode.title(model.language)).font(.headline)
                    Text(mode == .colorFocus
                         ? L10n.text("外側をグレー", "Gray outside", language: model.language)
                         : L10n.text("内側をグレー", "Gray inside", language: model.language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary.opacity(0.45))
            }
            .padding(17)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(selected ? Color.accentColor.opacity(0.09) : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    selected
                        ? Color.accentColor.opacity(0.55)
                        : Color(nsColor: .separatorColor).opacity(0.7),
                    lineWidth: selected ? 1.5 : 1
                )
        }
        .frame(maxWidth: .infinity)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct QuickAction: View {
    let icon: String
    let title: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "plus.circle.fill").foregroundStyle(.tint)
            }
            .padding(15)
        }
        .buttonStyle(.plain)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 13))
        .overlay { RoundedRectangle(cornerRadius: 13).stroke(.quaternary) }
        .frame(maxWidth: .infinity)
    }
}

struct SelectionRow: View {
    @EnvironmentObject private var model: AppModel
    let selection: RegionSelection

    var body: some View {
        let displayName = model.displayName(for: selection)
        HStack(spacing: 12) {
            Image(systemName: selection.systemImage)
                .foregroundStyle(.tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName).lineLimit(1)
                if selection.applicationName != nil {
                    Text(selection.isVisible == false
                         ? L10n.text("待機中", "Waiting", language: model.language)
                         : L10n.text("追従中", "Following", language: model.language))
                        .font(.caption)
                        .foregroundStyle(selection.isVisible == false ? Color.orange : Color.secondary)
                } else {
                    Text("\(Int(selection.frame.width)) × \(Int(selection.frame.height))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(role: .destructive) {
                model.removeSelection(id: selection.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .accessibilityLabel(L10n.text(
                "\(displayName) スポットを削除",
                "Remove \(displayName) spot",
                language: model.language
            ))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.quaternary.opacity(0.22), in: RoundedRectangle(cornerRadius: 11))
    }
}
