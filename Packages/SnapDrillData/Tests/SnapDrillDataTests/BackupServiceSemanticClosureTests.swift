//
//  BackupServiceSemanticClosureTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Testing
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers
@testable import SnapDrillData

@Suite("BackupService 语义闭包测试", .serialized)
struct BackupServiceSemanticClosureTests {
    private static let profileId = UUID()
    private static let dimensionId = UUID()
    private static let categoryValueId = UUID()

    @Test("extractPayload 在数据库 mutation 前拒绝缺失的引用图片")
    func extractPayload_rejectsMissingReferencedImageEntry() async throws {
        let archiveURL = try makeArchive(payload: makePayload())
        defer { cleanup(archiveURL) }

        await expectInvalidArchive(archiveURL)
    }

    @Test("extractPayload 在数据库 mutation 前拒绝不可解码的 JPEG entry")
    func extractPayload_rejectsUnreadableImageBytes() async throws {
        let archiveURL = try makeArchive(
            payload: makePayload(),
            imageEntries: [
                ZIPEntry(path: expectedImagePath, data: Data("not-a-jpeg".utf8))
            ]
        )
        defer { cleanup(archiveURL) }

        await expectInvalidArchive(archiveURL)
    }

    @Test("JPEG 预检在解码前拒绝异常像素尺寸")
    func validatePixelDimensions_rejectsExcessivePixelCount() {
        #expect(throws: BackupError.self) {
            try BackupImagePathValidator.validatePixelDimensions(width: 16_384, height: 16_384)
        }
    }

    @Test("JPEG 预检拒绝 GPS 元数据")
    func validateJPEGData_rejectsGPSMetadata() throws {
        let gpsMetadata: [CFString: Any] = [
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLatitude: 37.7749,
                kCGImagePropertyGPSLongitudeRef: "W",
                kCGImagePropertyGPSLongitude: 122.4194
            ]
        ]
        let gpsJPEG = try makeTestJPEGData(properties: gpsMetadata)
        let source = try #require(CGImageSourceCreateWithData(gpsJPEG as CFData, nil))
        let properties = try #require(
            CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        )
        #expect(properties[kCGImagePropertyGPSDictionary] != nil)

        #expect(throws: BackupError.self) {
            try BackupImagePathValidator.validateJPEGData(gpsJPEG)
        }
    }

    @Test("createBackup 不生成自身无法恢复的悬空分类归档")
    func createBackup_rejectsDanglingTaxonomy() async {
        let payload = makePayload(imagePath: nil, categoryValueDimensionId: UUID())
        let manifest = BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            appVersion: "1.0",
            totalItemCount: 1,
            profileCount: 1,
            profileNames: ["Default"]
        )

        await #expect(throws: BackupError.self) {
            _ = try await BackupService().createBackup(
                payload: payload,
                manifest: manifest,
                profileDirectories: []
            )
        }
    }

    @Test("extractPayload 在数据库 mutation 前拒绝重复图片 entry")
    func extractPayload_rejectsDuplicateImageEntries() async throws {
        let imageData = try makeTestJPEGData()
        let archiveURL = try makeArchive(
            payload: makePayload(),
            imageEntries: [
                ZIPEntry(path: expectedImagePath, data: imageData),
                ZIPEntry(path: expectedImagePath, data: imageData)
            ]
        )
        defer { cleanup(archiveURL) }

        await expectInvalidArchive(archiveURL)
    }

    @Test("extractPayload 在数据库 mutation 前拒绝未引用的额外图片 entry")
    func extractPayload_rejectsUnreferencedImageEntry() async throws {
        let archiveURL = try makeArchive(
            payload: makePayload(imagePath: nil),
            imageEntries: [
                ZIPEntry(path: expectedImagePath, data: try makeTestJPEGData())
            ]
        )
        defer { cleanup(archiveURL) }

        await expectInvalidArchive(archiveURL)
    }

    @Test("extractPayload 在数据库 mutation 前拒绝条目悬空的分类值引用")
    func extractPayload_rejectsDanglingCategoryValueReference() async throws {
        let archiveURL = try makeArchive(
            payload: makePayload(imagePath: nil, itemCategoryValueIds: [UUID()])
        )
        defer { cleanup(archiveURL) }

        await expectInvalidArchive(archiveURL)
    }

    @Test("extractPayload 在数据库 mutation 前拒绝分类值悬空的维度引用")
    func extractPayload_rejectsDanglingDimensionReference() async throws {
        let archiveURL = try makeArchive(
            payload: makePayload(imagePath: nil, categoryValueDimensionId: UUID())
        )
        defer { cleanup(archiveURL) }

        await expectInvalidArchive(archiveURL)
    }

    private var expectedImagePath: String {
        "profiles/\(Self.profileId.uuidString)/images/test.jpg"
    }

    private func makePayload(
        imagePath: String? = "images/test.jpg",
        itemCategoryValueIds: [UUID] = [Self.categoryValueId],
        categoryValueDimensionId: UUID? = Self.dimensionId
    ) -> BackupPayload {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        let profile = ProfileBackupData(
            profileName: "Default",
            profileId: Self.profileId,
            reviewItems: [
                ArchiveItemBackupDTO(
                    id: UUID(),
                    content: "Item",
                    imagePath: imagePath,
                    createdAt: now,
                    lastReviewedAt: now,
                    nextReviewAt: now,
                    answerText: nil,
                    answerImagePath: nil,
                    easeFactor: 2.5,
                    interval: 0,
                    repetitions: 0,
                    categoryValueIds: itemCategoryValueIds
                )
            ],
            dimensions: [
                CategoryDimensionBackupDTO(
                    id: Self.dimensionId,
                    name: "Dimension",
                    isMultiValue: false,
                    isBuiltIn: false,
                    systemKey: nil,
                    sortOrder: 0,
                    icon: "folder"
                )
            ],
            categoryValues: [
                CategoryValueBackupDTO(
                    id: Self.categoryValueId,
                    name: "Value",
                    icon: "tag",
                    colorHex: "#000000",
                    sortOrder: 0,
                    createdAt: now,
                    dimensionId: categoryValueDimensionId
                )
            ]
        )
        return BackupPayload(profiles: [profile])
    }

    private func makeArchive(
        payload: BackupPayload,
        imageEntries: [ZIPEntry] = []
    ) throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let archiveURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupSemanticClosure_\(UUID().uuidString).zip")
        try ZIPArchiver().createArchive(
            entries: [ZIPEntry(path: "data.json", data: try encoder.encode(payload))] + imageEntries,
            at: archiveURL
        )
        return archiveURL
    }

    private func makeTestJPEGData(properties: [CFString: Any] = [:]) throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
        let output = NSMutableData()
        let destination = try #require(
            CGImageDestinationCreateWithData(
                output,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        )
        CGImageDestinationAddImage(
            destination,
            try #require(image.cgImage),
            properties as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else {
            throw BackupError.invalidArchive
        }
        return output as Data
    }

    private func expectInvalidArchive(_ archiveURL: URL) async {
        await #expect(throws: BackupError.self) {
            _ = try await BackupService().extractPayload(from: archiveURL)
        }
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
