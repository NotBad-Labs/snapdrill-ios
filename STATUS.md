---
last_verified: 2026-05-26
layer: snapshot
scope: status
freshness:
  max_age_days: 7
  decay_trigger: [pr_merge, decision_recorded]
---
# 状态看板

> 本文件待由 `sync-status` skill 双向自动维护（[user-decision-log #006](docs/meta/user-decision-log.md#006) backlog → [MC-11](docs/meta/M-001-to-M-006-followup-backlog.md)）。skill 落地前，权威状态请见下列来源；本文件**只保留极简手动条目**。

## 当前焦点（手动维护）

- 元规则搭建期**完结**：M-000 v1.2 + M-001~M-006 全 ratify（[#028](docs/meta/user-decision-log.md#028)）
- 三件套（Goal D skill-provenance / Goal A DeepSeek 通道 / Goal B PreEdit hook）push 完成（commits 6547e8ac..95527f51，2026-05-26）
- 三家异源 cross-source review 通过（详 [docs/audits/three-goals-cross-source-review-20260526.md](docs/audits/three-goals-cross-source-review-20260526.md)）
- 进行中：Goal H 文档体系健康度全量收敛 sprint（H1-H8）+ Goal G 产品 milestone 方向待定

## 权威状态源

- 已生效裁决与 Overrule：[docs/meta/user-decision-log.md](docs/meta/user-decision-log.md)
- 下游派生 backlog：[docs/meta/M-001-to-M-006-followup-backlog.md](docs/meta/M-001-to-M-006-followup-backlog.md)
- 文件级变更：`git log --oneline -20`
- 进行中工作：`gh issue list --state open`、`gh pr list --state open`
