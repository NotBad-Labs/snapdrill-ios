---
last_verified: 2026-05-19
layer: snapshot
freshness:
  max_age_days: 7
  decay_trigger: [pr_merge]
---
# SnapDrill 项目状态看板

> 最后更新：2026-05-19（**文档体系深度清洁 Phase 0/1/2 部分完成**）
> 编译状态：✅ 0 errors · 0 lint violations · docaudit exit 0
> Open PR：0 · Open Issue：8（#699 backlog + Apple 阻塞链 + #626 真机待验）

## 当前状态（2026-05-19）

**文档体系深度清洁进行中**。Plan 在 Claude 私有空间（slug: virtual-jingling-raccoon）。已完成：

- **Phase 0**：接管 52-doc 审计成果，三方 verdict 提案汇总（cleanup-20260519-phase0-status.md）
- **Phase 1**：SSOT 自洽体检 — 修 KNOWLEDGE_MAP §1 §4 跳号 + DOC_DEPENDENCY_MAP §1 缺号；补 audit-rubric / skill-source-ledger / standards/README 到 KM；软上限触线机制（commit f40fcdcf）
- **Phase 2.1/2.2**：跑完 Gemini 5-batch verdict + 三方汇总裁决（cleanup-20260519-phase2-consensus.md）。Final 分布：47 VALID / 4 VALID_WITH_GAP / 1 STALE / 0 NEEDS_REVISION（A 组 / B 组 / C 组逐次闭环后的终态）
- **Phase 2.3/2.5**：31 VALID 文件批量刷 last_verified；A019 reference_codex_plugin_v104 归档到 docs/archive/（commit bdb7cbc6）
- **Phase 2.4 进行中**：20 个 NEEDS_REVISION 文档逐个修订

**Skill 体系**：54 个 distinct 一层 skill（14 项目治理、24 Claude-only 领域 skill、16 共享 skill）。SSOT：`docs/standards/skill-architecture.md`。

| 外部阻塞项 | 说明 | 状态 |
|---|---|---|
| Apple 开发者账号 (#163 链) | $99 年费待缴 | 用户控制 |
| #626 QuestionSplittingService | 需 iOS 26 真机 + Apple Intelligence | 待真机验证 |

### Apple 账号阻塞链

| Issue | 内容 |
|---|---|
| #163 | 公司 Apple 开发者账号 |
| #479 | StoreKit 付费墙 |
| #485 | iCloud CloudKit 同步 |
| #161 | TestFlight Build 6 |

## 产品决策索引

| 日期 | 决策 | ADR |
|---|---|---|
| 2026-04-10 | 删除 ATT 授权弹窗 | ADR-002 |
| 2026-04-10 | 智能组卷 Hybrid + 高级统计 Hybrid | ADR-001 |
