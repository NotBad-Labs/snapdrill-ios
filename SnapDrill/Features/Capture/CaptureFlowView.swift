import PhotosUI
import SwiftData
import SwiftUI

/// Full 3-step mistake capture wizard strictly consuming CapturePipelineServing (zero Vision/VisionKit/CoreImage/AVFoundation imports).
struct CaptureFlowView: View {
    let initialSession: CaptureSession?
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(AppEnvironment.self) private var environment

    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Query(sort: \MistakeTag.name) private var existingTags: [MistakeTag]
    @Query(sort: \CustomCause.sortOrder) private var customCauses: [CustomCause]

    @State private var session: CaptureSession?
    @State private var step: Int = 0 // 0: Source, 1: Correct/Enhance, 2: Multi-box Frame, 3: Preview & Save
    @State private var currentPageIndex: Int = 0
    @State private var activeBoxID: UUID?
    @State private var isEditingCorners: Bool = false
    @State private var hasAutoLaunchedCamera: Bool = false

    @State private var cameraAuthState: CameraAuthorizationState = .notDetermined
    @State private var showingCameraPicker: Bool = false
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
                if step > 0 {
                    stepProgressHeader
                }

                if isBusy {
                    Spacer()
                    ProgressView("Processing on device...")
                        .tint(SnapDrillTheme.inkBlue)
                    Spacer()
                } else {
                    switch step {
                    case 0: sourceSelectorView
                    case 1: step1CorrectionView
                    case 2: step2CroppingView
                    default: step3PreviewAndSaveView
                    }
                }
            }
            .paperBackground()
            .navigationTitle(navigationTitleForStep)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Task {
                            await environment.draftStore.clearDraft()
                            onDismiss()
                        }
                    }
                }

                if step > 1 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Back") {
                            step -= 1
                            persistDraftAsync()
                        }
                    }
                }
            }
            .task {
                await initializeFlow()
            }
            .sheet(isPresented: $showingCameraPicker) {
                CameraPickerBridge { data in
                    guard let data else { return }
                    Task { await appendImportedImageDatas([data]) }
                }
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhotoItems) { _, items in
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
            .onChange(of: selectedAnswerPhotoItems) { _, items in
                guard !items.isEmpty,
                      savePreview?.items.indices.contains(currentPreviewIndex) == true else {
                    return
                }
                let targetIdx = currentPreviewIndex
                Task {
                    var appendedAny = false
                    for item in items {
                        let existingCount = savePreview?.items[targetIdx].answerImageDatas.count ?? 0
                        guard existingCount < MistakeLimits.maxAnswerImages else { break }
                        if let data = try? await item.loadTransferable(type: Data.self),
                           UIImage(data: data) != nil {
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
            .fullScreenCover(isPresented: Binding(
                get: { eraserTargetIndex != nil },
                set: { if !$0 { eraserTargetIndex = nil } }
            )) {
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
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
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

    private var navigationTitleForStep: String {
        switch step {
        case 0: return String(localized: "Capture Mistakes")
        case 1: return String(localized: "1. Align & Enhance")
        case 2: return String(localized: "2. Frame Questions")
        default: return String(localized: "3. Clean & Save")
        }
    }

    // MARK: - Step 0: Camera / Album Source

    private var sourceSelectorView: some View {
        ScrollView {
            VStack(spacing: 18) {
                PaperCard(padding: 20) {
                    VStack(spacing: 14) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 42, weight: .light))
                            .foregroundStyle(SnapDrillTheme.inkBlue)
                            .frame(width: 78, height: 78)
                            .background(SnapDrillTheme.inkBlueSoft, in: Circle())
                            .accessibilityHidden(true)

                        Text("Photograph Homework or Exam Pages")
                            .font(.headline)
                            .foregroundStyle(SnapDrillTheme.inkBlack)
                            .multilineTextAlignment(.center)

                        Text("Capture up to 10 pages in one batch. All scanning, perspective correction, and handwriting removal run privately on your iPhone.")
                            .font(.subheadline)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                            .multilineTextAlignment(.center)

                        if cameraAuthState == .denied || cameraAuthState == .restricted {
                            VStack(spacing: 10) {
                                Text("Camera access is currently disabled. You can enable it in Settings or import photos directly from your album.")
                                    .font(.caption)
                                    .foregroundStyle(SnapDrillTheme.gradingRed)
                                    .multilineTextAlignment(.center)

                                Button("Open System Settings") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        openURL(url)
                                    }
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SnapDrillTheme.inkBlue)
                            }
                            .padding(.top, 4)
                        } else if cameraAuthState == .unavailable {
                            Text("Camera hardware is unavailable on this simulator; use Photos Import below.")
                                .font(.caption)
                                .foregroundStyle(SnapDrillTheme.inkSecondary)
                        } else {
                            Button {
                                Task { await openCamera() }
                            } label: {
                                Label("Open Camera", systemImage: "camera.fill")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(SnapDrillTheme.inkBlue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }

                        PhotosPicker(
                            selection: $selectedPhotoItems,
                            maxSelectionCount: environment.capturePipeline.maxPhotoCount,
                            matching: .images
                        ) {
                            Label("Import from Photos (Up to 10)", systemImage: "photo.on.rectangle.angled")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SnapDrillTheme.inkBlue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(SnapDrillTheme.inkBlueSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
            }
            .padding(SnapDrillTheme.screenPadding)
        }
    }

    // MARK: - Step 1: Edges & Enhancement (Overlay strictly bound to rawImageData coordinates)

    private var step1CorrectionView: some View {
        VStack(spacing: 12) {
            if let page = currentPage {
                // Explicit toggle between Raw Corner Alignment and Rectified Enhanced Preview
                Picker("Step 1 View Mode", selection: $isEditingCorners) {
                    Text("Preview Sheet").tag(false)
                    Text("Adjust Corners").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, SnapDrillTheme.screenPadding)

                let displayData = isEditingCorners ? page.rawImageData : page.enhancedImageData
                if let uiImage = UIImage(data: displayData) {
                    GeometryReader { geo in
                        let imageFrame = AspectFitCalculator.fittedRect(imageSize: uiImage.size, in: geo.size)

                        ZStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width, height: geo.size.height)

                            // Guarantee PerspectiveCornerOverlay ALWAYS maps over unwarped rawImageData coordinates
                            if isEditingCorners {
                                PerspectiveCornerOverlay(
                                    corners: Binding(
                                        get: { page.corners },
                                        set: { newCorners in
                                            if let idx = session?.pages.firstIndex(where: { $0.id == page.id }) {
                                                session?.pages[idx].corners = newCorners
                                            }
                                        }
                                    ),
                                    imageFrame: imageFrame
                                ) { committed in
                                    Task {
                                        guard let s = session else { return }
                                        session = try? await environment.capturePipeline.updateCorners(committed, pageID: page.id, in: s)
                                        persistDraftAsync()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }

                if isEditingCorners {
                    Button {
                        Task {
                            guard let s = session else { return }
                            session = try? await environment.capturePipeline.updateCorners(page.corners, pageID: page.id, in: s)
                            isEditingCorners = false
                            persistDraftAsync()
                        }
                    } label: {
                        Label("Apply Corners & Straighten", systemImage: "checkmark.rectangle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SnapDrillTheme.inkBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(SnapDrillTheme.inkBlueSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, SnapDrillTheme.screenPadding)
                } else {
                    // Enhancement mode switcher (PRD F-04)
                    HStack(spacing: 8) {
                        ForEach(ImageEnhancementMode.allCases) { mode in
                            let selected = page.enhancementMode == mode
                            Button {
                                Task {
                                    guard let s = session else { return }
                                    session = try? await environment.capturePipeline.setEnhancement(mode: mode, pageID: page.id, in: s)
                                    persistDraftAsync()
                                }
                            } label: {
                                Text(mode.localizedTitle)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(selected ? .white : SnapDrillTheme.inkBlack)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(
                                        Capsule().fill(selected ? SnapDrillTheme.inkBlue : SnapDrillTheme.cardSurface)
                                    )
                                    .overlay(
                                        Capsule().strokeBorder(selected ? Color.clear : SnapDrillTheme.ruledLine, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, SnapDrillTheme.screenPadding)
                }
            }

            pageThumbnailStrip(allowAddingMore: true)

            Button {
                isEditingCorners = false
                step = 2
                activeBoxID = currentPage?.boxes.first?.id
                persistDraftAsync()
            } label: {
                Text("Next: Frame Questions")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(SnapDrillTheme.inkBlue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, SnapDrillTheme.screenPadding)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Step 2: Single-Page Multi-Box & Multi-Page Framing

    private var step2CroppingView: some View {
        VStack(spacing: 12) {
            if let page = currentPage,
               let uiImage = UIImage(data: page.enhancedImageData) {
                GeometryReader { geo in
                    let imageFrame = AspectFitCalculator.fittedRect(imageSize: uiImage.size, in: geo.size)

                    ZStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width, height: geo.size.height)

                        MultiBoxCropOverlay(
                            boxes: page.boxes,
                            activeBoxID: activeBoxID,
                            imageFrame: imageFrame,
                            onSelectBox: { activeBoxID = $0 },
                            onUpdateBox: { updatedBox in
                                if let pIdx = session?.pages.firstIndex(where: { $0.id == page.id }),
                                   let bIdx = session?.pages[pIdx].boxes.firstIndex(where: { $0.id == updatedBox.id }) {
                                    session?.pages[pIdx].boxes[bIdx] = updatedBox
                                }
                            },
                            onDeleteBox: { boxID in
                                Task {
                                    guard let s = session else { return }
                                    session = try? await environment.capturePipeline.removeBox(boxID: boxID, on: page.id, in: s)
                                    activeBoxID = currentPage?.boxes.first?.id
                                    persistDraftAsync()
                                }
                            },
                            onDragEnded: {
                                persistDraftAsync()
                            }
                        )
                    }
                }
                .padding(.horizontal, 12)

                HStack(spacing: 10) {
                    Button {
                        Task {
                            guard let s = session else { return }
                            do {
                                let updated = try await environment.capturePipeline.addBox(on: page.id, rect: nil, in: s)
                                session = updated
                                activeBoxID = updated.pages[currentPageIndex].boxes.last?.id
                                persistDraftAsync()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        Label("Add Question (\(page.boxes.count)/10)", systemImage: "plus.rectangle.on.rectangle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SnapDrillTheme.inkBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(SnapDrillTheme.inkBlueSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(page.boxes.count >= environment.capturePipeline.maxBoxesPerPage)

                    Button {
                        if environment.proStore.isPro {
                            Task {
                                guard let s = session else { return }
                                session = try? await environment.capturePipeline.suggestQuestionBoxes(on: page.id, in: s)
                                activeBoxID = currentPage?.boxes.first?.id
                                persistDraftAsync()
                            }
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: environment.proStore.isPro ? "sparkles" : "lock.fill")
                            Text("Smart Frame")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SnapDrillTheme.inkBlack)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(SnapDrillTheme.cardSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(SnapDrillTheme.ruledLine, lineWidth: 1))
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, SnapDrillTheme.screenPadding)
            }

            pageThumbnailStrip(allowAddingMore: false)

            Button {
                Task { await buildPreviewForStep3() }
            } label: {
                Text("Next: Clean & Save (\(session?.totalBoxCount ?? 1))")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(SnapDrillTheme.inkBlue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, SnapDrillTheme.screenPadding)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Step 3: Handwriting Preview & Fast Save

    private var step3PreviewAndSaveView: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Pinned Subject Picker (PRD §8.2: remembers last saved subject)
                PaperCard(padding: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Subject (Required)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SnapDrillTheme.inkSecondary)
                            Spacer()
                            if let count = savePreview?.questionCount, count > 1 {
                                Text("Applies to all \(count) questions")
                                    .font(.caption2)
                                    .foregroundStyle(SnapDrillTheme.inkBlue)
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(regularSubjects) { subj in
                                    let selected = selectedSubjectID == subj.id
                                    Button {
                                        selectedSubjectID = subj.id
                                        persistDraftAsync()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(selected ? Color.white : Color(hexString: subj.colorHex))
                                                .frame(width: 8, height: 8)
                                            Text(subj.name)
                                                .font(.subheadline.weight(.medium))
                                        }
                                        .foregroundStyle(selected ? .white : SnapDrillTheme.inkBlack)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(
                                            Capsule().fill(selected ? SnapDrillTheme.inkBlue : SnapDrillTheme.elevatedSurface)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                if let preview = savePreview, preview.items.indices.contains(currentPreviewIndex) {
                    let item = preview.items[currentPreviewIndex]

                    if preview.items.count > 1 {
                        HStack {
                            Button {
                                currentPreviewIndex = max(0, currentPreviewIndex - 1)
                            } label: {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.title3)
                            }
                            .disabled(currentPreviewIndex == 0)
                            .accessibilityLabel(String(localized: "Previous Question"))

                            Spacer()
                            Text("Question \(currentPreviewIndex + 1) of \(preview.items.count)")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                            Spacer()

                            Button {
                                currentPreviewIndex = min(preview.items.count - 1, currentPreviewIndex + 1)
                            } label: {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.title3)
                            }
                            .disabled(currentPreviewIndex >= preview.items.count - 1)
                            .accessibilityLabel(String(localized: "Next Question"))
                        }
                        .foregroundStyle(SnapDrillTheme.inkBlue)
                    }

                    // Dual-image preview + manual touch-up eraser
                    PaperCard(padding: 12) {
                        VStack(spacing: 10) {
                            HStack {
                                Label(
                                    isPeekingOriginal ? String(localized: "Original") : (item.handwritingRemovalSucceeded ? String(localized: "Handwriting Removed") : String(localized: "Enhanced Original")),
                                    systemImage: isPeekingOriginal ? "photo" : (item.handwritingRemovalSucceeded ? "wand.and.stars" : "info.circle")
                                )
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(item.handwritingRemovalSucceeded ? SnapDrillTheme.inkBlue : SnapDrillTheme.inkSecondary)

                                Spacer()

                                Button {
                                    isPeekingOriginal.toggle()
                                } label: {
                                    Label(
                                        isPeekingOriginal ? String(localized: "Show Cleaned") : String(localized: "Compare Original"),
                                        systemImage: isPeekingOriginal ? "wand.and.stars" : "eye"
                                    )
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(isPeekingOriginal ? .white : SnapDrillTheme.inkBlack)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(isPeekingOriginal ? SnapDrillTheme.inkBlue : SnapDrillTheme.elevatedSurface, in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(String(localized: "Compare Original"))
                                .accessibilityValue(isPeekingOriginal ? String(localized: "Showing Original") : String(localized: "Showing Cleaned"))

                                Button {
                                    eraserTargetIndex = currentPreviewIndex
                                } label: {
                                    Label("Eraser", systemImage: "eraser.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(SnapDrillTheme.inkBlue, in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(String(localized: "Open Manual Eraser"))
                            }

                            if !item.handwritingRemovalSucceeded && inkMode != .off {
                                HStack(spacing: 8) {
                                    Image(systemName: "hand.draw")
                                        .foregroundStyle(SnapDrillTheme.inkBlue)
                                    Text("Dark pen ink could not be auto-removed safely. Enhanced original is kept — tap Eraser to clean spots.")
                                        .font(.caption2)
                                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                                    Spacer()
                                }
                                .padding(8)
                                .background(SnapDrillTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 8))
                            }

                            if let uiImg = UIImage(data: isPeekingOriginal ? item.originalImageData : item.cleanedImageData) {
                                Image(uiImage: uiImg)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 240)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            Picker("Cleaning Mode", selection: $inkMode) {
                                ForEach(InkRemovalMode.allCases) { mode in
                                    Text(mode.localizedTitle).tag(mode)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: inkMode) { _, newMode in
                                Task { await reprocessAllPreviewItems(mode: newMode) }
                            }
                        }
                    }

                    // Expandable optional details per question (F-21..25)
                    PaperCard(padding: 12) {
                        DisclosureGroup("Optional Details (Causes, Tags, Answer)", isExpanded: $showOptionalFields) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Error Causes")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(SnapDrillTheme.inkSecondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(MistakeCause.allCases) { cause in
                                            let selected = item.causes.contains(cause)
                                            Button {
                                                togglePreviewCause(cause, at: currentPreviewIndex)
                                            } label: {
                                                Text(cause.localizedTitle)
                                                    .font(.caption)
                                                    .foregroundStyle(selected ? .white : SnapDrillTheme.inkBlack)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        Capsule().fill(selected ? SnapDrillTheme.gradingRed : SnapDrillTheme.elevatedSurface)
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        ForEach(customCauses) { custom in
                                            let selected = item.customCauseNames.contains(custom.name)
                                            Button {
                                                toggleCustomCause(custom.name, at: currentPreviewIndex)
                                            } label: {
                                                Text(custom.name)
                                                    .font(.caption)
                                                    .foregroundStyle(selected ? .white : SnapDrillTheme.inkBlack)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        Capsule().fill(selected ? SnapDrillTheme.gradingRed : SnapDrillTheme.elevatedSurface)
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }

                                HStack {
                                    TextField("Add tag...", text: $newTagInput)
                                        .textFieldStyle(.roundedBorder)
                                    Button("Add") {
                                        addTagToCurrentItem()
                                    }
                                    .disabled(
                                        newTagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                        item.tagNames.count >= MistakeLimits.maxTagsPerMistake
                                    )
                                }

                                if !item.tagNames.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(item.tagNames, id: \.self) { tagName in
                                                Text("#\(tagName)")
                                                    .font(.caption)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(SnapDrillTheme.inkBlueSoft, in: Capsule())
                                            }
                                        }
                                    }
                                }

                                TextField("Correct answer / solution (optional)", text: Binding(
                                    get: { savePreview?.items[currentPreviewIndex].answerText ?? "" },
                                    set: {
                                        savePreview?.items[currentPreviewIndex].answerText = String($0.prefix(MistakeLimits.maxAnswerCharacters))
                                        scheduleDebouncedDraftSave()
                                    }
                                ), axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(.roundedBorder)

                                let currentAnswerDatas = item.answerImageDatas
                                if currentAnswerDatas.count < MistakeLimits.maxAnswerImages {
                                    PhotosPicker(
                                        selection: $selectedAnswerPhotoItems,
                                        maxSelectionCount: MistakeLimits.maxAnswerImages - currentAnswerDatas.count,
                                        matching: .images
                                    ) {
                                        Label(
                                            "Attach Answer Photos (\(currentAnswerDatas.count)/\(MistakeLimits.maxAnswerImages))",
                                            systemImage: "photo.badge.plus"
                                        )
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(SnapDrillTheme.inkBlue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(SnapDrillTheme.inkBlueSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                }

                                if !currentAnswerDatas.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(Array(currentAnswerDatas.enumerated()), id: \.offset) { ansIdx, ansData in
                                                ZStack(alignment: .topTrailing) {
                                                    if let ansImg = UIImage(data: ansData) {
                                                        Image(uiImage: ansImg)
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 84, height: 64)
                                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    }
                                                    Button {
                                                        guard savePreview?.items.indices.contains(currentPreviewIndex) == true,
                                                              savePreview?.items[currentPreviewIndex].answerImageDatas.indices.contains(ansIdx) == true else {
                                                            return
                                                        }
                                                        savePreview?.items[currentPreviewIndex].answerImageDatas.remove(at: ansIdx)
                                                        persistDraftAsync()
                                                    } label: {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundStyle(.white, SnapDrillTheme.gradingRed)
                                                    }
                                                    .accessibilityLabel(String(localized: "Remove Answer Photo"))
                                                }
                                            }
                                        }
                                    }
                                }

                                TextField("Personal note (optional)", text: Binding(
                                    get: { savePreview?.items[currentPreviewIndex].notes ?? "" },
                                    set: {
                                        savePreview?.items[currentPreviewIndex].notes = String($0.prefix(MistakeLimits.maxNotesCharacters))
                                        scheduleDebouncedDraftSave()
                                    }
                                ), axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(.roundedBorder)
                            }
                            .padding(.top, 10)
                        }
                    }

                    // Primary 1-tap Fast Save button (PRD F-27)
                    Button {
                        commitAndDismiss()
                    } label: {
                        Text("Save (\(preview.questionCount))")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(SnapDrillTheme.inkBlue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Save \(preview.questionCount) questions"))
                }
            }
            .padding(SnapDrillTheme.screenPadding)
        }
    }

    // MARK: - Shared Subviews & Helpers

    private var stepProgressHeader: some View {
        HStack(spacing: 6) {
            ForEach(1...3, id: \.self) { idx in
                Capsule()
                    .fill(idx <= step ? SnapDrillTheme.inkBlue : SnapDrillTheme.ruledLine)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, SnapDrillTheme.screenPadding)
        .padding(.vertical, 6)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func pageThumbnailStrip(allowAddingMore: Bool) -> some View {
        if let session {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(session.pages.enumerated()), id: \.element.id) { idx, page in
                        let selected = idx == currentPageIndex
                        Button {
                            currentPageIndex = idx
                            activeBoxID = page.boxes.first?.id
                        } label: {
                            ZStack(alignment: .bottomTrailing) {
                                if let thumb = UIImage(data: page.enhancedImageData) {
                                    Image(uiImage: thumb)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 48, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .strokeBorder(selected ? SnapDrillTheme.inkBlue : SnapDrillTheme.ruledLine, lineWidth: selected ? 2.5 : 1)
                                        )
                                }

                                if step == 2 {
                                    Text("\(page.boxes.count)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(SnapDrillTheme.inkBlue, in: Capsule())
                                        .offset(x: 3, y: 3)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(localized: "Page \(idx + 1)"))
                    }

                    if allowAddingMore && session.pages.count < environment.capturePipeline.maxPhotoCount {
                        if cameraAuthState == .authorized || cameraAuthState == .notDetermined {
                            Button {
                                Task { await openCamera() }
                            } label: {
                                Image(systemName: "camera.badge.ellipsis")
                                    .frame(width: 48, height: 60)
                                    .background(SnapDrillTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 6))
                            }
                            .accessibilityLabel(String(localized: "Capture Another Page"))
                        }

                        PhotosPicker(
                            selection: $selectedPhotoItems,
                            maxSelectionCount: environment.capturePipeline.maxPhotoCount - session.pages.count,
                            matching: .images
                        ) {
                            Image(systemName: "plus.rectangle.on.folder")
                                .frame(width: 48, height: 60)
                                .background(SnapDrillTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 6))
                        }
                        .accessibilityLabel(String(localized: "Import More Photos"))
                    }
                }
                .padding(.horizontal, SnapDrillTheme.screenPadding)
            }
        }
    }

    private func initializeFlow() async {
        SubjectCatalog.ensureSeeded(in: modelContext)
        inkMode = environment.preferences.defaultInkRemovalMode
        selectedSubjectID = environment.preferences.lastSubjectID ?? regularSubjects.first?.id
        cameraAuthState = environment.cameraAccess.authorizationState()

        if let initialSession {
            session = initialSession
            currentPageIndex = 0
            activeBoxID = initialSession.pages.first?.boxes.first?.id
            if let restoredSubject = initialSession.selectedSubjectID {
                selectedSubjectID = restoredSubject
            }
            if initialSession.activeStep >= 3 {
                if let restoredPreview = initialSession.savedPreview, !restoredPreview.items.isEmpty {
                    savePreview = restoredPreview
                    inkMode = restoredPreview.inkRemovalMode
                    currentPreviewIndex = 0
                    step = 3
                } else {
                    await buildPreviewForStep3()
                }
            } else {
                step = max(1, min(2, initialSession.activeStep))
            }
        } else if !hasAutoLaunchedCamera && cameraAuthState == .authorized {
            hasAutoLaunchedCamera = true
            showingCameraPicker = true
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
            step = 1
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
            step = 3
            persistDraftAsync()
        } catch {
            errorMessage = error.localizedDescription
        }
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
        } else if (savePreview?.items[index].customCauseNames.count ?? 0) < MistakeLimits.maxTagsPerMistake {
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

    private func commitAndDismiss() {
        draftSaveDebounceTask?.cancel()
        guard let preview = savePreview else { return }
        guard let subject = regularSubjects.first(where: { $0.id == selectedSubjectID }) ?? regularSubjects.first else {
            errorMessage = CapturePipelineError.subjectRequired.localizedDescription
            return
        }

        do {
            let saved = try environment.saveService.commitSave(preview: preview, subject: subject, in: modelContext)
            environment.preferences.lastSubjectID = subject.id
            Task { await environment.draftStore.clearDraft() }
            environment.showSavedConfirmation(count: saved.count)
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scheduleDebouncedDraftSave() {
        draftSaveDebounceTask?.cancel()
        draftSaveDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            persistDraftAsync()
        }
    }

    private func persistDraftAsync() {
        draftSaveDebounceTask?.cancel()
        guard var current = session else { return }
        current.activeStep = step
        current.selectedSubjectID = selectedSubjectID
        current.savedPreview = step >= 3 ? savePreview : nil
        Task {
            do {
                try await environment.draftStore.saveDraft(current)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
