import Compression
import SwiftData
import UIKit
import XCTest
@testable import SnapDrill

@MainActor
final class ProEntitlementAndBackupTests: XCTestCase {
    func testProExpirationRevertsPDFOptionsWithoutLockingData() {
        let suiteName = "com.notbadlabs.snapdrill.protests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ProEntitlementStore(userDefaults: defaults, startListeners: false)
        let requested = PDFExportOptions(
            title: "Final Review",
            paperSize: .b5,
            useCleanedImages: true,
            answerPlacement: .inlineBelow,
            blankSpace: .generous,
            includeFooterWatermark: false
        )

        // Active Pro keeps custom layout and removes watermark
        let proResolved = store.effectivePDFOptions(requested: requested, isPro: true)
        XCTAssertFalse(proResolved.includeFooterWatermark)
        XCTAssertEqual(proResolved.answerPlacement, .inlineBelow)
        XCTAssertEqual(proResolved.blankSpace, .generous)

        // Expired / Free safely reverts to P0 default layout with subtle watermark (PRD §8.6, AC-08)
        let freeResolved = store.effectivePDFOptions(requested: requested, isPro: false)
        XCTAssertTrue(freeResolved.includeFooterWatermark)
        XCTAssertEqual(freeResolved.answerPlacement, .endAppendix)
        XCTAssertEqual(freeResolved.blankSpace, .standard)
        XCTAssertEqual(freeResolved.paperSize, .b5)
    }

    func testSelectBestEntitlementPicksLatestNonRevokedTransaction() {
        let now = Date()
        let older = EntitlementSnapshot(
            productID: SnapDrillProductID.monthly.rawValue,
            expirationDate: now.addingTimeInterval(3600),
            isTrial: true,
            isRevoked: false
        )
        let newer = EntitlementSnapshot(
            productID: SnapDrillProductID.yearly.rawValue,
            expirationDate: now.addingTimeInterval(86_400 * 300),
            isTrial: false,
            isRevoked: false
        )
        let revokedFuture = EntitlementSnapshot(
            productID: SnapDrillProductID.yearly.rawValue,
            expirationDate: now.addingTimeInterval(86_400 * 999),
            isTrial: false,
            isRevoked: true
        )

        let chosen = ProEntitlementStore.selectBestEntitlement(from: [older, revokedFuture, newer])
        XCTAssertEqual(chosen, newer)

        // Non-expiring (nil expirationDate) takes precedence over finite expiration, and unknown product IDs are filtered out
        let nonExpiring = EntitlementSnapshot(
            productID: SnapDrillProductID.yearly.rawValue,
            expirationDate: nil,
            isTrial: false,
            isRevoked: false
        )
        let unknownID = EntitlementSnapshot(
            productID: "com.example.unknown",
            expirationDate: nil,
            isTrial: false,
            isRevoked: false
        )
        XCTAssertEqual(
            ProEntitlementStore.selectBestEntitlement(from: [newer, unknownID, nonExpiring]),
            nonExpiring
        )
        XCTAssertNil(ProEntitlementStore.selectBestEntitlement(from: [revokedFuture, unknownID]))
    }

    func testImageBudgetAndFullBackupZipCreation() async throws {
        let schema = ModelContainerFactory.schema
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("SnapDrillBackup-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let imageStore = MistakeImageStore(rootDirectory: tempDir.appendingPathComponent("images"))
        try await DemoNotebookSeeder.populateDemoMistakes(
            in: context,
            imageStore: imageStore,
            locale: Locale(identifier: "en_US")
        )

        let mistakes = try context.fetch(FetchDescriptor<MistakeItem>())
        XCTAssertGreaterThanOrEqual(mistakes.count, 3)

        // Verify combined original + cleaned stays below 1MB per problem across ALL seeded mistakes (PRD §9)
        for mistake in mistakes {
            let origData = try XCTUnwrap(mistake.resolvedOriginalImageData(imageStore: imageStore))
            let cleanData = try XCTUnwrap(mistake.resolvedCleanedImageData(imageStore: imageStore))
            XCTAssertLessThan(origData.count + cleanData.count, 1024 * 1024)
        }

        // Verify free full backup ZIP archive creation and inspect real ZIP entries + manifest.json (PRD F-54)
        let zipURL = try BackupExportService.createBackupArchive(
            in: context,
            imageStore: imageStore,
            outputDirectory: tempDir
        )
        let zipData = try Data(contentsOf: zipURL)
        XCTAssertGreaterThan(zipData.count, 1000)
        // Standard PK zip header bytes: 0x50 0x4B
        XCTAssertEqual(zipData.prefix(2), Data([0x50, 0x4B]))

        let archive = try inspectZipArchive(zipData)
        XCTAssertTrue(archive.entryNames.contains { $0.hasSuffix("manifest.json") })

        let manifestBytes = try XCTUnwrap(archive.manifestData)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedManifest = try decoder.decode(BackupManifest.self, from: manifestBytes)
        XCTAssertEqual(decodedManifest.mistakes.count, mistakes.count)
        XCTAssertGreaterThanOrEqual(decodedManifest.subjects.count, 1)

        for exportedMistake in decodedManifest.mistakes {
            if let origPath = exportedMistake.originalImagePath {
                XCTAssertTrue(archive.entryNames.contains { $0.hasSuffix(origPath) })
            }
            if let cleanPath = exportedMistake.cleanedImagePath {
                XCTAssertTrue(archive.entryNames.contains { $0.hasSuffix(cleanPath) })
            }
        }
    }

    private func readUInt16LE(_ data: Data, at offset: Int) -> UInt16 {
        UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private func readUInt32LE(_ data: Data, at offset: Int) -> UInt32 {
        UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }

    private func inspectZipArchive(_ zipData: Data) throws -> (entryNames: [String], manifestData: Data?) {
        let minEOCD = 22
        guard zipData.count >= minEOCD else {
            throw NSError(domain: "ZipTest", code: 1, userInfo: [NSLocalizedDescriptionKey: "ZIP truncated"])
        }
        let searchStart = max(0, zipData.count - 65_557)
        var eocdOffset: Int?
        for idx in stride(from: zipData.count - minEOCD, through: searchStart, by: -1) {
            if zipData[idx] == 0x50 && zipData[idx + 1] == 0x4B && zipData[idx + 2] == 0x05 && zipData[idx + 3] == 0x06 {
                eocdOffset = idx
                break
            }
        }
        let eocd = try XCTUnwrap(eocdOffset)
        let entryCount = Int(readUInt16LE(zipData, at: eocd + 10))
        let cdOffset = Int(readUInt32LE(zipData, at: eocd + 16))

        var pos = cdOffset
        var names: [String] = []
        var manifestData: Data?

        for _ in 0..<entryCount {
            XCTAssertEqual(readUInt32LE(zipData, at: pos), 0x02014b50)
            let method = readUInt16LE(zipData, at: pos + 10)
            let compressedSize = Int(readUInt32LE(zipData, at: pos + 20))
            let uncompressedSize = Int(readUInt32LE(zipData, at: pos + 24))
            let nameLen = Int(readUInt16LE(zipData, at: pos + 28))
            let extraLen = Int(readUInt16LE(zipData, at: pos + 30))
            let commentLen = Int(readUInt16LE(zipData, at: pos + 32))
            let localOffset = Int(readUInt32LE(zipData, at: pos + 42))

            let nameSlice = zipData[pos + 46 ..< pos + 46 + nameLen]
            let name = String(data: nameSlice, encoding: .utf8) ?? ""
            names.append(name)

            if name == "manifest.json" || name.hasSuffix("/manifest.json") {
                XCTAssertEqual(readUInt32LE(zipData, at: localOffset), 0x04034b50)
                let lhNameLen = Int(readUInt16LE(zipData, at: localOffset + 26))
                let lhExtraLen = Int(readUInt16LE(zipData, at: localOffset + 28))
                let payloadStart = localOffset + 30 + lhNameLen + lhExtraLen
                let compressed = Data(zipData[payloadStart ..< payloadStart + compressedSize])

                if method == 0 {
                    manifestData = compressed
                } else if method == 8 {
                    var dst = Data(count: max(1, uncompressedSize))
                    let decodedCount = dst.withUnsafeMutableBytes { dstBuf in
                        compressed.withUnsafeBytes { srcBuf in
                            compression_decode_buffer(
                                dstBuf.bindMemory(to: UInt8.self).baseAddress!,
                                uncompressedSize,
                                srcBuf.bindMemory(to: UInt8.self).baseAddress!,
                                compressed.count,
                                nil,
                                COMPRESSION_ZLIB
                            )
                        }
                    }
                    XCTAssertEqual(decodedCount, uncompressedSize)
                    manifestData = dst.prefix(decodedCount)
                }
            }

            pos += 46 + nameLen + extraLen + commentLen
        }

        return (names, manifestData)
    }

    func testAnnualSavingsPercentCalculation() {
        XCTAssertEqual(
            ProEntitlementStore.annualSavingsPercent(monthlyPrice: Decimal(string: "1.99")!, yearlyPrice: Decimal(string: "14.99")!),
            37
        )
        XCTAssertNil(
            ProEntitlementStore.annualSavingsPercent(monthlyPrice: Decimal(0), yearlyPrice: Decimal(string: "14.99")!)
        )
        XCTAssertNil(
            ProEntitlementStore.annualSavingsPercent(monthlyPrice: Decimal(1), yearlyPrice: Decimal(12))
        )
    }
}
