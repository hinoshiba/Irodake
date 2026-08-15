import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            if model.settings.hasCompletedOnboarding {
                MainView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(nil)
        .alert(
            L10n.text("確認してください", "Please check", language: model.language),
            isPresented: Binding(
                get: { model.lastError != nil },
                set: { if !$0 { model.lastError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { model.lastError = nil }
            if !model.permissionGranted {
                Button(L10n.text("システム設定を開く", "Open System Settings", language: model.language)) {
                    model.openPermissionSettings()
                }
            }
        } message: {
            Text(model.lastError ?? "")
        }
    }
}
