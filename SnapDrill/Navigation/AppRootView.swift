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
        .animation(.easeOut(duration: 0.25), value: container != nil)
        .task {
            await prepareStore()
        }
    }

  @MainActor
    private func prepareStore() async {
        guard container == nil else { return }
        let started = ContinuousClock.now
        let built = AppModelContainer.make()
        bootstrap.seedIfNeeded(context: built.mainContext)

        // 避免加载过快时启动页一闪不见；也避免体感「只有白屏」
        let minimumSplash = Duration.milliseconds(500)
        let elapsed = started.duration(to: .now)
        let remaining = minimumSplash - elapsed
        if remaining > .zero {
            try? await Task.sleep(for: remaining)
        }
        container = built
    }
}

private struct StartupView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 52))
                .foregroundStyle(SnapDrillTheme.inkBlue)
            Text("SnapDrill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(SnapDrillTheme.inkBlack)
            ProgressView()
                .tint(SnapDrillTheme.inkBlue)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
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