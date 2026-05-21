---
last_verified: 2026-05-21
layer: pattern
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D4-001 三方修复提案 — 任务定义书（架构重构）

> Phase 11 第三轮 worktree 任务（**ServiceContainer DI 系统性退化重构**）。三家共享同一份任务定义，独立产出修复方案 + 测试验证 + 架构图同步。

## Bug 描述

**症状**：`ServiceContainer` 协议只声明 5 个属性（`analytics / pdfExport / appConfig / privacyConsent / notification`），但项目实际有 12+ 个 Service。**7+ 个 Service 绕过 DI**——通过 `.shared` / `init()` 硬编码默认参数 / 类型层全局实例访问，违反 architecture.md 「Protocol-based DI + @Environment 替换只需改 DependencyContainer」的承诺。

**根因区域**：`Packages/SnapDrillCore/Sources/SnapDrillCore/DI/ServiceContainer.swift`（精确行号自行定位）。

**已知漏列服务**（**自行验证扩展**，本清单不穷举）：
- `CaptureDraftService` / `CaptureDraftServiceProtocol`
- `DeletionScheduler`
- `ProEntitlementProvider`（含 `DefaultProEntitlementProvider`）
- `ContentTaggingService`（Apple Foundation Models 端上 AI）
- `QuestionSplittingService`（一图多题智能拆题）
- `TelemetryGate`
- `ZIPArchiver`
- 可能还有其他——自行 grep 全 `Packages/SnapDrillCore/Sources/SnapDrillCore/Service/` 列出实际服务清单

**违反承诺**：
- `docs/tech/architecture.md` §模块职责 / §架构决策表「Protocol-based DI + @Environment 替换只需改 DependencyContainer，不影响其他模块」
- `docs/standards/permission-model.md` / `docs/standards/skill-architecture.md` 间接依赖 DI 契约稳定性

## 范围

| 项 | 内容 |
|---|---|
| 修复文件（核心）| `ServiceContainer.swift` / `LiveServiceContainer.swift` / `MockServiceContainer.swift` |
| 受影响调用方 | `View` / `ViewModel` 当前通过 `.shared` / 直接 `init()` 拿服务的所有位置 |
| 不可改 | Service 自身的 protocol / 实现（除非确实需要重构 Service API）|
| 周边影响 | 测试需要扩展 MockServiceContainer；新增 Service 时必须强制走 ServiceContainer 注入路径 |

## 修复方案要求

### 1. 设计决策必答

每家方案**必须**回答以下设计问题（不要照搬其他家立场）：

| 决策点 | 选项示例 |
|---|---|
| 一刀切扩展 vs 分层组织 | 全部 12+ Service 直接挂 ServiceContainer / 按职能分组（CaptureServices/ReviewServices/AnalyticsServices）/ 引入二级容器 |
| 全部走协议 vs 部分具体类型 | 仅强制可替换的服务走 Protocol（与 PDFExportService 现有做法一致）/ 全部 Protocol 化 |
| 当前直接 `.init()` / `.shared` 调用方处理 | 一次性全部改注入路径 / 渐进迁移（保留向后兼容方法 + Deprecated 标注）|
| Mock 容器策略 | 全部 Mock 实现 / 仅核心 mock + 其他用真实实现 / 引入 NullObject pattern |
| Service 单例语义保证 | 容器持有 `lazy var` / 工厂模式 / `Atomic` 包装 |
| ADR 是否需要 | 该重构是否升级到 ADR（影响范围 / 决策可回退性）|
| 测试覆盖最小集 | 单元测试 / 集成测试 / 编译期约束（如 `assertContainerExhaustive()`）|

### 2. 代码 diff

提供修复 patch，至少含：
- `ServiceContainer.swift` 协议扩展（含每个新 Service 的 `var` 声明 + doc comment）
- `LiveServiceContainer.swift` 实现扩展
- `MockServiceContainer.swift` 实现扩展
- 至少 3 个代表性调用方迁移示例（必须真实 grep + 改）
- 必要的协议化补丁（如果选择 Protocol 化新服务）

### 3. 测试用例

至少覆盖：
- 容器初始化所有 Service 不为 nil
- Service 单例缓存语义（同一容器内同一 Service 返回同实例）
- Mock 容器与 Live 容器接口对称（编译期 / 测试期可验证）
- 至少一个调用方迁移后的功能未回归

### 4. Architecture 文档同步

必须同步更新 `docs/tech/architecture.md` §SnapDrillCore §DI 段，列出所有新增 Service 的归属与注入路径。

### 5. 自检段

在你的产出报告末尾**必须**写一段「本方案的已知盲区」，列出：
- 当前修复**不**涵盖的服务（如有意识地排除）
- 渐进迁移路径的中间态风险
- 如果未来新增 Service，本方案的扩展工作量评估

## 产出位置

落档到你的 worktree 的 `docs/audits/S-D4-001-<vendor>.md`（vendor = codex 或 antigravity）。

Claude CLI 主笔产出位置：`docs/audits/S-D4-001-claude.md`（主分支）。

## 验收标准

- ✅ ServiceContainer 协议覆盖所有 Service（**或**明确豁免清单 + ADR）
- ✅ 至少 3 个 `.shared` / `init()` 直接调用迁移到 DI
- ✅ 编译通过：`xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`
- ✅ swiftlint --strict clean
- ✅ Architecture 文档同步
- ✅ 设计决策必答 7 项全部明确表态
- ✅ 「已知盲区」段诚实

## 严禁操作

- 不要直接 apply 修复到主分支（产出只是方案）
- 不要修改 Service 本身的对外协议（除非确有重构必要并明确论证）
- 不要修改主分支 ledger / STATUS / handoff / ADR
- 不要 cherry-pick 主分支或其他 audit 分支
- 不要参考其他家产出 / 主分支 S-D4-001-* 文件（如有）

## 收尾后行为

1. 在你的 worktree commit + push 到你的 audit 分支
2. 回复用户：worktree 路径 + 分支名 + 产出文件路径
3. 停止，等 Claude CLI 主笔做 cross-fix-consensus

## 关联

- [worktree-audit-workflow](../standards/worktree-audit-workflow.md) Phase 11+ 标准
- [S-D7-001-fix-consensus](S-D7-001-fix-consensus.md) Phase 11 首战参考
- [S-D4-002-fix-consensus](S-D4-002-fix-consensus.md) Phase 11 第二战参考
- 相关 finding：S-D4-002（通知 ID Multi-Profile 已 RESOLVED，**本修复不应推翻其 Service 注入方式**）
