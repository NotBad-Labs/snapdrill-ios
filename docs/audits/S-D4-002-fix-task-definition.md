---
last_verified: 2026-05-21
layer: pattern
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D4-002 三方修复提案 — 任务定义书

> Phase 11 第二个 worktree 任务（首个真生产 bug 三方修复）。三家共享同一份任务定义，独立产出修复方案 + 测试用例。
>
> Claude CLI / Codex 桌面端 / Antigravity 三家用完全相同的任务定义书，物理隔离在三个 worktree 内独立工作。

## Bug 描述

**症状**：Multi-Profile 模式下切换 Profile 时，**其他 Profile 的复习提醒通知会被系统级擦除**。直接表现：
- 用户 A 设置「每天 20:00 提醒复习」
- 切换到用户 B，B 设置「每天 19:00 提醒复习」
- 切回用户 A：A 的 20:00 通知**已被 cancel**，再也不会响

**根因区域**：`Packages/SnapDrillCore/Sources/SnapDrillCore/Service/LiveNotificationService.swift`（精确行号自行定位）

**关键代码缺陷**：

1. **通知 ID 全局硬编码**：所有 Profile 共用同一个 identifier `"com.snapdrill.daily-review"`，多 Profile 物理上没有独立空间
2. **scheduleDaily 调用 cancelAll**：每次设置新提醒前 `removeAllPendingNotificationRequests()` 物理擦除 *iOS 系统级所有* pending notification，跨 Profile 边界
3. **cancelAll 也是全局**：disable 时擦掉所有 Profile 的通知

**违反产品规格**：
- `docs/product/product-vision.md` §多孩家庭 Multi-Profile 刚需
- `docs/product/product-requirements.md` Profile 隔离边界

**Phase 10 抓到的证据**：维度 4 S-D4-002 finding，落档在 `docs/audits/audit-ledger-semantic-2026-05.tsv`。
（**修复提案阶段不要读上述基线** — 你需要从代码本身验证。）

## 范围

| 项 | 内容 |
|---|---|
| 修复文件（核心）| `Packages/SnapDrillCore/Sources/SnapDrillCore/Service/LiveNotificationService.swift` |
| 可能涉及 | `NotificationServiceProtocol.swift` / `NotificationServiceMock.swift` / `NotificationSettingsViewModel.swift` |
| Profile 上下文来源 | `ProfileManager` (Packages/SnapDrillData) 暴露 `activeProfileId: UUID` / `activeScope: ProfileScope?` |
| 不可改 | Profile 切换的 Container 重建机制（ProfileManager.swift 主流程不动）|
| 周边影响 | 升级路径：现有用户旧的 `"com.snapdrill.daily-review"` 通知如何处理（保留 / 清理 / 一次性迁移）|

## 修复方案要求

### 1. 设计决策必答

每家方案**必须**回答以下设计问题（不要照搬其他家立场）：

| 决策点 | 选项示例 |
|---|---|
| ID 拼接格式 | `<base>.<profileId>` / `<base>-<profileId>` / prefix vs suffix / 其他 |
| Profile 上下文如何注入 | 协议参数显式传 `profileId` / Service 持有 ProfileManager 弱引用 / 闭包注入 |
| 替代 cancelAll 的 scope 化 | 维护 active ID Set 主动 remove / pendingRequests filter prefix / 引入 perProfileIdentifiers() API |
| 升级路径（旧 `"com.snapdrill.daily-review"` 通知）| 启动时一次性清理 / 落到「默认 Profile」名下 / 忽略让 iOS 自然过期 |
| 是否需要保护性 cancelAll() 完全删除（破坏性）| 保留作 admin/reset API / 改为 cancelAllForActiveProfile / 完全移除 |
| Multi-Profile 测试边界覆盖 | 用 Mock NotificationCenter / 用真实 UNUserNotificationCenter 但隔离 / 接口层 spy |

### 2. 代码 diff

提供修复 patch（git diff 格式或完整新代码段），含：
- 修改文件路径 + 精确行号
- 修改前后对比
- 必要的协议 / mock / viewmodel 同步改动

### 3. 测试用例（边界覆盖）

至少覆盖以下边界，每条边界必须有显式 XCTAssert 或同等强度断言：

| 边界 | 期望 |
|---|---|
| 同一 Profile 重复 scheduleDaily | 后者覆盖前者，**不**影响其他 Profile |
| Profile A 设置后切到 B 设置，再切回 A 检查 pending | A 的提醒仍在 |
| disable on Profile A | 只擦 A 的通知，B 的不动 |
| cancelAll（如果保留）的语义 | 测试覆盖语义边界 |
| ID 格式不会与未来其他通知类型冲突 | 设计层断言（命名空间充分隔离）|
| 现有旧通知 ID 升级路径 | 升级逻辑被显式触发 + 验证 |

### 4. 自检段

在你的产出报告末尾**必须**写一段「本方案的已知盲区」，列出：
- 当前修复**不**覆盖的边界情况
- 为什么排除这些边界
- 如果未来需求变化（例如多通知类型 / 跨设备同步 / Apple Watch 转发），本方案需要重审的触发条件

## 产出位置

落档到你的 worktree 的 `docs/audits/S-D4-002-<vendor>.md`（vendor = codex 或 antigravity）。

Claude CLI 主笔产出位置：`docs/audits/S-D4-002-claude.md`（主分支）。

## 验收标准

- ✅ diff 简洁，副作用可控（不动 ProfileManager 主流程）
- ✅ 编译通过：`xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`
- ✅ swiftlint --strict clean
- ✅ 至少 5 个显式测试断言覆盖 Multi-Profile 隔离
- ✅ 「已知盲区」段诚实，不空话
- ✅ 设计决策必答 6 项全部明确表态

## 严禁操作

- 不要直接 apply 修复到主分支（产出只是方案）
- 不要修改 `Packages/SnapDrillData/Sources/SnapDrillData/ProfileManager.swift` 主流程
- 不要修改主分支 ledger / STATUS / handoff / ADR
- 不要 cherry-pick 主分支或其他 audit 分支
- 不要参考其他家产出 / 主分支 S-D4-002-* 文件（如有）

## 收尾后行为

完成后：

1. 在你的 worktree commit + push 到你的 audit 分支
2. 回复用户：worktree 路径 + 分支名 + 产出文件路径
3. 停止，等 Claude CLI 主笔做 cross-fix-consensus

---

## Claude CLI 自约束

Claude CLI 主笔在主分支执行本任务时，**也走同样流程**：

- 在主分支 `docs/audits/S-D4-002-claude.md` 落档（不直接改 LiveNotificationService.swift）
- 三家齐了之后再写 `S-D4-002-fix-consensus.md` 折叠 + 选最强方案 + apply
- Claude CLI 在主笔阶段才读其他家产出，独立产出阶段**不**读

## 关联

- [worktree-audit-workflow](../standards/worktree-audit-workflow.md) Phase 11+ 标准
- [S-D7-001-fix-consensus](S-D7-001-fix-consensus.md) Phase 11 首战参考
- [F-008](../memory/feedback.md) 「相同完整任务、不分工」
