<!-- last updated: 2026-04-13 -->
<!-- freshness: max_age_days=7, decay_trigger=[issue_change,code_change,priority_change], layer=snapshot -->
# Backlog (Codex 接管执行)

> 目的：维护可执行 backlog，不替代 issue 系统。优先级按可执行性与风险排序。

## P0（当前执行）

1. 文档体系全量梳理（Codex Baseline 主线）  
   现状：已完成入口迁移（`CODEX.md`）与规则迁移（`docs/agent/rules/*`）；里程碑 `Codex Baseline v1（文档治理）` 与主 issue `#583` 已建立；SoT 固化（Batch 1）与 Batch 2 均已回写收口（含 3 项裁决），详见 `docs/DOC_MISLEADING_AUDIT_20260413.md`、`docs/DOC_MISLEADING_AUDIT_BATCH2_20260413.md`、`#586`；里程碑收口报告见 `docs/DOC_GOVERNANCE_CLOSURE_BASELINE_V1_20260413.md`。
2. 三段全量遍历执行（Part 1/2/3）  
   现状：Part 1/2 已收口；Part 3 当前为 Batch A/B/C1/D 完成、Batch B 收口、Batch C2 第二轮完成待手工回归（详见 `repo-traversal-plan.md`）。

## P1（代码完整性）

1. 删除失败用户反馈链路  
   现状：失败已进入 `DeletionScheduler.lastCommitErrorMessage`，UI 层尚未消费该状态。
2. Data 层静默失败治理（Profile 管理/迁移）  
   现状：第三批已完成 `ProfileMigration` must-fail / best-effort 分层与 fallback 加固；`#581` 已关闭，后续仅观察是否需 reopen。

## P2（外部依赖阻塞）

1. StoreKit 订阅态接线（`#479`）  
   现状：`SmartPaperView`、`DashboardAnalyticsViewModel` 仍有 TODO 占位。
2. iCloud 同步与 Word 导出（`#485/#486`）  
   依赖 Apple 开发者账号与 App Store Connect 配置。

## 参考轨道（不进主线）

1. `#578/#579/#580`  
   现状：按 `#583` 基线口径降级为参考项；除外部依赖阻塞外，不作为当前主线输入。
