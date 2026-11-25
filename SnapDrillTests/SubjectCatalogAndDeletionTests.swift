import SwiftData
import UIKit
import XCTest
@testable import SnapDrill

@MainActor
final class SubjectCatalogAndDeletionTests: XCTestCase {
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

    func testLocaleSubjectPresetsAndIdempotency() throws {
        XCTAssertEqual(SubjectCatalog.defaultSubjects(for: Locale(identifier: "ja_JP")).map(\.name), ["数学", "英語", "国語", "理科", "社会"])
        XCTAssertEqual(SubjectCatalog.defaultSubjects(for: Locale(identifier: "ko_KR")).map(\.name), ["수학", "영어", "국어", "과학", "사회"])
        XCTAssertEqual(SubjectCatalog.defaultSubjects(for: Locale(identifier: "zh_CN")).map(\.name), ["数学", "英语", "语文", "物理", "化学"])
        XCTAssertEqual(SubjectCatalog.defaultSubjects(for: Locale(identifier: "zh_TW")).map(\.name), ["數學", "英文", "國文", "物理", "化學"])

        let container = try makeInMemoryContainer()
        let context = container.mainContext

        SubjectCatalog.ensureSeeded(in: context, locale: Locale(identifier: "ja_JP"))
        let firstCount = try context.fetchCount(FetchDescriptor<Subject>())
        XCTAssertEqual(firstCount, 6) // 5 subjects + 1 hidden uncategorized bucket

        // Second seed call must be strictly idempotent
        SubjectCatalog.ensureSeeded(in: context, locale: Locale(identifier: "ja_JP"))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Subject>()), 6)
    }

    func testDeleteNonEmptySubjectMovesToUncategorizedAndTagDeletionPreservesMistakes() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("SnapDrillTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = MistakeImageStore(rootDirectory: tempDir)
        let saveService = LibrarySaveService(imageStore: store)

        let subjects = SubjectCatalog.ensureSeeded(in: context, locale: Locale(identifier: "en_US"))
        let math = try XCTUnwrap(subjects.first { !$0.isUncategorizedBucket })
        let uncategorized = try XCTUnwrap(subjects.first { $0.isUncategorizedBucket })

        let tag = MistakeTag(name: "Midterm")
        context.insert(tag)

        let cause = CustomCause(name: "Time Pressure")
        context.insert(cause)

        let item = MistakeItem(
            notes: "Watch signs",
            customCauseNames: [cause.name],
            subject: math
        )
        item.tagList = [tag]
        context.insert(item)
        try context.save()

        // Deleting tag & custom cause must NEVER delete the MistakeItem (AC-09)
        try saveService.deleteTag(tag, in: context)
        try saveService.deleteCustomCause(cause, in: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<MistakeItem>()), 1)
        XCTAssertTrue(item.tagList.isEmpty)
        XCTAssertTrue(item.customCauseNames.isEmpty)

        // Deleting non-empty subject with moveToUncategorized retains mistake under fallback bucket
        try saveService.deleteSubject(math, strategy: .moveToUncategorized, in: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<MistakeItem>()), 1)
        XCTAssertEqual(item.subject?.id, uncategorized.id)

        // Attempting to delete fallback uncategorized bucket is ignored
        try saveService.deleteSubject(uncategorized, strategy: .deleteWithMistakes, in: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<MistakeItem>()), 1)
    }

    func testDeleteSubjectWithMistakesCleansUpDatabaseAndUnsharedDiskFiles() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("SnapDrillDeleteAll-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = MistakeImageStore(rootDirectory: tempDir)
        let saveService = LibrarySaveService(imageStore: store)

        let subjects = SubjectCatalog.ensureSeeded(in: context, locale: Locale(identifier: "en_US"))
        let math = try XCTUnwrap(subjects.first { !$0.isUncategorizedBucket })
        let physics = try XCTUnwrap(subjects.first { !$0.isUncategorizedBucket && $0.id != math.id })

        let jpeg = UIGraphicsImageRenderer(size: CGSize(width: 60, height: 60)).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 60, height: 60))
        }.jpegData(compressionQuality: 0.8)!

        let origPath = try store.saveJPEG(jpeg, relativePath: "orig/m1.jpg")
        let cleanPath = try store.saveJPEG(jpeg, relativePath: "clean/m1.jpg")
        let ansPath = try store.saveJPEG(jpeg, relativePath: "ans/m1-0.jpg")
        let sharedPagePath = try store.saveJPEG(jpeg, relativePath: "page/shared.jpg")

        let mathMistake = MistakeItem(
            notes: "Delete me",
            answerImagePaths: [ansPath],
            originalImagePath: origPath,
            cleanedImagePath: cleanPath,
            pageImagePath: sharedPagePath,
            subject: math
        )
        let survivingPhysicsMistake = MistakeItem(
            notes: "Keep shared page",
            pageImagePath: sharedPagePath,
            subject: physics
        )
        context.insert(mathMistake)
        context.insert(survivingPhysicsMistake)
        try context.save()

        try saveService.deleteSubject(math, strategy: .deleteWithMistakes, in: context)

        let remainingSubjects = try context.fetch(FetchDescriptor<Subject>())
        XCTAssertFalse(remainingSubjects.contains { $0.id == math.id })
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<MistakeItem>()), 1)

        // Unshared files owned by deleted subject's mistake must be removed from disk
        XCTAssertNil(store.loadData(relativePath: origPath))
        XCTAssertNil(store.loadData(relativePath: cleanPath))
        XCTAssertNil(store.loadData(relativePath: ansPath))
        // Shared page image referenced by surviving mistake must remain intact
        XCTAssertNotNil(store.loadData(relativePath: sharedPagePath))
    }
}
