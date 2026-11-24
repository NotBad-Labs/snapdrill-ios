import CoreGraphics
import Foundation

/// Persists unfinished Step 1/2/3 capture sessions using a lightweight JSON manifest + binary asset files
/// in Application Support (avoiding 10-page inline Base64 bloat while preserving Step 3 metadata, M-01/M-02/M3).
actor CaptureDraftStore: CaptureDraftPersisting {
    private let baseDir: URL
    private let draftFileURL: URL
    private let assetsDirectoryURL: URL

    init(directoryURL: URL? = nil) {
        let dir = directoryURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("SnapDrillDrafts", isDirectory: true)
        self.baseDir = dir
        self.draftFileURL = dir.appendingPathComponent("pending_capture_draft.json")
        self.assetsDirectoryURL = dir.appendingPathComponent("assets", isDirectory: true)
    }

    func saveDraft(_ session: CaptureSession) async throws {
        guard !session.pages.isEmpty else {
            await clearDraft()
            return
        }

        let fm = FileManager.default
        try fm.createDirectory(at: baseDir, withIntermediateDirectories: true)

        let stagingAssetsDir = baseDir.appendingPathComponent("assets-staging-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: stagingAssetsDir, withIntermediateDirectories: true)

        do {
            let pageManifests: [DraftPageManifest] = try session.pages.map { page in
                let rawFile = "\(page.id.uuidString)-raw.bin"
                let corrFile = "\(page.id.uuidString)-corr.bin"
                let enhFile = "\(page.id.uuidString)-enh.bin"
                try page.rawImageData.write(to: stagingAssetsDir.appendingPathComponent(rawFile), options: [.atomic])
                try page.correctedImageData.write(to: stagingAssetsDir.appendingPathComponent(corrFile), options: [.atomic])
                try page.enhancedImageData.write(to: stagingAssetsDir.appendingPathComponent(enhFile), options: [.atomic])

                return DraftPageManifest(
                    id: page.id,
                    rawAssetFilename: rawFile,
                    correctedAssetFilename: corrFile,
                    enhancedAssetFilename: enhFile,
                    corners: page.corners,
                    enhancementMode: page.enhancementMode,
                    boxes: page.boxes
                )
            }

            let previewManifest: DraftSavePreviewManifest?
            if let preview = session.savedPreview {
                let itemManifests: [DraftSaveItemManifest] = try preview.items.map { item in
                    let origFile = "item-\(item.id.uuidString)-orig.bin"
                    let cleanFile = "item-\(item.id.uuidString)-clean.bin"
                    try item.originalImageData.write(to: stagingAssetsDir.appendingPathComponent(origFile), options: [.atomic])
                    try item.cleanedImageData.write(to: stagingAssetsDir.appendingPathComponent(cleanFile), options: [.atomic])

                    var pageFile: String? = nil
                    if let pageData = item.pageImageData {
                        let name = "item-\(item.id.uuidString)-page.bin"
                        try pageData.write(to: stagingAssetsDir.appendingPathComponent(name), options: [.atomic])
                        pageFile = name
                    }

                    var ansFiles: [String] = []
                    for (ansIdx, ansData) in item.answerImageDatas.prefix(MistakeLimits.maxAnswerImages).enumerated() {
                        let name = "item-\(item.id.uuidString)-ans-\(ansIdx).bin"
                        try ansData.write(to: stagingAssetsDir.appendingPathComponent(name), options: [.atomic])
                        ansFiles.append(name)
                    }

                    return DraftSaveItemManifest(
                        id: item.id,
                        pageIndex: item.pageIndex,
                        boxIndex: item.boxIndex,
                        originalAssetFilename: origFile,
                        cleanedAssetFilename: cleanFile,
                        handwritingRemovalSucceeded: item.handwritingRemovalSucceeded,
                        ocrText: item.ocrText,
                        pageAssetFilename: pageFile,
                        cropRectNormalized: item.cropRectNormalized,
                        causes: item.causes,
                        customCauseNames: item.customCauseNames,
                        tagNames: item.tagNames,
                        answerText: item.answerText,
                        answerAssetFilenames: ansFiles,
                        notes: item.notes,
                        sourceTitle: item.sourceTitle
                    )
                }

                previewManifest = DraftSavePreviewManifest(
                    items: itemManifests,
                    inkRemovalMode: preview.inkRemovalMode
                )
            } else {
                previewManifest = nil
            }

            let manifest = DraftManifest(
                id: session.id,
                createdAt: session.createdAt,
                pages: pageManifests,
                activeStep: session.activeStep,
                selectedSubjectID: session.selectedSubjectID,
                savedPreview: previewManifest
            )

            let backupAssetsDir = baseDir.appendingPathComponent("assets-old-\(UUID().uuidString)", isDirectory: true)
            let hadExistingAssets = fm.fileExists(atPath: assetsDirectoryURL.path)
            if hadExistingAssets {
                try fm.moveItem(at: assetsDirectoryURL, to: backupAssetsDir)
            }

            do {
                try fm.moveItem(at: stagingAssetsDir, to: assetsDirectoryURL)
                let manifestData = try JSONEncoder().encode(manifest)
                try manifestData.write(to: draftFileURL, options: [.atomic])
                if hadExistingAssets {
                    try? fm.removeItem(at: backupAssetsDir)
                }
            } catch {
                if !fm.fileExists(atPath: assetsDirectoryURL.path) && hadExistingAssets {
                    try? fm.moveItem(at: backupAssetsDir, to: assetsDirectoryURL)
                }
                throw error
            }
        } catch {
            try? fm.removeItem(at: stagingAssetsDir)
            throw error
        }
    }

    func loadDraft() async -> CaptureSession? {
        let fm = FileManager.default
        guard fm.fileExists(atPath: draftFileURL.path),
              let data = try? Data(contentsOf: draftFileURL) else {
            return nil
        }

        if let manifest = try? JSONDecoder().decode(DraftManifest.self, from: data),
           !manifest.pages.isEmpty {
            var hydratedPages: [CapturePage] = []
            hydratedPages.reserveCapacity(manifest.pages.count)

            for p in manifest.pages {
                guard let raw = try? Data(contentsOf: assetsDirectoryURL.appendingPathComponent(p.rawAssetFilename)),
                      let corr = try? Data(contentsOf: assetsDirectoryURL.appendingPathComponent(p.correctedAssetFilename)),
                      let enh = try? Data(contentsOf: assetsDirectoryURL.appendingPathComponent(p.enhancedAssetFilename)) else {
                    return nil
                }
                hydratedPages.append(
                    CapturePage(
                        id: p.id,
                        rawImageData: raw,
                        correctedImageData: corr,
                        enhancedImageData: enh,
                        corners: p.corners,
                        enhancementMode: p.enhancementMode,
                        boxes: p.boxes
                    )
                )
            }

            var hydratedPreview: CaptureSavePreview? = nil
            if let previewManifest = manifest.savedPreview {
                var hydratedItems: [CaptureSaveItem] = []
                hydratedItems.reserveCapacity(previewManifest.items.count)
                for item in previewManifest.items {
                    guard let orig = try? Data(contentsOf: assetsDirectoryURL.appendingPathComponent(item.originalAssetFilename)),
                          let clean = try? Data(contentsOf: assetsDirectoryURL.appendingPathComponent(item.cleanedAssetFilename)) else {
                        continue
                    }
                    let pageData = item.pageAssetFilename.flatMap {
                        try? Data(contentsOf: assetsDirectoryURL.appendingPathComponent($0))
                    }
                    let answerDatas = item.answerAssetFilenames.compactMap {
                        try? Data(contentsOf: assetsDirectoryURL.appendingPathComponent($0))
                    }
                    hydratedItems.append(
                        CaptureSaveItem(
                            id: item.id,
                            pageIndex: item.pageIndex,
                            boxIndex: item.boxIndex,
                            originalImageData: orig,
                            cleanedImageData: clean,
                            handwritingRemovalSucceeded: item.handwritingRemovalSucceeded,
                            ocrText: item.ocrText,
                            pageImageData: pageData,
                            cropRectNormalized: item.cropRectNormalized,
                            causes: item.causes,
                            customCauseNames: item.customCauseNames,
                            tagNames: item.tagNames,
                            answerText: item.answerText,
                            answerImageDatas: answerDatas,
                            notes: item.notes,
                            sourceTitle: item.sourceTitle
                        )
                    )
                }
                if !hydratedItems.isEmpty {
                    hydratedPreview = CaptureSavePreview(
                        items: hydratedItems,
                        inkRemovalMode: previewManifest.inkRemovalMode
                    )
                }
            }

            return CaptureSession(
                id: manifest.id,
                createdAt: manifest.createdAt,
                pages: hydratedPages,
                activeStep: manifest.activeStep,
                selectedSubjectID: manifest.selectedSubjectID,
                savedPreview: hydratedPreview
            )
        }

        // Fallback compatibility for any legacy inline CaptureSession draft
        if let legacySession = try? JSONDecoder().decode(CaptureSession.self, from: data),
           !legacySession.pages.isEmpty {
            return legacySession
        }
        return nil
    }

    func clearDraft() async {
        let fm = FileManager.default
        if fm.fileExists(atPath: draftFileURL.path) {
            try? fm.removeItem(at: draftFileURL)
        }
        if fm.fileExists(atPath: assetsDirectoryURL.path) {
            try? fm.removeItem(at: assetsDirectoryURL)
        }
    }
}

private struct DraftManifest: Codable {
    let id: UUID
    let createdAt: Date
    let pages: [DraftPageManifest]
    let activeStep: Int
    let selectedSubjectID: UUID?
    let savedPreview: DraftSavePreviewManifest?
}

private struct DraftPageManifest: Codable {
    let id: UUID
    let rawAssetFilename: String
    let correctedAssetFilename: String
    let enhancedAssetFilename: String
    let corners: QuadCorners
    let enhancementMode: ImageEnhancementMode
    let boxes: [CaptureCropBox]
}

private struct DraftSavePreviewManifest: Codable {
    let items: [DraftSaveItemManifest]
    let inkRemovalMode: InkRemovalMode
}

private struct DraftSaveItemManifest: Codable {
    let id: UUID
    let pageIndex: Int
    let boxIndex: Int
    let originalAssetFilename: String
    let cleanedAssetFilename: String
    let handwritingRemovalSucceeded: Bool
    let ocrText: String
    let pageAssetFilename: String?
    let cropRectNormalized: CGRect?
    let causes: [MistakeCause]
    let customCauseNames: [String]
    let tagNames: [String]
    let answerText: String
    let answerAssetFilenames: [String]
    let notes: String
    let sourceTitle: String
}
