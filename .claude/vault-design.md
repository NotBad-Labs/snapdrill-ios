# 多 Profile（Vault）架构设计

> v1.5 规划文档，2026-03-10 创建
> 产品依据：`product-journeys.md` 旅程 5 — 多孩家庭没有 Profile = 产品不可用

## 设计理念

参考 Obsidian Vault 模式：每个 Profile = 独立数据库 + 独立档案信息。
切换 Profile 就像切换 Vault，数据完全隔离，零交叉污染。

## 数据隔离策略

### 按 Profile 隔离（切换时变化）

| 数据 | 存储方式 | 说明 |
|---|---|---|
| 题目/标签/分类 | SwiftData（独立 .store 文件） | 每个 Profile 一个数据库 |
| 用户档案 | UserDefaults（profileKey 前缀） | userName, userMotto, userAvatar, dailyReviewGoal |
| 图片文件 | 文件系统（按 Profile 分目录） | `images/{profileID}/` 物理隔离，删除 Profile 时整目录清理 |
| 采集草稿 | CaptureDraftService | 按 Profile 隔离，避免切换时草稿串档 |
| 自动推断上下文 | UserDefaults（profileKey 前缀） | lastSelectedSubject, lastSelectedSource |
| 复习卡片外观 | UserDefaults（profileKey 前缀） | cardFrontAlignment 等 4 个设置（不同孩子可能有不同偏好） |

### 全局共享（不随 Profile 变化）

| 数据 | 说明 |
|---|---|
| 外观模式 | appearanceMode, appTintColor |
| 采集字段可见性 | captureFieldSubject 等 5 个开关 |
| 通知设置 | notificationsEnabled 等 |
| 隐私设置 | analyticsEnabled, crashReportingEnabled |
| iCloud 同步开关 | 全局控制，但需按 Profile 存储 |
| 活跃 Profile ID | `selectedProfileID`，冷启动时恢复上次 Profile |

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

## Profile 切换：重启级操作

**核心问题**：已挂载的 ViewModel 持有旧 Profile 的 RepositoryContainer 引用，
单纯替换 `@Environment(\.repositories)` 无法更新它们——这会导致跨档数据污染。

**解决方案**：Profile 切换是"重启级"操作，而非变量赋值。

```
切换流程：
1. 取消所有进行中的 Task（OCR、保存、草稿等）
2. 保存当前 Profile 的 mainContext（持久化未保存变更）
3. 清空所有 Router 的 NavigationPath（回到根视图）
4. 释放旧 ProfileContainer（置 nil，ARC 释放 ModelContainer）
5. 创建新 ProfileContainer（新的 ModelContainer + RepositoryContainer）
6. 更新 Environment 注入
7. 刷新所有 Tab 的根视图（ViewModel 重新从 Environment 获取 repositories）
```

**实现方式**：在 `ContentView` 中监听 `vaultManager.activeProfile` 变化，
使用 `.id(activeProfile?.descriptor.id)` 强制重建整个 TabView 子树，
确保所有 View 和 ViewModel 从零开始初始化，获取新的 repositories。

```swift
// ContentView.swift
TabView(selection: $selectedTab) {
    // ... tabs ...
}
.id(container.vaultManager.activeProfile?.descriptor.id ?? "none")
// activeProfile 变化 → SwiftUI 销毁整个 TabView → 所有子 View/ViewModel 重建
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
配合 `.id()` 修饰符，切换时整棵视图树重建，ViewModel 自然获取新的 repositories。

## AppStorage 前缀机制

```swift
// UserDefaultsKeys.swift 新增
public enum UDKey {
    // 现有全局 key 不变...

    /// 生成 Profile 作用域的 key
    public static func scoped(_ key: String, profileID: String) -> String {
        "profile_\(profileID)_\(key)"
    }

    /// 冷启动时恢复上次活跃的 Profile
    public static let selectedProfileID = "selectedProfileID"
}
```

需要隔离的 key（10 个）：
- 用户档案：`userName`, `userMotto`, `userAvatar`, `userAvatarColorIndex`, `dailyReviewGoal`
- 自动推断：`lastSelectedSubject`, `lastSelectedSource`
- 复习卡片外观：`cardFrontAlignment` 等（具体 key 待实现时清点）

EditProfileView 中 `@AppStorage` 的 key 需动态化，
改为 ViewModel 持有 `UserDefaults` 实例手动读写，
建议封装 `ProfileSettingsStore` 避免 scoped key 拼接逻辑散落各处。

## 向后兼容（首次升级迁移）

采用 **copy-first** 安全迁移策略，避免中断导致数据丢失：

1. 首次启动检测：`profiles` 列表为空
2. 自动创建 "default" Profile
3. **复制**（非移动）现有 `default.store` 数据库到 `Profiles/default/data.store`
4. 验证新路径 `ModelContainer` 可正常打开
5. **复制**现有 `images/` 目录到 `images/default/`（保留原目录）
6. 将现有全局 UserDefaults 中的档案 key 复制到 `profile_default_*` 前缀 key
7. 迁移完成后标记 `UDKey.vaultMigrationCompleted = true`
8. **标记完成后**，删除旧 `default.store` 和旧 `images/` 中已迁移的文件

**容错**：步骤 7 之前任何环节失败或 App 被杀，下次启动重新执行全流程（幂等）。
旧文件只在标记完成后才删除，确保数据永不丢失。

## 图片存储隔离

**策略**：按 Profile 物理分目录，删除 Profile 时整目录清理，零僵尸文件。

```swift
// ImageStorage 改造：接受 profileID 参数
public struct ImageStorage {
    private let profileID: String

    public init(profileID: String) {
        self.profileID = profileID
    }

    /// 图片存储路径：.../images/{profileID}/{uuid}.jpg
    private func imageDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("images/\(profileID)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
```

**Profile 删除时的清理**：
```swift
// VaultManager.delete()
func delete(_ profileID: String) throws {
    // 1. 删除数据库：Profiles/{profileID}/ 整目录
    // 2. 删除图片：images/{profileID}/ 整目录
    // 3. 清理 UserDefaults 中 profile_{profileID}_* 前缀的所有 key
    // 4. 从 profiles 列表中移除 descriptor
}
```

## 文件系统布局

```
~/Library/Application Support/
├── Profiles/
│   ├── {uuid-1}/
│   │   └── data.store
│   ├── {uuid-2}/
│   │   └── data.store
│   └── ...
├── images/
│   ├── {uuid-1}/                 # Profile 1 的图片
│   │   ├── {image-uuid}.jpg
│   │   └── ...
│   ├── {uuid-2}/                 # Profile 2 的图片
│   │   ├── {image-uuid}.jpg
│   │   └── ...
│   └── ...
└── default.store                 # 迁移前的旧数据库（迁移完成后删除）
```

## 备份与恢复

- 备份范围：当前活跃 Profile 的全部数据（题目 + 分类 + 该 Profile 的图片目录）
- 备份文件名：`SnapDrill_小明_2026-03-10.snapdrill`
- 恢复时选择目标 Profile
- 现有 BackupService API 无需改动（已按 RepositoryContainer 粒度工作）
- 单 Profile 备份策略 v1.5 足够；如需"全量备份所有 Profile"，列入 v2.0

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

## 已知限制与预警

### iCloud 多 Container 限制（v2.0 预警）

Apple 的 `SwiftData + CloudKit`（`NSPersistentCloudKitContainer`）不支持
同时绑定多个本地 Container 或动态切换绑定源。
v2.0 实现 iCloud 按 Profile 同步时，可能需要：
- 方案 A：所有 Profile 数据合并到单一 Container，用 `profileID` 字段区分（放弃物理隔离）
- 方案 B：使用手动 CloudKit API（`CKRecord` + `CKDatabase`）而非 SwiftData 自动同步
- 需在 v2.0 架构评审时提前决策

## 不在此范围

- iCloud 按 Profile 同步（v2.0，见上方预警）
- Profile 导出/导入分享（v2.0）
- 家长模式 / 权限控制（待产品决策）

## 实现顺序（v1.5 开发时）

1. `ProfileDescriptor` + `UDKey.scoped()` + `selectedProfileID` — Core 层，零风险
2. `ImageStorage` 改造（接受 profileID）— Core 层
3. `ProfileContainer` — Data 层，独立 ModelContainer
4. `VaultManager` — Data 层，Profile CRUD + 重启级切换
5. 向后兼容迁移逻辑（copy-first 策略）— Data 层
6. `DependencyContainer` 改造 + `.id()` 视图树重建 — App 层
7. `ProfileSettingsStore` + `ProfileListView` + `EditProfileView` 改造 — Features 层
8. 测试（重点：切换后旧 ViewModel 不残留、迁移幂等性、Profile 删除清理完整性）
