import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @State private var step = 0
    @State private var reveal: CGFloat = 0.62
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                BrandMark(size: 32)
                Text("Irodake")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text("\(step + 1) / 3")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(24)

            Group {
                switch step {
                case 0: valueStep
                case 1: permissionStep
                default: readyStep
                }
            }
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .trailing)))

            HStack {
                if step > 0 {
                    Button(L10n.text("戻る", "Back", language: model.language)) {
                        withAnimation { step -= 1 }
                    }
                }
                Spacer()
                Button {
                    if step < 2 {
                        withAnimation { step += 1 }
                    } else {
                        Task {
                            await model.setEnabled(true)
                            if model.settings.isEnabled {
                                model.completeOnboarding()
                            }
                        }
                    }
                } label: {
                    Text(step < 2
                         ? L10n.text("続ける", "Continue", language: model.language)
                         : L10n.text("Irodakeをはじめる", "Start Irodake", language: model.language))
                        .frame(minWidth: 110)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var valueStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(L10n.text("色は、必要な場所だけ。", "Color only where it matters.", language: model.language))
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text(L10n.text(
                "Mac全体を静かなグレーに。\n必要な場所だけ、いつでもカラーに戻せます。",
                "Make your Mac quietly grayscale.\nKeep color exactly where you need it.",
                language: model.language
            ))
            .font(.title3)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    demoScene(saturated: false)
                    demoScene(saturated: true)
                        .mask(alignment: .leading) {
                            Rectangle().frame(width: geometry.size.width * reveal)
                        }
                    Rectangle()
                        .fill(.white)
                        .frame(width: 2)
                        .offset(x: geometry.size.width * reveal)
                        .shadow(color: .black.opacity(0.4), radius: 5)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.quaternary)
                }
            }
            .frame(maxWidth: 600, maxHeight: 260)

            Slider(value: $reveal, in: 0.12...0.88)
                .frame(width: 280)
                .accessibilityLabel(L10n.text("カラーデモ", "Color demo", language: model.language))
            Spacer()
        }
        .padding(.horizontal, 48)
    }

    private func demoScene(saturated: Bool) -> some View {
        ZStack {
            LinearGradient(
                colors: saturated
                    ? [.blue.opacity(0.9), .purple.opacity(0.85), .orange.opacity(0.8)]
                    : [.gray.opacity(0.8), .gray.opacity(0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            HStack(spacing: 18) {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.82))
                        .frame(width: 118, height: CGFloat(90 + index * 34))
                        .overlay(alignment: .topLeading) {
                            Circle()
                                .fill(saturated ? [Color.cyan, .pink, .orange][index] : .gray)
                                .frame(width: 18, height: 18)
                                .padding(12)
                        }
                }
            }
        }
    }

    private var permissionStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "rectangle.inset.filled.and.person.filled")
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(.tint)
            Text(L10n.text("画面収録の許可について", "About Screen Recording access", language: model.language))
                .font(.title.bold())
            Text(L10n.text(
                "画面フレームをメモリ上でリアルタイム処理します。\n動画ファイルへ保存せず、外部送信もしません。",
                "Screen frames are processed live in memory.\nThey are never saved to a recording or sent off-device.",
                language: model.language
            ))
            .font(.title3)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            HStack(spacing: 18) {
                PrivacyPill(icon: "internaldrive", text: L10n.text("保存しない", "Never saved", language: model.language))
                PrivacyPill(icon: "network.slash", text: L10n.text("送信しない", "Never sent", language: model.language))
                PrivacyPill(icon: "eye.slash", text: L10n.text("分析しない", "No analytics", language: model.language))
            }
            Button(model.permissionGranted
                   ? L10n.text("許可済み", "Access granted", language: model.language)
                   : L10n.text("画面収録を許可", "Allow Screen Recording", language: model.language)) {
                model.requestPermission()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(model.permissionGranted)
            Spacer()
        }
        .padding(.horizontal, 48)
    }

    private var readyStep: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
            Text(L10n.text("いつでも、1秒で切り替え。", "Switch anytime, in a second.", language: model.language))
                .font(.title.bold())
            VStack(spacing: 12) {
                ShortcutRow(keys: "⌥⌘G", text: L10n.text("Irodakeを一括ON / OFF", "Turn Irodake on or off", language: model.language))
                ShortcutRow(keys: "⌥⌘C", text: L10n.text("押している間だけ全カラー", "Hold to peek at all colors", language: model.language))
            }
            .frame(maxWidth: 480)
            Text(L10n.text(
                "メニューバーからも、同じ操作をいつでも使えます。",
                "The same controls are always available from the menu bar.",
                language: model.language
            ))
            .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 48)
    }
}

private struct PrivacyPill: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.callout.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.quaternary.opacity(0.45), in: Capsule())
    }
}

private struct ShortcutRow: View {
    let keys: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Text(keys)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .frame(width: 86)
                .padding(.vertical, 10)
                .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
            Text(text)
                .font(.body.weight(.medium))
            Spacer()
        }
    }
}
