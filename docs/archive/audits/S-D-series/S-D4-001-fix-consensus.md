---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D4-001 三方修复方案 — Cross-Fix-Consensus

> Phase 11 B 方案串行第一战收尾（**ServiceContainer DI 系统性退化重构**）。
> Claude CLI 主笔，融合 Antigravity 实证创新 + Codex 架构规范 + Claude 盲区清单。
>
> 单家产出：[claude](S-D4-001-claude.md) · [codex](S-D4-001-codex.md) · [antigravity](S-D4-001-antigravity.md)
> 任务定义书：[S-D4-001-fix-task-definition.md](S-D4-001-fix-task-definition.md)

## 1. 三家共识（3/3 命中）

| 共识点 | 内容 |
|---|---|
| 根因 | ServiceContainer 仅 5 属性，6+ Service 通过 .shared / 默认 init 绕过 DI |
| 一刀切扩展 | 不引入二级容器（服务数 11-13 仍可读）|
| 协议化原则 | 跨模块可替换 / 测试 mock 诉求 → Protocol；纯本地状态机 → 具体类型 |
| Mock 容器对称 | MockServiceContainer 必须与 LiveServiceContainer 字面对称 |
| Service 单例语义 | 容器 `public let` Eager Binding |
| `@deprecated` 标注 | 旧 `.shared` 保留作向后兼容入口，标注 deprecated 引导新代码 |
| Architecture 文档同步 | architecture.md §DI 注入链路 / §模块职责 必须同步 |

## 2. 三家差异点对比

| 维度 | Claude | Codex | Antigravity |
|---|---|---|---|
| **Service 覆盖** | 6 个新（OCR+CaptureDraft+DeletionScheduler+ContentTagging+QuestionSplitting+ProEntitlement）| **8 个新**（含 AppActivityTracker + ReviewScheduler）| 7 个新（含 AppActivityTracker，不挂 ReviewScheduler）|
| **AppActivityTracker** | ❌ 漏抓 | ✅ 挂入 | ✅ 挂入 |
| **ReviewScheduler** | ❌ | ✅ 挂入（独家）| ❌ |
| **SwiftUI `@State` ViewModel 解法** | 不触及 | View 层重写 onAppear 创建 | **`inject()` 后置注入**（独家创新）|
| **CaptureDraftService.fileprivate init 暴露** | 不触及 | 不触及 | **改 public**（实测发现）|
| **LiveNotificationService.current() 静态初始化崩溃** | 不触及 | 不触及 | **延迟求值修复**（实测发现）|
| **PrivacySettingsViewModel 测试 AppActivityTracker.shared 串扰** | 不触及 | 不触及 | **完整修复 + 测试更新**（实测发现）|
| **ADR 立场** | 不需要 | **需要 ADR**（独家）| 不需要，直接更新 architecture.md |
| **architecture.md §「新增 Core service 规则」段** | 不触及 | **新增**（独家）| 不触及 |
| **MockProEntitlementProvider 接口设计** | 含 isPro: Bool 注入 | 含 isProUser 参数 | 默认实例 |
| **实证强度** | 未临时 apply | 未临时 apply | ✅ 临时 apply + AllTests 跑通 + git restore |
| **测试用例数** | 5 | 4 + 迁移示例 | 3 + 实证发现的 2 个真生产 bug |
| **盲区诚实度** | 7 条 future-proof 触发器 | 7 条（含 ProfileManager 集成风险）| 3 条 + 实证暴露的盲区 |

## 3. 综合裁决

### 评分矩阵（1-5 分）

| 维度 | Claude | Codex | Antigravity |
|---|---|---|---|
| 正确性 | 5 | 5 | 5 |
| 服务覆盖完整性 | 3 (6) | **5 (8)** | 4 (7) |
| 类型表达 | 4 | 4 | 4 |
| 迁移策略实战可行性 | 3（无 SwiftUI `@State` 解法）| 4 | **5**（inject() 后置注入解决核心阻塞）|
| Mock 容器策略 | 4 | 4 | **5**（100% 对称 + 实证验证）|
| Architecture 同步质量 | 3 | **5**（新增 Core service 规则段）| 4 |
| 测试架构 | 3 | 4 | **5**（含实证发现 2 个真生产 bug）|
| 实证强度 | 2 | 3 | **5**（临时 apply + AllTests 100% 绿）|
| 盲区诚实度 | **5**（7 触发器最全）| 4 | 4 |
| 已知风险预见 | 3 | 4 | **5**（暴露真生产 bug）|
| **总分** | **37** | **42** | **46** |

### 最强方案：**Antigravity 基础 + Codex ReviewScheduler/规则段 + Claude 盲区清单**

**Antigravity 显著胜出**理由：
1. **`inject()` 后置注入** 解决 SwiftUI `@State private var viewModel = X()` 这个 Swift/SwiftUI 真实困境（其他两家未触及）
2. **临时 apply 实证流程** 暴露 2 个**真生产 bug**：
   - `LiveNotificationService.current()` 在非宿主单元测试静态初始化崩溃
   - `PrivacySettingsViewModel` 测试因 `AppActivityTracker.shared` 全局污染失败
3. **AppActivityTracker 挂入容器**（Claude 漏抓，Codex 也挂）
4. **CaptureDraftService.fileprivate init → public** — 容器组装必需
5. **Mock 100% 对称的工程纪律**

### 采纳 Codex 增强

1. **ReviewScheduler 第 8 个 Service**——SM-2 策略可替换 / 测试 mock 诉求成立
2. **architecture.md §「新增 Core service 规则」段** — 防漂移
3. **3 个完整迁移示例**（CaptureView / LibraryViewModel / DashboardAnalyticsViewModel 含 SmartPaperView）
4. **MockProEntitlementProvider(isProUser: Bool)** 设计

### 采纳 Claude 增强

- 7 条 future-proof 盲区触发器清单（比 Codex 7 条更细致）

### ADR 决策

**2:1 不需要 ADR**——直接更新 `architecture.md`。理由：
- 是兑现既有「Protocol-based DI + @Environment 替换只需改 DependencyContainer」承诺，非新决策
- 既有 ADR-004 / ADR-005 已覆盖此类「实现 vs 文档对齐」类工作
- 但 architecture.md §模块职责 §DI 注入链路 必须同步（已在范围内）

## 4. 融合方案（最终 apply 清单）

### 4.1 Service 范围（8 个新挂入 + 既有 5）

```
既有：analytics / pdfExport / appConfig / privacyConsent / notification
新挂：ocr / captureDraft / deletionScheduler / contentTagging / questionSplitting / proEntitlement / activityTracker / reviewScheduler
合计：13 个属性
```

### 4.2 关键改动

1. **协议扩展**：`ServiceContainer.swift` 增 8 个属性
2. **Live 容器扩展**：`LiveServiceContainer.swift` 同
3. **Mock 容器扩展**：`MockServiceContainer.swift` 同 + 新增 3 个 Mock：
   - `OCRServiceMock`（新建）
   - `CaptureDraftServiceMock`（新建）
   - `MockProEntitlementProvider(isProUser: Bool = false)`（新建）
4. **deprecated 标注**：`CaptureDraftService.shared` / `DeletionScheduler.shared` / `AppActivityTracker.shared` / `DefaultProEntitlementProvider`
5. **`CaptureDraftService.fileprivate init` → `public init`**（容器组装必需，Antigravity 实证发现）
6. **`LiveNotificationService` 静态初始化降级**（Antigravity 实证修复）
7. **ViewModel 迁移**（采用 Antigravity inject() 模式）：
   - `CaptureViewModel.inject(ocrService: / draftService: / activityTracker:)`
   - `CaptureResultViewModel` init 接收 contentTagging / draftService / activityTracker
   - `LibraryViewModel` init 接收 deletionScheduler
   - `DashboardAnalyticsViewModel` init 移除默认参数
   - `SmartPaperView` 用 `@Environment(\.services)`
   - `DashboardViewModel` init 接收 draftService
   - `ProfileListViewModel` init 接收 draftService
   - `LibraryEditViewModel` init 接收 ocrService
8. **PrivacySettingsViewModel + 测试**：注入 AppActivityTracker（Antigravity 实证修复）
9. **`SnapDrillApp` / `AppRootView` 装配**：注入 services 到 environment（如已注入则不重复）
10. **architecture.md**：DI 注入链路表 + 模块职责表 + 新增「Core service 规则」段
11. **测试套件**：`ServiceContainerTests.swift` 扩展（接口完整性 + 单例语义 + Mock 对称）

### 4.3 已知盲区（融合三家 + 实战补充）

| 盲区 | 处理 |
|---|---|
| TelemetryGate (nonisolated enum) | 不挂容器，视为静态全局状态（三家一致）|
| ZIPArchiver (Data 层) | 跨包循环依赖，不挂 Core 容器（三家一致）|
| ImageStorage (Profile-scoped) | 由 ProfileManager 管理，不挂全局容器（三家一致）|
| OnboardingManager / DependencyContainer.shared | 不属于 Core service 边界 |
| 渐进迁移期 deprecated warning 噪音 | PR 顺手清理，1-2 cycle 后移除 deprecated 标注 |
| AppActivityTracker 被 ProfileManager 直接用 | 本方案先挂入容器；ProfileManager 注入留后续小 PR |
| `inject()` 后置注入与传统 ctor 注入的混用 | SwiftUI `@State` 场景用 inject()；其他场景用 ctor 注入；约定写入 architecture |

## 5. Apply 计划

1. ✅ 写本 consensus 文件
2. apply ServiceContainer 协议 + Live/Mock 容器扩展（8 个新属性）
3. 新建 3 个 Mock（OCRServiceMock / CaptureDraftServiceMock / MockProEntitlementProvider）
4. CaptureDraftService init 改 public + 各 .shared 加 deprecated 标注
5. LiveNotificationService 静态初始化降级
6. ViewModel 迁移（8 处）+ inject() 模式
7. PrivacySettingsViewModel + 测试 AppActivityTracker 注入修复
8. ServiceContainerTests 扩展
9. swiftlint + xcodebuild test
10. architecture.md 同步 + 新增「Core service 规则」段
11. ledger 翻面 S-D4-001 OPEN → RESOLVED
12. commit + push + 清 worktree

## 6. Phase 11 串行第一战工作流观察

| 项 | 评价 |
|---|---|
| 物理隔离效果 | ✅ 三家产出 7 项设计决策真实分歧（Service 覆盖 / SwiftUI 解法 / ADR 立场）|
| 实证强度差异化 | ✅ Antigravity 临时 apply 暴露 2 个真生产 bug（其他两家未发现）|
| 模型差异化能力 | ✅ Antigravity 工程实证 / Codex 架构规范 / Claude 盲区清单——三种风格互补 |
| 控制变量法纪律 | ✅ 提示词净化 + 物理隔离三家无串扰 |
| 用户决策调整为「串行」 | ✅ 用户即时反馈避免 S-D7-002/003 并行风险 |

## 7. 关联

- [worktree-audit-workflow](../standards/worktree-audit-workflow.md)
- [S-D7-001-fix-consensus](S-D7-001-fix-consensus.md) Phase 11 首战参考
- [S-D4-002-fix-consensus](S-D4-002-fix-consensus.md) Phase 11 第二战参考
- [ADR-005](../decisions/ADR-005-doc-semantic-layer-audit.md) §Phase 10 全局收官
- 关联 finding：S-D4-002 已 RESOLVED（本修复保持 NotificationServiceProtocol 注入方式不变）
