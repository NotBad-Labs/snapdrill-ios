import SwiftData
import SwiftUI

/// Root shell implementing PRD §8.1 navigation: Home | Center Capture FAB | Review | Settings,
/// plus 5-second undo delete bar, calm post-save toast, and interrupted draft recovery prompt.
struct RootTabView: View {
    let launchArgs: AppLaunchArguments

    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var environment

    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Query(sort: \MistakeItem.createdAt, order: .reverse) private var allMistakes: [MistakeItem]

    @State private var selectedTab: SnapDrillTab = .home
    @State private var showingCaptureFlow: Bool = false
    @State private var resumeSessionForCapture: CaptureSession?

    // Optional debug inspection deep-links
    @State private var debugInspectMistake: MistakeItem?
    @State private var debugInspectEraserItem: MistakeItem?
    @State private var debugPDFItems: [MistakeItem]?
    @State private var debugShowPaywall: Bool = false
    @State private var debugReviewItems: [MistakeItem]?
    @State private var hasRunStartup: Bool = false

    private var visibleMistakes: [MistakeItem] {
        allMistakes.filter { !environment.pendingDeletionIDs.contains($0.id) }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                Tab("Notebook", systemImage: "books.vertical.fill", value: SnapDrillTab.home) {
                    HomeView(
                        onStartCapture: { openCapture(with: nil) }
                    )
                }

                Tab("Review", systemImage: "rectangle.stack.fill", value: SnapDrillTab.review) {
                    ReviewHubView()
                }

                Tab("Settings", systemImage: "gearshape.fill", value: SnapDrillTab.settings) {
                    SettingsView()
                }
            }
            .tint(SnapDrillTheme.inkBlue)

            // Center floating "Snap" camera button anchored over the bottom bar on Home & Review (PRD §8.1)
            VStack(spacing: 8) {
                if environment.undoBannerCount > 0 {
                    undoDeleteBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if let savedCount = environment.savedToastQuestionCount {
                    savedToastBanner(count: savedCount)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if let draft = environment.recoverableDraft {
                    draftRecoveryBanner(draft: draft)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if selectedTab != .settings {
                    HStack {
                        Spacer()
                        Button {
                            openCapture(with: nil)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.title3.weight(.semibold))
                                Text("Snap")
                                    .font(.subheadline.weight(.bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(SnapDrillTheme.inkBlue, in: Capsule(style: .continuous))
                            .shadow(color: SnapDrillTheme.inkBlue.opacity(0.32), radius: 10, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(localized: "Capture Mistakes"))
                        Spacer()
                    }
                    .padding(.bottom, 58)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: environment.undoBannerCount)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: environment.savedToastQuestionCount)
        }
        .task {
            await performStartup()
        }
        .fullScreenCover(isPresented: $showingCaptureFlow) {
            CaptureFlowView(initialSession: resumeSessionForCapture) {
                showingCaptureFlow = false
                resumeSessionForCapture = nil
            }
        }
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
    }

    // MARK: - Floating Banners

    private var undoDeleteBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash")
                .foregroundStyle(.white.opacity(0.85))
            Text("Deleted (\(environment.undoBannerCount))")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
            Button("Undo") {
                environment.undoLastDeletion()
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(SnapDrillTheme.pencilYellow)
            .accessibilityLabel(String(localized: "Undo Delete"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hexString: "1F1F22"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func savedToastBanner(count: Int) -> some View {
        HStack(spacing: 10) {
            PandaMascotView(mood: .savedBadge, size: 30)
            Text("Saved \(count) — ready when you want to practice")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SnapDrillTheme.inkBlack)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(SnapDrillTheme.cardSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(SnapDrillTheme.ruledLine, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 16)
    }

    private func draftRecoveryBanner(draft: CaptureSession) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.badge.clock")
                .foregroundStyle(SnapDrillTheme.inkBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text("Resume unfinished capture?")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SnapDrillTheme.inkBlack)
                Text("\(draft.pages.count) pages · \(draft.totalBoxCount) questions")
                    .font(.caption2)
                    .foregroundStyle(SnapDrillTheme.inkSecondary)
            }
            Spacer()
            Button("Discard") {
                Task { await environment.discardRecoverableDraft() }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(SnapDrillTheme.inkSecondary)

            Button("Resume") {
                openCapture(with: draft)
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(SnapDrillTheme.inkBlue, in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(SnapDrillTheme.cardSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(SnapDrillTheme.inkBlue.opacity(0.35), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 16)
    }

    // MARK: - Actions & Startup

    private func openCapture(with draft: CaptureSession?) {
        resumeSessionForCapture = draft
        environment.recoverableDraft = nil
        showingCaptureFlow = true
    }

    private func performStartup() async {
        guard !hasRunStartup else { return }
        hasRunStartup = true

        SubjectCatalog.ensureSeeded(in: modelContext)
        selectedTab = launchArgs.initialTab
        await environment.checkForRecoverableDraft()

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
    }
}
