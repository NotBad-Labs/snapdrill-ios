# Changelog

All notable changes to SnapDrill are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Version scheme: `MAJOR.MINOR.PATCH` (App Store) + build number.

---

## [Unreleased]

### Fixed
- **复习页面** 生成测试数据后复习队列不刷新的根本原因：移除 `ReviewView` 中
  不稳定的 `isFirstAppear` 状态机，改为 `viewModel == nil` 判断，保证每次
  Tab 切换回来都能重新加载数据。
- **设置页面** 删除 `generateMockData()` 中的冗余通知，`DataSeeder` 已在
  `save()` 后统一 post `reviewDataDidChange`，避免双发导致竞态。

### Changed
- 代码质量全量审计修复（F01–F07，约 97 项）：
  - **F01** `Task` 句柄补全：`SettingsView`、`DataAndSyncSettingsView`、
    `NotificationSettingsView` 异步 Task 现均存储句柄并在视图消失时取消；
    `PerformanceMonitoringExtensions` fire-and-forget 埋点添加豁免注释。
  - **F02** 死代码清理：删除全项目零引用的 `Routable.swift`；
    `ReviewCardFactory` 降级为 `internal`（仅包内使用，无需 `public`）。
  - **F03** 布尔命名规范：`showingSubjectManager` → `isShowingSubjectManager`，
    `showingDraftAlert` → `isShowingDraftAlert`，`animate` → `isAnimating`。
  - **F04** 未使用状态清理：删除 `HelpView` 中零引用的 `@State selectedTopic`。
  - **F05** 文件头与注释修正：10 个文件补全职责描述行；删除
    `NetworkMonitor`、`ReviewRepository` 中两处已实现但未更新的 TODO；
    修正 `FirebaseAnalyticsService` 过期历史注释；
    同步 `DataSeeder` DocC 与实际行为。
  - **F06** 测试质量提升：将 11 个 `XCTAssertTrue(true, "...")` 虚假测试
    改为 `XCTAssertNoThrow` 并加 `_doesNotCrash` 后缀；新增 5 个
    `AnalyticsServiceMock` 行为合约测试（trackedEvents、trackedScreens、
    sessionCount、userProperties、clear）。
  - **F07** 样式修正：补全 `PerformanceMonitor.measure(_:_:_:)` 空 DocC 行。

---

## [1.1.0] — Internal TestFlight (Build 4)

> 内部测试阶段，尚未公开发布。

### Added
- Onboarding 引导页（首次安装引导流程）
- 隐私政策页底部添加官网完整版链接
- Firebase Hosting 隐私政策静态页面

### Changed
- **架构重大重构**：删除 `SnapDrillDomain` 包（UseCase 层 + Domain struct 映射层）。
  `@Model` 直接作领域对象，ViewModel 直接调用 `Repository`，减少约 40 个文件、
  消除所有 `toEntity()` 映射代码。
- `DataSeeder` 改为接受并使用 `mainContext`，避免跨 Context 合并时机竞争。
- `RepositoryContainer` 升级为聚合容器，提供统一数据清理入口。
- SPM 包由 5 个精简为 4 个（Core / Data / UI / Features）。
- API 基础设施清单 (`.claude/infrastructure.md`) 建立，防止凭空捏造接口。
- 功能验收标准与发版前检查清单 (`ACCEPTANCE.md`) 建立。

### Fixed
- **复习界面** 图片题正面空白、背面无题目上下文。
- **题库界面** 答案展示缺失、批量删除静默失败、`loadPhoto` Task 泄漏。
- **首页仪表盘** 来源删除保护缺失、假数据进度环、断链操作。
- **拍照界面** 空剪贴板无反馈、剪贴板逻辑泄漏至 View 层。
- **设置界面** 占位语言切换器改为系统设置跳转；隐私政策与用户协议法律文本修正；
  License 页补全 Firebase 相关开源许可。
- `PersistenceController.isUsingInMemoryFallback` 成功路径错误赋值修复。
- `MockSubjectRepository`/`SourceRepository` cascade 语义修复（旧 key 未删除）。
- `ReviewDataNotification.post()` 错误调用修正。
- 全模块代码审查（批次 1）：Task 取消安全、访问控制、并发隔离等约 20 项修复。

### Removed
- `SnapDrillDomain` 包（UseCase 层、Domain struct、`toEntity()` 映射）
- `DefaultUseCaseContainer`、`\.useCases` Environment key
- `Routable.swift`（全项目零引用，`FeatureRouter` 为唯一路由协议）

---

## [1.0.0] — 初始开发版本

> 项目基础架构建立，核心功能实现。

### Added
- SM-2 间隔重复调度引擎（`ReviewScheduler`）
- 拍照 + OCR 录题流程（`CaptureView`）
- 题库管理（`LibraryView`，支持搜索 + 多维过滤）
- 复习会话（卡片翻转、滑动评分、撤销）
- 首页仪表盘（今日统计、待复习计数、进度环）
- 设置（通知提醒、数据导出、iCloud 同步状态）
- Firebase Analytics + Crashlytics 集成
- ATT (App Tracking Transparency) 隐私授权流程
- SwiftData 持久化 + iCloud CloudKit 同步
- 4 个 SPM 包模块化架构（Core / Data / UI / Features）
