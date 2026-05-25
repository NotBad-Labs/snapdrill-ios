---
last_verified: 2026-05-21
layer: pattern
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D7-002 三方修复提案 — 任务定义书（流程治理设计）

> Phase 11 流程治理设计任务。三家共享同一份任务定义，独立产出 hook / skill / 文档治理改进方案。

## Bug 描述

**症状**：F-005「对抗性审查」+ `docs/workflow.md:108-120` 明确规定「所有 PR 必须完成 review 后合并 + Review 结论必须留痕」。但实证抽样：

- **PR #742「docs: 归零审计」MERGED**
  - reviews: 0
  - comments: 0
  - body 无 Codex / Gemini / Xcode review 留痕
  - 但已合并到 develop

这是真生产级 F-rule 违规——纸面纪律 vs 实际执行漂移。

**根因区域**：当前无机械化拦截，依赖人/Claude 自觉。

## 范围

| 项 | 内容 |
|---|---|
| 涉及文件（可能）| `docs/workflow.md` / `.github/workflows/ci.yml` / `.github/pull_request_template.md`（如有）/ `.git/hooks/*` / `.claude/hooks/*` / sprint-contract skill / cross-audit skill |
| 实现层目标 | 用 hook / CI / template 在合并前**机械**校验 review 留痕 |
| 设计层目标 | 给「docs-only / trivial PR」明确豁免边界 |
| 不可改 | F-005 本身的纪律强度（不能因为难落地就放松要求）|

## 修复方案要求

### 1. 设计决策必答

每家方案**必须**回答以下设计问题：

| 决策点 | 选项示例 |
|---|---|
| 强化路径 | GitHub Branch Protection rules / pre-merge hook / PR template 自动检查 / Claude CI 检测插件 |
| 豁免条件设计 | 完全不豁免 / docs-only PR 豁免 / `[skip review]` 标签豁免 / Appetite=Small 豁免 |
| 留痕格式标准化 | PR body 段头模板（如 `## Codex Review` / `## Gemini Review` / `## Xcode Review`）/ 自由格式但必含关键词 / commit message 体例 |
| 检测时机 | merge 前阻断 / merge 后回溯告警 / CI step 阻塞 |
| 历史 PR 处理 | 不追溯 / 抽样回溯标记 / 强制补 review 后再合下个 PR |
| 直推 develop 场景 | 直推也走相同规则 / 直推豁免（已有 `ALLOW_DIRECT_PUSH=1` 机制配合）/ 直推强制 commit msg 含 review 摘要 |
| 与 sprint-contract / cross-audit skill 联动 | sprint-contract closeout 时强制写 review 段 / cross-audit 产出自动 attach 到 PR body |

### 2. 实现方案

提供以下中至少 2 项（最强方案应覆盖 hook + 文档双层）：
- **Hook 实现**：pre-push / pre-merge 检查脚本（bash / python），含拦截语义 + override 机制 + 错误信息
- **CI 检查**：GitHub Actions workflow step，检查 PR body / commits 含留痕关键词
- **PR Template**：`.github/pull_request_template.md` 强制段头模板
- **Skill 改进**：sprint-contract / cross-audit skill 加 review 留痕步骤

### 3. 豁免条件文档化

如设计豁免清单，必须：
- 明确豁免触发条件（machine-readable / human-readable）
- 列出可豁免文件路径模式（如 `docs/**` / `*.md only` / `Scripts/audit/policy.yaml`）
- 给出反例：哪些场景**绝不**能豁免（如 `Packages/**/*.swift` / 任何 `.swiftlint.yml` 变更）

### 4. 测试用例

至少覆盖：
- 一个 PR 无 review 留痕 → 被拦截
- 一个 docs-only PR 走豁免路径 → 放行
- 一个 PR 有 review 留痕但不在标准格式 → 给出明确错误信息
- 直推 develop 场景的等价拦截路径

### 5. 自检段

「本方案的已知盲区」必须列出：
- 用户绕过机制的可能路径（如 `ALLOW_DIRECT_PUSH=1` 是否需要联动收紧）
- 假阳性场景（review 内容合规但格式不标准）
- 与未来 GitHub Enterprise / 协议变化的兼容性

## 产出位置

落档到你的 worktree 的 `docs/audits/S-D7-002-<vendor>.md`（vendor = codex 或 antigravity）。

Claude CLI 主笔产出位置：`docs/audits/S-D7-002-claude.md`（主分支）。

## 验收标准

- ✅ 至少 2 层机械化拦截（hook + CI / hook + template 等组合）
- ✅ 豁免条件 machine-readable
- ✅ 至少 4 个测试场景覆盖
- ✅ 与现有 `Scripts/hooks/pre-push` + `.claude/hooks/block-dangerous-bash.sh` 不冲突
- ✅ 设计决策必答 7 项全部表态
- ✅ 「已知盲区」段诚实

## 严禁操作

- 不要直接 apply hook / workflow 改动到主分支（产出只是方案）
- 不要修改 `docs/workflow.md` §F-005 段（除非有强论证）
- 不要降低 F-005 纪律强度
- 不要 cherry-pick 主分支或其他 audit 分支
- 不要参考其他家产出

## 收尾后行为

同 S-D4-001 / S-D4-002 任务定义书。

## 关联

- [worktree-audit-workflow](../standards/worktree-audit-workflow.md)
- `docs/memory/feedback.md` F-005
- `docs/workflow.md` §对抗性审查
- `.github/pull_request_template.md`（如存在）/ `.claude/hooks/` / `Scripts/hooks/pre-push`
