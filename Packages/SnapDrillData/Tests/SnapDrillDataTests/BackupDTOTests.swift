//
//  BackupDTOTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import Testing
@testable import SnapDrillData

@Suite("Backup v3 wire")
struct BackupDTOTests {
    private static let fixtureDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/BackupWireV3")
    private static let itemId = fixedUUID("22222222-2222-2222-2222-222222222222")
    private static let dimensionId = fixedUUID("33333333-3333-3333-3333-333333333333")
    private static let valueId = fixedUUID("44444444-4444-4444-4444-444444444444")

    @Test("manifest v3 golden wire has no Profile metadata")
    func manifestGoldenWire() throws {
        let manifest = BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(timeIntervalSince1970: 1_704_067_200),
            appVersion: "1.0.0",
            totalItemCount: 1
        )
        let encoded = try canonicalString(manifest)
        let fixture = try fixtureString(named: "manifest.json")
        #expect(BackupManifest.currentSchemaVersion == 3)
        #expect(encoded == fixture)
        #expect(!fixture.contains("profile"))
    }

    @Test("payload v3 golden wire is one direct library")
    func payloadGoldenWire() throws {
        let encoded = try canonicalString(goldenPayload())
        let fixture = try fixtureString(named: "data.json")
        let decoded = try canonicalDecoder().decode(BackupPayload.self, from: Data(fixture.utf8))
        #expect(encoded == fixture)
        #expect(!fixture.contains(#""profiles""#))
        #expect(decoded.reviewItems[0].id == Self.itemId)
        #expect(decoded.reviewItems[0].categoryValueIds == [Self.valueId])
        #expect(decoded.dimensions[0].systemKey == CategorySystemKey.category)
        #expect(decoded.categoryValues[0].dimensionId == Self.dimensionId)
    }

    @Test("empty payload preserves all direct arrays")
    func emptyPayloadGoldenWire() throws {
        let fixture = try fixtureString(named: "data-empty.json")
        let payload = try canonicalDecoder().decode(BackupPayload.self, from: Data(fixture.utf8))
        #expect(payload.reviewItems.isEmpty)
        #expect(payload.dimensions.isEmpty)
        #expect(payload.categoryValues.isEmpty)
        #expect(try canonicalString(payload) == fixture)
    }

    @Test("nullable item fields round-trip")
    func nullableItemFields() throws {
        let item = ArchiveItemBackupDTO(
            id: UUID(), content: nil, imagePath: nil,
            createdAt: .distantPast, lastReviewedAt: .distantPast, nextReviewAt: .distantPast,
            answerText: nil, answerImagePath: nil,
            easeFactor: 2.5, interval: 0, repetitions: 0, categoryValueIds: []
        )
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ArchiveItemBackupDTO.self, from: data)
        #expect(decoded.content == nil)
        #expect(decoded.answerText == nil)
        #expect(decoded.answerImagePath == nil)
        #expect(decoded.categoryValueIds.isEmpty)
    }

    private func goldenPayload() -> BackupPayload {
        BackupPayload(
            reviewItems: [
                ArchiveItemBackupDTO(
                    id: Self.itemId,
                    content: "Reference item",
                    imagePath: "images/22222222-2222-2222-2222-222222222222.jpg",
                    createdAt: Date(timeIntervalSince1970: 1_704_067_200),
                    lastReviewedAt: Date(timeIntervalSince1970: 1_704_153_600),
                    nextReviewAt: Date(timeIntervalSince1970: 1_704_672_000),
                    answerText: "Reference answer",
                    answerImagePath: nil,
                    easeFactor: 2.5,
                    interval: 6,
                    repetitions: 2,
                    categoryValueIds: [Self.valueId]
                )
            ],
            dimensions: [
                CategoryDimensionBackupDTO(
                    id: Self.dimensionId,
                    name: "Category",
                    isMultiValue: false,
                    isBuiltIn: true,
                    systemKey: CategorySystemKey.category,
                    sortOrder: 0,
                    icon: "tray.full"
                )
            ],
            categoryValues: [
                CategoryValueBackupDTO(
                    id: Self.valueId,
                    name: "Reference",
                    icon: "doc.text",
                    colorHex: "#3366FF",
                    sortOrder: 0,
                    createdAt: Date(timeIntervalSince1970: 1_704_067_200),
                    dimensionId: Self.dimensionId
                )
            ]
        )
    }

    private func canonicalEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private func canonicalDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func fixtureString(named name: String) throws -> String {
        let data = try Data(contentsOf: Self.fixtureDirectory.appendingPathComponent(name))
        return try #require(String(data: data, encoding: .utf8))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func canonicalString<T: Encodable>(_ value: T) throws -> String {
        let data = try canonicalEncoder().encode(value)
        return try #require(String(data: data, encoding: .utf8))
    }

    private static func fixedUUID(_ value: String) -> UUID {
        guard let uuid = UUID(uuidString: value) else {
            fatalError("Invalid fixed UUID fixture value: \(value)")
        }
        return uuid
    }
}
