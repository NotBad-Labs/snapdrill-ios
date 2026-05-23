---
last_verified: 2026-05-23
layer: snapshot
scope: status
freshness:
  max_age_days: 7
  decay_trigger: [pr_merge, decision_recorded]
---
# 状态看板

> 本文件待由 `sync-status` skill 双向自动维护（user-decision-log #006 backlog）。skill 落地前，权威状态请见下列来源；本文件**只保留极简手动条目**。

## 当前焦点（手动维护）

- M-000 Meta-Vision v1.2 已 ratified（user-decision-log #004）
- Round 1 Boot 序列重构落地中（user-decision-log #006）
- 下游 M-001 ~ M-006 起草待启动（顺序：M-005 → M-002 → M-006 → M-001 → M-004 → M-003）

## 权威状态源

- 已生效裁决与 Overrule：[docs/meta/user-decision-log.md](docs/meta/user-decision-log.md)
- 下游派生 backlog：[docs/meta/M-001-to-M-006-followup-backlog.md](docs/meta/M-001-to-M-006-followup-backlog.md)
- 文件级变更：`git log --oneline -20`
- 进行中工作：`gh issue list --state open`、`gh pr list --state open`
