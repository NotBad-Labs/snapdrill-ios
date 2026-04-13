<!-- last updated: 2026-04-13 -->
<!-- freshness: max_age_days=7, decay_trigger=[issue_change,code_change,priority_change], layer=snapshot -->
# Backlog (Codex 接管执行)

> 目的：维护可执行 backlog，不替代 issue 系统。优先级按可执行性与风险排序。

## P0（当前执行）

1. 文档体系全量梳理（Codex Baseline 主线）  
   现状：已完成入口迁移（`CODEX.md`）与规则迁移（`docs/agent/rules/*`）；里程碑 `Codex Baseline v1（文档治理）` 与主 issue `#583` 已建立；SoT 固化（Batch 1）已落地（`docs/workflow.md` Baseline 切换策略 + `docs/DOC_MISLEADING_AUDIT_20260413.md`）；Batch 2 第一轮已回写 5 项一致性修复，剩余 3 项待产品裁决（见 `docs/DOC_MISLEADING_AUDIT_BATCH2_20260413.md` / `#586`）。
2. `#579/#580` 验收与关单推进  
   现状：两项代码均已落地并已回写最新评论；`#579` 已通过 DEBUG 注入路径大图回归（文件可消费删除），但 `simctl openurl` 路径结果不稳定；`#580` 已补充阻断语义测试；两项暂保持 OPEN，待手工体感回归后关单。
3. 三段全量遍历执行（Part 1/2/3）  
   现状：Part 1/2 已收口；Part 3 当前为 Batch A/B/C1/D 完成、Batch B 收口、Batch C2 第二轮完成待手工回归（详见 `repo-traversal-plan.md`）。

## P1（代码完整性）

1. `AppActivityTracker` 接线补全  
   现状：关键链路已接线（Capture/Export/Print/BackupRestore）并加入引用计数保护；行为测试已并入 `SnapDrillFeaturesTests` 且补充 `ProfileSwitchBlockingTests`；待真机体感回归；跟踪 `#580`。
2. 删除失败用户反馈链路  
   现状：失败已进入 `DeletionScheduler.lastCommitErrorMessage`，UI 层尚未消费该状态。
3. Share Extension 大图入站主线程 I/O 风险  
   现状：已迁移后台读取/解码并补齐失败日志；DEBUG 注入路径回归通过；`simctl openurl` 路径暂未稳定复现消费删除，需手工场景确认；跟踪 `#579`。
4. Data 层静默失败治理（Profile 管理/迁移）  
   现状：第三批已完成 `ProfileMigration` must-fail / best-effort 分层与 fallback 加固；`#581` 已关闭，后续仅观察是否需 reopen。

## P2（外部依赖阻塞）

1. `#578` 审计报告（参考项）  
   现状：用户口径已降级为参考，不作为当前治理阻断项。
2. StoreKit 订阅态接线（`#479`）  
   现状：`SmartPaperView`、`DashboardAnalyticsViewModel` 仍有 TODO 占位。
3. iCloud 同步与 Word 导出（`#485/#486`）  
   依赖 Apple 开发者账号与 App Store Connect 配置。
