import PhotosUI
import SwiftData
import SwiftUI

/// PRD §8.2 — UI 仅依赖 `CapturePipelineServing`（见 `CaptureContracts.swift`）。
struct CaptureFlowView: View {
    @Environment(\.dismiss) private var dismiss

    private let pipeline: any CapturePipelineServing

    @State private var step: Step = .pick
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var session: CaptureSession?
    @State private var savePreview: CaptureSavePreview?
    @State private var statusMessage = ""
    @State private var isBusy = false

    init(pipeline: (any CapturePipelineServing)? = nil) {
        self.pipeline = pipeline ?? CapturePipelineFactory.makeDefault()
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
            Text(String(localized: "Import up to \(pipeline.maxPhotoCount) photos"))
                .font(.headline)
            PhotosPicker(selection: $pickerItems, maxSelectionCount: pipeline.maxPhotoCount, matching: .images) {
                Label(String(localized: "Photo library"), systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SnapDrillTheme.inkBlue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Button {
                Task { await beginWithPlaceholderCamera() }
            } label: {
                Label(String(localized: "Open camera (Slice 2)"), systemImage: "camera")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
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
            Text(String(localized: "Subject picker + LibrarySave in Slice 2"))
                .font(.footnote)
                .foregroundStyle(.secondary)
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
            session = try await pipeline.beginSession(importedImageData: data)
            session = try await pipeline.applyDocumentCorrection(session: session!)
            statusMessage = String(localized: "Imported \(data.count) photo(s)")
            step = .crop
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    @MainActor
    private func beginWithPlaceholderCamera() async {
        statusMessage = String(localized: "Camera defers to Slice 2 — import a photo to continue.")
    }

    @MainActor
    private func applyEnhancement(mode: ImageEnhancementMode, pageID: UUID) async {
        guard var session else { return }
        do {
            session = try await pipeline.setEnhancement(mode: mode, pageID: pageID, in: session)
            self.session = session
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    @MainActor
    private func addBoxOnFirstPage() async {
        guard let pageID = session?.pages.first?.id, var session else { return }
        do {
            session = try await pipeline.addBox(on: pageID, in: session)
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
                savePreview = try await pipeline.buildSavePreview(for: session)
                step = .save
            } catch {
                statusMessage = error.localizedDescription
            }
        case .save:
            guard let savePreview else { return }
            do {
                let count = try await pipeline.commitSave(preview: savePreview, subjectID: UUID())
                statusMessage = String(localized: "Saved \(count) (stub — Slice 2 persists)")
                dismiss()
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }

    private enum Step: Int, CaseIterable {
        case pick = 0
        case crop = 1
        case box = 2
        case save = 3
    }
}