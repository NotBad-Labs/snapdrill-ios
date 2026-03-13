---
id: ADR-006
status: Accepted
date: 2026-03-01
---

# ADR-006: SwiftData 而非 CoreData

## 背景

项目需要本地持久化框架存储题目、学科、标签等数据。iOS 生态中的两个主要选项是 CoreData（成熟稳定，20 年历史）和 SwiftData（Apple 2023 年推出，基于 CoreData 构建的现代 API）。

## 决策

**采用 SwiftData 作为唯一持久化框架。**

理由：
- 项目 Deployment Target 为 iOS 26.0+，SwiftData 的 API 已趋于稳定
- `@Model` 宏与 SwiftUI 的 `@Query` 深度集成，声明式数据流与声明式 UI 天然契合
- Swift 原生优先原则：SwiftData 是 Apple 明确推荐的 CoreData 继任者

## 被否决的方案

### 方案 A：CoreData

- **为什么否决**：CoreData 的 NSManagedObject 是重量级对象，需要 NSManagedObjectContext 线程管理、手动 fetchRequest 构建、Objective-C 风格 API。对于新项目（无历史数据迁移负担），选择 CoreData 是选择更高的认知成本换取零额外收益
- **何时重新评估**：如果 SwiftData 在某个关键场景（如复杂 Predicate、多对多关系查询）出现框架级 bug 且 Apple 长期不修复

### 方案 B：SQLite（直接或通过 GRDB）

- **为什么否决**：丧失 SwiftUI @Query 响应式更新能力，需要手动实现数据变更通知和 UI 刷新。项目不需要 SQL 的灵活性（不做跨平台、不做自定义查询语言）
- **何时重新评估**：如果需要跨平台共享数据层（如 macOS/watchOS App 共用同一 SQLite）

### 方案 C：Realm

- **为什么否决**：第三方框架，违反 Apple 原生优先原则。Realm 被 MongoDB 收购后社区活跃度下降，长期维护存疑
- **何时重新评估**：不适用——第三方持久化框架与 Apple 原生优先原则根本冲突

## 后果

**正面**：
- `@Model` 直接作领域对象（ADR-001），消除映射层
- `@Query` 驱动 View 自动刷新，减少手动状态同步
- 与 CloudKit 的集成路径明确（SwiftData `.automatic` 模式，v2.0 规划）
- in-memory ModelContainer 提供可靠的测试基础设施（ADR-002）

**负面**：
- SwiftData 的 `#Predicate` 在 macOS 上存在 SIGTRAP 已知问题（macOS `swift test` 时 Predicate 相关测试需跳过）
- Many-to-many 关系的 `#Predicate` 支持不完善，LibraryView 的 tags 过滤被迫在内存端处理（框架限制，非设计问题）
- SwiftData 迁移工具（SchemaMigrationPlan）的文档和社区经验相比 CoreData 较少

**技术债**：
- LibraryViewModel 的 tags 内存过滤是 SwiftData 框架限制导致的，待 Apple 完善 many-to-many Predicate 后重新评估引入 @Query
