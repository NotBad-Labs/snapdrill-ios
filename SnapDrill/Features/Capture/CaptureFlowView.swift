import PhotosUI
import SwiftData
import SwiftUI

/// Explicit workflow stages replacing raw integer step tracking.
enum CaptureFlowStep: Int, Sendable, Equatable, Comparable {
    case source = 0
    case correction = 1
    case cropping = 2
    case previewSave = 3

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var navigationTitle: String {
        switch self {
        case .source: return String(localized: "Capture Mistakes")
        case .correction: return String(localized: "1. Align & Enhance")
        case .cropping: return String(localized: "2. Frame Questions")
        case .previewSave: return String(localized: "3. Clean & Save")
        }
    }
}

/// Full 3-step mistake capture coordinator strictly consuming CapturePipelineServing (zero Vision/VisionKit/CoreImage/AVFoundation imports).
struct CaptureFlowView: View {
    let initialSession: CaptureSession?
    var startMode: CaptureStartMode = .cameraDefault
    var preferredSubjectID: UUID?
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(AppEnvironment.self) private var environment

    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Query(sort: \CustomCause.sortOrder) private var customCauses: [CustomCause]

    @State private var session: CaptureSession?
    @State private var step: CaptureFlowStep = .source
    @State private var currentPageIndex: Int = 0
    @State private var activeBoxID: UUID?
    @State private var isEditingCorners: Bool = false
    @State private var hasAutoLaunchedCamera: Bool = false

    @State private var cameraAuthState: CameraAuthorizationState = .notDetermined
    @State private var showingCameraPicker: Bool = false
    @State private var showingPhotoPicker: Bool = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    @State private var savePreview: CaptureSavePreview?
    @State private var currentPreviewIndex: Int = 0
    @State private var inkMode: InkRemovalMode = .autoAll
    @State private var isPeekingOriginal: Bool = false
    @State private var selectedSubjectID: UUID?
    @State private var showOptionalFields: Bool = false
    @State private var newTagInput: String = ""
    @State private var selectedAnswerPhotoItems: [PhotosPickerItem] = []

    @State private var eraserTargetIndex: Int?
    @State private var showingPaywall: Bool = false
    @State private var isBusy: Bool = false
    @State private var errorMessage: String?
    @State private var draftSaveDebounceTask: Task<Void, Never>?
    @State private var activeDraftSaveTask: Task<Void, Never>?
    @State private var draftEpoch: UInt64 = 0
    @State private var isDismissingOrSaving: Bool = false

    private var regularSubjects: [Subject] {
        subjects.filter { !$0.isUncategorizedBucket }
    }

    private var currentPage: CapturePage? {
        guard let session, session.pages.indices.contains(currentPageIndex) else { return nil }
        return session.pages[currentPageIndex]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if step > .source {
                    stepProgressHeader
                }

                if isBusy {
                    Spacer()
                    ProgressView("Processing on device...")
                        .tint(SnapDrillTheme.inkBlue)
                    Spacer()
                } else {
                    stepContentView
                }
            }
            .paperBackground()
            .navigationTitle(step.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { captureToolbar }
            .task { await initializeFlow() }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedPhotoItems,
                maxSelectionCount: max(1, environment.capturePipeline.maxPhotoCount - (session?.pages.count ?? 0)),
                matching: .images
            )
            .fullScreenCover(isPresented: $showingCameraPicker) { cameraCoverContent }
            .onChange(of: selectedPhotoItems) { _, items in handlePickedPageItems(items) }
            .onChange(of: selectedAnswerPhotoItems) { _, items in handlePickedAnswerItems(items) }
            .onChange(of: inkMode) { _, newMode in
                guard Self.shouldReprocessPreview(
                    step: step,
                    currentPreviewMode: savePreview?.inkRemovalMode,
                    newMode: newMode
                ) else { return }
                Task { await reprocessAllPreviewItems(mode: newMode) }
            }
            .fullScreenCover(isPresented: Binding(
                get: { eraserTargetIndex != nil },
                set: { if !$0 { eraserTargetIndex = nil } }
            )) { eraserCoverContent }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .alert("Notice", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var stepContentView: some View {
        switch step {
        case .source:
            CaptureSourceStepView(
                cameraAuthState: cameraAuthState,
                maxPhotoCount: environment.capturePipeline.maxPhotoCount,
                selectedPhotoItems: $selectedPhotoItems,
                onOpenCamera: { Task { await openCamera() } },
                onOpenSettings: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            )
        case .correction:
            CaptureCorrectionStepView(
                page: currentPage,
                pages: session?.pages ?? [],
                currentPageIndex: $currentPageIndex,
                isEditingCorners: $isEditingCorners,
                cameraAuthState: cameraAuthState,
                maxPhotoCount: environment.capturePipeline.maxPhotoCount,
                selectedPhotoItems: $selectedPhotoItems,
                onUpdateCornersLive: { pageID, newCorners in
                    if let idx = session?.pages.firstIndex(where: { $0.id == pageID }) {
                        session?.pages[idx].corners = newCorners
                    }
                },
                onCommitCorners: { pageID, committed, exitEditMode in
                    Task { await commitCorners(committed, pageID: pageID, exitEditMode: exitEditMode) }
                },
                onSelectEnhancement: { pageID, mode in
                    Task { await applyEnhancement(mode, pageID: pageID) }
                },
                onSelectPage: selectPage(at:),
                onRemovePage: removePage(id:),
                onOpenCamera: { Task { await openCamera() } },
                onNextStep: {
                    isEditingCorners = false
                    step = .cropping
                    activeBoxID = currentPage?.boxes.first?.id
                    persistDraftAsync()
                }
            )
        case .cropping:
            CaptureCroppingStepView(
                page: currentPage,
                pages: session?.pages ?? [],
                totalBoxCount: session?.totalBoxCount ?? 1,
                currentPageIndex: currentPageIndex,
                activeBoxID: $activeBoxID,
                maxBoxesPerPage: environment.capturePipeline.maxBoxesPerPage,
                isPro: environment.proStore.isPro,
                cameraAuthState: cameraAuthState,
                maxPhotoCount: environment.capturePipeline.maxPhotoCount,
                selectedPhotoItems: $selectedPhotoItems,
                onUpdateBox: { pageID, updatedBox in
                    if let pIdx = session?.pages.firstIndex(where: { $0.id == pageID }),
                       let bIdx = session?.pages[pIdx].boxes.firstIndex(where: { $0.id == updatedBox.id }) {
                        session?.pages[pIdx].boxes[bIdx] = updatedBox
                    }
                },
                onDeleteBox: { pageID, boxID in
                    Task { await deleteBox(boxID, pageID: pageID) }
                },
                onAddBox: { pageID in
                    Task { await addBox(pageID: pageID) }
                },
                onSmartFrame: { pageID in
                    if environment.proStore.isPro {
                        Task { await runSmartFrame(pageID: pageID) }
                    } else {
                        showingPaywall = true
                    }
                },
                onDragEnded: persistDraftAsync,
                onSelectPage: selectPage(at:),
                onRemovePage: removePage(id:),
                onNextStep: { Task { await buildPreviewForStep3() } }
            )
        case .previewSave:
            CapturePreviewSaveStepView(
                savePreview: $savePreview,
                currentPreviewIndex: $currentPreviewIndex,
                inkMode: $inkMode,
                isPeekingOriginal: $isPeekingOriginal,
                selectedSubjectID: $selectedSubjectID,
                showOptionalFields: $showOptionalFields,
                newTagInput: $newTagInput,
                selectedAnswerPhotoItems: $selectedAnswerPhotoItems,
                regularSubjects: regularSubjects,
                customCauses: customCauses,
                isDismissingOrSaving: isDismissingOrSaving,
                isFullInkModelAvailable: CapturePipelineFactory.isCoreMLModelBundled,
                onSelectSubject: persistDraftAsync,
                onOpenEraser: { eraserTargetIndex = $0 },
                onToggleCause: togglePreviewCause(_:at:),
                onToggleCustomCause: toggleCustomCause(_:at:),
                onAddTag: addTagToCurrentItem,
                onRemoveAnswerPhoto: { ansIdx in
                    guard savePreview?.items.indices.contains(currentPreviewIndex) == true,
                          savePreview?.items[currentPreviewIndex].answerImageDatas.indices.contains(ansIdx) == true else {
                        return
                    }
                    savePreview?.items[currentPreviewIndex].answerImageDatas.remove(at: ansIdx)
                },
                onScheduleDebouncedDraftSave: scheduleDebouncedDraftSave,
                onPersistDraft: persistDraftAsync,
                onCommit: commitAndDismiss
            )
        }
    }

    @ToolbarContentBuilder
    private var captureToolbar: some ToolbarContent {
        if step <= .correction {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { cancelAndDismiss() }
                    .disabled(isDismissingOrSaving)
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if let prev = CaptureFlowStep(rawValue: step.rawValue - 1) {
                        step = prev
                        persistDraftAsync()
                    }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") { cancelAndDismiss() }
                    .disabled(isDismissingOrSaving)
            }
        }
    }

    private var cameraCoverContent: some View {
        CameraPickerBridge(
            maxPhotos: max(1, environment.capturePipeline.maxPhotoCount - (session?.pages.count ?? 0)),
            onFinishBatch: { datas in
                showingCameraPicker = false
                Task { await appendImportedImageDatas(datas) }
            },
            onRequestPhotoLibrary: { capturedDatas in
                showingCameraPicker = false
                Task {
                    if !capturedDatas.isEmpty {
                        await appendImportedImageDatas(capturedDatas)
                    }
                    let remaining = environment.capturePipeline.maxPhotoCount - (session?.pages.count ?? 0)
                    guard remaining > 0 else { return }
                    try? await Task.sleep(for: .milliseconds(450))
                    showingPhotoPicker = true
                }
            },
            onCancel: { showingCameraPicker = false }
        )
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var eraserCoverContent: some View {
        if let idx = eraserTargetIndex,
           let items = savePreview?.items,
           items.indices.contains(idx),
           let cleanedUI = UIImage(data: items[idx].cleanedImageData),
           let originalUI = UIImage(data: items[idx].originalImageData) {
            HandwritingEraserView(initialImage: cleanedUI, originalReferenceImage: originalUI) { edited in
                if let jpeg = edited.jpegData(compressionQuality: 0.90) {
                    savePreview?.items[idx].cleanedImageData = jpeg
                    savePreview?.items[idx].handwritingRemovalSucceeded = true
                    persistDraftAsync()
                }
            }
        }
    }

    private var stepProgressHeader: some View {
        HStack(spacing: 6) {
            ForEach(1...3, id: \.self) { idx in
                Capsule()
                    .fill(idx <= step.rawValue ? SnapDrillTheme.inkBlue : SnapDrillTheme.ruledLine)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, SnapDrillTheme.screenPadding)
        .padding(.vertical, 6)
        .accessibilityHidden(true)
    }

    // MARK: - Pipeline Actions & State Transitions

    private func selectPage(at index: Int) {
        guard let session, session.pages.indices.contains(index) else { return }
        currentPageIndex = index
        activeBoxID = session.pages[index].boxes.first?.id
    }

    private func removePage(id: UUID) {
        guard var current = session,
              let removedIndex = current.pages.firstIndex(where: { $0.id == id }) else {
            return
        }
        current.pages.remove(at: removedIndex)
        savePreview = nil
        if current.pages.isEmpty {
            session = nil
            currentPageIndex = 0
            activeBoxID = nil
            isEditingCorners = false
            step = .source
            draftEpoch &+= 1
            draftSaveDebounceTask?.cancel()
            activeDraftSaveTask?.cancel()
            let draftStore = environment.draftStore
            Task { await draftStore.clearDraft() }
            return
        }
        session = current
        currentPageIndex = min(removedIndex, current.pages.count - 1)
        activeBoxID = currentPage?.boxes.first?.id
        persistDraftAsync()
    }

    private func handlePickedPageItems(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            var loaded: [Data] = []
            for item in items.prefix(environment.capturePipeline.maxPhotoCount) {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    loaded.append(data)
                }
            }
            selectedPhotoItems = []
            await appendImportedImageDatas(loaded)
        }
    }

    private func handlePickedAnswerItems(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty,
              savePreview?.items.indices.contains(currentPreviewIndex) == true else {
            return
        }
        let targetIdx = currentPreviewIndex
        let targetItemID = savePreview?.items[targetIdx].id
        Task {
            var appendedAny = false
            for item in items {
                guard let currentItems = savePreview?.items,
                      currentItems.indices.contains(targetIdx),
                      currentItems[targetIdx].id == targetItemID,
                      currentItems[targetIdx].answerImageDatas.count < MistakeLimits.maxAnswerImages else {
                    break
                }
                if let data = try? await item.loadTransferable(type: Data.self),
                   UIImage(data: data) != nil {
                    guard let latestItems = savePreview?.items,
                          latestItems.indices.contains(targetIdx),
                          latestItems[targetIdx].id == targetItemID,
                          latestItems[targetIdx].answerImageDatas.count < MistakeLimits.maxAnswerImages else {
                        break
                    }
                    savePreview?.items[targetIdx].answerImageDatas.append(data)
                    appendedAny = true
                }
            }
            selectedAnswerPhotoItems = []
            if appendedAny {
                persistDraftAsync()
            }
        }
    }

    private func initializeFlow() async {
        SubjectCatalog.ensureSeeded(in: modelContext)
        inkMode = environment.preferences.defaultInkRemovalMode
        if let preferredSubjectID, regularSubjects.contains(where: { $0.id == preferredSubjectID }) {
            selectedSubjectID = preferredSubjectID
        } else {
            selectedSubjectID = environment.preferences.lastSubjectID ?? regularSubjects.first?.id
        }
        cameraAuthState = environment.cameraAccess.authorizationState()

        if let initialSession {
            session = initialSession
            currentPageIndex = 0
            activeBoxID = initialSession.pages.first?.boxes.first?.id
            if let restoredSubject = initialSession.selectedSubjectID {
                selectedSubjectID = restoredSubject
            }
            if initialSession.activeStep >= CaptureFlowStep.previewSave.rawValue {
                if let restoredPreview = initialSession.savedPreview, !restoredPreview.items.isEmpty {
                    savePreview = restoredPreview
                    inkMode = restoredPreview.inkRemovalMode
                    currentPreviewIndex = 0
                    step = .previewSave
                } else {
                    await buildPreviewForStep3()
                }
            } else {
                step = initialSession.activeStep == CaptureFlowStep.cropping.rawValue ? .cropping : .correction
            }
        } else if !hasAutoLaunchedCamera {
            switch startMode {
            case .photoLibrary:
                hasAutoLaunchedCamera = true
                showingPhotoPicker = true
            case .cameraDefault:
                if cameraAuthState == .authorized {
                    hasAutoLaunchedCamera = true
                    showingCameraPicker = true
                }
            }
        }
    }

    private func openCamera() async {
        let state = environment.cameraAccess.authorizationState()
        if state == .notDetermined {
            let grantedState = await environment.cameraAccess.requestAccess()
            cameraAuthState = grantedState
            if grantedState == .authorized {
                showingCameraPicker = true
            }
        } else {
            cameraAuthState = state
            if state == .authorized {
                showingCameraPicker = true
            }
        }
    }

    private func appendImportedImageDatas(_ newDatas: [Data]) async {
        guard !newDatas.isEmpty else { return }
        isBusy = true
        defer { isBusy = false }

        do {
            if var existing = session {
                let extraSession = try await environment.capturePipeline.beginSession(importedImageData: newDatas)
                let combinedCount = existing.pages.count + extraSession.pages.count
                if combinedCount > environment.capturePipeline.maxPhotoCount {
                    throw CapturePipelineError.tooManyPhotos(limit: environment.capturePipeline.maxPhotoCount)
                }
                existing.pages.append(contentsOf: extraSession.pages)
                session = existing
                currentPageIndex = max(0, existing.pages.count - 1)
            } else {
                let created = try await environment.capturePipeline.beginSession(importedImageData: newDatas)
                session = created
                currentPageIndex = 0
            }
            isEditingCorners = false
            step = .correction
            persistDraftAsync()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func commitCorners(_ corners: QuadCorners, pageID: UUID, exitEditMode: Bool) async {
        guard let currentSession = session else { return }
        do {
            let updated = try await environment.capturePipeline.updateCorners(corners, pageID: pageID, in: currentSession)
            if let updatedPage = updated.pages.first(where: { $0.id == pageID }),
               let idx = session?.pages.firstIndex(where: { $0.id == pageID }) {
                session?.pages[idx] = updatedPage
            }
            if exitEditMode { isEditingCorners = false }
            persistDraftAsync()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyEnhancement(_ mode: ImageEnhancementMode, pageID: UUID) async {
        guard let currentSession = session else { return }
        do {
            let updated = try await environment.capturePipeline.setEnhancement(mode: mode, pageID: pageID, in: currentSession)
            if let updatedPage = updated.pages.first(where: { $0.id == pageID }),
               let idx = session?.pages.firstIndex(where: { $0.id == pageID }) {
                session?.pages[idx] = updatedPage
            }
            persistDraftAsync()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func addBox(pageID: UUID) async {
        guard let currentSession = session else { return }
        do {
            let updated = try await environment.capturePipeline.addBox(on: pageID, rect: nil, in: currentSession)
            session = updated
            activeBoxID = updated.pages.first(where: { $0.id == pageID })?.boxes.last?.id
            persistDraftAsync()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteBox(_ boxID: UUID, pageID: UUID) async {
        guard let currentSession = session else { return }
        do {
            session = try await environment.capturePipeline.removeBox(boxID: boxID, on: pageID, in: currentSession)
            activeBoxID = currentPage?.boxes.first?.id
            persistDraftAsync()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func runSmartFrame(pageID: UUID) async {
        guard let currentSession = session else { return }
        do {
            session = try await environment.capturePipeline.suggestQuestionBoxes(on: pageID, in: currentSession)
            activeBoxID = currentPage?.boxes.first?.id
            persistDraftAsync()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func buildPreviewForStep3() async {
        guard let session else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            savePreview = try await environment.capturePipeline.buildSavePreview(for: session, mode: inkMode)
            currentPreviewIndex = 0
            step = .previewSave
            persistDraftAsync()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Prevents draft restoration in Step 3 from overwriting manual edits when `inkMode` syncs with the saved preview.
    nonisolated static func shouldReprocessPreview(
        step: CaptureFlowStep,
        currentPreviewMode: InkRemovalMode?,
        newMode: InkRemovalMode
    ) -> Bool {
        step == .previewSave && currentPreviewMode != newMode
    }

    private func reprocessAllPreviewItems(mode: InkRemovalMode) async {
        guard var preview = savePreview else { return }
        isBusy = true
        defer { isBusy = false }
        for idx in preview.items.indices {
            preview.items[idx] = await environment.capturePipeline.reprocessItem(preview.items[idx], mode: mode)
        }
        preview.inkRemovalMode = mode
        savePreview = preview
        persistDraftAsync()
    }

    private func togglePreviewCause(_ cause: MistakeCause, at index: Int) {
        guard savePreview?.items.indices.contains(index) == true else { return }
        if savePreview?.items[index].causes.contains(cause) == true {
            savePreview?.items[index].causes.removeAll { $0 == cause }
        } else {
            savePreview?.items[index].causes.append(cause)
        }
        persistDraftAsync()
    }

    private func toggleCustomCause(_ name: String, at index: Int) {
        guard savePreview?.items.indices.contains(index) == true else { return }
        if savePreview?.items[index].customCauseNames.contains(name) == true {
            savePreview?.items[index].customCauseNames.removeAll { $0 == name }
        } else if (savePreview?.items[index].customCauseNames.count ?? 0) < MistakeLimits.maxCustomCausesPerMistake {
            savePreview?.items[index].customCauseNames.append(name)
        }
        persistDraftAsync()
    }

    private func addTagToCurrentItem() {
        let clean = newTagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty,
              savePreview?.items.indices.contains(currentPreviewIndex) == true,
              (savePreview?.items[currentPreviewIndex].tagNames.count ?? 0) < MistakeLimits.maxTagsPerMistake else {
            return
        }
        if savePreview?.items[currentPreviewIndex].tagNames.contains(clean) == false {
            savePreview?.items[currentPreviewIndex].tagNames.append(clean)
        }
        newTagInput = ""
        persistDraftAsync()
    }

    private func cancelAndDismiss() {
        guard !isDismissingOrSaving else { return }
        isDismissingOrSaving = true
        draftEpoch &+= 1
        draftSaveDebounceTask?.cancel()
        draftSaveDebounceTask = nil
        activeDraftSaveTask?.cancel()
        let inFlightSave = activeDraftSaveTask
        activeDraftSaveTask = nil
        let draftStore = environment.draftStore

        Task {
            await inFlightSave?.value
            await draftStore.clearDraft()
            onDismiss()
        }
    }

    private func commitAndDismiss() {
        guard !isDismissingOrSaving else { return }
        draftSaveDebounceTask?.cancel()
        draftSaveDebounceTask = nil
        guard let preview = savePreview else { return }
        guard let subject = regularSubjects.first(where: { $0.id == selectedSubjectID }) ?? regularSubjects.first else {
            errorMessage = CapturePipelineError.subjectRequired.localizedDescription
            return
        }

        isDismissingOrSaving = true
        draftEpoch &+= 1
        activeDraftSaveTask?.cancel()
        let inFlightSave = activeDraftSaveTask
        activeDraftSaveTask = nil

        do {
            let saved = try environment.saveService.commitSave(preview: preview, subject: subject, in: modelContext)
            environment.preferences.lastSubjectID = subject.id
            let draftStore = environment.draftStore
            Task {
                await inFlightSave?.value
                await draftStore.clearDraft()
                environment.showSavedConfirmation(count: saved.count)
                onDismiss()
            }
        } catch {
            isDismissingOrSaving = false
            errorMessage = error.localizedDescription
        }
    }

    private func scheduleDebouncedDraftSave() {
        guard !isDismissingOrSaving else { return }
        draftSaveDebounceTask?.cancel()
        draftSaveDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled, !isDismissingOrSaving else { return }
            persistDraftAsync()
        }
    }

    private func persistDraftAsync() {
        draftSaveDebounceTask?.cancel()
        draftSaveDebounceTask = nil
        guard !isDismissingOrSaving, var current = session else { return }
        current.activeStep = step.rawValue
        current.selectedSubjectID = selectedSubjectID
        current.savedPreview = step >= .previewSave ? savePreview : nil
        draftEpoch &+= 1
        let targetEpoch = draftEpoch
        let draftStore = environment.draftStore
        let previousSave = activeDraftSaveTask
        previousSave?.cancel()

        activeDraftSaveTask = Task {
            await previousSave?.value
            guard !Task.isCancelled, !isDismissingOrSaving, draftEpoch == targetEpoch else { return }
            do {
                try await draftStore.saveDraft(current)
            } catch is CancellationError {
                return
            } catch {
                guard !isDismissingOrSaving, draftEpoch == targetEpoch else { return }
                errorMessage = error.localizedDescription
            }
        }
    }
}
