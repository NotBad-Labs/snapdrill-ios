---
last_verified: 2026-05-25
layer: archive
scope: meta-audit
---

# docs/archive/memory/ — 整个 docs/memory/ 目录归档（#022）

> 2026-05-25 [#022](../../meta/user-decision-log.md#022)：帅哥审视 `docs/memory/` 目录后，3 个文件都无 M-000 派生锚（违反 M-000 §8 概念单一权威 + M-003 §2 决策树）。整目录归档，新规则不再使用 `docs/memory/` 路径。

## 归档文件

| 文件 | 原路径 | 归档理由 |
|---|---|---|
| `decisions-legacy.md` | `docs/memory/decisions.md` | D-001~D-005 工程决策记录。M-000 派生锚缺失。后续 PR 评估每条：active 决策 → 升 ADR（`docs/decisions/ADR-NNN.md`）；过时 → 归档 |
| `feedback-f-rules-redirect-legacy.md` | `docs/memory/feedback.md` | F-rule 退役 redirect 索引。F-rule 体系 [#022](../../meta/user-decision-log.md#022) 全部退役。F-004 timeboxed policy 应迁移到 `docs/standards/migration-policy.md`（待建）。500+ refs 后续 PR 分批替换为直接引用权威源 |
| `handoff-pre-009-snapshot.md` | `docs/memory/handoff.md` | Pre-#009 时代 Phase 状态 snapshot。13 处引用 Phase 10/11 等已过时概念。当前状态可由 user-decision-log + git log + STATUS.md 覆盖，handoff 不再独立 |

## 后续 PR 计划

1. 每条 D-XXX 评估 → 升 ADR 或归档（见 decisions-legacy.md）
2. F-rule 500+ refs 批量替换为直接引用（feedback.md 历史链接逐步 break）
3. `docs/standards/migration-policy.md` 新建承接 F-004 timeboxed policy
