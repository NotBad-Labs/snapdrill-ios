import PhotosUI
import SwiftUI

/// Step 3: Ink-removal preview, per-question metadata, and fast 1-tap save bar.
struct CapturePreviewSaveStepView: View {
    @Binding var savePreview: CaptureSavePreview?
    @Binding var currentPreviewIndex: Int
    @Binding var inkMode: InkRemovalMode
    @Binding var isPeekingOriginal: Bool
    @Binding var selectedSubjectID: UUID?
    @Binding var showOptionalFields: Bool
    @Binding var newTagInput: String
    @Binding var selectedAnswerPhotoItems: [PhotosPickerItem]

    let regularSubjects: [Subject]
    let customCauses: [CustomCause]
    let isDismissingOrSaving: Bool
    let isFullInkModelAvailable: Bool

    let onSelectSubject: () -> Void
    let onOpenEraser: (Int) -> Void
    let onToggleCause: (MistakeCause, Int) -> Void
    let onToggleCustomCause: (String, Int) -> Void
    let onAddTag: () -> Void
    let onRemoveAnswerPhoto: (Int) -> Void
    let onScheduleDebouncedDraftSave: () -> Void
    let onPersistDraft: () -> Void
    let onCommit: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                subjectPickerCard

                if let preview = savePreview, preview.items.indices.contains(currentPreviewIndex) {
                    let item = preview.items[currentPreviewIndex]

                    if preview.items.count > 1 {
                        questionSwitcher(count: preview.items.count)
                    }

                    previewCard(item: item)
                    optionalDetailsCard(item: item)
                }
            }
            .padding(SnapDrillTheme.screenPadding)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let preview = savePreview {
                BottomActionBarContainer {
                    Button(action: onCommit) {
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
                    .disabled(isDismissingOrSaving)
                    .accessibilityLabel(String(localized: "Save \(preview.questionCount) questions"))
                }
            }
        }
    }

    private var subjectPickerCard: some View {
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
                                onSelectSubject()
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
    }

    private func questionSwitcher(count: Int) -> some View {
        HStack {
            Button {
                currentPreviewIndex = max(0, currentPreviewIndex - 1)
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title3)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .disabled(currentPreviewIndex == 0)
            .accessibilityLabel(String(localized: "Previous Question"))

            Spacer()
            Text("Question \(currentPreviewIndex + 1) of \(count)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
            Spacer()

            Button {
                currentPreviewIndex = min(count - 1, currentPreviewIndex + 1)
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title3)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .disabled(currentPreviewIndex >= count - 1)
            .accessibilityLabel(String(localized: "Next Question"))
        }
        .foregroundStyle(SnapDrillTheme.inkBlue)
    }

    /// Returns honest preview status copy so partial colored-ink cleanup never claims full black-pen removal.
    nonisolated static func statusMetadata(
        isPeekingOriginal: Bool,
        inkMode: InkRemovalMode,
        removalSucceeded: Bool,
        isFullInkModelAvailable: Bool
    ) -> (title: String, symbol: String, isHighlighted: Bool) {
        if isPeekingOriginal {
            return (String(localized: "Original"), "photo", false)
        }
        if inkMode == .off {
            return (String(localized: "Enhanced Original"), "info.circle", false)
        }
        if removalSucceeded {
            let title = (inkMode == .autoAll && isFullInkModelAvailable)
                ? String(localized: "Handwriting Removed")
                : String(localized: "Colored Marks Cleaned")
            return (title, "wand.and.stars", true)
        }
        return (String(localized: "Enhanced Original"), "info.circle", false)
    }

    private func previewCard(item: CaptureSaveItem) -> some View {
        PaperCard(padding: 12) {
            VStack(spacing: 10) {
                HStack {
                    let status = Self.statusMetadata(
                        isPeekingOriginal: isPeekingOriginal,
                        inkMode: inkMode,
                        removalSucceeded: item.handwritingRemovalSucceeded,
                        isFullInkModelAvailable: isFullInkModelAvailable
                    )
                    Label(status.title, systemImage: status.symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(status.isHighlighted ? SnapDrillTheme.inkBlue : SnapDrillTheme.inkSecondary)

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
                        .padding(.vertical, 6)
                        .background(isPeekingOriginal ? SnapDrillTheme.inkBlue : SnapDrillTheme.elevatedSurface, in: Capsule())
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Compare Original"))
                    .accessibilityValue(isPeekingOriginal ? String(localized: "Showing Original") : String(localized: "Showing Cleaned"))

                    Button {
                        onOpenEraser(currentPreviewIndex)
                    } label: {
                        Label("Eraser", systemImage: "eraser.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(SnapDrillTheme.inkBlue, in: Capsule())
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Open Manual Eraser"))
                }

                if !item.handwritingRemovalSucceeded && inkMode != .off {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.draw")
                            .foregroundStyle(SnapDrillTheme.inkBlue)
                        Text("Dark pen ink could not be auto-removed safely. Any colored marks were cleaned where possible — tap Eraser to clean remaining spots.")
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
            }
        }
    }

    private func optionalDetailsCard(item: CaptureSaveItem) -> some View {
        PaperCard(padding: 12) {
            DisclosureGroup("Optional Details (Causes, Tags, Answer)", isExpanded: $showOptionalFields) {
                VStack(alignment: .leading, spacing: 12) {
                    causesSelectorSection(item: item)
                    tagsSelectorSection(item: item)

                    TextField("Correct answer / solution (optional)", text: Binding(
                        get: {
                            guard savePreview?.items.indices.contains(currentPreviewIndex) == true else { return "" }
                            return savePreview?.items[currentPreviewIndex].answerText ?? ""
                        },
                        set: {
                            guard savePreview?.items.indices.contains(currentPreviewIndex) == true else { return }
                            savePreview?.items[currentPreviewIndex].answerText = String($0.prefix(MistakeLimits.maxAnswerCharacters))
                            onScheduleDebouncedDraftSave()
                        }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                    .paperInputField()

                    answerPhotosSection(currentAnswerDatas: item.answerImageDatas)

                    TextField("Personal note (optional)", text: Binding(
                        get: {
                            guard savePreview?.items.indices.contains(currentPreviewIndex) == true else { return "" }
                            return savePreview?.items[currentPreviewIndex].notes ?? ""
                        },
                        set: {
                            guard savePreview?.items.indices.contains(currentPreviewIndex) == true else { return }
                            savePreview?.items[currentPreviewIndex].notes = String($0.prefix(MistakeLimits.maxNotesCharacters))
                            onScheduleDebouncedDraftSave()
                        }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                    .paperInputField()
                }
                .padding(.top, 10)
            }
        }
    }

    private func causesSelectorSection(item: CaptureSaveItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Error Causes")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SnapDrillTheme.inkSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(MistakeCause.allCases) { cause in
                        let selected = item.causes.contains(cause)
                        Button {
                            onToggleCause(cause, currentPreviewIndex)
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
                            onToggleCustomCause(custom.name, currentPreviewIndex)
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
        }
    }

    private func tagsSelectorSection(item: CaptureSaveItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Add tag...", text: $newTagInput)
                    .paperInputField()
                Button("Add", action: onAddTag)
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
        }
    }

    @ViewBuilder
    private func answerPhotosSection(currentAnswerDatas: [Data]) -> some View {
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
                    ForEach(IndexedPhotoData.wrap(currentAnswerDatas)) { photo in
                        ZStack(alignment: .topTrailing) {
                            if let ansImg = UIImage(data: photo.data) {
                                Image(uiImage: ansImg)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 84, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            Button {
                                onRemoveAnswerPhoto(photo.index)
                                onPersistDraft()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white, SnapDrillTheme.gradingRed)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityLabel(String(localized: "Remove Answer Photo"))
                        }
                    }
                }
            }
        }
    }
}
