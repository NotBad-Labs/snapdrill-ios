// ReviewKit - 错题复习核心库
//
// 这是 NotBad 的领域层（Domain Layer），包含：
// - 实体 (Entity): ReviewItemModel
// - 值对象 (Value Objects): Subject, Grade, Difficulty 等
// - 业务逻辑 (Business Logic): ReviewScheduler
// - 持久化 (Persistence): PersistenceController
//
// 可以在 iOS App、Widget、App Clip、macOS、watchOS、CLI 等任何环境使用。
// 主 App 和 Widget 都 import ReviewKit，确保使用相同的
// 完全限定类名 `ReviewKit.ReviewItemModel`。

@_exported import Foundation
@_exported import SwiftData

// MARK: - 重导出公共 API

// 调度器
public typealias Scheduler = ReviewScheduler

// 模型（保持向后兼容）
// ReviewItem 和 ReviewItemModel 都可用

