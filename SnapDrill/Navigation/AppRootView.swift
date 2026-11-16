import SwiftData
import SwiftUI

/// 首帧纸色占位，SwiftData 就绪后再进主界面（减轻白屏感）。
struct AppRootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var container: ModelContainer?
    @State private var bootstrap = AppBootstrap()

    var body: some View {
        ZStack {
            SnapDrillTheme.background(for: colorScheme)
                .ignoresSafeArea()

            if let container {
                RootTabView()
                    .modelContainer(container)
                    .transition(.opacity)
            } else {
                StartupView()
            }
        }
        .animation(.easeOut(duration: 0.2), value: container != nil)
        .task {
            guard container == nil else { return }
            let built = AppModelContainer.make()
            bootstrap.seedIfNeeded(context: built.mainContext)
            container = built
        }
    }
}

private struct StartupView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 44))
                .foregroundStyle(SnapDrillTheme.inkBlue.opacity(0.85))
            ProgressView()
                .tint(SnapDrillTheme.inkBlue)
        }
        .accessibilityLabel(String(localized: "Starting SnapDrill"))
    }
}

enum AppModelContainer {
    static func make() -> ModelContainer {
        let schema = Schema([
            Subject.self,
            MistakeItem.self,
            MistakeTag.self,
            CaptureDraft.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer failed: \(error)")
        }
    }
}