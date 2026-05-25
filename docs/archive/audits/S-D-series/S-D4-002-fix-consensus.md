---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D4-002 三方修复方案 — Cross-Fix-Consensus

> Phase 11 第二战（首个真生产 bug 三方修复）收尾。Claude CLI 主笔，融合三家最强点。
>
> 单家产出：[claude](S-D4-002-claude.md) · [codex](S-D4-002-codex.md) · [antigravity](S-D4-002-antigravity.md)
> 任务定义书：[S-D4-002-fix-task-definition.md](S-D4-002-fix-task-definition.md)

## 1. 三家共识（3/3 命中）

| 共识点 | 内容 |
|---|---|
| 根因定位 | `LiveNotificationService.scheduleDaily` 的 `cancelAll()` + 硬编码 identifier `"com.snapdrill.daily-review"` 全局共享 |
| Multi-Profile 失效证据 | Profile A 设 → 切 B 设 → cancelAll 物理擦除 A 的 pending → A 永不再响 |
| ID 修复方向 | 拼接 profileId 形成 per-profile identifier |
| 业务路径替代 cancelAll | 新增 `cancelDaily(for:)` 或 `cancelForProfile(_:)` 精准 scope 化 API |
| 协议参数显式传 Profile 上下文 | 三家一致（不让 Service 反向依赖 ProfileManager）|
| ViewModel init 注入 profile 标识 | 三家一致 |
| View 从 `@Environment(\.profileManager)` 拿 profile | 三家一致 |
| Mock 改成 per-profile state 追踪 | 三家一致 |

## 2. 三家差异点对比

| 维度 | Claude | Codex | Antigravity |
|---|---|---|---|
| **D1 ID 命名空间深度** | 3 层 `com.snapdrill.daily-review.<uuid>` | **4 层 `com.snapdrill.notification.daily-review.profile.<lowercase-uuid>`** | 3 层 `com.snapdrill.daily-review.<uuid>` |
| **D2 Profile 上下文类型** | `UUID` | **`ProfileScope`**（项目已有类型）| `UUID` |
| **D3 cancel scope 实现** | 精准 ID removal | 精准 ID removal | 精准 ID removal |
| **D4 升级路径** | App boot 一次性 purge + UDKey 防重跑 | **级联清理**（每次 schedule 顺手清 legacy）| 级联清理（schedule + cancel 都清 legacy）|
| **D5 cancelAll 去留** | 完全移除（YAGNI）| 移除 + 新增 `cancelAllSnapDrillNotifications()`（managed prefix filter）| 保留 cancelAll 作 GDPR/admin |
| **D6 测试架构** | Mock per-profile dict | **`UserNotificationScheduling` facade + FakeCenter**（可测真实 Live）| Stateful Mock Spy 字典 + 临时 apply 实证 |
| 实证强度 | 未临时 apply（纯模拟）| 未临时 apply（diff + 设计） | ✅ 临时 apply + swiftlint + 7 tests pass + git restore |
| 测试数量 | 7 boundary | 6 boundary | 7（5 新 + 2 历史适配）|
| 盲区诚实度 | 7 条 future-proof 触发器 | 6 条 | 3 条（深度论证）|

## 3. 综合裁决

### 评分矩阵（1-5 分）

| 维度 | Claude | Codex | Antigravity |
|---|---|---|---|
| 正确性（编译 + 多 profile 隔离）| 5 | 5 | 5 |
| Namespace 未来扩展性 | 3 | **5** | 3 |
| 类型表达力（Profile 上下文）| 3（UUID）| **5**（ProfileScope）| 3（UUID）|
| 升级路径鲁棒性 | 3（boot 阻塞冷起风险）| **5**（级联清理无 init race） | 4（级联但 cancelAll 仍保留风险）|
| cancelAll 防滥用 | 4（移除但缺替代）| **5**（移除 + 命名明确的 reset API）| 3（保留是后门）|
| 测试可达性（能测真实 Live）| 3 | **5**（facade + Fake）| 4（Mock 充分但测不到 Live）|
| 实证强度 | 2 | 3 | **5**（编译过 + 测过）|
| 防御性（外部 app 通知保护）| 3 | **5**（cancelAllSnapDrill 用 prefix filter）| 3 |
| 自检诚实度 | **5**（7 条触发器）| 4（6 条）| 4（3 条深度）|
| **总分** | 31 | **42** | 34 |

### 最强方案：**Codex 为基础 + Antigravity 实证流程 + Claude 盲区清单**

**Codex 显著胜出**理由：
1. **4 层 namespace 含 type segment**——未来加新通知类型（错题提醒 / 备份提醒 / 家长周报）零成本扩展
2. **`ProfileScope` 类型注入**——利用 Swift 类型系统表达 scope 边界（项目已有 ProfileScope 类型，符合架构语义）
3. **`UserNotificationScheduling` facade protocol**——单元测试可注入 FakeCenter 测**真实 LiveNotificationService 行为**，不只测 Mock 契约
4. **`cancelAllSnapDrillNotifications()` 用 managed prefix filter**——真正实现「重置我们的通知不触碰其他 app」（系统级 `removeAllPendingNotificationRequests()` 是危险操作，本方案根除）
5. **级联清理升级路径**——schedule 时顺手清 legacy ID，无 App boot 阻塞冷起风险

### 采纳 Antigravity 增强

- **实证流程**：临时 apply + swiftlint + xcodebuild test + git restore（已被 S-D7-001 + S-D4-002 两轮证实是最严谨流程）
- **历史测试适配**：旧 `cancelAllCallCount == 1` 类断言全部更新为 per-profile 等价断言

### 采纳 Claude 增强

- **7 条 future-proof 触发器表**——比 Codex 5 条更细致的「未来何时需重审本设计」清单
- **Mock 完整契约一致性**——`scheduledHoursByProfile` / `cancelledProfileIds` 等命名

### 三家共同贡献

| 贡献 | 来源 |
|---|---|
| 主架构（facade + 4 层 namespace + scope 化） | Codex |
| 完整 Diff（含 NotificationServiceMock 实证 patch） | 三家齐 |
| 临时 apply + 编译验证流程 | Antigravity |
| 盲区 future-proof 触发器细致清单 | Claude |
| Multi-Profile 测试边界 | Codex + Claude（6+7 边界融合）|

## 4. 融合方案（最终 apply）

### 4.1 NotificationServiceProtocol.swift

完全采用 Codex 提案 + 协议方法名 `cancelDaily(for:)` 用 `ProfileScope`。

### 4.2 LiveNotificationService.swift

完全采用 Codex 提案：
- 顶层 `UserNotificationScheduling` facade protocol
- `UNUserNotificationCenter` extension 实现 facade
- `SnapDrillNotificationID` enum（含 `legacyDailyReview` / `managedPrefix` / `dailyReview(for:)` / `isManaged(_:)`）
- DI inject notificationCenter (default = current())
- scheduleDaily 同时 remove legacy id 实现级联清理
- cancelDaily exact ID removal
- cancelAllSnapDrillNotifications 用 pending query + isManaged filter

### 4.3 NotificationServiceMock.swift

采用 Codex 方案 + Antigravity 增强（per-profile dict 追踪）。

### 4.4 NotificationSettingsViewModel.swift / NotificationSettingsView.swift

完全采用 Codex 提案：ProfileScope 注入 + View 从 `@Environment(\.profileManager).activeScope` 拿。

### 4.5 测试套件

采用 Codex 6 个 Core 单元测试（`FakeNotificationCenter` + `UserNotificationScheduling` facade）+ 适配现有 `NotificationServiceTests` / `NotificationSettingsViewModelTests`。

## 5. Apply 计划

1. ✅ 写本 consensus 文件
2. apply Codex 主架构 patch（含 facade / namespace / scope 化）
3. apply Mock 增强（per-profile dict）
4. apply ViewModel + View 注入
5. 适配旧 `NotificationServiceTests` 测试（cancelAll → cancelDaily 语义）
6. 适配旧 `NotificationSettingsViewModelTests` 测试
7. 新增 6 个 Codex Core 边界测试（FakeNotificationCenter facade）
8. swiftlint --strict + build-for-testing + 单元测试
9. ledger 翻面：S-D4-002 OPEN → RESOLVED
10. commit + push + 清 worktree

## 6. Phase 11 第二战 worktree 工作流观察

| 观察项 | 评价 |
|---|---|
| 物理隔离效果 | ✅ 三家产出无串扰，6 项设计决策各自独立表态（D1 namespace 深度 / D2 类型 / D4 升级路径 / D5 cancelAll 去留全有真实分歧）|
| 净化提示词效果 | ✅ 三家**3/3** 共识根因 + 修复方向，差异在具体实现策略 |
| 实证强度差异化 | ⚠️ Antigravity 临时 apply + 编译 + 测试最严谨 / Codex 设计深度最强 / Claude 中等 |
| 三家差异化能力暴露 | ✅ Codex 架构抽象（facade）/ Antigravity 工程实证（编译验证）/ Claude 防御性盲区清单——三种风格清晰可辨 |
| 控制变量法纪律 | ✅ 物理隔离 + 净化提示词第二次实战成功 |
| 工作流缺陷 | ⚠️ Antigravity 汇报层再次用 `file:///` 绝对路径（产出文件层无此问题）；下次提示词强化 |

### Antigravity 汇报层 `file:///` 重复犯

S-D7-001 已警告过一次，本轮再次出现——说明提示词「文件路径使用 worktree 相对路径，不要用 file:///」**对外审汇报层无效**（只对产出文件层有效）。

后续工作流改进：在用户视角的文档中明确「外审汇报层 `file:///` 链接为已知低危行为，不返工」，避免重复噪音。

## 7. 关联

- [worktree-audit-workflow](../standards/worktree-audit-workflow.md) Phase 11+ 标准
- [S-D7-001-fix-consensus](S-D7-001-fix-consensus.md) Phase 11 首战参考
- [ADR-005](../decisions/ADR-005-doc-semantic-layer-audit.md) §Phase 10 全局收官
- [audit-ledger-semantic-2026-05.tsv](audit-ledger-semantic-2026-05.tsv) S-D4-002 待翻面
- 关联 finding：S-D4-001（ServiceContainer DI 退化，本修复**不加重它**——通过 `@Environment(\.profileManager)` 而非 ServiceContainer 拿 Profile）
