import Combine
import CoreData
import SwiftData
import SwiftUI

/// Root shell implementing PRD §8.1 navigation with a pure native Liquid Glass tab bar (Notebook | Review | Settings).
/// Capture entry points live in each screen's toolbar / empty state (Apple Notes-style), never floating over the tab bar.
struct RootTabView: View {
    let launchArgs: AppLaunchArguments

    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var environment

    @Query(sort: \MistakeItem.createdAt, order: .reverse) private var allMistakes: [MistakeItem]

    @State private var selectedTab: SnapDrillTab = .home
    @State private var showingCaptureFlow: Bool = false
    @State private var resumeSessionForCapture: CaptureSession?
    @State private var captureStartMode: CaptureStartMode = .cameraDefault
    @State private var capturePreferredSubjectID: UUID?
    private let quickActionRouter = QuickActionRouter.shared

    #if DEBUG
    // Optional debug inspection deep-links (compiled out of Release builds)
    @State private var debugInspectMistake: MistakeItem?
    @State private var debugInspectEraserItem: MistakeItem?
    @State private var debugPDFItems: [MistakeItem]?
    @State private var debugShowPaywall: Bool = false
    @State private var debugReviewItems: [MistakeItem]?
    #endif
    @State private var hasRunStartup: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Notebook", systemImage: "books.vertical.fill", value: SnapDrillTab.home) {
                HomeView()
            }

            Tab("Review", systemImage: "rectangle.stack.fill", value: SnapDrillTab.review) {
                ReviewHubView()
            }

            Tab("Settings", systemImage: "gearshape.fill", value: SnapDrillTab.settings) {
                SettingsView()
            }
        }
        .tint(SnapDrillTheme.inkBlue)
        .tabBarMinimizeBehavior(.onScrollDown)
        .task {
            await performStartup()
        }
        .fullScreenCover(isPresented: $showingCaptureFlow) {
            CaptureFlowView(
                initialSession: resumeSessionForCapture,
                startMode: captureStartMode,
                preferredSubjectID: capturePreferredSubjectID
            ) {
                showingCaptureFlow = false
                resumeSessionForCapture = nil
                capturePreferredSubjectID = nil
                environment.isCaptureFlowActive = false
                Task { await environment.checkForRecoverableDraft() }
            }
        }
        .onChange(of: showingCaptureFlow) { _, isShowing in
            environment.isCaptureFlowActive = isShowing
        }
        .onChange(of: environment.captureRequest) { _, request in
            guard let request else { return }
            environment.captureRequest = nil
            guard !showingCaptureFlow else { return }
            openCapture(request)
        }
        .onChange(of: quickActionRouter.pendingAction) { _, _ in
            handlePendingQuickAction()
        }
        .onReceive(
            NotificationCenter.default
                .publisher(for: .NSPersistentStoreRemoteChange)
                .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
        ) { _ in
            SubjectCatalog.deduplicateExisting(in: modelContext)
        }
        #if DEBUG
        .sheet(item: $debugInspectMistake) { mistake in
            NavigationStack {
                MistakeDetailView(mistake: mistake)
            }
        }
        .fullScreenCover(item: $debugInspectEraserItem) { mistake in
            if let imgData = mistake.resolvedCleanedImageData(imageStore: environment.imageStore),
               let image = UIImage(data: imgData),
               let origData = mistake.resolvedOriginalImageData(imageStore: environment.imageStore),
               let orig = UIImage(data: origData) {
                HandwritingEraserView(initialImage: image, originalReferenceImage: orig) { edited in
                    try? environment.saveService.saveManualCleanedImage(edited, for: mistake, in: modelContext)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { debugPDFItems != nil },
            set: { if !$0 { debugPDFItems = nil } }
        )) {
            if let items = debugPDFItems {
                PDFExportPreviewView(
                    mistakes: items,
                    defaultTitle: PDFExportOptions.defaultTitle(subjectName: items.first?.subject?.name)
                )
            }
        }
        .sheet(isPresented: $debugShowPaywall) {
            PaywallView()
        }
        .fullScreenCover(isPresented: Binding(
            get: { debugReviewItems != nil },
            set: { if !$0 { debugReviewItems = nil } }
        )) {
            if let items = debugReviewItems {
                ReviewSessionView(mistakes: items) {
                    debugReviewItems = nil
                }
            }
        }
        #endif
    }

    // MARK: - Actions & Startup

    private func openCapture(_ request: CaptureRequest) {
        resumeSessionForCapture = request.resumeSession
        captureStartMode = request.mode
        capturePreferredSubjectID = request.preferredSubjectID
        environment.recoverableDraft = nil
        showingCaptureFlow = true
    }

    private func handlePendingQuickAction() {
        guard let action = quickActionRouter.consume() else { return }
        switch action {
        case .capture:
            guard !showingCaptureFlow else { return }
            openCapture(CaptureRequest(mode: .cameraDefault, preferredSubjectID: nil, resumeSession: nil))
        case .review:
            selectedTab = .review
        }
    }

    private func performStartup() async {
        guard !hasRunStartup else { return }
        hasRunStartup = true

        SubjectCatalog.ensureSeeded(in: modelContext)
        selectedTab = launchArgs.initialTab
        await environment.checkForRecoverableDraft()
        handlePendingQuickAction()

        #if DEBUG
        if launchArgs.seedDemoIfEmpty && allMistakes.isEmpty {
            try? await DemoNotebookSeeder.populateDemoMistakes(
                in: modelContext,
                imageStore: environment.imageStore
            )
        }

        // Wait briefly for SwiftData @Query propagation if demo items were just inserted
        if launchArgs.openFirstDetail || launchArgs.openFirstEraser || launchArgs.openPDFPreview || launchArgs.openReviewSession {
            try? await Task.sleep(for: .milliseconds(250))
            let fetched = (try? modelContext.fetch(FetchDescriptor<MistakeItem>(sortBy: [SortDescriptor(\MistakeItem.createdAt, order: .reverse)]))) ?? []
            if launchArgs.openFirstDetail, let first = fetched.first {
                debugInspectMistake = first
            } else if launchArgs.openFirstEraser, let first = fetched.first {
                debugInspectEraserItem = first
            } else if launchArgs.openPDFPreview, !fetched.isEmpty {
                debugPDFItems = Array(fetched.prefix(3))
            } else if launchArgs.openReviewSession, !fetched.isEmpty {
                debugReviewItems = fetched
            }
        }

        if launchArgs.openPaywall {
            debugShowPaywall = true
        }
        #endif
    }
}
