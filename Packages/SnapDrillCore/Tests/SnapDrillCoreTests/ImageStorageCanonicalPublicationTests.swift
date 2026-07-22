//
//  ImageStorageCanonicalPublicationTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Darwin
import Foundation
import Testing
import UIKit
@testable import SnapDrillCore

@Suite("ImageStorage canonical publication tests")
struct ImageStorageCanonicalPublicationTests {
    private let testDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("ImageStorageCanonicalPublication_\(UUID().uuidString)")
    private var storage: ImageStorage { ImageStorage(baseDirectory: testDirectory) }

    @Test("saveImage publishes bytes accepted by the canonical validator")
    func saveImage_publishesCanonicalJPEG() async throws {
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        let path = try await storage.saveImage(createTestImage(width: 50, height: 40))
        let url = try #require(storage.imageFileURL(path: path))
        let bytes = try Data(contentsOf: url)
        let metadata = try CanonicalJPEG.validate(bytes)

        #expect(metadata.width == 50)
        #expect(metadata.height == 40)
        #expect(try FileManager.default.contentsOfDirectory(
            at: url.deletingLastPathComponent(),
            includingPropertiesForKeys: nil
        ).map(\.lastPathComponent) == [url.lastPathComponent])
    }

    @Test("saveImage encoding failure leaves the active directory untouched")
    func saveImage_encodeFailureHasNoMutation() async {
        await #expect(throws: ImageStorageError.invalidImageData) {
            try await storage.saveImage(UIImage())
        }
        #expect(!FileManager.default.fileExists(atPath: testDirectory.path))
    }

    @Test("saveImage removes a unique staging file after a pre-rename failure")
    func saveImage_notPublishedCleansStaging() async throws {
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        let faultStorage = ImageStorage(baseDirectory: testDirectory) { bytes, staging, _, root in
            let stagingURL = root.appendingPathComponent("images")
                .appendingPathComponent(staging.fileName)
            try bytes.prefix(16).write(to: stagingURL)
            throw DurableRegularFilePublicationError(
                outcome: .notPublished,
                step: .writeStagingBytes,
                code: EIO
            )
        }

        await #expect(throws: ImageStorageError.publicationFailed) {
            try await faultStorage.saveImage(createTestImage(width: 20, height: 20))
        }
        let images = testDirectory.appendingPathComponent("images")
        #expect(try FileManager.default.contentsOfDirectory(atPath: images.path).isEmpty)
    }

    @Test("saveImage accepts matching uncertain bytes and preserves mismatched unreferenced bytes")
    func saveImage_reconcilesUncertainPublication() async throws {
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        let matching = ImageStorage(baseDirectory: testDirectory) { bytes, _, destination, root in
            let destinationURL = root.appendingPathComponent("images")
                .appendingPathComponent(destination.fileName)
            try bytes.write(to: destinationURL)
            throw DurableRegularFilePublicationError(
                outcome: .publicationOutcomeUncertain,
                step: .synchronizeDestinationParent,
                code: EIO
            )
        }
        let path = try await matching.saveImage(createTestImage(width: 20, height: 20))
        #expect(matching.loadImage(path: path) != nil)

        try FileManager.default.removeItem(at: testDirectory)
        let mismatched = ImageStorage(baseDirectory: testDirectory) { _, _, destination, root in
            let destinationURL = root.appendingPathComponent("images")
                .appendingPathComponent(destination.fileName)
            try Data("mismatch".utf8).write(to: destinationURL)
            throw DurableRegularFilePublicationError(
                outcome: .publicationOutcomeUncertain,
                step: .verifyFinalBytes,
                code: EIO
            )
        }
        await #expect(throws: ImageStorageError.publicationOutcomeUncertain) {
            try await mismatched.saveImage(createTestImage(width: 20, height: 20))
        }
        let images = testDirectory.appendingPathComponent("images")
        let entries = try FileManager.default.contentsOfDirectory(atPath: images.path)
        #expect(entries.count == 1 && entries[0].hasSuffix(".jpg"))
    }

    @Test("saveImage rejects matching uncertain bytes with wrong backup attributes")
    func saveImage_uncertainWrongAttributesDoNotReconcile() async throws {
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        let wrongAttributes = ImageStorage(baseDirectory: testDirectory) { bytes, _, destination, root in
            var destinationURL = root.appendingPathComponent("images")
                .appendingPathComponent(destination.fileName)
            try bytes.write(to: destinationURL)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try destinationURL.setResourceValues(values)
            throw DurableRegularFilePublicationError(
                outcome: .publicationOutcomeUncertain,
                step: .verifyFinalAttributes,
                code: EIO
            )
        }

        await #expect(throws: ImageStorageError.publicationOutcomeUncertain) {
            try await wrongAttributes.saveImage(createTestImage(width: 20, height: 20))
        }
        let images = testDirectory.appendingPathComponent("images")
        let entries = try FileManager.default.contentsOfDirectory(
            at: images,
            includingPropertiesForKeys: [.isExcludedFromBackupKey]
        )
        #expect(entries.count == 1)
        #expect(try entries[0].resourceValues(forKeys: [.isExcludedFromBackupKey])
            .isExcludedFromBackup == true)
    }

    @Test("saveImage preserves an uncertain destination whose inode cannot be proven")
    func saveImage_uncertainUnprovenNodeIsNotPathDeleted() async throws {
        let outside = FileManager.default.temporaryDirectory
            .appendingPathComponent("ImageStorageUnproven_\(UUID().uuidString).jpg")
        defer {
            try? FileManager.default.removeItem(at: testDirectory)
            try? FileManager.default.removeItem(at: outside)
        }
        try Data("outside".utf8).write(to: outside)
        let ambiguous = ImageStorage(baseDirectory: testDirectory) { _, _, destination, root in
            let destinationURL = root.appendingPathComponent("images")
                .appendingPathComponent(destination.fileName)
            try FileManager.default.createSymbolicLink(at: destinationURL, withDestinationURL: outside)
            throw DurableRegularFilePublicationError(
                outcome: .publicationOutcomeUncertain,
                step: .verifyFinalNode,
                code: EIO
            )
        }

        await #expect(throws: ImageStorageError.publicationOutcomeUncertain) {
            try await ambiguous.saveImage(createTestImage(width: 20, height: 20))
        }
        let entries = try FileManager.default.contentsOfDirectory(
            at: testDirectory.appendingPathComponent("images"),
            includingPropertiesForKeys: [.isSymbolicLinkKey]
        )
        #expect(entries.count == 1)
        #expect(try entries[0].resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true)
        #expect(try Data(contentsOf: outside) == Data("outside".utf8))
    }

    @Test("saveImage reconciliation stays bound to the pre-publication images directory")
    func saveImage_uncertainDirectorySubstitutionDoesNotSucceed() async throws {
        defer { try? FileManager.default.removeItem(at: testDirectory) }
        let substituted = ImageStorage(baseDirectory: testDirectory) { bytes, _, destination, root in
            let images = root.appendingPathComponent("images", isDirectory: true)
            let original = root.appendingPathComponent("images-original", isDirectory: true)
            try FileManager.default.moveItem(at: images, to: original)
            try FileManager.default.createDirectory(at: images, withIntermediateDirectories: false)
            try bytes.write(to: images.appendingPathComponent(destination.fileName))
            throw DurableRegularFilePublicationError(
                outcome: .publicationOutcomeUncertain,
                step: .verifyFinalBytes,
                code: EIO
            )
        }

        await #expect(throws: ImageStorageError.publicationOutcomeUncertain) {
            try await substituted.saveImage(createTestImage(width: 20, height: 20))
        }
        let replacementEntries = try FileManager.default.contentsOfDirectory(
            atPath: testDirectory.appendingPathComponent("images").path
        )
        #expect(replacementEntries.count == 1)
        #expect(try FileManager.default.contentsOfDirectory(
            atPath: testDirectory.appendingPathComponent("images-original").path
        ).isEmpty)
    }

    private func createTestImage(width: CGFloat, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height),
            format: format
        )
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
}
