---
last_verified: 2026-05-25
layer: pattern
derived_from: [M-001]
---
# 单家审计/修复提示词模板（Phase 11+ Worktree 版）

> Phase 11+ 起的标准模板。适用于：语义维度审计、三方修 bug 提案、设计选型等一切「三方对抗任务」。
>
> **重大变更**：Phase 10 维度 4-7 版本含「Claude CLI 已抓 X，避免重复」段，实战证明会被外审解读为分工指令，污染独立性。本版本走 **worktree 物理隔离** + **净化提示词** 两条腿，详见 [[worktree-audit-workflow]]。

## 何时不需要走本模板

| 场景 | 处理 |
|---|---|
| 纯机械批改（rename、批量 frontmatter）| 单家直做 |
| Skill body 微调、typo | 单家直做 |
| 流程治理实现层（hook 脚本、CI 配置）| 设计走对抗，实现可单家 |

判断口诀见 [[worktree-audit-workflow]] §何时使用 Worktree 三方对抗。

## 工作流（与 worktree-audit-workflow Step 1-5 对齐）

1. Claude CLI 在主分支起草 **任务定义书** `docs/audits/<task-slug>-task-definition.md`
2. 拉两个 worktree：`../snapdrill-ios-codex` / `../snapdrill-ios-ag`
3. 用下方净化模板**三家同时启动**（**不串行**）
4. 三家完成 commit + push 各自 worktree 分支
5. Claude CLI 主笔回汇 + cross-audit/fix-consensus 落档

## 净化模板（复制贴 Codex 桌面端 / Antigravity）

```text
以三方对抗模式独立完成 SnapDrill 项目【任务：<task-slug>】。

==== 工作目录（必读，决定你看到什么）====
- **你的 worktree**：<填入> 例如 ../snapdrill-ios-codex (audit/codex-<task-slug> 分支)
- **禁止访问**：主仓库目录 /Users/yiming/Developer/snapdrill-ios 或 ../snapdrill-ios-ag
- **理由**：物理隔离是控制变量法的核心保证。

==== 任务定义书（唯一信息源）====
必读：docs/audits/<task-slug>-task-definition.md（你的 worktree 内）

任务定义书是三家共享的同一份文件。所有要求以它为准。
不要参考主分支已有的 consensus / ledger / ADR 等基线（即使你能看到也不要读）。

==== 产出 ====
落档到你的 worktree 的 docs/audits/<task-slug>-<vendor>.md
（vendor = codex 或 antigravity）
文件头必须带 frontmatter:
---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---

==== 控制变量法纪律（关键，违反会被回退）====
1. 你的任务和其他家 **完全相同**，**刻意冗余**正是控制变量法精髓
2. 不要刻意避开任何可能 finding / 修复方案 / 设计选项
3. 与其他家产出 **重叠是好事**，分布对比正是分析价值所在
4. **不要参考其他家产出**，包括主分支 consensus / ledger / ADR 中的已有结论
5. 不要假设「Claude 已经覆盖 X」「Codex 已经抓 Y」——你独立完成全部任务范围

==== 严禁操作（违反会被回退）====
1. 禁止修改你 worktree 之外的任何文件
2. 禁止修改主分支 ledger / STATUS / handoff / ADR
3. 禁止在你的产出文件写「✅ 已完成 / 已收官」类终态标记
4. 禁止指向「下一任务」「下一维度」「下一会话方向」
5. 禁止合并/cherry-pick 主分支或其他 audit 分支

==== 完成后 ====
1. 在你的 worktree commit：git add . && git commit -m "audit: <task-slug> <vendor> 独立产出"
2. push 到对应 audit 分支：git push -u origin audit/<vendor>-<task-slug>
3. 在与用户的会话回复中说明：worktree 路径 + 分支名 + 产出文件路径
4. 然后停止，等待 Claude CLI 主笔在主分支做共识收尾
```

## 修 bug 场景的补充段（task-definition.md 内含）

修 bug 任务的任务定义书必须包含：

```text
==== bug 描述 ====
- 症状：<具体观察>
- 根因区域：<文件:行号>
- 复现：<最小复现步骤>

==== 修复要求 ====
1. 提供修复 diff（patch 格式或完整新代码段）
2. 提供测试用例覆盖以下边界：
   - <边界 1>
   - <边界 2>
   - <边界 3>
3. 提供完整 declared/输入空间验证（运行修复后的代码 + dump 关键集合）
4. 自检：本方案可能漏的边界有哪些？为什么排除？

==== 禁止 ====
- 参考其他家方案
- 参考主分支已有提案
- 直接 apply 到代码（产出只是方案，apply 由 Claude CLI 主笔在共识后做）
```

## 适配各任务类型

| 任务类型 | task-definition.md 关键字段 |
|---|---|
| 语义维度审计 | 范围（文件清单）/ 判据（ADR-005 §维度 N）/ finding 输出格式 |
| 三方修 bug 提案 | bug 描述 / 修复要求 / 测试用例边界清单 |
| 架构设计选型 | 设计目标 / 约束 / 候选维度 / 决策判据 |

## 关联

- [[worktree-audit-workflow]] SSOT，本模板从属之
- [[ADR-005-doc-semantic-layer-audit]] §Phase 10 全局收官（污染反思）
- [[F-008]] 「相同完整任务、不分工」纪律

## 历史

- Phase 10 维度 1-3：无「严禁操作」段
- Phase 10 维度 4：首次加「严禁操作」段封堵 Antigravity 抢跑（成功）
- Phase 10 维度 5-7：「Claude CLI 已抓」段污染三家独立性（**反面教材**）
- Phase 11+：迁移到本 worktree 净化版（**当前**）
