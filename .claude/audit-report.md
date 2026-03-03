# SnapDrill 全量代码审计报告

> 审计员：Claude Code
> 审计日期：2026-03-03
> 范围：164 个业务 .swift 文件，约 19,275 行
> 标准：audit-checklist.md（A1-A6, B1-B6, C1-C5, D1-D6, E1-E6）
> 批次：B01–B18（共 19 批，B17+B18 合并执行）

---

## 执行摘要

| 严重程度 | 数量 | 说明 |
|---|---|---|
| 🔴 严重（功能性 Bug / 架构违规） | 14 | 需立即修复 |
| 🟡 中等（命名/文档/最佳实践） | 64 | 下次迭代修复 |
| 🟢 低（风格/细节） | 40 | 可接受但建议优化 |
| **合计** | **~118** | |

**已在本次审计中修复（5 项）：**
1. ✅ `SettingsViewModel.swift` — clearAllData() 漏发 reviewDataDidChange 通知（功能性 Bug）
2. ✅ `ExportOptionsSheet.swift` — 删除两个僵尸 @State 属性（showingWordShare, wordExportURL）
3. ✅ `ExportPreviewView.swift` — 修正文件头描述（错误标为"已废弃"）
4. ✅ `ReviewComponents.swift` — 删除空占位符文件（18 行，无实际代码）
5. ✅ `DashboardComponents.swift` — 删除空占位符文件（14 行，无实际代码）

---

## 批次详细结果

---

### B01 — SnapDrillCore / DI + Engine + Model（10 文件，551 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| B2 | `ReviewRating.swift:21` | `var description` 实为 UI label，命名有歧义 | 重命名为 `var label: String` |
| A5 | `SM2Engine.swift:15` | 注释引用 `SM2Engine` 但类型是 `ReviewScheduler` | 删除或更新注释 |

**总计：2 个问题（均为低/中等）**

---

### B02 — SnapDrillCore / Service 前半（10 文件，728 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| A3 | `AnalyticsServiceProtocol.swift:8` | 文件头描述行缺失 | 补充一行中文职责描述 |
| A3 | `CrashReportingProtocol.swift:8` | 文件头描述行缺失 | 补充一行中文职责描述 |
| A3 | `CrashReportingServiceMock.swift:8` | 文件头描述行缺失 | 补充一行中文职责描述 |
| B2 | `AnalyticsServiceMock.swift:12` | `var eventLog: [String]` 布尔标志命名缺 is/has 前缀（不适用此处，但 `tracking` 属性命名歧义） | 确认语义后重命名 |
| D4 | `CrashReportingServiceMock.swift` | `import Foundation` 可能多余（若仅用 Swift 标准库） | 验证后删除 |

**总计：5 个问题（均为低/中等）**

---

### B03 — SnapDrillCore / Firebase + ImageStorage + Keychain + LiveNotification + Network（6 文件，478 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| A4 | `FirebaseAnalyticsService.swift:22` | 注释"替换 AnalyticsTrackingService"但后者已被完全替换，注释失效 | 删除该历史注释 |
| A3 | `KeychainService.swift:8` | 文件头描述行缺失 | 补充中文职责描述 |
| B2 | `NetworkMonitor.swift:18` | `var isConnected` 正确，但 `status` 属性缺少语义限定词 | 重命名为 `connectionStatus` 或 `networkStatus` |
| E1 | `LiveNotificationService.swift:45` | Task { } 无句柄存储（I/O 操作） | 存储 task 句柄以支持取消 |
| A5 | `NetworkMonitor.swift:35` | `// TODO: 支持 WiFi/Cellular 区分` — 现有代码已支持区分 | 删除过时 TODO |
| B5 | `KeychainService.swift:30` | 参数 `forKey` 缩写不清晰 | 使用 `key:` 标签 |
| D4 | `LiveNotificationService.swift` | `import UserNotifications` 与 `import Foundation` 可能重复 | 验证依赖链后清理 |

**总计：7 个问题（含 1 个中等 E1）**

---

### B04 — SnapDrillCore / Service 后半（9 文件，794 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| A3 | `PrivacyConsentService.swift:8` | 文件头描述行缺失 | 补充中文职责描述 |
| A3 | `SubscriptionServiceMock.swift:8` | 文件头描述行缺失 | 补充中文职责描述 |
| B2 | `SubscriptionServiceMock.swift:20` | `var isSubscribed` 应更精确，与 `SubscriptionStatus` 区分 | 保持一致性，或使用 `hasActiveSubscription` |
| D1 | `PDFExportService.swift:55` | `static var pageCount: Int` 未在任何 UI 中引用 | 确认是否 TODO 功能，否则删除 |
| E2 | `PDFExportService.swift:30` | `nonisolated(unsafe)` 使用处缺少理由注释 | 补充注释说明为何必须 nonisolated(unsafe) |
| A1 | `OCRService.swift:40` | DocC 注释描述"返回识别文本"但抛出错误时返回空字符串而非抛出 | 更新注释或修改行为 |
| B6 | `PerformanceMonitor.swift:25` | 参数标签 `_ name` 丢失介词，违反 Swift API Design Guidelines | 改为 `named name:` 或 `withName name:` |
| A5 | `AppConfiguration.swift:50` | `// TODO: 从远程加载配置` — 已有网络监控基础设施 | 评估是否仍计划实现，否则删除 TODO |

**总计：8 个问题（含 1 个中等 E2）**

---

### B05 — SnapDrillCore / Support + Utils（10 文件，1,006 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| 🔴 C4 | `AppConfiguration.swift:35` | `static func registerRemoteProvider()` 修改 `@MainActor` 隔离状态但自身无 `@MainActor` 标注 | 添加 `@MainActor` 标注 |
| 🔴 E1 | `PerformanceMonitoringExtensions.swift:60` | `Task { }` 在阈值超出回调中无句柄，I/O fire-and-forget | 存储 task 句柄或使用 structured concurrency |
| A3 | `DateExtensions.swift:8` | 文件头描述行缺失 | 补充中文职责描述 |
| B3 | `Constants.swift:15` | 部分常量用 `lowerCamelCase`，部分用 `UPPER_SNAKE_CASE` | 统一为 `lowerCamelCase`（Swift 规范） |
| D6 | `StringExtensions.swift:55` | `func trimmedLines() -> [String]` 在整个项目中无调用 | 确认是否需要，否则删除 |
| A2 | `ReviewDataNotification.swift` | 文件仅包含通知名称，但 `// MARK: - Notification Names` 暗示可能有更多——实际没有 | 删除 MARK 标签或合并到 Support 文件 |
| B1 | `DateExtensions.swift` | `today()` / `isToday` / `startOfDay` 命名风格不统一（混用名词/布尔/动词） | 统一为 Swift 惯用风格 |
| B5 | `CollectionExtensions.swift:20` | `func safeSubscript` 内部方法名含 "safe" 缩写前缀，违反 API 指南 | 使用 `subscript(safe index:)` |

**总计：8 个问题（含 2 个🔴严重）**

---

### B06 — SnapDrillCore / Tests（9 文件，841 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| 🔴 系统性 | `AnalyticsTrackingServiceTests.swift` | 7 个测试仅验证"不崩溃"，无行为断言 | 补充 XCTAssertEqual/XCTAssertTrue 验证实际输出 |
| 🔴 系统性 | `CrashReportingServiceTests.swift` | 7 个测试仅验证"不崩溃"，无行为断言 | 同上 |
| A5 | `OCRServiceTests.swift:15` | 缺少 @Suite / @Test 注解（Swift Testing 标准） | 迁移至 Swift Testing 框架 |
| A5 | `PDFExportServiceTests.swift:15` | 同上 | 同上 |
| D1 | `TestHelpers.swift:30-60` | `makeItem(withTags:)` 等 3 个辅助方法在测试文件中无调用 | 删除未使用的辅助方法 |
| B4 | `ReviewSchedulerTests.swift` | 文件名与 `// MARK:` 中的"SM2 Engine"不一致 | 统一为"ReviewScheduler" |

**总计：6 个问题条目（其中"系统性"每项含 7+ 个测试，实质问题约 16 个）**

---

### B07 — SnapDrillData / Models（10 文件，638 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| B6 | `SubjectModel.swift:25` | `init(name:)` 无默认值，与 `SourceModel` / `GradeModel` 不一致 | 添加 `colorHex: String = "#888888"` 等默认值 |
| A1 | `TagModel.swift:18` | DocC 注释"颜色默认蓝色"但 `colorHex` 无默认值 | 修正注释或添加默认值 |
| D5 | `ReviewItemModel.swift:80-90` | 注释掉的 `// var legacyField` 字段 | 删除注释代码 |
| A3 | `MigrationPlan.swift:8` | 文件头描述缺失 | 补充中文职责描述 |
| B2 | `ReviewItemModel.swift:60` | `var isOverdue: Bool` 正确，但 `var urgency` 属性名缺乏语义 | 重命名为 `var overdueUrgency` 或删除 |
| A6 | `ReviewItemModel.swift:105` | DocC 注释参数列表与实际 init 签名不完全匹配（缺少 `grade` 参数） | 更新注释 |

**总计：6 个问题（均为中等/低）**

---

### B08 — SnapDrillData / Repositories + DataSeeder（7 文件，1,131 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| 🔴 D1 | `SourceRepository.swift` | 数据变更（insert/delete/update）后未发 `reviewDataDidChange` 通知，与 ReviewRepository 行为不一致 | 在写入操作后补充 NotificationCenter.default.post |
| 🔴 A1 | `DataSeeder.swift:20` | 注释"生成约 100 条"但实际 mockData 数组只有 50 条 | 修正注释为"约 50 条" |
| B6 | `TagRepository.swift` | 接口不对称——缺少 `totalCount()` 和 `seedDefaultsIfNeeded()` | 与 SubjectRepository 等对齐，或在接口文档中说明差异 |
| D4 | `GradeRepository.swift` | `import SnapDrillCore` 若仅用于 Logger，考虑是否可以通过 transitive dep 获得 | 验证后决定 |
| A5 | `ReviewRepository.swift:150` | `// TODO: 支持全文搜索` — 已有 fetchFilteredModels | 删除过时 TODO |
| B1 | `DataSeeder.swift` | `seed()` / `seedReviewItems()` / `populate()` 同义动词混用 | 统一为 `seed...` 前缀 |
| A2 | `RepositoryContainer.swift` | `// MARK: - Taxonomy` 区块包含了 review 相关操作 | 调整 MARK 标签 |
| E6 | `DataSeeder.swift:45` | `seedReviewItems()` 为同步方法但内部包含复杂循环——在大数据量时可能阻塞主线程 | 考虑 async/throws 签名 |
| D6 | `SourceRepository.swift:90` | `private func buildPredicate(...)` 在类内只被一处调用 | 可内联以减少复杂度 |
| B2 | `ReviewRepository.swift:30` | `var limit: Int` 属性无 `max` 语义前缀 | 重命名为 `maxResultLimit` |
| A3 | `RepositoryContainer.swift:8` | 文件头描述行缺失 | 补充中文职责描述 |

**总计：11 个问题（含 2 个🔴严重）**

---

### B09 — SnapDrillData / Tests（7 文件，807 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| D1 | `TestHelpers.swift:40-80` | `makeFullItem()`, `makeTaggedItem()`, `makeSubjectItem()` 在测试中无调用 | 删除未使用辅助方法 |
| B4 | `SubjectRepositoryTests.swift` | 文件内测试类名为 `TaxonomyRepositoryTests`（B4 不一致） | 重命名类型 |
| A5 | `ReviewRepositoryTests.swift:20` | `// TODO: 添加并发测试` — 并发测试已存在（concurrentAccess 测试） | 删除过时 TODO |
| D5 | `ReviewItemModelTests.swift:55-62` | 注释掉的 `// func testDeprecatedField()` | 删除注释代码 |
| B2 | `DataSeederTests.swift:15` | `var seeded = false` 应为 `var isSeeded = false` | 重命名 |
| E4 | `ReviewRepositoryTests.swift` | 非 `@MainActor` 上下文中调用 `@MainActor` 标注的 Repository 方法 | 添加 `@MainActor` 或在 await 中调用 |
| A6 | `GradeRepositoryTests.swift:30` | 注释说"测试级联删除"但测试仅验证单项删除 | 补充级联删除测试或修正注释 |
| D1 | `TagRepositoryTests.swift:60` | `func assertTagCount()` 辅助方法只被一个测试使用 | 内联或保留（可接受） |
| B1 | `DataSeederTests.swift` | `verify()` / `check()` / `assert()` 混用命名风格 | 统一使用 XCT 标准断言 |
| A3 | `TestHelpers.swift:8` | 文件头描述行缺失 | 补充中文职责描述 |

**总计：10 个问题（均为中等/低）**

---

### B10 — SnapDrillUI / 长文件（4 文件，1,032 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| D3 | `HelpView.swift:25` | `@State private var selectedSection: String?` 声明但从未在 body 中使用 | 删除 |
| D4 | `ContextualErrorView.swift:12` | `import Combine` 在文件中无 Combine 使用 | 删除 |
| A3 | `OnboardingView.swift` | 描述行"Onboarding 流程主视图"为英文混合，不规范 | 改为纯中文 |

**总计：3 个问题（均为低/中等）**

---

### B11 — SnapDrillUI / 短文件 + Tests（11 文件，945 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| 🔴 D1 | `Routable.swift` + `Navigation.swift` | 两个文件都定义了 Router 协议，存在接口重复 | 合并为单一协议，删除冗余文件 |
| B2 | `FlipView.swift:20` | `var flipped: Bool` 应为 `isFlipped` | 重命名 |
| A3 | `TagInputView.swift:8` | 文件头描述缺失 | 补充中文职责描述 |

**总计：3 个问题（含 1 个🔴严重）**

---

### B12 — SnapDrillFeatures / Capture（11 文件，1,818 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| E1 | `CaptureViewModel.swift:55` | 内部 `Task { Task { } }` 嵌套结构，外层无句柄 | 展开为单层 Task 并存储句柄 |
| E2 | `CaptureResultViewModel.swift:30` | `nonisolated(unsafe) private var imageData` 无理由注释 | 补充注释说明必要性 |
| D4 | `CaptureView.swift` | `import StoreKit` 无 StoreKit 使用（已在审计前修复） | 已修复 ✅（历史记录） |
| A3 | `CaptureRouter.swift:8` | 文件头描述缺失 | 补充中文职责描述 |

**总计：4 个问题（均为中等）**

---

### B13 — SnapDrillFeatures / Dashboard（14 文件，1,772 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| 🔴 D5 | `DashboardComponents.swift` | 纯占位符文件，无实际代码 | 已删除 ✅ |
| 🔴 C1 | `GradeManagerView.swift` | `struct GradeManagerView` 缺少 `public`，但被 DashboardView（同包）通过 Sheet 呈现 | 确认访问权限需求；若同包则 internal 合法，但需与其他 ManagerView 对齐 |
| 🔴 C1 | `SourceManagerView.swift` | 同上 | 同上 |
| 🔴 C1 | `SubjectManagerView.swift` | 同上 | 同上 |
| B2 | `DashboardView.swift:40` | `var showingStats = false` 应为 `isShowingStats` | 重命名 |
| B2 | `DashboardViewModel.swift:25` | `var loaded = false` 应为 `isLoaded` | 重命名 |
| A1 | `BentoCard.swift:15` | DocC 注释"action 为 nil 时隐藏"但实际是"不包裹 Button" | 修正注释 |
| B5 | `ReviewHeroCard.swift:30` | `var pct` 缩写不清晰 | 重命名为 `progressPercentage` |
| A3 | `DailyStatsView.swift:8` | 文件头描述"Coming Soon" — 功能已接通 | 更新为实际功能描述 |

**总计：9 个问题（含 4 个🔴严重，其中 DashboardComponents 已修复）**

---

### B14 — SnapDrillFeatures / Library（13 文件，1,932 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| 🔴 A4 | `ExportPreviewView.swift:8` | 文件头标为"已废弃"但文件仍活跃使用 | 已修复 ✅ |
| 🔴 D3 | `ExportOptionsSheet.swift:26` | `@State private var showingWordShare`, `wordExportURL` 僵尸属性 | 已修复 ✅ |
| B2 | `LibraryView.swift:22` | `var editing = false` 应为 `isEditing` | 重命名 |
| B2 | `LibraryViewModel.swift:35` | `var fetching = false` 应为 `isFetching` | 重命名 |
| A1 | `ResolvedExportSheet.swift:20` | DocC 注释说"导出 ReviewItem"但实际导出 `ReviewExportSnapshot` | 更新注释（若 ReviewItem 仍存在）或确认已迁移 |
| D4 | `LibraryEditView.swift` | `import SnapDrillCore` 若 SnapDrillData 已 re-export 所有需要类型，此 import 多余 | 验证后删除 |

**总计：6 个问题（含 2 个🔴已修复）**

---

### B15 — SnapDrillFeatures / Review（12 文件，1,614 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| 🔴 D5 | `ReviewComponents.swift` | 纯占位符文件，无实际代码 | 已删除 ✅ |
| C1 | `ReviewCardFactory.swift` | `public` 标注但仅在 SnapDrillFeatures 内使用 | 降为 `internal` |
| B2 | `ReviewBackground.swift:25` | `var animate = false` 应为 `isAnimating` | 重命名 |
| B2 | `ReviewViewModel.swift:30` | `var loading = false` 应为 `isLoading` | 重命名 |
| A3 | `ReviewRouter.swift:8` | 文件头描述缺失 | 补充中文职责描述 |
| D4 | `ReviewCardContent.swift` | `import SnapDrillDomain` 若已完成 Domain 删除则多余 | 确认依赖后删除（属于 Phase 2 重构范畴） |

**总计：6 个问题（含 1 个🔴已修复）**

---

### B16 — SnapDrillFeatures / Settings（14 文件，2,124 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| 🔴 D6 | `SettingsViewModel.swift:29` | `clearAllData()` 漏发 `reviewDataDidChange` 通知 | 已修复 ✅ |
| 🔴 E1 | `SettingsView.swift:60` | 生成测试数据的 Task { } 无句柄 | 存储句柄到 `@State private var seedTask: Task<Void, Never>?` |
| 🔴 E1 | `DataAndSyncSettingsView.swift:45` | clearCache 的 Task { } 无句柄 | 同上 |
| 🔴 E1 | `NotificationSettingsView.swift:80` | DatePicker onChange 触发的 Task { } 无句柄 | 同上 |
| B2 | `SettingsView.swift:20` | `var showingDeleteAlert = false` 应为 `isShowingDeleteAlert` | 重命名 |
| A3 | `DataAndSyncSettingsView.swift:8` | 文件头描述行缺失 | 补充中文职责描述 |

**总计：6 个问题（含 4 个🔴严重，其中 SettingsViewModel 已修复）**

---

### B17+B18 — SnapDrillFeatures / Environment + Tests + MainApp（7 文件，941 行）

| 编号 | 文件:行号 | 问题 | 建议 |
|---|---|---|---|
| C1 | `DependencyContainer.swift:20` | `internal` 类型暴露的 `public` 方法超出实际需求 | 确认访问范围，降级多余 public |
| A3 | `SnapDrillApp.swift:8` | 文件头描述行缺失（或描述不准确） | 补充中文职责描述 |

**总计：2 个问题（均为低/中等）**

---

## 汇总：按严重程度分类

### 🔴 严重问题（功能性 / 架构违规）

| # | 文件 | 类别 | 状态 |
|---|---|---|---|
| 1 | `SettingsViewModel.swift` | E1 / 功能 Bug | ✅ 已修复 |
| 2 | `ExportPreviewView.swift` | A4 / 误导性注释 | ✅ 已修复 |
| 3 | `ExportOptionsSheet.swift` | D3 / 僵尸属性 | ✅ 已修复 |
| 4 | `ReviewComponents.swift` | D5 / 空占位符 | ✅ 已删除 |
| 5 | `DashboardComponents.swift` | D5 / 空占位符 | ✅ 已删除 |
| 6 | `AppConfiguration.swift` | C4 / @MainActor 缺失 | ⏳ 待修复 |
| 7 | `PerformanceMonitoringExtensions.swift` | E1 / fire-and-forget I/O | ⏳ 待修复 |
| 8 | `SourceRepository.swift` | D1 / 数据变更漏发通知 | ⏳ 待修复 |
| 9 | `DataSeeder.swift` | A1 / 注释严重误导（100≠50） | ⏳ 待修复 |
| 10 | `Routable.swift` / `Navigation.swift` | D1 / 协议重复定义 | ⏳ 待修复 |
| 11 | `GradeManagerView.swift` 等 3 个 | C1 / 访问控制待确认 | ⏳ 待确认 |
| 12 | `SettingsView.swift` | E1 / Task 无句柄 | ⏳ 待修复 |
| 13 | `DataAndSyncSettingsView.swift` | E1 / Task 无句柄 | ⏳ 待修复 |
| 14 | `NotificationSettingsView.swift` | E1 / Task 无句柄 | ⏳ 待修复 |

### 🟡 中等问题（最佳实践 / 命名 / 文档）

共 ~64 个，主要集中在：
- **B2 布尔命名**：约 12 个 `var xxx = false` 缺 `is/has/should` 前缀
- **A3 文件头描述缺失**：约 10 个文件无中文职责描述
- **D1 未使用方法**：约 8 个私有/测试辅助方法无调用
- **A5 过时 TODO**：约 6 个已实现功能的 TODO 注释
- **B6 参数标签**：约 4 处违反 Swift API Design Guidelines
- **B1 动词不统一**：约 4 处同义动词混用

### 🟢 低优先级问题（风格 / 细节）

共 ~40 个，主要集中在：
- **B3 常量命名风格**：lowerCamelCase vs UPPER_SNAKE_CASE 混用
- **A2 MARK 标签**：区块内容与标签不完全吻合
- **A6 注释参数**：DocC 参数与签名轻微不符
- **D5 注释代码**：少量注释掉的历史代码

---

## 专项：B06 测试质量问题（系统性）

`AnalyticsTrackingServiceTests.swift` 和 `CrashReportingServiceTests.swift` 共包含 14+ 个测试，格式均为：

```swift
func testEventTracked() {
    XCTAssertNoThrow(service.track(event: "test"))
    // 无断言验证 eventLog 是否实际记录了事件
}
```

**建议改造模板：**
```swift
func testEventTracked() {
    service.track(event: "test_event")
    XCTAssertEqual(service.eventLog.last, "test_event")
}
```

---

## 结论与建议

### 总体评价
代码库整体质量良好，架构设计清晰，命名风格基本一致。发现的问题多为中等/低优先级的代码风格和文档问题，无重大安全漏洞。

### 立即需要修复（影响用户体验或数据完整性）
1. ✅ SettingsViewModel 通知 Bug（已修复）
2. ⏳ SourceRepository 数据变更漏发通知（与上同类问题）
3. ⏳ Settings 3 个 Task 无句柄（内存泄漏风险）

### 建议在下次迭代修复
1. B06 测试质量：补充行为断言
2. ~12 个布尔命名问题（B2）
3. DataSeeder 注释"100 条"→"50 条"
4. Routable.swift / Navigation.swift 协议合并

### 可以接受但建议长期关注
1. 文件头描述缺失（不影响功能）
2. 常量命名风格不统一
3. 过时 TODO 注释

---

*报告生成于 2026-03-03，基于 audit-checklist.md 中定义的标准*
