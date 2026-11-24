import SwiftData
import XCTest
@testable import SnapDrill

@MainActor
final class ReviewAndFilterTests: XCTestCase {
    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = ModelContainerFactory.schema
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    func testCombinedFilteringAndOCRSearchGating() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let math = Subject(name: "Math", sortOrder: 0)
        let physics = Subject(name: "Physics", sortOrder: 1)
        context.insert(math)
        context.insert(physics)

        let tagExam = MistakeTag(name: "Final")
        context.insert(tagExam)

        let now = Date()
        let oldDate = Calendar.current.date(byAdding: .day, value: -45, to: now)!

        let m1 = MistakeItem(
            createdAt: now,
            notes: "Sign error",
            causes: [.calculationError],
            mastery: .unknown,
            ocrText: "quadratic discriminant delta",
            subject: math
        )
        m1.tagList = [tagExam]

        let m2 = MistakeItem(
            createdAt: oldDate,
            notes: "Slope mistake",
            causes: [.conceptUnclear],
            mastery: .mastered,
            ocrText: "newton second law",
            subject: physics
        )
        context.insert(m1)
        context.insert(m2)
        try context.save()

        // Combined filter matches m1
        var criteria = MistakeFilterCriteria(
            subjectIDs: [math.id],
            causes: [.calculationError],
            tagNames: ["Final"],
            masteryLevels: [.unknown],
            dateRange: .last7Days
        )
        XCTAssertEqual(MistakeFilterEngine.filter([m1, m2], using: criteria, referenceDate: now).map(\.id), [m1.id])

        // OCR keyword search only matches when includeOCRTextSearch is true (Pro gated)
        criteria = MistakeFilterCriteria(searchQuery: "discriminant", includeOCRTextSearch: false)
        XCTAssertTrue(MistakeFilterEngine.filter([m1, m2], using: criteria, referenceDate: now).isEmpty)

        criteria.includeOCRTextSearch = true
        XCTAssertEqual(MistakeFilterEngine.filter([m1, m2], using: criteria, referenceDate: now).map(\.id), [m1.id])
    }

    func testUndoDeleteTimerExpiryAndDraftStoreRecovery() async throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("SnapDrillUndo-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let imageStore = MistakeImageStore(rootDirectory: tempDir)
        let env = AppEnvironment(
            preferences: AppPreferencesStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!),
            proStore: ProEntitlementStore(startListeners: false),
            imageStore: imageStore,
            draftStore: CaptureDraftStore(directoryURL: tempDir),
            undoDelay: .milliseconds(150)
        )

        let dummyJPG = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40)).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }.jpegData(compressionQuality: 0.8)!
        let savedPath = try imageStore.saveJPEG(dummyJPG, relativePath: "orig/undo-test.jpg")

        let item = MistakeItem(notes: "Temporary note", originalImagePath: savedPath)
        context.insert(item)
        try context.save()

        env.scheduleSoftDelete([item], in: context)
        XCTAssertTrue(env.pendingDeletionIDs.contains(item.id))
        XCTAssertEqual(env.undoBannerCount, 1)

        // Undo restores visibility and keeps DB row and disk file intact
        env.undoLastDeletion()
        XCTAssertFalse(env.pendingDeletionIDs.contains(item.id))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<MistakeItem>()), 1)
        XCTAssertNotNil(imageStore.loadData(relativePath: savedPath))

        // Schedule again and allow async timer to expire naturally
        env.scheduleSoftDelete([item], in: context)
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<MistakeItem>()), 0)
        XCTAssertNil(imageStore.loadData(relativePath: savedPath))

        // Draft persistence round-trip (AC-09) including Step 3
        let draftSession = CaptureSession(
            pages: [CapturePage(rawImageData: Data([0xFF, 0xD8]))],
            activeStep: 3
        )
        try await env.draftStore.saveDraft(draftSession)
        let loaded = await env.draftStore.loadDraft()
        XCTAssertEqual(loaded?.id, draftSession.id)
        XCTAssertEqual(loaded?.activeStep, 3)

        await env.draftStore.clearDraft()
        let afterClear = await env.draftStore.loadDraft()
        XCTAssertNil(afterClear)
    }
}
