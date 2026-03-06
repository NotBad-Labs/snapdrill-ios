# SnapDrill 架构铁律（2026-03-06 同步 .claude/architecture.md）

> ⚠️ 此文件与 `.claude/architecture.md` 和 `CLAUDE.md` 保持同步。如有冲突以 `.claude/` 为准。

## 技术栈

- **语言**: Swift 6.2（严格并发检查）
- **UI**: SwiftUI，iOS 26.0+
- **持久化**: SwiftData（`@Model` 直接作领域对象，无 Domain 层）
- **架构**: 5 个 SPM 包，严格单向依赖

## 包结构（5 包，严禁新增）

```
SnapDrillFeatures ──► SnapDrillData ──► SnapDrillCore（零依赖）
        │                                      ▲
        └──────────► SnapDrillUI ──────────────┘

SnapDrill/App ──► SnapDrillInfrastructure ──► SnapDrillCore
```

| 包 | 职责 | 禁止 |
|---|---|---|
| **SnapDrillCore** | SM-2 调度器、OCR、ImageStorage、Logger、枚举 | 不得 import 任何本地包 |
| **SnapDrillData** | @Model 类、具体 Repository 类、PersistenceController | 无 Repository 协议、无 Domain struct |
| **SnapDrillUI** | 设计系统、ImageCropper、TabItem | 无业务逻辑 |
| **SnapDrillFeatures** | View + ViewModel（5 个 feature） | 不得直接操作 ModelContext |
| **SnapDrillInfrastructure** | Firebase 全部实现 | 仅 SnapDrill/App 可 import |

## 已删除层（禁止重新引入）

- ~~Domain 层~~ — @Model 直接作领域对象
- ~~UseCase 层~~ — ViewModel 直接调 Repository
- ~~Repository 协议~~ — 使用具体 Repository 类
- ~~SnapDrillEngine 包~~ — SM-2 在 SnapDrillCore
- ~~SnapDrillService 包~~ — OCR/ImageStorage 在 SnapDrillCore
- ~~SnapDrillFeatureDashboard/Capture/Library/Review/Settings~~ — 合并为 SnapDrillFeatures

## 并发规则

- **ViewModel**: 必须是 `@Observable @MainActor final class`（View 层和 ViewModel 层都要 @MainActor）
- **Task**: 必须保存句柄，提供 `cancelTasks()`，禁止 fire-and-forget
- **禁止**: `@unchecked Sendable`、force unwrap `!`、`any` existentials（两个例外见 CLAUDE.md）
- **NotificationCenter**: 用 `for await _ in NotificationCenter.default.notifications(named:)` 替代 `addObserver`

## 数据流

```
View (@Query 驱动) → 只读 ViewModel 状态，转发用户事件
ViewModel (@MainActor) → 调用 Repository → 写入 ModelContext
ViewModel → 调用 ReviewScheduler（Core）计算 SM-2
```

## 其他铁律

- 禁止 `print()`，使用 `SnapDrillLogger`
- 禁止 `try?` 静默失败（关键路径）
- 注释：中文描述，参数名保留英文
- 每改一个字段最多改 3 个文件（警戒线）
