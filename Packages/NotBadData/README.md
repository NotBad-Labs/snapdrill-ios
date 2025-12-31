# NotBadData

**数据持久化层 (The Persistence Layer)**

`NotBadData` 使用 **SwiftData** 管理所有本地数据库交互。它封装了数据存储、检索和迁移的复杂性。

## 职责
- **数据模型**: `ReviewItemModel` (SwiftData 类)。
- **仓库 (Repositories)**: `ReviewRepository` (增删改查操作)。
- **栈管理**: `PersistenceController` (负责 ModelContainer 的配置)。

## 依赖
- `NotBadCore`: 将核心领域实体映射为持久化模型。

## 关键用法
```swift
// 需要有效的上下文 (MainActor)
let repo = ReviewRepository(modelContext: context)
let items = try repo.fetchAll()
```
