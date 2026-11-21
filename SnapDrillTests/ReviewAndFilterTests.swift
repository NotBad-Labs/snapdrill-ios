import SwiftData
import XCTest
@testable import SnapDrill

@MainActor
final class ReviewAndFilterTests: XCTestCase {
    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            Subject.self,
            MistakeItem.self,
            MistakeTag.self,
            CustomCause.self
        ])
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
        m1.tags = [tagExam]

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

    func testUndoDeleteAndDraftStoreRecovery() async throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("SnapDrillUndo-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let env = AppEnvironment(
            preferences: AppPreferencesStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!),
            proStore: ProEntitlementStore(startListeners: false),
            imageStore: MistakeImageStore(rootDirectory: tempDir),
            draftStore: CaptureDraftStore(directoryURL: tempDir)
        )

        let item = MistakeItem(notes: "Temporary note")
        context.insert(item)
        try context.save()

        env.scheduleSoftDelete([item], in: context)
        XCTAssertTrue(env.pendingDeletionIDs.contains(item.id))
        XCTAssertEqual(env.undoBannerCount, 1)

        // Undo restores visibility and keeps DB row intact
        env.undoLastDeletion()
        XCTAssertFalse(env.pendingDeletionIDs.contains(item.id))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<MistakeItem>()), 1)

        // Commit deletion permanently removes row
        env.scheduleSoftDelete([item], in: context)
        env.commitPendingDeletions()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<MistakeItem>()), 0)

        // Draft persistence round-trip (AC-09)
        let draftSession = CaptureSession(
            pages: [CapturePage(rawImageData: Data([0xFF, 0xD8]))],
            activeStep: 2
        )
        await env.draftStore.saveDraft(draftSession)
        let loaded = await env.draftStore.loadDraft()
        XCTAssertEqual(loaded?.id, draftSession.id)
        XCTAssertEqual(loaded?.activeStep, 2)

        await env.draftStore.clearDraft()
        let afterClear = await env.draftStore.loadDraft()
        XCTAssertNil(afterClear)
    }
}
