# ``SnapDrillData``

SwiftData 数据层，提供 `@Model` 领域对象和具体 Repository 类。

## 概述

`SnapDrillData` 直接将 `@Model` 类作为领域对象使用，无映射层、无 Domain struct。
这是有意为之的设计决策：对于单用户本地优先的 App，`@Model` 足够轻量，额外的映射层只带来维护成本。

所有写操作通过 Repository 类完成，View 层通过 `@Query` 或 `@Environment(\.repositories)` 访问数据。

## 主要类型

### 数据模型（@Model）

- ``ReviewItemModel`` — 题目主模型，包含内容、图片、SM-2 状态、分类信息
- ``SubjectModel`` — 学科（如数学、语文）
- ``SourceModel`` — 来源（如试卷、作业、教材）
- ``GradeModel`` — 年级
- ``TagModel`` — 自由标签

### Repository（@MainActor final class）

- ``ReviewRepository`` — 题目的 CRUD、计数、过滤、级联更新
- ``SubjectRepository`` — 学科的 CRUD
- ``SourceRepository`` — 来源的 CRUD
- ``GradeRepository`` — 年级的 CRUD
- ``TagRepository`` — 标签的 fetch-or-create

### 容器

- ``RepositoryContainer`` — 聚合所有 Repository 的单一入口，通过 `@Environment(\.repositories)` 注入
- ``PersistenceController`` — 配置 `ModelContainer`，管理 Schema 迁移

### 导出

- ``ReviewExportSnapshot`` — 6 字段 `Sendable` 快照，用于跨 actor 边界传递题目数据

### 备份与恢复

- ``BackupService`` — `.snapdrill` 备份文件的创建和解压（actor）
- ``BackupManifest`` — 备份文件元数据清单（schema 版本、条目数）
- ``BackupPayload`` — 备份数据传输对象顶层结构
- ``BackupError`` — 备份操作错误类型
- ``DataSeeder`` — 开发调试用的测试数据生成器

## Schema 版本

当前为 V3，迁移计划见 `MigrationPlan.swift`。

## 禁止模式

- 禁止新增 Domain struct + `toEntity()` 映射
- 禁止新增 Repository 协议（测试使用内存 `ModelContainer`）
