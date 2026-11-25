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

        // Verify combined original + cleaned stays below 1MB per problem (PRD §9)
        let first = try XCTUnwrap(mistakes.first)
        let origData = try XCTUnwrap(first.resolvedOriginalImageData(imageStore: imageStore))
        let cleanData = try XCTUnwrap(first.resolvedCleanedImageData(imageStore: imageStore))
        XCTAssertLessThan(origData.count + cleanData.count, 1024 * 1024)

        // Verify free full backup ZIP archive creation (PRD F-54)
        let zipURL = try BackupExportService.createBackupArchive(
            in: context,
            imageStore: imageStore,
            outputDirectory: tempDir
        )
        let zipData = try Data(contentsOf: zipURL)
        XCTAssertGreaterThan(zipData.count, 1000)
        // Standard PK zip header bytes: 0x50 0x4B
        XCTAssertEqual(zipData.prefix(2), Data([0x50, 0x4B]))
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
