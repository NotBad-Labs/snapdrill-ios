import PhotosUI
import SwiftData
import SwiftUI

/// Detailed mistake inspection screen featuring lossless Cleaned/Original toggle, pinch zoom,
/// manual eraser launch, re-crop, collapsible self-test answer block, and edit sheet (PRD §8.3, AC-04, AC-05).
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

    private var displayedImage: UIImage? {
        let relPath = showOriginalImage
            ? mistake.originalImagePath
            : (mistake.cleanedImagePath ?? mistake.originalImagePath)
        return environment.imageStore.loadImage(relativePath: relPath)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                problemImageCard
                quickActionBar
                masteryCard
                collapsibleAnswerCard
                metadataCard
            }
            .padding(.horizontal, SnapDrillTheme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 108)
        }
        .paperBackground()
        .navigationTitle(mistake.subject?.name ?? String(localized: "Mistake Detail"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }

                Menu {
                    Button {
                        showingPDFPreview = true
                    } label: {
                        Label("Export PDF / Print", systemImage: "doc.richtext")
                    }

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
            }
        }
        .fullScreenCover(isPresented: $showingEraser) {
            if let current = environment.imageStore.loadImage(relativePath: mistake.cleanedImagePath ?? mistake.originalImagePath),
               let original = environment.imageStore.loadImage(relativePath: mistake.originalImagePath) {
                HandwritingEraserView(initialImage: current, originalReferenceImage: original) { edited in
                    try? environment.saveService.saveManualCleanedImage(edited, for: mistake, in: modelContext)
                    showOriginalImage = false
                }
            }
        }
        .sheet(isPresented: $showingRecrop) {
            if let orig = environment.imageStore.loadImage(relativePath: mistake.originalImagePath) {
                SingleMistakeRecropSheet(sourceImage: orig) { normalizedRect in
                    Task {
                        try? await environment.saveService.recropMistake(
                            mistake,
                            normalizedRect: normalizedRect,
                            mode: environment.preferences.defaultInkRemovalMode,
                            in: modelContext
                        )
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
                defaultTitle: mistake.subject?.name ?? String(localized: "Mistake Sheet")
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

                if let displayedImage {
                    ZoomableImageView(image: displayedImage)
                        .frame(height: 280)
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(SnapDrillTheme.cardSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(SnapDrillTheme.ruledLine, lineWidth: 1))
            }

            Button {
                showingRecrop = true
            } label: {
                Label("Re-crop", systemImage: "crop")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SnapDrillTheme.inkBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(SnapDrillTheme.cardSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(SnapDrillTheme.ruledLine, lineWidth: 1))
            }

            Button {
                showingPDFPreview = true
            } label: {
                Label("PDF", systemImage: "doc.richtext")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(SnapDrillTheme.inkBlue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .buttonStyle(.plain)
    }

    private var masteryCard: some View {
        PaperCard(padding: 14) {
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
        PaperCard(padding: 14) {
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
                }
                .buttonStyle(.plain)

                if showAnswerBlock {
                    RuledDivider()

                    if mistake.answerText.isEmpty && mistake.answerImagePaths.isEmpty {
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

                        if !mistake.answerImagePaths.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(mistake.answerImagePaths, id: \.self) { path in
                                        if let img = environment.imageStore.loadImage(relativePath: path) {
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
        PaperCard(padding: 14) {
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
                    if mistake.tags.isEmpty {
                        Text("No tags")
                            .font(.subheadline)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(mistake.tags) { tag in
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

/// Modal editor for updating subject, causes, tags, answer text/images, and notes (PRD §8.3, §8.6).
struct MistakeEditSheet: View {
    @Bindable var mistake: MistakeItem

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var environment

    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Query(sort: \MistakeTag.name) private var allTags: [MistakeTag]
    @Query(sort: \CustomCause.sortOrder) private var customCauses: [CustomCause]

    @State private var selectedSubjectID: UUID?
    @State private var sourceTitle = ""
    @State private var selectedCauses: Set<MistakeCause> = []
    @State private var selectedCustomCauses: Set<String> = []
    @State private var selectedTagNames: Set<String> = []
    @State private var newTagInput = ""
    @State private var answerText = ""
    @State private var notes = ""
    @State private var pickedAnswerItems: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Subject & Source") {
                    Picker("Subject", selection: $selectedSubjectID) {
                        ForEach(subjects.filter { !$0.isUncategorizedBucket }) { subj in
                            Text(subj.name).tag(Optional(subj.id))
                        }
                    }

                    TextField("Source (e.g. Midterm P.12)", text: $sourceTitle)
                }

                Section("Error Causes") {
                    ForEach(MistakeCause.allCases) { cause in
                        let selected = selectedCauses.contains(cause)
                        Button {
                            if selected { selectedCauses.remove(cause) } else { selectedCauses.insert(cause) }
                        } label: {
                            HStack {
                                Text(cause.localizedTitle).foregroundStyle(SnapDrillTheme.inkBlack)
                                Spacer()
                                if selected { Image(systemName: "checkmark").foregroundStyle(SnapDrillTheme.inkBlue) }
                            }
                        }
                    }

                    ForEach(customCauses) { custom in
                        let selected = selectedCustomCauses.contains(custom.name)
                        Button {
                            if selected { selectedCustomCauses.remove(custom.name) } else { selectedCustomCauses.insert(custom.name) }
                        } label: {
                            HStack {
                                Text(custom.name).foregroundStyle(SnapDrillTheme.inkBlack)
                                Spacer()
                                if selected { Image(systemName: "checkmark").foregroundStyle(SnapDrillTheme.inkBlue) }
                            }
                        }
                    }
                }

                Section("Tags (max \(MistakeLimits.maxTagsPerMistake))") {
                    HStack {
                        TextField("Add tag (e.g. Chapter 3)", text: $newTagInput)
                        Button("Add") {
                            let clean = newTagInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !clean.isEmpty, selectedTagNames.count < MistakeLimits.maxTagsPerMistake else { return }
                            selectedTagNames.insert(clean)
                            newTagInput = ""
                        }
                        .disabled(newTagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    ForEach(allTags) { tag in
                        let selected = selectedTagNames.contains(tag.name)
                        Button {
                            if selected {
                                selectedTagNames.remove(tag.name)
                            } else if selectedTagNames.count < MistakeLimits.maxTagsPerMistake {
                                selectedTagNames.insert(tag.name)
                            }
                        } label: {
                            HStack {
                                Text("#\(tag.name)").foregroundStyle(SnapDrillTheme.inkBlack)
                                Spacer()
                                if selected { Image(systemName: "checkmark").foregroundStyle(SnapDrillTheme.inkBlue) }
                            }
                        }
                    }
                }

                Section("Answer & Explanation (\(answerText.count)/\(MistakeLimits.maxAnswerCharacters))") {
                    TextEditor(text: $answerText)
                        .frame(minHeight: 90)
                        .onChange(of: answerText) { _, newValue in
                            if newValue.count > MistakeLimits.maxAnswerCharacters {
                                answerText = String(newValue.prefix(MistakeLimits.maxAnswerCharacters))
                            }
                        }

                    let attachedAnswerCount = mistake.answerImagePaths.count
                    if attachedAnswerCount < MistakeLimits.maxAnswerImages {
                        PhotosPicker(
                            selection: $pickedAnswerItems,
                            maxSelectionCount: MistakeLimits.maxAnswerImages - attachedAnswerCount,
                            matching: .images
                        ) {
                            Label("Attach Answer Photos (\(attachedAnswerCount)/\(MistakeLimits.maxAnswerImages))", systemImage: "photo.badge.plus")
                        }
                    }

                    if !mistake.answerImagePaths.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(mistake.answerImagePaths, id: \.self) { path in
                                    ZStack(alignment: .topTrailing) {
                                        if let img = environment.imageStore.loadImage(relativePath: path) {
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 96, height: 72)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        Button {
                                            mistake.answerImagePaths.removeAll { $0 == path }
                                            environment.imageStore.deleteFile(relativePath: path)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white, SnapDrillTheme.gradingRed)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Notes (\(notes.count)/\(MistakeLimits.maxNotesCharacters))") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .onChange(of: notes) { _, newValue in
                            if newValue.count > MistakeLimits.maxNotesCharacters {
                                notes = String(newValue.prefix(MistakeLimits.maxNotesCharacters))
                            }
                        }
                }
            }
            .navigationTitle(String(localized: "Edit Mistake"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                selectedSubjectID = mistake.subject?.id
                sourceTitle = mistake.sourceTitle
                selectedCauses = Set(mistake.causes)
                selectedCustomCauses = Set(mistake.customCauseNames)
                selectedTagNames = Set(mistake.tags.map(\.name))
                answerText = mistake.answerText
                notes = mistake.notes
            }
            .onChange(of: pickedAnswerItems) { _, newItems in
                Task {
                    for pickerItem in newItems {
                        if let data = try? await pickerItem.loadTransferable(type: Data.self),
                           let uiImg = UIImage(data: data) {
                            try? environment.saveService.appendAnswerImage(uiImg, to: mistake, in: modelContext)
                        }
                    }
                    pickedAnswerItems = []
                }
            }
        }
    }

    private func saveChanges() {
        if let sid = selectedSubjectID, let found = subjects.first(where: { $0.id == sid }) {
            mistake.subject = found
        }
        mistake.sourceTitle = sourceTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        mistake.causes = Array(selectedCauses)
        mistake.customCauseNames = Array(selectedCustomCauses).sorted()
        mistake.answerText = String(answerText.prefix(MistakeLimits.maxAnswerCharacters))
        mistake.notes = String(notes.prefix(MistakeLimits.maxNotesCharacters))

        // Resolve or create tags up to maxTagsPerMistake
        var resolved: [MistakeTag] = []
        for name in Array(selectedTagNames).sorted().prefix(MistakeLimits.maxTagsPerMistake) {
            if let existing = allTags.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                resolved.append(existing)
            } else {
                let newTag = MistakeTag(name: name)
                modelContext.insert(newTag)
                resolved.append(newTag)
            }
        }
        mistake.tags = resolved
        try? modelContext.save()
        dismiss()
    }
}

/// Interactive single-box re-crop modal launched from MistakeDetailView (PRD §8.3, AC-05).
struct SingleMistakeRecropSheet: View {
    let sourceImage: UIImage
    let onConfirm: (CGRect) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var cropBox = CaptureCropBox(normalizedRect: CGRect(x: 0.05, y: 0.05, width: 0.90, height: 0.90))

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Drag corners to adjust the problem boundary")
                    .font(.caption)
                    .foregroundStyle(SnapDrillTheme.inkSecondary)

                GeometryReader { geo in
                    let imageFrame = AspectFitCalculator.fittedRect(
                        imageSize: sourceImage.size,
                        in: geo.size
                    )

                    ZStack {
                        Image(uiImage: sourceImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width, height: geo.size.height)

                        CropBoxOverlayItem(
                            box: cropBox,
                            indexNumber: 1,
                            isActive: true,
                            imageFrame: imageFrame,
                            onSelect: {},
                            onUpdate: { cropBox = $0 }
                        )
                    }
                }
                .padding(16)
            }
            .paperBackground()
            .navigationTitle(String(localized: "Re-crop Question"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onConfirm(cropBox.normalizedRect)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
