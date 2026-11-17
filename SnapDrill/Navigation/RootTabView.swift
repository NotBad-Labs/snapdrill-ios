import SwiftUI

/// PRD §8.1 底部导航
struct RootTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showCapture = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(String(localized: "Notebook"), systemImage: "books.vertical", value: .home) {
                HomeView()
            }

            Tab(String(localized: "Review"), systemImage: "rectangle.stack", value: .review) {
                ReviewHubView()
            }

            Tab(String(localized: "Settings"), systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
        .paperBackground()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CaptureFloatingButton {
                showCapture = true
            }
            .padding(.bottom, 56)
        }
        .fullScreenCover(isPresented: $showCapture) {
            CaptureFlowView(preferCameraOnAppear: true)
        }
    }
}

private enum AppTab: Hashable {
    case home
    case review
    case settings
}

private struct CaptureFloatingButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(String(localized: "Capture"), systemImage: "camera.fill")
                .font(.headline)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(SnapDrillTheme.inkBlue)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .accessibilityIdentifier("captureFab")
    }
}