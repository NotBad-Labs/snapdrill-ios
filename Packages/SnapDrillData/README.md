# SnapDrillData

> **文档角色：当前实现参考。** 本页描述 live SwiftData / ZIP v2 路径，不把 Multi-Profile 或
> ZIP v2 提升为 Release 1 目标；目标边界见 Local Library Data Contract 与 Backup Wire Format。

**数据持久化层 (The Persistence Layer)**

`SnapDrillData` 使用 **SwiftData** 管理所有本地数据库交互。`@Model` 类直接作领域对象（无独立 Domain struct 映射层）。

## 组成部分

### 数据模型（@Model）
- `ArchiveItemModel`: 归档资料项（核心实体）
- `CategoryDimensionModel`: 动态分类维度（内置 systemKey: category/source/level/tag）
- `CategoryValueModel`: 分类维度值（与 ArchiveItemModel 多对多关联）

### 具体 Repository 类（无协议）
- `ArchiveRepository`: 归档资料项的 CRUD、计数、过滤
- `CategoryDimensionRepository`: 分类维度管理
- `CategoryValueRepository`: 分类值管理（含 fetchOrCreate）

### 数据管理
- `RepositoryContainer`: 聚合容器，统一数据清理入口
- `BackupService`: 数据备份与恢复（JSON + 图片 ZIP 归档）
- `ProfileManager`: 当前 Multi-Profile 实现遗留（创建/切换/删除 Profile），待单资料库收敛
- `ArchiveExportSnapshot`: 导出专用 Sendable 快照（桥接 @Model → Transferable）
- `DataExecutor`: actor 持有 `ModelContainer`，负责持久化入口与 #599 死锁规避
- `DataSeeder`: 测试数据生成器

## 依赖
- `SnapDrillCore`: 引用核心类型（ReviewRating、PDFExportable 等）
- `ZIPFoundation`: ZIP 压缩/解压（备份归档）

## 关键用法
```swift
// 需要有效的上下文 (MainActor)
let repo = ArchiveRepository(modelContext: context)
let items = try repo.fetchAllModels()
```
