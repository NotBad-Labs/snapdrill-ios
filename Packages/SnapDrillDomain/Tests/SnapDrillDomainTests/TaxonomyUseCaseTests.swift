//
//  TaxonomyUseCaseTests.swift
//  SnapDrillDomainTests
//
//  Created by SnapDrill Labs on 2026/02/28.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  TaxonomyUseCase 业务逻辑单元测试。
//

import Testing
import Foundation
@testable import SnapDrillDomain

@MainActor
struct TaxonomyUseCaseTests {

    // MARK: - Helpers

    private func makeUseCase(
        subjectRepo: MockSubjectRepository = MockSubjectRepository(),
        sourceRepo: MockSourceRepository = MockSourceRepository(),
        tagRepo: MockTagRepository = MockTagRepository(),
        gradeRepo: MockGradeRepository = MockGradeRepository(),
        reviewRepo: MockReviewRepository = MockReviewRepository()
    ) -> TaxonomyUseCase {
        TaxonomyUseCase(
            subjectRepo: subjectRepo,
            sourceRepo: sourceRepo,
            tagRepo: tagRepo,
            gradeRepo: gradeRepo,
            reviewRepo: reviewRepo
        )
    }

    // MARK: - addSubject

    @Test("addSubject 成功保存学科")
    func addSubjectPersists() throws {
        let subjectRepo = MockSubjectRepository()
        let useCase = makeUseCase(subjectRepo: subjectRepo)

        try useCase.addSubject(name: "数学", icon: "function", colorHex: "#FF0000")

        let subjects = try subjectRepo.fetchAll()
        #expect(subjects.contains { $0.name == "数学" })
    }

    // MARK: - deleteSubject

    @Test("deleteSubject — 未使用时成功删除")
    func deleteSubjectWithNoUsageSucceeds() throws {
        let subjectRepo = MockSubjectRepository()
        let reviewRepo = MockReviewRepository()
        let useCase = makeUseCase(subjectRepo: subjectRepo, reviewRepo: reviewRepo)

        try useCase.addSubject(name: "语文", icon: "textformat", colorHex: "#00FF00")
        try useCase.deleteSubject(name: "语文")

        let subjects = try subjectRepo.fetchAll()
        #expect(!subjects.contains { $0.name == "语文" })
    }

    @Test("deleteSubject — 被引用时 throw DomainError.entityInUse")
    func deleteSubjectWithUsageThrows() throws {
        let subjectRepo = MockSubjectRepository()
        let reviewRepo = MockReviewRepository()
        let useCase = makeUseCase(subjectRepo: subjectRepo, reviewRepo: reviewRepo)

        try useCase.addSubject(name: "物理", icon: "atom", colorHex: "#0000FF")
        // 添加引用此学科的 ReviewItem
        let item = ReviewItem(content: "物理题", subject: "物理")
        try reviewRepo.save(item)

        #expect(throws: DomainError.self) {
            try useCase.deleteSubject(name: "物理")
        }
    }

    // MARK: - canDeleteSubject

    @Test("canDeleteSubject — 无引用时返回 true")
    func canDeleteSubjectWithNoUsageReturnsTrue() throws {
        let subjectRepo = MockSubjectRepository()
        let reviewRepo = MockReviewRepository()
        let useCase = makeUseCase(subjectRepo: subjectRepo, reviewRepo: reviewRepo)

        try useCase.addSubject(name: "化学", icon: "flask", colorHex: "#FF00FF")

        #expect(try useCase.canDeleteSubject(name: "化学") == true)
    }

    @Test("canDeleteSubject — 有引用时返回 false")
    func canDeleteSubjectWithUsageReturnsFalse() throws {
        let reviewRepo = MockReviewRepository()
        let useCase = makeUseCase(reviewRepo: reviewRepo)

        let item = ReviewItem(content: "生物题", subject: "生物")
        try reviewRepo.save(item)

        #expect(try useCase.canDeleteSubject(name: "生物") == false)
    }

    // MARK: - updateSubject (级联)

    @Test("updateSubject — 重命名时级联更新 ReviewItems")
    func updateSubjectCascadesReviewItems() throws {
        let subjectRepo = MockSubjectRepository()
        let reviewRepo = MockReviewRepository()
        let useCase = makeUseCase(subjectRepo: subjectRepo, reviewRepo: reviewRepo)

        // 添加学科和条目
        try useCase.addSubject(name: "英语", icon: "textformat.abc", colorHex: "#FFFF00")
        let item = ReviewItem(content: "英语题", subject: "英语")
        try reviewRepo.save(item)

        // 重命名
        try useCase.updateSubject(oldName: "英语", newName: "外语", icon: "globe", colorHex: "#FFFF00")

        // 验证级联
        let updated = try reviewRepo.fetchById(item.id)
        #expect(updated?.subject == "外语")

        // 验证学科名更新
        let subjects = try subjectRepo.fetchAll()
        #expect(subjects.contains { $0.name == "外语" })
        #expect(!subjects.contains { $0.name == "英语" })
    }

    // MARK: - getOrCreateTag

    @Test("getOrCreateTag — 第一次创建，第二次返回相同实例")
    func getOrCreateTagDeduplicates() throws {
        let tagRepo = MockTagRepository()
        let useCase = makeUseCase(tagRepo: tagRepo)

        let tag1 = try useCase.getOrCreateTag(name: "重点", colorHex: "#FF0000")
        let tag2 = try useCase.getOrCreateTag(name: "重点", colorHex: "#FF0000")

        #expect(tag1.id == tag2.id)
        #expect(try tagRepo.fetchAll().count == 1)
    }
}
