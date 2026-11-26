import PhotosUI
import SwiftData
import SwiftUI

/// Modal editor for updating subject, causes, tags, answer text/images, and notes (PRD §8.3, §8.6).
struct MistakeEditSheet: View {
    @Bindable var mistake: MistakeItem

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var environment

    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]
    @Query(sort: \MistakeTag.name) private var allTags: [MistakeTag]
    @Query(sort: \CustomCause.sortOrder) private var customCauses: [CustomCause]

    private struct EditableAnswerSlot: Identifiable {
        let id: UUID
        var path: String?
        var data: Data?
    }

    @State private var selectedSubjectID: UUID?
    @State private var sourceTitle = ""
    @State private var selectedCauses: Set<MistakeCause> = []
    @State private var selectedCustomCauses: Set<String> = []
    @State private var selectedTagNames: Set<String> = []
    @State private var newTagInput = ""
    @State private var answerText = ""
    @State private var notes = ""
    @State private var pickedAnswerItems: [PhotosPickerItem] = []
    @State private var editableAnswerSlots: [EditableAnswerSlot] = []
    @State private var didModifyAnswerSlots = false
    @State private var stagedDeletedAnswerPaths: Set<String> = []
    @State private var editErrorMessage: String?

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
                            if selected {
                                selectedCustomCauses.remove(custom.name)
                            } else if selectedCustomCauses.count < MistakeLimits.maxCustomCausesPerMistake {
                                selectedCustomCauses.insert(custom.name)
                            }
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

                    let attachedAnswerCount = editableAnswerSlots.count
                    if attachedAnswerCount < MistakeLimits.maxAnswerImages {
                        PhotosPicker(
                            selection: $pickedAnswerItems,
                            maxSelectionCount: MistakeLimits.maxAnswerImages - attachedAnswerCount,
                            matching: .images
                        ) {
                            Label("Attach Answer Photos (\(attachedAnswerCount)/\(MistakeLimits.maxAnswerImages))", systemImage: "photo.badge.plus")
                        }
                    }

                    if !editableAnswerSlots.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(editableAnswerSlots.enumerated()), id: \.element.id) { slotIndex, slot in
                                    let hasSubsequentUnhydrated = editableAnswerSlots
                                        .dropFirst(slotIndex + 1)
                                        .contains { $0.data == nil }

                                    ZStack(alignment: .topTrailing) {
                                        if let data = slot.data, let img = UIImage(data: data) {
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 96, height: 72)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(SnapDrillTheme.elevatedSurface)
                                                .frame(width: 96, height: 72)
                                                .overlay {
                                                    VStack(spacing: 4) {
                                                        ProgressView()
                                                            .controlSize(.small)
                                                        Text("Syncing...")
                                                            .font(.caption2)
                                                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                                                    }
                                                }
                                        }
                                        Button {
                                            editableAnswerSlots.removeAll { $0.id == slot.id }
                                            didModifyAnswerSlots = true
                                            if let path = slot.path {
                                                stagedDeletedAnswerPaths.insert(path)
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(
                                                    .white,
                                                    hasSubsequentUnhydrated ? SnapDrillTheme.inkSecondary : SnapDrillTheme.gradingRed
                                                )
                                                .frame(width: 44, height: 44)
                                                .contentShape(Rectangle())
                                        }
                                        .disabled(hasSubsequentUnhydrated)
                                        .accessibilityLabel(String(localized: "Remove Answer Photo"))
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
            .scrollContentBackground(.hidden)
            .paperBackground()
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
                selectedTagNames = Set(mistake.tagList.map(\.name))
                answerText = mistake.answerText
                notes = mistake.notes
                let slotCount = max(
                    mistake.answerImagePaths.count,
                    [mistake.answerImageData0, mistake.answerImageData1, mistake.answerImageData2].compactMap { $0 }.count
                )
                editableAnswerSlots = (0..<min(MistakeLimits.maxAnswerImages, slotCount)).compactMap { idx in
                    let path = mistake.answerImagePaths.indices.contains(idx) ? mistake.answerImagePaths[idx] : nil
                    let data = mistake.resolvedAnswerImageData(at: idx, imageStore: environment.imageStore)
                    guard path != nil || data != nil else { return nil }
                    return EditableAnswerSlot(id: UUID(), path: path, data: data)
                }
                stagedDeletedAnswerPaths.removeAll()
                didModifyAnswerSlots = false
            }
            .onChange(of: pickedAnswerItems) { _, newItems in
                guard !newItems.isEmpty else { return }
                Task {
                    for pickerItem in newItems {
                        guard editableAnswerSlots.count < MistakeLimits.maxAnswerImages else { break }
                        if let data = try? await pickerItem.loadTransferable(type: Data.self),
                           UIImage(data: data) != nil {
                            editableAnswerSlots.append(EditableAnswerSlot(id: UUID(), path: nil, data: data))
                            didModifyAnswerSlots = true
                        }
                    }
                    pickedAnswerItems = []
                }
            }
            .alert("Notice", isPresented: Binding(
                get: { editErrorMessage != nil },
                set: { if !$0 { editErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(editErrorMessage ?? "")
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
        mistake.tagList = resolved

        var newlyWrittenPaths: [String] = []
        do {
            if didModifyAnswerSlots {
                newlyWrittenPaths = try environment.saveService.applyAnswerImageEdits(
                    slots: editableAnswerSlots.map { ($0.path, $0.data) },
                    to: mistake
                )
            }
            try modelContext.save()
            for path in stagedDeletedAnswerPaths {
                environment.imageStore.deleteFile(relativePath: path)
            }
            dismiss()
        } catch {
            modelContext.rollback()
            for relPath in newlyWrittenPaths {
                environment.imageStore.deleteFile(relativePath: relPath)
            }
            editErrorMessage = error.localizedDescription
        }
    }
}

/// Interactive single-box re-crop modal launched from MistakeDetailView over the preserved full page (PRD §8.3, AC-05, M-04).
struct SingleMistakeRecropSheet: View {
    let sourceImage: UIImage
    let initialNormalizedRect: CGRect
    let onConfirm: (CGRect) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var cropBox: CaptureCropBox

    init(sourceImage: UIImage, initialNormalizedRect: CGRect, onConfirm: @escaping (CGRect) -> Void) {
        self.sourceImage = sourceImage
        self.initialNormalizedRect = initialNormalizedRect
        self.onConfirm = onConfirm
        _cropBox = State(initialValue: CaptureCropBox(normalizedRect: initialNormalizedRect))
    }

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
                    .coordinateSpace(name: MultiBoxCropOverlay.canvasSpaceName)
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
