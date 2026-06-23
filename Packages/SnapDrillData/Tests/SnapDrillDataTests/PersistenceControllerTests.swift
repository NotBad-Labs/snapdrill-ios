//
//  PersistenceControllerTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PersistenceController 单元测试（Swift Testing）。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillData

@Suite("PersistenceController 测试")
struct PersistenceControllerTests {

    @Test("in-memory 初始化成功")
    func initializeWithInMemory() throws {
        let controller = PersistenceController(inMemory: true)

        #expect(controller.container != nil)
        #expect(controller.isUsingInMemoryFallback == false)
        #expect(controller.initializationError == nil)
    }

    @Test("container 的 mainContext 可访问")
    func containerIsAccessible() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.mainContext

        #expect(context != nil)
    }

    @Test("插入数据后可以查询")
    func canInsertAndFetchData() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.mainContext

        let model = ArchiveItemModel(
            id: UUID(),
            content: "测试题目"
        )
        context.insert(model)
        try context.save()

        let descriptor = FetchDescriptor<ArchiveItemModel>()
        let items = try context.fetch(descriptor)
        #expect(items.count == 1)
        #expect(items.first?.content == "测试题目")
    }

    @Test("shared 单例可访问", .disabled("访问 shared 会触发真实 SQLite 文件创建，影响测试隔离性"))
    func sharedInstanceIsAccessible() {
        let shared = PersistenceController.shared

        #expect(shared.container != nil)
    }

    @Test("fallback 标记初始值为 false")
    func fallbackFlagInitiallyFalse() {
        let controller = PersistenceController(inMemory: true)

        #expect(controller.isUsingInMemoryFallback == false)
    }

    @Test("error 属性初始值为 nil")
    func errorPropertyInitiallyNil() {
        let controller = PersistenceController(inMemory: true)

        #expect(controller.initializationError == nil)
    }
}
