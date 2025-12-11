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
@_exported import ReviewKitCore
@_exported import ReviewKitModels
@_exported import ReviewKitPersistence

// 调度器别名保持兼容
public typealias Scheduler = ReviewScheduler
// 模型别名保持兼容（ReviewItem 在模型模块内定义）


