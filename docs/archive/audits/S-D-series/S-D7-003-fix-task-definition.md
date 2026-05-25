---
last_verified: 2026-05-21
layer: pattern
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D7-003 三方修复提案 — 任务定义书（流程治理设计）

> Phase 11 流程治理设计任务（**F-018 Sprint Contract 应用率漂移**）。三家共享同一份任务定义。

## Bug 描述

**症状**：F-018「编码前契约」+ `sprint-contract` skill 在文件层和 skill 层活跃，但实证抽样 GitHub Issue 数据：

- enhancement Issues #159 / #137 / #136 / #31 / #30 = **0/5 有 Sprint Contract comment**
- chore Issues #735 / #684 / #718 / #720 = **0/4 有 Sprint Contract comment**
- 仅 epic #766 有

**三态漂移**：dead-on-paper（feedback.md 写明）/ alive-in-skill（skill 文档完备）/ not-applied-in-practice（实际 ≈0% 应用率）。

**根因区域**：当前无机械化拦截。Sprint Contract 是 Claude 自觉行为，但 Claude 经常忘 / 跳。

## 范围

| 项 | 内容 |
|---|---|
| 涉及文件 | `.claude/hooks/*` / `.github/ISSUE_TEMPLATE/*.md` / `sprint-contract` skill / `docs/workflow.md` |
| 实现层目标 | **机械拦截**——Issue 进入 Building 状态但无 Sprint Contract → 阻断代码修改权限 |
| 设计层目标 | Sprint Contract 应该机械必填还是软引导 |
| 不可改 | F-018 本身的纪律意图（编码前必须先有 scope 契约）|

## 修复方案要求

### 1. 设计决策必答

| 决策点 | 选项示例 |
|---|---|
| 拦截位置 | Claude PreToolUse Edit hook 检测当前 Issue 状态 / Edit 前检测最近 Issue comment 含 Sprint Contract / commit msg 检测 |
| 拦截强度 | 软警告（log + 继续）/ 硬阻断（exit 2）/ 渐进硬化（首次软警告、第二次硬阻断）|
| Issue 状态识别 | `gh issue view --json labels` 检查 status:building / 检查最近 comment 是否含 "Sprint Contract" 字眼 / 检查 PR body 含 contract 段 |
| Appetite=Small 豁免 | chore Small 直接豁免 / 简化为 Touches/No-Touch/DoD 三条 / 完全不豁免 |
| 历史 Issue 处理 | 不追溯 / 抽样回溯补 contract / 强制下次启动前补 |
| 与 cross-audit / post-merge skill 联动 | sprint-contract 落档自动触发 cross-audit 流程 / cross-audit 完成自动 closeout sprint contract |
| 直接 commit 场景（无 Issue）| 完全阻断 / 直接 commit 也需要 commit msg 含 Touches / No-Touch / DoD 摘要 / 豁免 |

### 2. 实现方案

至少 2 项中至少 1 项：
- **Claude Hook 实现**：`.claude/hooks/pre-edit-sprint-contract.sh` 或同等机制
- **`sprint-contract` skill 改进**：加 Issue 状态检测 + 自动启动入口 + 阻塞代码修改 API
- **`.github/ISSUE_TEMPLATE` 改进**：让 Sprint Contract 段在 Issue 创建时默认必填
- **CLI 包装**：`gh-issue-building` wrapper 自动检查 contract

### 3. 测试用例

至少覆盖：
- Issue 处于 Building 状态但无 Sprint Contract comment → Edit 被拦截
- Issue 处于 Building 且有 Sprint Contract → Edit 放行
- Appetite=Small 的 chore Issue → 按豁免/简化规则走
- 没有 Issue 关联的 ad-hoc edit → 按设计决策处理
- 误拦截恢复路径（如何让用户加完 contract 后立即解锁）

### 4. 与 S-D7-002 review 留痕联动

S-D7-002 和 S-D7-003 都是 F-rule 应用率漂移的「机械化拦截」问题。**本方案必须**说明：
- 是否复用 S-D7-002 hook 框架
- 是否产生新 hook（命名约定）
- 与 dangerous-bash hook / swift-autolint hook 的优先级关系

### 5. 自检段

「本方案的已知盲区」必须列出：
- 用户绕过路径（环境变量 / 直接编辑文件等）
- 假阳性场景（Issue 描述含「Sprint Contract」关键字但实际不是合规 contract）
- 团队规模扩大后的可扩展性

## 产出位置

落档到你的 worktree 的 `docs/audits/S-D7-003-<vendor>.md`（vendor = codex 或 antigravity）。

Claude CLI 主笔产出位置：`docs/audits/S-D7-003-claude.md`（主分支）。

## 验收标准

- ✅ 机械化拦截能在「Issue 进入 Building 但无 contract」时真实阻断 Edit
- ✅ 豁免条件 machine-readable
- ✅ 至少 5 个测试场景覆盖
- ✅ 设计决策必答 7 项全部表态
- ✅ 与 S-D7-002 联动说明清晰
- ✅ 「已知盲区」段诚实

## 严禁操作

同 S-D7-002 任务定义书。

## 收尾后行为

同上。

## 关联

- [worktree-audit-workflow](../standards/worktree-audit-workflow.md)
- `docs/memory/feedback.md` F-018
- `docs/workflow.md` §编码前契约
- `.claude/skills/sprint-contract/`
- `.github/ISSUE_TEMPLATE/feature_request.md` §Sprint Contract / `chore.md` §Sprint Contract
- **联动**：S-D7-002（F-005 review 留痕机械化）
