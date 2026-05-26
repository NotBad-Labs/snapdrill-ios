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
- 三件套（Goal D/A/B）push 完成（commits 6547e8ac..95527f51，2026-05-26，详 [three-goals-cross-source-review](docs/audits/three-goals-cross-source-review-20260526.md)）
- **Goal H 文档体系健康度收敛 sprint 完结**：H1-H8 全完成（详 [h7-standards-content-audit](docs/audits/h7-standards-content-audit-20260526.md) / [h7-batch2-content-audit](docs/audits/h7-batch2-content-audit-20260526.md) / [h7-p0-verify](docs/audits/h7-p0-verify-20260526.md) / [h6-skill-links-upstream-issue](docs/audits/h6-skill-links-upstream-issue-20260526.md)）
- 后续：Goal G 产品 milestone 方向待定 + MC-12 (M-005 §G.7) + MC-13 (M-000 §11.10 v2.2) backlog 待启动

## 权威状态源

- 已生效裁决与 Overrule：[docs/meta/user-decision-log.md](docs/meta/user-decision-log.md)
- 下游派生 backlog：[docs/meta/M-001-to-M-006-followup-backlog.md](docs/meta/M-001-to-M-006-followup-backlog.md)
- 文件级变更：`git log --oneline -20`
- 进行中工作：`gh issue list --state open`、`gh pr list --state open`
