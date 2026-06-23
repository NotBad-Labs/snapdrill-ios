# ``SnapDrillData``

SwiftData 数据层，提供 `@Model` 领域对象和具体 Repository 类。

## 概述

`SnapDrillData` 直接将 `@Model` 类作为领域对象使用，无映射层、无 Domain struct。
这是有意为之的设计决策：对于单用户本地优先的 App，`@Model` 足够轻量，额外的映射层只带来维护成本。

所有写操作通过 Repository 类完成，View 层通过 `@Query` 或 `@Environment(\.repositories)` 访问数据。

## 主要类型

### 数据模型（@Model）

- ``ReviewItemModel`` — 资料条目主模型，包含内容、图片、SM-2 状态、动态分类信息
- ``CategoryDimensionModel`` — 动态分类维度（如分类、来源、级别、标签）
- ``CategoryValueModel`` — 某个动态分类维度下的可选值

### Repository（@MainActor final class）

- ``ReviewRepository`` — 题目的 CRUD、计数、过滤、级联更新
- ``CategoryDimensionRepository`` — 动态分类维度的 CRUD
- ``CategoryValueRepository`` — 动态分类值的 CRUD 与 fetch-or-create

### 容器与持久化

- ``RepositoryContainer`` — 聚合所有 Repository 的单一入口，通过 `@Environment(\.repositories)` 注入
- ``PersistenceController`` — 配置 `ModelContainer`，管理 Schema 迁移
- ``ProfileManager`` — Multi-Profile 管理（创建/切换/删除 Profile，驱动 ModelContainer 重建）

### 导出

- ``ReviewExportSnapshot`` — Sendable 快照（含 id、题干、图片路径、动态维度值等字段），用于跨 actor 边界传递题目数据

### 备份与恢复

- ``BackupService`` — `.zip` 备份文件的创建和解压（actor）
- ``BackupManifest`` — 备份文件元数据清单（schema 版本、条目数）
- ``BackupPayload`` — 备份数据传输对象顶层结构
- ``BackupError`` — 备份操作错误类型
- ``DataSeeder`` — 开发调试用的测试数据生成器

## Schema 版本

当前为 V1（旧版 V2/V3/V4 已在 PR #456 清理合并；`#Unique` 不可用因 CloudKit 不兼容），迁移计划见 `MigrationPlan.swift`。

## 依赖

- `SnapDrillCore`：引用核心类型（ReviewRating、PDFExportable 等）
- `ZIPFoundation`：ZIP 压缩/解压（备份归档）

## 禁止模式

- 禁止新增 Domain struct + `toEntity()` 映射
- 禁止新增 Repository 协议（测试使用内存 `ModelContainer`）
