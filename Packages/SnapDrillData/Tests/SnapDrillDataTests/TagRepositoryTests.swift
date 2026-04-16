//
//  TagRepositoryTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs on 2026/03/10.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  TagRepository CRUD 与 fetchOrCreate 逻辑测试。
//

import Testing
import SwiftData

import Foundation
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("TagRepository 单元测试", .serialized)
final class TagRepositoryTests {

    private let container: ModelContainer
    private let repo: TagRepository

    init() throws {
        container = try TestModelContainer.create()
        repo = TagRepository(modelContext: container.mainContext)
    }

    // MARK: - fetchOrCreateModel

    @Test("fetchOrCreateModel 不存在时创建新标签")
    func fetchOrCreate_newTag_createsIt() throws {
        let tag = try repo.fetchOrCreateModel(name: "易错", colorHex: "#FF0000")

        #expect(tag.name == "易错")
        #expect(tag.colorHex == "#FF0000")
    }

    @Test("fetchOrCreateModel 已存在时返回现有标签")
    func fetchOrCreate_existingTag_returnsExisting() throws {
        let first = try repo.fetchOrCreateModel(name: "重点", colorHex: "#00FF00")
        let second = try repo.fetchOrCreateModel(name: "重点", colorHex: "#0000FF")

        // 同一个对象，颜色不应改变
        #expect(first.id == second.id)
        #expect(second.colorHex == "#00FF00")
    }

    // MARK: - fetchAllModels

    @Test("fetchAllModels 按创建时间降序")
    func fetchAllModels_sortedByCreatedAt() throws {
        _ = try repo.fetchOrCreateModel(name: "标签A", colorHex: "#000000")
        _ = try repo.fetchOrCreateModel(name: "标签B", colorHex: "#111111")

        let all = try repo.fetchAllModels()
        #expect(all.count == 2)
    }

    // MARK: - delete

    @Test("delete 成功移除指定标签")
    func delete_removesTag() throws {
        let tag = try repo.fetchOrCreateModel(name: "临时", colorHex: "#FFFFFF")

        let allBefore = try repo.fetchAllModels()
        #expect(allBefore.count == 1)

        try repo.delete(id: tag.id)

        let allAfter = try repo.fetchAllModels()
        #expect(allAfter.isEmpty)
    }

    @Test("delete 不存在的 ID 不崩溃")
    func delete_nonExistentId_noCrash() throws {
        try repo.delete(id: UUID())
    }

    // MARK: - deleteAll

    @Test("deleteAll 清空所有标签")
    func deleteAll_removesAll() throws {
        _ = try repo.fetchOrCreateModel(name: "标签1", colorHex: "#000000")
        _ = try repo.fetchOrCreateModel(name: "标签2", colorHex: "#111111")
        try repo.saveContext()

        try repo.deleteAll()
        try repo.saveContext()
        let all = try repo.fetchAllModels()
        #expect(all.isEmpty)
    }
}
