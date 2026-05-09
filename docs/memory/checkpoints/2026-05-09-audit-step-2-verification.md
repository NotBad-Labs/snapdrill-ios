---
last_verified: 2026-05-09
layer: snapshot
freshness:
  max_age_days: 90
  decay_trigger: [next_audit]
---
# Step 2: 验证体系审计

## Goal

审计测试覆盖完整性、测试质量、disabled tests 合理性、snapshot baseline 健康状况。

## Scope

67 文件：测试 Swift(49) + snapshot PNG(16) + xctestplan(1) + XCUITest(1)

## Findings

### Critical (0)

无 Critical 发现。

### Warning (4)

**W1: SnapDrillInfrastructure 零测试（2 源文件，0 测试文件）**
- `FirebaseAnalyticsService.swift`（81 行）和 `FirebaseBootstrap.swift`（48 行）
- Package.swift 中无 `.testTarget` 声明
- 风险：Firebase Analytics/Crashlytics 适配器未经测试，双重 opt-in 守卫（`isFirebaseConfigured` + `analyticsEnabled`）未被验证
- 这是最明显的测试缺口

**W2: DeletionScheduler 无测试**
- `DeletionScheduler.swift` — App 级软删除调度器，5 秒撤销窗口逻辑
- 这是有业务逻辑的 Service 实现（非 Protocol），应被测试覆盖
- 风险：撤销窗口计时、Tab 切换时的倒计时存活等关键行为未被验证

**W3: 2 个 disabled 测试的 reactivation 条件不明确**

| 测试 | 原因 | reactivation 条件 |
|---|---|---|
| `PDFExportServiceTests.generationCancellation` | "CI 环境下时序不稳定" | 无：未说明何时/如何修复时序问题 |
| `PersistenceControllerTests.sharedInstanceIsAccessible` | "访问 shared 会触发真实 SQLite" | 无：未说明如何隔离 shared 单例 |

- risk：disabled 测试可能永久休眠（F-014 纪律覆盖此场景，但需要定期复核）

**W4: snapshot 测试仅覆盖 16 个 View，大量 UI 组件无快照覆盖**
- SnapDrillUI 13 个源文件，snapshot 仅覆盖 4 个组件（Button, ProgressLoading, ErrorMessage, TipPopover）
- 未覆盖：TagInputView、SwipeCard、TermsOfServiceView、OnboardingView、SnapDrillDatePicker、EmptyStateView 等
- Features 层大量内部 View 也无快照
- 风险：UI 回归只能靠手工测试或 XCUITest

### Info (3)

**I1: 7 个 Protocol 类型无测试（合理豁免）**
- `AnalyticsServiceProtocol`、`CaptureDraftServiceProtocol`、`NotificationServiceProtocol`、`OCRServiceProtocol` — Protocol 定义，无需独立测试
- `ServiceContainer+Environment`、`AnalyticsService+Environment` — SwiftUI Environment 键，样板代码
- `PrivacyConsentService` — ADR-002 后已成空壳（ATT 已移除），无需独立测试

**I2: LiveNotificationService 无测试（部分豁免）**
- 依赖 UNUserNotificationCenter，难以在单元测试中 mock
- 但可以通过 Protocol 注入的 mock 测试——当前未覆盖

**I3: XCUITest 仅 1 个 E2E 测试**
- `SnapDrillUITests.swift` 只有"手动录入到题库"一条路径
- 无其他 E2E 路径（Share Extension、Settings、Profile 管理等）

## Positive Findings

- ✅ ViewModel 覆盖率 16/16（100%），业界高标准
- ✅ Data 层 16 测试文件，覆盖 Repository + Model + Migration + Backup + Concurrency + Executor
- ✅ Core 层 11 测试文件，覆盖主要 Service
- ✅ Features 层 20 测试文件，含 snapshot + CSV parser + performance
- ✅ 测试隔离良好：in-memory ModelContainer + mock service
- ✅ 全部使用 Swift Testing（非 XCTest），现代化
- ✅ snapshot testing 配置合理（CI=missing, SnapshotRecord=all）
- ✅ 2 个 disabled 测试都有明确理由和 F-014 引用
- ✅ `AllTests.xctestplan` 覆盖 Core/Data/Features/Share 四个 test target
- ✅ 性能测试 3 个（Library 加载 <500ms、搜索 <300ms、PDF 导出 <5s）

## Score

| 维度 | 得分 | 说明 |
|---|---|---|
| 正确性 | 8/10 | 已有测试质量好，但 Infrastructure 零覆盖 + DeletionScheduler 缺测试 |
| 完整性 | 6/10 | ViewModel 100% 但 Service 覆盖不均、UI 快照有限、E2E 极简 |
| 一致性 | 8/10 | 测试模式统一（Swift Testing + in-memory + mock），disabled 策略一致 |
| 可维护性 | 8/10 | 测试 helper 复用良好，命名规范清晰 |
| **综合** | **7.5/10** | |

## Next

Step 7: 依赖与供应链审计
