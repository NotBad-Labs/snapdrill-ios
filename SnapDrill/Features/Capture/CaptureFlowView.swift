import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// PRD §8.2 — UI 仅依赖 `CapturePipelineServing`（见 `CaptureContracts.swift`）。
struct CaptureFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.sortOrder) private var subjects: [Subject]

    @State private var pipeline: (any CapturePipelineServing)?
    @State private var selectedSubjectID: UUID?

    @State private var step: Step = .pick
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var session: CaptureSession?
    @State private var savePreview: CaptureSavePreview?
    @State private var statusMessage = ""
    @State private var isBusy = false

    @State private var showCameraPicker = false
    @State private var pendingCameraShots: [Data] = []
    @State private var showCameraBatchDialog = false
    @State private var didTryLaunchCamera = false

    private let preferCameraOnAppear: Bool

    init(
        pipeline: (any CapturePipelineServing)? = nil,
        preferCameraOnAppear: Bool = false
    ) {
        _pipeline = State(initialValue: pipeline)
        self.preferCameraOnAppear = preferCameraOnAppear
    }

    private var activePipeline: any CapturePipelineServing {
        pipeline ?? CapturePipelineStub()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                stepIndicator

                switch step {
                case .pick:
                    pickStep
                case .crop:
                    cropStep
                case .box:
                    boxStep
                case .save:
                    saveStep
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(String(localized: "Capture"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Close")) { dismiss() }
                }
                if step != .pick {
                    ToolbarItem(placement: .primaryAction) {
                        Button(step == .save ? String(localized: "Save") : String(localized: "Next")) {
                            Task { await advance() }
                        }
                        .disabled(isBusy)
                    }
                }
            }
            .paperBackground()
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            CaptureCameraPicker(
                onCapture: { data in
                    pendingCameraShots.append(data)
                    showCameraBatchDialog = true
                },
                onCancel: {}
            )
            .ignoresSafeArea()
        }
        .confirmationDialog(
            String(localized: "Camera"),
            isPresented: $showCameraBatchDialog,
            titleVisibility: .visible
        ) {
            if pendingCameraShots.count < activePipeline.maxPhotoCount {
                Button(String(localized: "Take another page")) {
                    showCameraPicker = true
                }
            }
            Button(String(localized: "Continue with \(pendingCameraShots.count) photo(s)")) {
                Task { await beginSessionFromCamera() }
            }
            Button(String(localized: "Discard shots"), role: .destructive) {
                pendingCameraShots = []
            }
        }
        .task {
            if pipeline == nil {
                pipeline = CapturePipelineFactory.makeDefault(modelContext: modelContext)
            }
            if selectedSubjectID == nil {
                selectedSubjectID = subjects.first(where: { !$0.isUncategorizedBucket })?.id
            }
            if preferCameraOnAppear, !didTryLaunchCamera {
                didTryLaunchCamera = true
                await openCameraEntry()
            }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(Step.allCases, id: \.self) { s in
                Capsule()
                    .fill(s == step ? SnapDrillTheme.inkBlue : Color.secondary.opacity(0.25))
                    .frame(height: 4)
            }
        }
    }

    private var pickStep: some View {
        VStack(spacing: 16) {
            Text(String(localized: "Import up to \(activePipeline.maxPhotoCount) photos"))
                .font(.headline)
            PhotosPicker(selection: $pickerItems, maxSelectionCount: activePipeline.maxPhotoCount, matching: .images) {
                Label(String(localized: "Photo library"), systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SnapDrillTheme.inkBlue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Button {
                Task { await openCameraEntry() }
            } label: {
                Label(String(localized: "Take photo"), systemImage: "camera")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(SnapDrillTheme.inkBlue)

            if !pendingCameraShots.isEmpty {
                Text(String(localized: "\(pendingCameraShots.count) shot(s) ready — open camera again or import to continue."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if CameraCaptureAccess.isDeniedOrRestricted {
                Text(String(localized: "Camera access is off. Use Photo library or enable camera in Settings."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(String(localized: "Open Settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .font(.footnote)
            }
        }
        .onChange(of: pickerItems) { _, _ in
            Task { await importFromPicker() }
        }
    }

    private var cropStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Step 1 · Crop & enhance"))
                .font(.title3.weight(.semibold))
            if let session {
                Text(String(localized: "\(session.pages.count) page(s)"))
                Picker(String(localized: "Enhancement"), selection: enhancementBinding) {
                    ForEach(ImageEnhancementMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            Text(String(localized: "Perspective UI lands in Slice 2; pipeline contract is wired."))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var enhancementBinding: Binding<ImageEnhancementMode> {
        Binding(
            get: {
                session?.pages.first?.enhancementMode ?? .enhanced
            },
            set: { newValue in
                guard let session, let pageID = session.pages.first?.id else { return }
                Task {
                    await applyEnhancement(mode: newValue, pageID: pageID)
                }
            }
        )
    }

    private var boxStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Step 2 · Box questions"))
                .font(.title3.weight(.semibold))
            if let session {
                Text(String(localized: "\(session.totalBoxCount) box(es) total"))
                Button(String(localized: "+ Add box on page 1")) {
                    Task { await addBoxOnFirstPage() }
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var saveStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Step 3 · Remove ink & save"))
                .font(.title3.weight(.semibold))
            if let savePreview {
                Text(String(localized: "Ready to save \(savePreview.questionCount) question(s)"))
            }
            if selectableSubjects.isEmpty {
                Text(String(localized: "No subject available — reopen after app seeds catalog."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Picker(String(localized: "Subject"), selection: $selectedSubjectID) {
                    ForEach(selectableSubjects) { subject in
                        Text(subject.name).tag(Optional(subject.id))
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @MainActor
    private func importFromPicker() async {
        isBusy = true
        defer { isBusy = false }
        var data: [Data] = []
        for item in pickerItems {
            if let raw = try? await item.loadTransferable(type: Data.self) {
                data.append(raw)
            }
        }
        guard !data.isEmpty else { return }
        do {
            session = try await activePipeline.beginSession(importedImageData: data)
            session = try await activePipeline.applyDocumentCorrection(session: session!)
            statusMessage = String(localized: "Imported \(data.count) photo(s)")
            step = .crop
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    @MainActor
    private func openCameraEntry() async {
        guard CameraCaptureAccess.isHardwareAvailable else {
            statusMessage = String(localized: "Camera isn’t available here. Use Photo library.")
            return
        }
        guard await CameraCaptureAccess.requestAccessIfNeeded() else {
            statusMessage = String(localized: "Camera access denied. Use Photo library or Settings.")
            return
        }
        showCameraPicker = true
    }

    @MainActor
    private func beginSessionFromCamera() async {
        guard !pendingCameraShots.isEmpty else { return }
        isBusy = true
        defer { isBusy = false }
        let data = pendingCameraShots
        pendingCameraShots = []
        do {
            session = try await activePipeline.beginSession(importedImageData: data)
            session = try await activePipeline.applyDocumentCorrection(session: session!)
            statusMessage = String(localized: "Captured \(data.count) photo(s)")
            step = .crop
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    @MainActor
    private func applyEnhancement(mode: ImageEnhancementMode, pageID: UUID) async {
        guard var session else { return }
        do {
            session = try await activePipeline.setEnhancement(mode: mode, pageID: pageID, in: session)
            self.session = session
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    @MainActor
    private func addBoxOnFirstPage() async {
        guard let pageID = session?.pages.first?.id, var session else { return }
        do {
            session = try await activePipeline.addBox(on: pageID, in: session)
            self.session = session
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    @MainActor
    private func advance() async {
        isBusy = true
        defer { isBusy = false }
        switch step {
        case .pick:
            break
        case .crop:
            step = .box
        case .box:
            guard let session else { return }
            do {
                savePreview = try await activePipeline.buildSavePreview(for: session)
                step = .save
            } catch {
                statusMessage = error.localizedDescription
            }
        case .save:
            guard let savePreview, let subjectID = selectedSubjectID else {
                statusMessage = String(localized: "Choose a subject before saving.")
                return
            }
            do {
                let count = try await activePipeline.commitSave(preview: savePreview, subjectID: subjectID)
                statusMessage = String(localized: "Saved \(count) mistake(s)")
                dismiss()
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }

    private var selectableSubjects: [Subject] {
        subjects.filter { !$0.isUncategorizedBucket }
    }

    private enum Step: Int, CaseIterable {
        case pick = 0
        case crop = 1
        case box = 2
        case save = 3
    }
}