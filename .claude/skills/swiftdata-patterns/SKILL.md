---
name: swiftdata-patterns
description: SwiftData 模式速查。当涉及 @Model、#Predicate、ModelContainer、迁移、测试时自动激活。避免常见陷阱（actor 隔离、Predicate 限制、in-memory 测试）。
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# SwiftData Patterns（SnapDrill 专用）

## 核心决策（ADR 快速索引）

| 决策 | 结论 | ADR |
|---|---|---|
| @Model = 领域对象 | 无 Domain struct，无映射层 | ADR-001 |
| Repository 无协议 | in-memory ModelContainer 替代 Mock | ADR-002 |
| SwiftData > CoreData | 原生 Swift 宏，简洁 API | ADR-006 |

## Gotchas（踩过的坑）

### 1. ModelContainer 生命周期
ModelContext 对 ModelContainer 持**弱引用**。如果 container 被提前释放（如测试中作为局部变量），后续 insert/fetch/save 会崩溃（`x0 = nil, brk #1`）。
**正确做法**：container 必须作为实例属性保活。

### 2. #Predicate many-to-many 不支持
SwiftData `#Predicate` 无法表达 `tags.contains(where:)` 等 many-to-many 关系过滤。
**正确做法**：fetch 全量后内存端过滤（LibraryViewModel 现有模式）。见 TD-1。

### 3. macOS swift test 崩溃
SwiftData `#Predicate` 在 macOS 上会 SIGTRAP（XCTest 框架限制）。
**正确做法**：Predicate 相关测试必须通过 Xcode Simulator 运行，不用 `swift test`。

### 4. @Query vs Repository.fetch
- **@Query**：列表展示、实时聚合统计、简单过滤
- **Repository.fetch**：复杂业务规则、跨多源聚合、状态机流程（ReviewViewModel）
- 详见 `principles.md`「@Query 使用原则」

### 5. in-memory 测试模式
```swift
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(for: ReviewItemModel.self, configurations: config)
let repo = ReviewRepository(modelContext: container.mainContext)
```
不需要协议，不需要 Mock。测试完整的 SwiftData 行为栈。

### 6. 迁移
`MigrationPlan.swift` 管理 Schema V1→V2 迁移。新增字段时：
1. 在 `@Model` 加字段（带默认值）
2. 新建 Schema 版本
3. 加 `MigrationStage`
4. 最多改 3 个文件是警戒线

### 7. insert vs insertAndSave
- `insert()` = 纯内存插入，不 save。批量操作后统一 `saveContext()`
- `insertAndSave()` = insert + save，单条操作用
- `saveContext()` 失败时调 `rollbackContext()` 回滚

## 参考

- `infrastructure.md`：所有 Repository API 签名
- `principles.md`：@Query 使用原则、@Model = 领域对象
- `principles.md`（@Model = 领域对象、Repository 无协议、SwiftData 选型）
