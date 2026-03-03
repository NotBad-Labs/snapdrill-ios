# SnapDrill 系统性重构计划

**目标**：删除 SnapDrillDomain 整个包，5 包 → 4 包。
**跟踪**：GitHub Issues（仓库：NotBad-Labs/snapdrill-ios，MCP 已配置）

格式：`[ ]` 待处理 / `[x]` 完成 / `[-]` 已确认不需要

---

## Phase 1：迁移 Core 内容（无破坏性，先做）✅

> Issue [#27](https://github.com/NotBad-Labs/snapdrill-ios/issues/27)（已关闭）

- [x] `ReviewRating` enum 移到 Core（`Engine/ReviewRating.swift`）
- [x] `SM2State` 值类型新建于 Core（`Engine/SM2State.swift`）—— 解耦 ReviewScheduler 与 ReviewItem
- [x] `ReviewScheduler` 重构并移回 Core（`Engine/ReviewScheduler.swift`），接口改为 SM2State
- [x] `Difficulty` enum 移到 Core（`Model/Difficulty.swift`）
- [x] `ReviewDataNotification` 移到 Core（`Support/ReviewDataNotification.swift`）
- [x] Domain `ReviewUseCase` 适配 SM2State（构建 SM2State → 调度 → 写回 ReviewItem）
- [x] Domain `ReviewSchedulerTests` 改用 SM2State + `import SnapDrillCore`
- [x] swift test Core 12/12 ✅，Domain 31/31 ✅，Data XCTest ✅

---

## ⚠️ 执行顺序修正（2026-03-02）

Phase 2/3/4/5 深度耦合，`ReviewItem` 在 Features 30+ 处使用。
正确执行顺序：**4 → 3+5 → 2 → 6**

---

## Phase 4：Repository 层去协议化（容器层）✅

> Issue [#28](https://github.com/NotBad-Labs/snapdrill-ios/issues/28)（已关闭）

**实际范围**：仅去掉 `RepositoryContainer` 容器协议。个别 Repository 协议（ReviewRepositoryProtocol 等）因 UseCase 循环依赖暂保留，待 Phase 3+5 一并删除。

- [x] `RepositoryContainer` 协议删除，`DefaultRepositoryContainer` 改名为 `RepositoryContainer` 具体类
- [x] `RepositoryContainer` 属性类型从协议改为具体类（`ReviewRepository`、`SubjectRepository` 等）
- [x] `DefaultUseCaseContainer.init(repositories:)` 参数类型改为具体 `RepositoryContainer`
- [x] `DependencyContainer.repositories` 类型改为具体 `RepositoryContainer`
- [x] Features 新增 `@Environment(\.repositories)` 环境键（`RepositoryContainer+Environment.swift`）
- [x] `SnapDrillApp` 注入 `.environment(\.repositories, container.repositories)`
- [-] 个别 Repository 协议（ReviewRepositoryProtocol 等）**暂保留**（Phase 3+5 删）
- [x] swift test Domain 31/31 ✅，Data XCTest ✅

---

## Phase 3+5：删 UseCase + Features 全量适配（第二步，最大工作量）

> Issue #__（待创建）

**目标**：Features ViewModel 直接调用具体 Repository；引入 @Query；删除整个 UseCase 层。

- [ ] 删除 `ReviewSessionManager`（ViewModel 直接调用 Repository）
- [ ] 删除 `ReviewUseCase` / `ReviewUseCaseProtocol`
- [ ] 删除 `TaxonomyUseCase` / `TaxonomyUseCaseProtocol`
- [ ] 删除 `UseCaseContainer` / `DefaultUseCaseContainer` / `UseCaseContainer+Environment.swift`
- [ ] `ReviewViewModel` 改为注入 `ReviewRepository` + `ReviewScheduler`
- [ ] `LibraryViewModel` → `@Query` 驱动列表（替代 `reviewDataDidChange` 通知）
- [ ] `DashboardViewModel` → `@Query` 驱动统计数据
- [ ] `ReviewViewModel` → 评估 @Query 适用性（session 状态机特殊）
- [ ] 所有 ViewModel 删除 `useCases.xxx`，改为直接调 `repositories.xxx`
- [ ] `[ReviewItem]` → `[ReviewItemModel]`，`[Subject]` → `[SubjectModel]` 等全量替换

---

## Phase 2：删除 Domain 实体（第三步，此时已无引用）

> Issue #__（待创建）

- [ ] 删除 `ReviewItem`（Domain struct）
- [ ] 删除 `Subject`、`Source`、`Tag`、`Grade`（Domain struct）
- [ ] 删除所有 `toEntity()` / `fromEntity()` 映射代码（Data 层）
- [ ] 删除 `DomainError`
- [ ] 删除 `ReviewItem+PDFExportable.swift`（改为 `ReviewItemModel` 遵循 `PDFExportable`）
- [ ] 删除 `SnapDrillDomain` Package.swift 及目录

---

## Phase 6：清理与收尾

> Issue #__（待创建）

- [ ] 从 `SnapDrillFeatures/Package.swift` 移除 `SnapDrillDomain` 依赖
- [ ] 从主工程 `project.pbxproj` 移除 Domain 包引用
- [ ] 运行全量 build 验证
- [ ] 运行 `swift test`（Core + Data）
- [ ] 跑 `swiftlint`，0 violations

---

## 不动的部分

- Service 层（OCR、Firebase Analytics、Crashlytics、通知服务）
- `@Model` 类的字段定义（只是去掉映射层）
- Repository 的 fetch 封装（predicate 逻辑有价值）
- SM-2 算法本身（ReviewScheduler 逻辑）
- DI 组合根（DependencyContainer）结构
- SwiftUI View 层整体结构
- `@Observable @MainActor final class` ViewModel 约定
