---
id: ADR-001
status: Accepted
date: 2026-03-03
---

# ADR-001: @Model 直接作领域对象（删除 Domain 层）

## 背景

项目早期采用了经典的分层架构：SwiftData `@Model` 仅作为持久化实体，另有独立的 Domain struct 作为领域对象，通过 `toEntity()` / `toDomain()` 映射层在两者之间转换。

随着功能迭代，这套架构暴露了严重问题：
- 每改一个字段需要同步修改 5+ 个文件（Model、Domain struct、映射方法、Repository、ViewModel）
- 映射层是纯机械代码，零业务价值，但占据大量维护成本
- 对于本地优先、单体 App，Domain struct 与 @Model 的字段完全一一对应，抽象层无实际收益

## 决策

**删除 Domain 层。SwiftData `@Model` 直接作为领域对象，贯穿 Repository → ViewModel → View 全链路。**

每改一个字段最多改 3 个文件（Model 定义、Repository 查询、ViewModel/View 使用）是警戒线。

## 被否决的方案

### 方案 A：保留 Domain struct + 映射层

- **为什么否决**：SwiftData 的 `@Model` 是轻量级的（不同于 NSManagedObject），对于本地优先的单体 App，Domain struct 与 @Model 字段完全一致，映射层是纯维护成本
- **什么时候重新评估**：如果出现跨平台复用需求（如 macOS App 共享领域逻辑），或需要将领域对象序列化传输到远端

### 方案 B：MVVM + UseCase 层

- **为什么否决**：UseCase 层在当前规模下是透传层——每个 UseCase 方法只是调用 Repository 同名方法。删除后 ViewModel 直接调 Repository，代码更短且无信息损失
- **什么时候重新评估**：如果出现复杂业务编排（一个操作需要协调多个 Repository + 外部服务），UseCase 层才有存在价值

## 后果

**正面**：
- 字段变更的改动文件数从 5+ 降到 3 以内
- 消除了约 200 行纯映射代码
- 新开发者（含 AI 协作者）理解数据流的认知成本大幅降低

**负面**：
- `@Model` 类直接暴露给 View 层，理论上 View 可以直接修改模型属性（通过 ViewModel 纪律约束，而非编译器强制）
- 如果未来需要跨平台共享领域逻辑，需要重新引入映射层

**技术债**：无。这是有意的架构简化，不是偷懒。
