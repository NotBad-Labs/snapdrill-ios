# ADR-002: 选择 SwiftData 作为持久层

## 状态
已采纳

## 日期
2025年12月

## 上下文

NotBad 需要本地持久化以下数据：
- 错题记录 (ReviewItem)：包含题目内容、答案、图片等
- 科目信息 (Subject)：分类管理
- 复习历史和掌握度

iOS 持久化方案选择：
- Core Data：成熟稳定，但 API 复杂
- Realm：第三方库，性能好但有依赖风险
- SwiftData：Apple 新框架，Swift 原生
- SQLite：底层，需要大量封装

## 决策

采用 **SwiftData** 作为持久化框架。

```swift
@Model
final class ReviewItem {
    var id: UUID
    var question: String
    var answer: String
    var masteryLevel: MasteryLevel
    var nextReviewDate: Date
    // ...
}
```

## 选项考虑

### 选项 A: Core Data
- ✅ 成熟稳定，久经考验
- ✅ 丰富的功能（iCloud 同步、迁移等）
- ❌ API 设计老旧，大量模板代码
- ❌ 类型安全差，运行时错误多
- ❌ 需要 `.xcdatamodel` 文件

### 选项 B: SwiftData
- ✅ Swift 原生，类型安全
- ✅ 声明式 API，代码简洁
- ✅ 与 SwiftUI 深度集成
- ✅ 自动迁移支持
- ❌ 相对较新，可能有 bug
- ❌ iOS 17+ 限制（已不是问题）

### 选项 C: Realm
- ✅ 性能优秀
- ✅ 跨平台支持
- ❌ 第三方依赖风险
- ❌ 包体积增加
- ❌ 与 Swift 并发模型兼容性问题

### 选项 D: SQLite + 自定义封装
- ✅ 完全控制
- ✅ 无依赖
- ❌ 开发成本高
- ❌ 需要手动处理迁移

## 后果

### 正面
1. **代码简洁**：无需 NSManagedObject 样板代码
2. **类型安全**：编译时检查模型定义
3. **SwiftUI 集成**：`@Query` 宏自动响应数据变化
4. **未来投资**：Apple 官方框架，持续演进

### 负面
1. **版本要求**：需要 iOS 17+（项目已设为 iOS 26+）
2. **早期 bug**：部分边缘情况需要 workaround
3. **迁移学习**：团队需要学习新 API

## 迁移策略

采用 `VersionedSchema` 支持数据迁移：

```swift
enum ReviewItemMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ReviewItemSchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        []
    }
}

enum ReviewItemSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [ReviewItem.self, Subject.self]
    }
}
```

## 参考

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [WWDC23: Meet SwiftData](https://developer.apple.com/videos/play/wwdc2023/10187/)
