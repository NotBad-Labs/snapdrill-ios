# SnapDrillData

**数据持久化层 (The Persistence Layer)**

`SnapDrillData` 使用 **SwiftData** 管理所有本地数据库交互。`@Model` 类直接作领域对象（无独立 Domain struct 映射层）。

## 组成部分

### 数据模型（@Model）
- `ReviewItemModel`: 复习条目（核心实体）
- `SubjectModel`: 学科
- `SourceModel`: 来源
- `GradeModel`: 年级
- `TagModel`: 标签（多对多关联）

### 具体 Repository 类（无协议）
- `ReviewRepository`: 复习条目的 CRUD、计数、过滤
- `SubjectRepository` / `SourceRepository` / `GradeRepository`: 分类管理
- `TagRepository`: 标签管理（含 fetchOrCreate）

### 数据管理
- `RepositoryContainer`: 聚合容器，统一数据清理入口
- `BackupService`: 数据备份与恢复（JSON + 图片 ZIP 归档）
- `ProfileManager`: Multi-Profile 管理（创建/切换/删除 Profile）
- `ReviewExportSnapshot`: 导出专用 Sendable 快照（桥接 @Model → Transferable）
- `PersistenceController`: ModelContainer 配置与迁移
- `DataSeeder`: 测试数据生成器

## 依赖
- `SnapDrillCore`: 引用核心类型（Difficulty、ReviewRating 等）
- `ZIPFoundation`: ZIP 压缩/解压（备份归档）

## 关键用法
```swift
// 需要有效的上下文 (MainActor)
let repo = ReviewRepository(modelContext: context)
let items = try repo.fetchAllModels()
```
