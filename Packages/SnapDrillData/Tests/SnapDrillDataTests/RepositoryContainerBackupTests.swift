//
//  RepositoryContainerBackupTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  RepositoryContainer 的 collectProfileBackupData / restoreFromProfileData round-trip 测试（L3 动态维度）。
//

import Testing
import SwiftData
import Foundation
import SnapDrillCore
@testable import SnapDrillData

@Suite("RepositoryContainer 备份/恢复测试")
final class RepositoryContainerBackupTests {

    // MARK: - Properties

    private static let testProfileId = UUID()

    private let container: ModelContainer
    private let repos: RepositoryContainer

    init() throws {
        container = try TestModelContainer.create()
        repos = RepositoryContainer(modelContext: container.mainContext)
    }

    /// 建一个分类维度 + 一个值（已 save），返回值供挂题
    private func seedCategoryValue(dimensionName: String, valueName: String) throws -> CategoryValueModel {
        let dimension = CategoryDimensionModel(
            name: dimensionName, isMultiValue: false, isBuiltIn: true,
            systemKey: CategorySystemKey.category, sortOrder: 0, icon: "book"
        )
        try repos.dimension.insertAndSave(dimension)
        let value = CategoryValueModel(name: valueName, sortOrder: 0, dimension: dimension)
        try repos.categoryValue.insertAndSave(value)
        return value
    }

    // MARK: - collectProfileBackupData

    @Test("collectProfileBackupData 正确收集全量数据（动态维度）")
    func collectPayloadBasic() throws {
        let value = try seedCategoryValue(dimensionName: "分类", valueName: "数学")

        let item = ArchiveItemModel(content: "测试题", answerText: "答案文本")
        item.categoryValues = [value]
        repos.archive.insert(item)
        try repos.archive.saveContext()

        let profileData = try repos.collectProfileBackupData(
            profileName: "默认",
            profileId: Self.testProfileId
        )

        #expect(profileData.reviewItems.count == 1)
        #expect(profileData.reviewItems[0].content == "测试题")
        #expect(profileData.reviewItems[0].categoryValueIds == [value.id])
        #expect(profileData.reviewItems[0].answerText == "答案文本")

        #expect(profileData.dimensions.contains(where: { $0.name == "分类" }))
        #expect(profileData.categoryValues.contains(where: { $0.name == "数学" }))
    }

    @Test("空数据库 collectProfileBackupData 返回空数据")
    func collectPayloadEmpty() throws {
        let profileData = try repos.collectProfileBackupData(
            profileName: "空",
            profileId: UUID()
        )

        #expect(profileData.reviewItems.isEmpty)
        #expect(profileData.dimensions.isEmpty)
        #expect(profileData.categoryValues.isEmpty)
    }

    // MARK: - restoreFromProfileData

    @Test("restoreFromProfileData 全量恢复 round-trip（动态维度）")
    func restorePayloadRoundTrip() async throws {
        let value = try seedCategoryValue(dimensionName: "英语", valueName: "听力")

        let item = ArchiveItemModel(
            content: "原始题目", answerText: "A", easeFactor: 2.8, interval: 5, repetitions: 3
        )
        item.categoryValues = [value]
        repos.archive.insert(item)
        try repos.archive.saveContext()

        let profileData = try repos.collectProfileBackupData(
            profileName: "默认",
            profileId: Self.testProfileId
        )

        try repos.archive.deleteAll()
        try repos.categoryValue.deleteAll()
        try repos.dimension.deleteAll()
        try repos.archive.saveContext()
        #expect(try repos.archive.totalCount() == 0)

        try await repos.restoreFromProfileData(profileData)

        let restoredItems = try repos.archive.fetchAllModels()
        #expect(restoredItems.count == 1)
        let restored = restoredItems[0]
        #expect(restored.content == "原始题目")
        #expect(restored.answerText == "A")
        #expect(restored.easeFactor == 2.8)
        #expect(restored.interval == 5)
        #expect(restored.repetitions == 3)
        #expect(restored.categoryValues?.first?.name == "听力")
        #expect(restored.categoryValues?.first?.dimension?.name == "英语")

        let dims = try repos.dimension.fetchAllModels()
        #expect(dims.contains(where: { $0.name == "英语" }))
    }

    @Test("restoreFromProfileData 替换已有数据")
    func restoreReplacesExistingData() async throws {
        let oldItem = ArchiveItemModel(content: "旧题目")
        repos.archive.insert(oldItem)
        try repos.archive.saveContext()
        #expect(try repos.archive.totalCount() == 1)

        let dimID = UUID()
        let valueID = UUID()
        let newProfileData = ProfileBackupData(
            profileName: "新",
            profileId: UUID(),
            reviewItems: [
                ArchiveItemBackupDTO(
                    id: UUID(), content: "新题目 A", imagePath: nil,
                    createdAt: Date(), lastReviewedAt: .distantPast, nextReviewAt: .distantPast,
                    answerText: nil, answerImagePath: nil,
                    easeFactor: 2.5, interval: 0, repetitions: 0, categoryValueIds: []
                ),
                ArchiveItemBackupDTO(
                    id: UUID(), content: "新题目 B", imagePath: nil,
                    createdAt: Date(), lastReviewedAt: .distantPast, nextReviewAt: .distantPast,
                    answerText: nil, answerImagePath: nil,
                    easeFactor: 2.5, interval: 0, repetitions: 0, categoryValueIds: [valueID]
                )
            ],
            dimensions: [
                CategoryDimensionBackupDTO(
                    id: dimID, name: "物理", isMultiValue: false, isBuiltIn: false,
                    systemKey: nil, sortOrder: 0, icon: "bolt"
                )
            ],
            categoryValues: [
                CategoryValueBackupDTO(
                    id: valueID, name: "力学", icon: "circle", colorHex: "#FF0000",
                    sortOrder: 0, createdAt: Date(), dimensionId: dimID
                )
            ]
        )

        try await repos.restoreFromProfileData(newProfileData)

        let items = try repos.archive.fetchAllModels()
        #expect(items.count == 2)
        #expect(items.contains(where: { $0.content == "新题目 A" }))
        #expect(items.contains(where: { $0.content == "新题目 B" }))
        #expect(!items.contains(where: { $0.content == "旧题目" }))
    }

    @Test("restoreFromProfileData 维度值关联正确恢复")
    func restoreCategoryValueAssociations() async throws {
        let dimID = UUID()
        let v1 = UUID()
        let v2 = UUID()
        let v3 = UUID()
        let profileData = ProfileBackupData(
            profileName: "测试",
            profileId: UUID(),
            reviewItems: [
                ArchiveItemBackupDTO(
                    id: UUID(), content: "多值题目", imagePath: nil,
                    createdAt: Date(), lastReviewedAt: .distantPast, nextReviewAt: .distantPast,
                    answerText: nil, answerImagePath: nil,
                    easeFactor: 2.5, interval: 0, repetitions: 0, categoryValueIds: [v1, v2, v3]
                )
            ],
            dimensions: [
                CategoryDimensionBackupDTO(
                    id: dimID, name: "标签", isMultiValue: true, isBuiltIn: true,
                    systemKey: CategorySystemKey.tag, sortOrder: 0, icon: "tag"
                )
            ],
            categoryValues: [
                CategoryValueBackupDTO(id: v1, name: "易错", icon: "circle", colorHex: "#FF0000", sortOrder: 0, createdAt: Date(), dimensionId: dimID),
                CategoryValueBackupDTO(id: v2, name: "高频", icon: "circle", colorHex: "#00FF00", sortOrder: 1, createdAt: Date(), dimensionId: dimID),
                CategoryValueBackupDTO(id: v3, name: "考前", icon: "circle", colorHex: "#0000FF", sortOrder: 2, createdAt: Date(), dimensionId: dimID)
            ]
        )

        try await repos.restoreFromProfileData(profileData)

        let items = try repos.archive.fetchAllModels()
        #expect(items.count == 1)
        let names = (items[0].categoryValues ?? []).map(\.name).sorted()
        #expect(names == ["易错", "高频", "考前"].sorted())
    }

    @Test("restoreFromProfileData 逐字段 round-trip：维度 flag + 值样式存活（非默认值重建）")
    func restorePreservesAllFields() async throws {
        // 多值维度 + 全非默认字段——区分「正确恢复」与「init 默认值重建」
        let tagDim = CategoryDimensionModel(
            name: "标签", isMultiValue: true, isBuiltIn: true,
            systemKey: CategorySystemKey.tag, sortOrder: 3, icon: "tag.fill"
        )
        try repos.dimension.insertAndSave(tagDim)
        let value = CategoryValueModel(
            name: "易错", icon: "star.fill", colorHex: "#123456", sortOrder: 7,
            createdAt: Date(timeIntervalSinceReferenceDate: 700_000_000), dimension: tagDim
        )
        try repos.categoryValue.insertAndSave(value)
        let item = ArchiveItemModel(content: "题")
        item.categoryValues = [value]
        repos.archive.insert(item)
        try repos.archive.saveContext()

        let profileData = try repos.collectProfileBackupData(profileName: "默认", profileId: Self.testProfileId)
        try repos.archive.deleteAll()
        try repos.categoryValue.deleteAll()
        try repos.dimension.deleteAll()
        try repos.archive.saveContext()

        try await repos.restoreFromProfileData(profileData)

        let dims = try repos.dimension.fetchAllModels()
        let restoredDim = try #require(dims.first { $0.systemKey == CategorySystemKey.tag })
        #expect(restoredDim.name == "标签")
        #expect(restoredDim.isMultiValue == true)
        #expect(restoredDim.isBuiltIn == true)
        #expect(restoredDim.sortOrder == 3)
        #expect(restoredDim.icon == "tag.fill")

        let values = repos.categoryValue.fetchAllModels(in: restoredDim)
        let restoredValue = try #require(values.first { $0.name == "易错" })
        #expect(restoredValue.icon == "star.fill")
        #expect(restoredValue.colorHex == "#123456")
        #expect(restoredValue.sortOrder == 7)
        #expect(restoredValue.createdAt == Date(timeIntervalSinceReferenceDate: 700_000_000))
    }
}
