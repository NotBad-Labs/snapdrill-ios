import SwiftData
import UIKit
import XCTest
@testable import SnapDrill

@MainActor
final class CloudKitAndRecoveryTests: XCTestCase {
    private func makeTestImageData(color: UIColor, size: CGSize = CGSize(width: 400, height: 300)) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }.jpegData(compressionQuality: 0.9)!
    }

    func testCloudKitRequestedContainerGracefullyFallsBackOrOpensWithoutRecoveryTrap() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("SnapDrillCK-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let storeURL = tempDir.appendingPathComponent("SnapDrill.sqlite")

        let localResult = ModelContainerFactory.makeContainer(cloudKitRequested: false, storeURL: storeURL)
        XCTAssertNotNil(localResult.container)
        XCTAssertEqual(localResult.syncStatus, .localOnly)

        // Even when CloudKit entitlement/account is missing on unsigned simulator, factory must fall back to local instead of failing open
        let ckResult = ModelContainerFactory.makeContainer(cloudKitRequested: true, storeURL: storeURL)
        XCTAssertNotNil(ckResult.container)
        XCTAssertNil(ckResult.errorDescription)
    }

    func testCrossDeviceExternalStorageHydrationWhenLocalFilesMissing() throws {
        let schema = ModelContainerFactory.schema
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let emptyImageDir = FileManager.default.temporaryDirectory.appendingPathComponent("SnapDrillHydrate-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: emptyImageDir) }
        let freshStore = MistakeImageStore(rootDirectory: emptyImageDir)

        let origBytes = makeTestImageData(color: .systemGray6)
        let cleanBytes = makeTestImageData(color: .white)
        let pageBytes = makeTestImageData(color: .systemYellow, size: CGSize(width: 600, height: 800))
        let ansBytes0 = makeTestImageData(color: .systemBlue, size: CGSize(width: 240, height: 180))
        let ansBytes1 = makeTestImageData(color: .systemGreen, size: CGSize(width: 240, height: 180))

        // Simulate CloudKit delivering paths + @Attribute(.externalStorage) bytes to a second device with no local files yet
        let syncedMistake = MistakeItem(
            originalImagePath: "orig/synced.jpg",
            cleanedImagePath: "clean/synced.jpg",
            pageImagePath: "page/synced.jpg",
            handwritingRemovalSucceeded: true,
            originalImageData: origBytes,
            cleanedImageData: cleanBytes,
            pageImageData: pageBytes
        )
        syncedMistake.answerImagePaths = ["ans/0.jpg", "ans/1.jpg"]
        syncedMistake.setSyncedAnswerImageDatas([ansBytes0, ansBytes1])
        context.insert(syncedMistake)
        try context.save()

        XCTAssertNil(freshStore.loadData(relativePath: "orig/synced.jpg"))

        XCTAssertEqual(syncedMistake.resolvedOriginalImageData(imageStore: freshStore), origBytes)
        XCTAssertEqual(syncedMistake.resolvedCleanedImageData(imageStore: freshStore), cleanBytes)
        XCTAssertEqual(syncedMistake.resolvedPageImageData(imageStore: freshStore), pageBytes)
        XCTAssertEqual(syncedMistake.resolvedAnswerImageDatas(imageStore: freshStore).count, 2)

        // Verify local cache hydrated lazily after access
        XCTAssertEqual(freshStore.loadData(relativePath: "orig/synced.jpg"), origBytes)
        XCTAssertEqual(freshStore.loadData(relativePath: "ans/1.jpg"), ansBytes1)
    }

    func testCommitSaveRollbackRemovesNewTagsAndFilesOnFailure() throws {
        let schema = ModelContainerFactory.schema
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("SnapDrillRollback-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let store = MistakeImageStore(rootDirectory: tempDir)
        let service = LibrarySaveService(imageStore: store, textRecognizer: { _ in "mock ocr" })

        let subject = Subject(name: "Math")
        context.insert(subject)
        try context.save()

        // Create a collision file at "orig" (a regular file instead of directory) to force disk write failure mid-commit
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try Data([0x00]).write(to: tempDir.appendingPathComponent("orig"))

        let preview = CaptureSavePreview(
            items: [
                CaptureSaveItem(
                    id: UUID(),
                    pageIndex: 0,
                    boxIndex: 0,
                    originalImageData: makeTestImageData(color: .white),
                    cleanedImageData: makeTestImageData(color: .white),
                    handwritingRemovalSucceeded: false,
                    ocrText: "test",
                    pageImageData: makeTestImageData(color: .lightGray),
                    tagNames: ["ShouldRollbackTag"]
                )
            ],
            inkRemovalMode: .autoAll
        )

        XCTAssertThrowsError(try service.commitSave(preview: preview, subject: subject, in: context))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<MistakeItem>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<MistakeTag>()), 0)
        let pageFiles = (try? FileManager.default.contentsOfDirectory(atPath: tempDir.appendingPathComponent("page").path)) ?? []
        XCTAssertTrue(pageFiles.isEmpty)
    }

    func testFullPageRecropAndSharedPageRetentionOnDelete() async throws {
        let schema = ModelContainerFactory.schema
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("SnapDrillRecrop-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let store = MistakeImageStore(rootDirectory: tempDir)
        let service = LibrarySaveService(imageStore: store, textRecognizer: { _ in "mock ocr" })

        let subject = Subject(name: "Physics")
        context.insert(subject)
        try context.save()

        // Full page image: upper half white, lower half blue
        let pageImg = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 800)).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 600, height: 400))
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 400, width: 600, height: 400))
        }.jpegData(compressionQuality: 0.9)!

        let upperCrop = CapturePipelineLive.cropImageData(pageImg, normalizedRect: CGRect(x: 0.05, y: 0.05, width: 0.9, height: 0.35))!
        let lowerCrop = CapturePipelineLive.cropImageData(pageImg, normalizedRect: CGRect(x: 0.05, y: 0.55, width: 0.9, height: 0.35))!

        let preview = CaptureSavePreview(
            items: [
                CaptureSaveItem(
                    id: UUID(),
                    pageIndex: 0,
                    boxIndex: 0,
                    originalImageData: upperCrop,
                    cleanedImageData: upperCrop,
                    handwritingRemovalSucceeded: false,
                    ocrText: "Q1",
                    pageImageData: pageImg,
                    cropRectNormalized: CGRect(x: 0.05, y: 0.05, width: 0.9, height: 0.35)
                ),
                CaptureSaveItem(
                    id: UUID(),
                    pageIndex: 0,
                    boxIndex: 1,
                    originalImageData: lowerCrop,
                    cleanedImageData: lowerCrop,
                    handwritingRemovalSucceeded: false,
                    ocrText: "Q2",
                    pageImageData: pageImg,
                    cropRectNormalized: CGRect(x: 0.05, y: 0.55, width: 0.9, height: 0.35)
                )
            ],
            inkRemovalMode: .off
        )

        let saved = try service.commitSave(preview: preview, subject: subject, in: context)
        XCTAssertEqual(saved.count, 2)
        let first = saved[0]
        let sharedPagePath = try XCTUnwrap(first.pageImagePath)

        // Re-crop first mistake onto LOWER half of the full page (would be impossible if cropping only inside old upperCrop)
        try await service.recropMistake(first, normalizedRect: CGRect(x: 0.1, y: 0.65, width: 0.8, height: 0.25), mode: .off, in: context)
        XCTAssertEqual(first.cropRectNormalized?.origin.y ?? 0, 0.65, accuracy: 0.01)

        // Delete first mistake -> shared page image stays alive for second mistake!
        try service.permanentlyDeleteMistake(first, in: context)
        XCTAssertNotNil(store.loadData(relativePath: sharedPagePath))

        // Delete second mistake -> shared page image is now removed
        try service.permanentlyDeleteMistake(saved[1], in: context)
        XCTAssertNil(store.loadData(relativePath: sharedPagePath))

        // Missing source throws RecropError.missingSourceImage instead of returning silently
        let broken = MistakeItem()
        context.insert(broken)
        do {
            try await service.recropMistake(broken, normalizedRect: CGRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5), mode: .off, in: context)
            XCTFail("Expected RecropError.missingSourceImage")
        } catch let error as RecropError {
            XCTAssertEqual(error, .missingSourceImage)
        }
    }

    func testRecoveryPackageContainsStoreAndArchivalMovesStoreSafely() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("SnapDrillRecovery-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let storeURL = tempDir.appendingPathComponent("SnapDrill.sqlite")

        var result: ContainerLoadResult? = ModelContainerFactory.makeContainer(cloudKitRequested: false, storeURL: storeURL)
        XCTAssertNotNil(result?.container)

        let imageStore = MistakeImageStore(rootDirectory: tempDir.appendingPathComponent("images"))
        _ = try imageStore.saveJPEG(makeTestImageData(color: .white), relativePath: "orig/test.jpg")

        let recoveryZip = try ModelContainerFactory.createRecoveryPackageArchive(
            storeURL: storeURL,
            imageStore: imageStore,
            errorSummary: "Simulated error",
            outputDirectory: tempDir
        )
        let zipData = try Data(contentsOf: recoveryZip)
        XCTAssertEqual(zipData.prefix(2), Data([0x50, 0x4B]))
        XCTAssertGreaterThan(zipData.count, 500)

        // Release active ModelContainer before archiving database files (simulates failed-open launch state)
        result = nil
        let archiveFolder = try ModelContainerFactory.archiveCorruptedStoreFiles(storeURL: storeURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: archiveFolder.appendingPathComponent("SnapDrill.sqlite").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: storeURL.path))
    }

    func testCaptureDraftStoreThrowsWhenDirectoryUnwritableAndSupportsStep3() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("SnapDrillDraftErr-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = CaptureDraftStore(directoryURL: tempDir)
        let sessionStep3 = CaptureSession(pages: [CapturePage(rawImageData: Data([0xFF, 0xD8]))], activeStep: 3)
        try await store.saveDraft(sessionStep3)
        let loaded = await store.loadDraft()
        XCTAssertEqual(loaded?.activeStep, 3)

        // Block path with a regular file so saveDraft must throw instead of silently ignoring
        let blockedFile = tempDir.appendingPathComponent("blocked_parent")
        try Data([0x01]).write(to: blockedFile)
        let failingStore = CaptureDraftStore(directoryURL: blockedFile.appendingPathComponent("nested"))
        do {
            try await failingStore.saveDraft(sessionStep3)
            XCTFail("Expected CaptureDraftStore.saveDraft to throw when directory creation fails")
        } catch {
            // Expected throw
        }
    }
}
