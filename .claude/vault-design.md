# 多 Profile（Vault）架构设计

> v1.5 规划文档，2026-03-10 创建
> 产品依据：`product.md` 旅程 5 — 多孩家庭没有 Profile = 产品不可用

## 设计理念

参考 Obsidian Vault 模式：每个 Profile = 独立数据库 + 独立档案信息。
切换 Profile 就像切换 Vault，数据完全隔离，零交叉污染。

## 数据隔离策略

### 按 Profile 隔离（切换时变化）

| 数据 | 存储方式 | 说明 |
|---|---|---|
| 题目/标签/分类 | SwiftData（独立 .store 文件） | 每个 Profile 一个数据库 |
| 用户档案 | UserDefaults（profileKey 前缀） | userName, userMotto, userAvatar, dailyReviewGoal |
| 图片文件 | 文件系统（共享目录） | v1.5 全局共享，路径含 UUID 天然隔离 |

### 全局共享（不随 Profile 变化）

| 数据 | 说明 |
|---|---|
| 外观模式 | appearanceMode, appTintColor |
| 采集字段可见性 | captureFieldSubject 等 5 个开关 |
| 复习卡片外观 | cardFrontAlignment 等 4 个设置 |
| 通知设置 | notificationsEnabled 等 |
| 隐私设置 | analyticsEnabled, crashReportingEnabled |
| iCloud 同步开关 | 全局控制，但需按 Profile 存储 |

## 核心类型设计

### ProfileDescriptor（SnapDrillCore）

```swift
/// Profile 元数据（轻量 Codable，存储在全局 UserDefaults）
public struct ProfileDescriptor: Codable, Sendable, Identifiable {
    public let id: String          // UUID
    public var displayName: String // "小明" / "小红"
    public let createdAt: Date
}
```

### ProfileContainer（SnapDrillData）

```swift
/// 单个 Profile 的数据容器，持有独立的 ModelContainer 和 RepositoryContainer
@MainActor
public final class ProfileContainer {
    public let descriptor: ProfileDescriptor
    public let container: ModelContainer
    public let repositories: RepositoryContainer

    public init(descriptor: ProfileDescriptor) throws {
        self.descriptor = descriptor
        let dbURL = Self.databaseURL(for: descriptor.id)
        let config = ModelConfiguration(url: dbURL)
        self.container = try ModelContainer(
            for: Schema(SnapDrillSchemaV2.models),
            migrationPlan: SnapDrillMigrationPlan.self,
            configurations: config
        )
        self.repositories = RepositoryContainer(modelContext: container.mainContext)
    }

    /// 数据库文件路径：.../Profiles/{profileID}/data.store
    private static func databaseURL(for profileID: String) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Profiles/\(profileID)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("data.store")
    }
}
```

### VaultManager（SnapDrillData）

```swift
/// 管理所有 Profile 的创建/切换/删除
@MainActor
@Observable
public final class VaultManager {
    /// 当前激活的 Profile
    public private(set) var activeProfile: ProfileContainer?
    /// 所有已注册的 Profile 描述符
    public private(set) var profiles: [ProfileDescriptor] = []

    public func loadProfiles()
    public func switchTo(_ profileID: String) throws
    public func create(name: String) throws -> ProfileDescriptor
    public func delete(_ profileID: String) throws
}
```

## DependencyContainer 改造

```
现状：
  DependencyContainer.shared
    ├─ services（全局）
    ├─ repositories（全局单例）
    └─ router（全局）

改造后：
  DependencyContainer.shared
    ├─ services（全局，不变）
    ├─ vaultManager（全局）
    │   └─ activeProfile
    │       ├─ container（ModelContainer）
    │       └─ repositories（RepositoryContainer）
    └─ router（全局，不变）
```

View 层通过 `@Environment(\.repositories)` 获取当前 Profile 的 repositories，
VaultManager 切换 Profile 时更新 Environment 注入。

## AppStorage 前缀机制

```swift
// UserDefaultsKeys.swift 新增
public enum UDKey {
    // 现有全局 key 不变...

    /// 生成 Profile 作用域的 key
    public static func scoped(_ key: String, profileID: String) -> String {
        "profile_\(profileID)_\(key)"
    }
}
```

需要隔离的 key（5 个）：
- `userName`, `userMotto`, `userAvatar`, `userAvatarColorIndex`, `dailyReviewGoal`

EditProfileView 中 `@AppStorage` 的 key 需动态化，
可能需要改为 ViewModel 持有 `UserDefaults` 实例手动读写。

## 向后兼容（首次升级迁移）

1. 首次启动检测：`profiles` 列表为空
2. 自动创建 "default" Profile
3. 将现有 `default.store` 数据库**移动**到 `Profiles/default/data.store`
4. 将现有全局 UserDefaults 中的 5 个档案 key 复制到 `profile_default_*` 前缀 key
5. 迁移完成后标记 `UDKey.vaultMigrationCompleted = true`

## 文件系统布局

```
~/Library/Application Support/
├── Profiles/
│   ├── {uuid-1}/
│   │   └── data.store
│   ├── {uuid-2}/
│   │   └── data.store
│   └── ...
├── images/                    # 图片存储（v1.5 全局共享）
│   ├── {uuid}.jpg             # ImageStorage 生成的 UUID 文件名天然隔离
│   └── ...
└── default.store              # 迁移前的旧数据库（迁移后删除）
```

## 备份与恢复

- 备份范围：当前活跃 Profile 的全部数据（题目 + 分类 + 图片）
- 备份文件名：`SnapDrill_小明_2026-03-10.snapdrill`
- 恢复时选择目标 Profile
- 现有 BackupService API 无需改动（已按 RepositoryContainer 粒度工作）

## UI 设计

### 设置页 Profile 区域（SettingsView 顶部）

```
┌─────────────────────────────┐
│  👤 小明              ✏️ 编辑 │  ← 当前 Profile
│  共 47 道题                   │
├─────────────────────────────┤
│  切换档案                  >  │  ← NavigationLink → ProfileListView
└─────────────────────────────┘
```

### ProfileListView

```
┌─────────────────────────────┐
│  ✅ 小明        47 道题      │  ← 当前选中
│     小红        23 道题      │
│     + 新建档案               │
└─────────────────────────────┘
```

## 不在此范围

- iCloud 按 Profile 同步（v2.0）
- Profile 导出/导入分享（v2.0）
- 按 Profile 隔离图片目录（v2.0，当前 UUID 文件名已天然隔离）
- 家长模式 / 权限控制（待产品决策）

## 实现顺序（v1.5 开发时）

1. `ProfileDescriptor` + `UDKey.scoped()` — Core 层，零风险
2. `ProfileContainer` — Data 层，独立 ModelContainer
3. `VaultManager` — Data 层，Profile CRUD
4. 向后兼容迁移逻辑 — Data 层
5. `DependencyContainer` 改造 — App 层
6. `ProfileListView` + `EditProfileView` 改造 — Features 层
7. 测试
