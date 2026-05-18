---
last_verified: 2026-05-18
layer: snapshot
freshness:
  max_age_days: 7
  decay_trigger: [pr_merge]
---
# SnapDrill 项目状态看板

> 最后更新：2026-05-15（**Phase 5 零信任审计修复完工 — 11 PR 全合，24 真问题清零**）
> 编译状态：✅ 0 errors · 0 lint violations · docaudit exit 0
> Open PR：0 · Open Issue：8（#699 backlog + Apple 阻塞链 + #626 真机待验）

## 当前状态（2026-05-18）

**文档治理 + skill 体系重构收口中**。54 个 distinct 一层 skill 名称：14 项目治理、33 Claude-only 领域 skill、7 共享 skill；其中 `accessibility-generator`、`attributed-string`、`navigation-patterns`、`privacy-manifests` 使用 Claude thin adapter，3 个受管 Swift skill 使用既有 Claude symlink entry。另有 2 个 `.agents/skills/*/skills/*/SKILL.md` 属于 plugin payload，不计入一层 skill 数。目录架构 SSOT：`docs/standards/skill-architecture.md`。

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
