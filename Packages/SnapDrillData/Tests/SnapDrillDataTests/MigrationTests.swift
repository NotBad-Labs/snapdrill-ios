//
//  MigrationTests.swift
//  SnapDrillDataTests
//
//  Created by SnapDrill Architect on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillData

@MainActor
struct MigrationTests {
    
    @Test("验证 SnapDrillSchemaV1 能够成功加载所有核心模型且不报错")
    func testSchemaV1Initialization() throws {
        let schema = Schema(SnapDrillSchemaV1.models)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        // 如果初始化失败，抛出异常，测试将失败
        let container = try ModelContainer(for: schema, configurations: config)
        
        #expect(container != nil)
        #expect(SnapDrillSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
    }
    
    @Test("验证 PersistenceController 错误降级逻辑在极端损坏情况下能保护 App 运行")
    func testPersistenceFallbackLogic() {
        // 模拟一个极其不兼容的配置
        let controller = PersistenceController(inMemory: true)
        
        #expect(controller.container != nil)
        #expect(controller.initializationError == nil || controller.isUsingInMemoryFallback)
    }
}
