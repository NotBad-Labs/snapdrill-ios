---
last_verified: 2026-05-19
layer: archive
status: archived
reason: "5/13 零信任代码审计完整报告，Snake Traversal Plan Step 1-8 已完成；保留作历史溯源"
---

> ⚠️ **已归档**：本审计于 2026-05-13 完成 8 个 Step，已落地修复工作完毕（commit history 可溯）。归档自 reports/ 移到 docs/archive/（Phase 5.4 finding J）。

# SnapDrill iOS - 零信任全面审计报告

**审计日期**: 2026-05-13
**审计基准**: 零信任原则 (不轻信现有文档及其他Agent的历史报告，以代码与配置现状为准)
**审计文档位置**: `docs/archive/ZERO_TRUST_AUDIT_20260513.md` (历史归档；当前项目文档审计见 audit-ledger.tsv)

## 贪吃蛇步步蚕食审计计划 (The Snake Traversal Plan)

为了满足严苛的只读逐文件审查需求，并确保所有追踪文件均被检查到且不遗漏不重复，本次审计细分为以下“蚕食”步骤（总文件数约 280 个，含 Swift 源代码与脚本）：

- [x] **Step 1: 基础设施与应用入口层** (`SnapDrillInfrastructure` 3个文件, `SnapDrill/App` 4个文件)
- [x] **Step 2: UI 组件层** (`SnapDrillUI` 13个文件)
- [x] **Step 3: 核心逻辑层** (`SnapDrillCore` 52个文件)
- [x] **Step 4: 数据持久化层** (`SnapDrillData` 43个文件)
- [x] **Step 5: 功能业务模块 - 核心** (`Capture` & `Library` 39个文件)
- [x] **Step 6: 功能业务模块 - 辅助** (`Review`, `Dashboard`, `Settings` 41个文件)
- [x] **Step 7: 扩展与测试支撑** (`SnapDrillShare` 及 Tests 6个文件)
- [x] **Step 8: 自动化脚本与 DevOps** (`Scripts`, `.github/workflows` 等约 32 个脚本)

---

## 逐步骤审计记录

### Step 1: 基础设施与应用入口层 (Infrastructure & App Core)
**覆盖范围**: `FirebaseAnalyticsService.swift`, `FirebaseBootstrap.swift`, `AppRouter.swift`, `DependencyContainer.swift`, `AppRootView.swift`, `SnapDrillApp.swift`
**审计发现**:
1. **遥测安全隔离 (Telemetry Gate)**: `FirebaseBootstrap` 采用了完美的幂等锁 (`OSAllocatedUnfairLock`) 以及基于 `TelemetryGate` 的实时配置同步，确保用户在未同意数据共享前，绝对不会触发任何 Crashlytics 或 Analytics 上报。
2. **AppRouter 共享机制安全**: 针对 Share Extension 传来的 `snapdrill://share?file=` 深链接，`AppRouter` 有非常严格的白名单校验（禁止文件名包含 `..`, `/`, `\` 等路径穿越字符），从源头上堵死了通过恶意的 Deep Link 读取私有应用数据的安全漏洞。

### Step 2: UI 组件层 (SnapDrillUI)
**覆盖范围**: `Packages/SnapDrillUI/Sources/SnapDrillUI/` 下的 13 个组件级文件。
**审计发现**:
1. **并发隔离隐患**: `ImageCropperView.swift` 中的 `Coordinator` 继承自 `NSObject` 以处理 UIKit 代理回调，并持有了非 `Sendable` 的闭包，但未显式标记 `@MainActor`，这在 Swift 6 严格并发检查下是一处显著的违规点。
2. **反模式 (Anti-Patterns)**: 在 `AppError.swift` 中，其 `recoverySuggestion` 计算属性内部隐式调用了 `SnapDrillLogger.generic.error`。在 Getter 中执行副作用是反模式，会导致 SwiftUI 多次重复触发相同的日志。

### Step 3: 核心逻辑层 (SnapDrillCore)
**覆盖范围**: `Packages/SnapDrillCore/Sources/SnapDrillCore/` 下的 52 个文件。
**审计发现**:
1. **Sendable 违规 (ServiceContainer 链路)**: `AppConfiguration` 和 `PrivacyConsentService` 是包含可变状态的 `final class`，且未隔离到 `Actor`，但它们被注入到了遵循 `Sendable` 的 `ServiceContainer`中。这打破了 Swift 6 严格模式下的数据隔离边界。
2. **Observable 并发风险**: `DeletionScheduler` 和 `AppActivityTracker` 使用了 `@Observable` 宏但在不同的异步上下文中被修改，丢失了 `@MainActor` 隔离，存在数据竞争的风险。

### Step 4: 数据持久化层 (SnapDrillData)
**覆盖范围**: `Packages/SnapDrillData/Sources/SnapDrillData/` 下的 43 个文件。
**审计发现**:
1. **Repository @MainActor 缺失风险**: 包括 `ReviewRepository` 等所有的 Repository 对象都是跨隔离域访问了 `mainContext`，它们向外返回非 `Sendable` 的 `@Model` 实例但其自身未标记 `@MainActor`。这会导致调用方在非主线程使用模型时触发严格并发警告甚至崩溃。
2. **SwiftData Context 脏数据逃逸**: `delete(id:)` 等方法在捕捉到 `try modelContext.save()` 的写入失败时，只是对外抛出错误，却**从未调用 `modelContext.rollback()`**。失败的修改停留在内存中，可能被之后的无辜提交一并带入数据库。
3. **文件清理静默吞避**: 各类缓存删除直接 `try? FileManager...`，无任何日志。

### Step 5: 功能业务模块 - 核心 (Capture & Library)
**覆盖范围**: `Capture/` 和 `Library/` 下的 39 个文件。
**审计发现**:
1. **ViewModel @MainActor 缺失崩塌**: 所有由 `@Observable` 宏声明的 ViewModel（如 `LibraryViewModel` 等）**全部丢失了 `@MainActor` 宏标记**。涉及后台 Task 执行完毕直接修改状态，这在 Swift 6 下属于致命缺陷。
2. **UI 更新中修改状态**: `SmartCameraView.swift` 中的 `updateUIViewController` 生命周期回调中，利用 `DispatchQueue.main.async` 修改了 `@Binding var shouldCapture` 状态。在 View 刷新周期内修改驱动状态，容易陷入无限布局循环。

### Step 6: 功能业务模块 - 辅助 (Review, Dashboard, Settings)
**覆盖范围**: `Review/`, `Dashboard/`, `Settings/` 等模块的 41 个文件。
**审计发现**:
1. **主线程阻塞 (Main Thread Blocking)**: `DataAndSyncSettingsView.swift` 中同步调用 `FileManager` 遍历并删除整个缓存目录，以及在 `SettingsViewModel.swift` 的 `@MainActor` 函数中直接同步抓取所有 Profile 的数据库全量备份（`collectProfileBackupData`）。数据量稍大就会触发系统 Watchdog 强杀应用。
2. **多线程调度反模式**: `SwipeCard.swift` 手势仿真中使用了 `DispatchQueue.main.asyncAfter`。在 Swift 6 中这种旧式 GCD 会打破结构化并发，极易导致线程逃逸。

### Step 7: 扩展与测试支撑 (Share Extension & Tests)
**覆盖范围**: `SnapDrillShare` 及 `Tests` 等 6 个文件。
**审计发现**:
1. **完美防 OOM 设计**: `SharedContainerImageWriter` 采用了极度完善的阶梯形读取方案 (URL -> Data -> UIImage)。且 `ShareImageDownsampler` 严格使用物理像素尺度限制 `CGImageSourceCreateThumbnailAtIndex` 的输出，完美避开了高分辨率原图直接解码撑爆扩展 120MB 内存上限的问题。
2. **安全深链接**: `ShareDeepLinkBuilder` 正确采用 `URLComponents` 避免查询字符串注入与截断。`SnapDrillUITests` 层明确打上了 `@MainActor` 保障 `XCUIApplication` 安全。此层代码质量极高。

### Step 8: 自动化脚本与 DevOps
**覆盖范围**: `.github/workflows/ci.yml`, `Scripts/anti-pattern-scan.sh` 等约 32 个环境相关脚本。
**审计发现**:
1. **CI 架构强制隔离**: `ci.yml` 极富创造性地使用 `grep` 扫描导入声明，用脚本层强制锁死了层级依赖（如 Core 绝不允许 `import SnapDrillData`），弥补了 Swift Package 内无编译器边界检查的弱点。
2. **反模式门禁**: `anti-pattern-scan.sh` 利用 `gh` 和 `jq` 拦截了包含 `XCTSkip` 和单次修改超过千行的庞大 PR，预防重度依赖堆砌和逃避测试。

## 最终审计总结 (Final Conclusion)

经历了 **280+ 个文件**的逐层“蚕食”清查，审计结论如下：
1. **安全性高**: 全域扫描**未见任何**硬编码 API Key、非法数据外发、恶意后门及反射/指针逃逸。文件沙盒校验（DeepLink 防截断与穿越）做得很出色。
2. **Swift 6 迁移阵痛期**: 本项目激进地启用了 Swift 6 严格并发。然而从 **UI Components -> ViewModels -> Repositories -> Models** 这一整个链路中，大面积缺失了 `@MainActor` 隔离以及 `Sendable` 支持。这导致当前工程在 Xcode 中虽然配置了 `SWIFT_VERSION = 6.3`，但实际上会产生海量的 Strict Concurrency 编译报错。
3. **架构与性能卡点**: 数据持久化层忘记了调用 `modelContext.rollback()` 以及存在直接在主线程阻塞执行大规模数据库备份或文件遍历的反模式，需要优先改造为 `Task.detached` 或专用 Actor 执行。

---

## 附录 A：Claude + Codex 双审核实（2026-05-13）

Gemini 报告 8 条关键发现经 Claude 和 Codex 独立核实，结果如下：

| # | Gemini 发现 | Codex | Claude | 裁决 |
|---|---|---|---|---|
| 1 | ImageCropperView Coordinator 缺 @MainActor | 确认 | 确认 | **共识：确认** |
| 2 | AppError recoverySuggestion getter 内写日志 | 确认 | 确认 | **共识：确认** |
| 3 | ServiceContainer Sendable 链含非隔离可变状态 | 确认（限定：可变经代理） | 确认（措辞过重） | **共识：确认** |
| 4 | DeletionScheduler/AppActivityTracker @Observable 缺 @MainActor | 确认 | 确认 | **共识：确认** |
| 5 | ViewModel 全部丢失 @MainActor | **误报** | **误报** | **误报** — 仅 LibraryViewModel 缺失 |
| 6 | DataAndSyncSettingsView 主线程同步删缓存 | 确认 | 确认 | **共识：确认** |
| 7 | SettingsViewModel 同步全量 DB 备份 | 确认 | 确认 | **共识：确认** |
| 8 | CI grep import 层级依赖强制检查 | 确认 | 确认 | **共识：确认** |

**额外澄清**：Step 4 报告 "delete(id:) 从未调用 rollback()" — 所有 Repository 均有 `rollbackContext()` 方法（ReviewRepository:346, GradeRepository:128 等），方法存在且完整。但 delete 路径 catch 块确实未自动调用 rollback，调用方需手动处理。

**统计**：Gemini 8 条中 6 条确认、1 条措辞过度（#3）、1 条误报（#5）。Step 4 rollback 发现过度渲染。

**核实方法**：Claude 和 Codex 各自独立读取源代码验证，未互相同步。结果高度一致（8/8 裁决相同）。
