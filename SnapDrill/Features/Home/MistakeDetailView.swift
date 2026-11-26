import PhotosUI
import SwiftData
import SwiftUI

/// Detailed mistake inspection screen featuring lossless Cleaned/Original toggle, pinch zoom,
/// full-page re-crop, manual eraser, collapsible self-test answer block, and edit sheet (PRD §8.3, AC-04, AC-05).
struct MistakeDetailView: View {
    @Bindable var mistake: MistakeItem

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var environment

    @State private var showOriginalImage = false
    @State private var showAnswerBlock = false
    @State private var showingEraser = false
    @State private var showingRecrop = false
    @State private var showingEditSheet = false
    @State private var showingPDFPreview = false
    @State private var shareImageItem: UIImage?
    @State private var errorMessage: String?

    private var displayedImage: UIImage? {
        let data = showOriginalImage
            ? mistake.resolvedOriginalImageData(imageStore: environment.imageStore)
            : mistake.resolvedCleanedImageData(imageStore: environment.imageStore)
        return data.flatMap { UIImage(data: $0) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                problemImageCard
                collapsibleAnswerCard
                studyRecordCard
            }
            .padding(.horizontal, SnapDrillTheme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .paperBackground()
        .navigationTitle(mistake.subject?.name ?? String(localized: "Mistake Detail"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingPDFPreview = true
                } label: {
                    Image(systemName: "printer")
                }
                .accessibilityLabel(String(localized: "Export PDF / Print"))

                Button("Edit") {
                    showingEditSheet = true
                }
                .accessibilityLabel(String(localized: "Edit Mistake"))

                Menu {
                    if let img = displayedImage {
                        Button {
                            shareImageItem = img
                        } label: {
                            Label("Share Problem Image", systemImage: "square.and.arrow.up")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        environment.scheduleSoftDelete([mistake], in: modelContext)
                        dismiss()
                    } label: {
                        Label("Delete Mistake", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel(String(localized: "More Actions"))
            }
        }
        .fullScreenCover(isPresented: $showingEraser) {
            if let currentData = mistake.resolvedCleanedImageData(imageStore: environment.imageStore),
               let current = UIImage(data: currentData),
               let origData = mistake.resolvedOriginalImageData(imageStore: environment.imageStore),
               let original = UIImage(data: origData) {
                HandwritingEraserView(initialImage: current, originalReferenceImage: original) { edited in
                    do {
                        try environment.saveService.saveManualCleanedImage(edited, for: mistake, in: modelContext)
                        showOriginalImage = false
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .sheet(isPresented: $showingRecrop) {
            if let pageData = mistake.strictPageImageData(imageStore: environment.imageStore),
               let pageImg = UIImage(data: pageData) {
                SingleMistakeRecropSheet(
                    sourceImage: pageImg,
                    initialNormalizedRect: mistake.cropRectNormalized ?? CGRect(x: 0.05, y: 0.05, width: 0.90, height: 0.90)
                ) { normalizedRect in
                    Task {
                        do {
                            try await environment.saveService.recropMistake(
                                mistake,
                                normalizedRect: normalizedRect,
                                mode: environment.preferences.defaultInkRemovalMode,
                                in: modelContext
                            )
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            MistakeEditSheet(mistake: mistake)
        }
        .sheet(isPresented: $showingPDFPreview) {
            PDFExportPreviewView(
                mistakes: [mistake],
                defaultTitle: PDFExportOptions.defaultTitle(subjectName: mistake.subject?.name)
            )
        }
        .sheet(isPresented: Binding(
            get: { shareImageItem != nil },
            set: { if !$0 { shareImageItem = nil } }
        )) {
            if let shareImageItem {
                ActivityShareSheet(items: [shareImageItem])
            }
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

    // MARK: - Cards

    private var problemImageCard: some View {
        PaperCard(padding: 10) {
            VStack(spacing: 10) {
                HStack {
                    if !mistake.handwritingRemovalSucceeded {
                        Label("Enhanced Original", systemImage: "info.circle")
                            .font(.caption2)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                    } else {
                        Label(
                            showOriginalImage ? String(localized: "Original Photo") : String(localized: "Handwriting Removed"),
                            systemImage: showOriginalImage ? "photo" : "wand.and.stars"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(showOriginalImage ? SnapDrillTheme.inkSecondary : SnapDrillTheme.inkBlue)
                    }

                    Spacer()

                    Picker("Image Version", selection: $showOriginalImage) {
                        Text("Cleaned").tag(false)
                        Text("Original").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 170)
                }

                if !mistake.handwritingRemovalSucceeded && !showOriginalImage {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.draw")
                            .foregroundStyle(SnapDrillTheme.inkBlue)
                        Text("Auto-clean kept dark ink untouched. Tap Manual Eraser to clean handwritten spots.")
                            .font(.caption2)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                        Spacer()
                    }
                    .padding(8)
                    .background(SnapDrillTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 8))
                }

                if let displayedImage {
                    ZoomableImageView(
                        image: displayedImage,
                        accessibilityDescription: showOriginalImage
                            ? String(localized: "Original Question Image")
                            : String(localized: "Cleaned Question Image")
                    )
                    .aspectRatio(adaptiveImageAspectRatio(for: displayedImage), contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(SnapDrillTheme.elevatedSurface)
                        .frame(height: 200)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(SnapDrillTheme.inkSecondary)
                        }
                }

                RuledDivider()

                quickActionBar
            }
        }
    }

    /// Keeps the problem image close to its true shape (no fixed 280pt box) while avoiding extreme heights.
    private func adaptiveImageAspectRatio(for image: UIImage) -> CGFloat {
        guard image.size.width > 0, image.size.height > 0 else { return 1.4 }
        return min(max(image.size.width / image.size.height, 0.8), 2.0)
    }

    private var studyRecordCard: some View {
        PaperCard(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                masteryCard
                RuledDivider()
                metadataCard
            }
        }
    }

    private var quickActionBar: some View {
        HStack(spacing: 10) {
            Button {
                showingEraser = true
            } label: {
                Label("Manual Eraser", systemImage: "eraser.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SnapDrillTheme.inkBlack)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(SnapDrillTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(String(localized: "Open Manual Eraser"))

            Button {
                if mistake.strictPageImageData(imageStore: environment.imageStore) != nil {
                    showingRecrop = true
                } else {
                    errorMessage = RecropError.missingSourceImage.localizedDescription
                }
            } label: {
                Label("Re-crop", systemImage: "crop")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SnapDrillTheme.inkBlack)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(SnapDrillTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(String(localized: "Re-crop Question"))

        }
        .buttonStyle(.plain)
    }

    private var masteryCard: some View {
        Group {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Mastery")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SnapDrillTheme.inkBlack)
                    Spacer()
                    if mistake.reviewCount > 0 {
                        Text("Reviewed \(mistake.reviewCount)×")
                            .font(.caption)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                    }
                }

                Picker("Mastery", selection: Binding(
                    get: { mistake.mastery },
                    set: { newValue in
                        mistake.mastery = newValue
                        try? modelContext.save()
                    }
                )) {
                    ForEach(MasteryLevel.allCases) { level in
                        Text(level.localizedTitle).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var collapsibleAnswerCard: some View {
        let resolvedAnswerDatas = mistake.resolvedAnswerImageDatas(imageStore: environment.imageStore)

        return PaperCard(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAnswerBlock.toggle()
                    }
                } label: {
                    HStack {
                        Label("Answer & Explanation", systemImage: showAnswerBlock ? "eye.fill" : "eye.slash")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SnapDrillTheme.inkBlack)
                        Spacer()
                        Text(showAnswerBlock ? String(localized: "Hide") : String(localized: "Tap to Reveal"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(SnapDrillTheme.inkBlue)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if showAnswerBlock {
                    RuledDivider()

                    if mistake.answerText.isEmpty && resolvedAnswerDatas.isEmpty {
                        Text("No answer recorded yet. Tap Edit to add a solution or photo.")
                            .font(.subheadline)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                    } else {
                        if !mistake.answerText.isEmpty {
                            Text(mistake.answerText)
                                .font(.subheadline)
                                .foregroundStyle(SnapDrillTheme.inkBlack)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if !resolvedAnswerDatas.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(IndexedPhotoData.wrap(resolvedAnswerDatas)) { photo in
                                        if let img = UIImage(data: photo.data) {
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 150, height: 110)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var metadataCard: some View {
        Group {
            VStack(alignment: .leading, spacing: 10) {
                if !mistake.sourceTitle.isEmpty {
                    HStack {
                        Text("Source")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                        Spacer()
                        Text(mistake.sourceTitle)
                            .font(.subheadline)
                            .foregroundStyle(SnapDrillTheme.inkBlack)
                    }
                    RuledDivider()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Causes")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SnapDrillTheme.inkSecondary)

                    if mistake.causes.isEmpty && mistake.customCauseNames.isEmpty {
                        Text("None selected")
                            .font(.subheadline)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(mistake.causes) { cause in
                                    Text(cause.localizedTitle)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(SnapDrillTheme.gradingRed)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(SnapDrillTheme.gradingRedSoft, in: Capsule())
                                }
                                ForEach(mistake.customCauseNames, id: \.self) { custom in
                                    Text(custom)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(SnapDrillTheme.gradingRed)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(SnapDrillTheme.gradingRedSoft, in: Capsule())
                                }
                            }
                        }
                    }
                }

                RuledDivider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tags")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                    if mistake.tagList.isEmpty {
                        Text("No tags")
                            .font(.subheadline)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(mistake.tagList) { tag in
                                    Text("#\(tag.name)")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(SnapDrillTheme.inkBlue)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(SnapDrillTheme.inkBlueSoft, in: Capsule())
                                }
                            }
                        }
                    }
                }

                if !mistake.notes.isEmpty {
                    RuledDivider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                        Text(mistake.notes)
                            .font(.subheadline)
                            .foregroundStyle(SnapDrillTheme.inkBlack)
                    }
                }

                RuledDivider()

                HStack {
                    Text("Captured")
                        .font(.caption)
                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                    Spacer()
                    Text(mistake.createdAt.formatted(date: .long, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                }
            }
        }
    }
}
