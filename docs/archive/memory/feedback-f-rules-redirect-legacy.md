---
last_verified: 2026-05-25
layer: archive
---

# F-NNN 规则 — 全部退役（[#022](../meta/user-decision-log.md#022)）

> **2026-05-25 系统性消解**（#022 第六次元规则修订）：所有 F-NNN 规则**全部退役**。原因：F-rule 是 pre-M-000 时代的临时编号体系，与 M-000 §8「概念单一权威」+ M-003 §6「派生映射」冲突——每条 F-rule 都有正式的 skill/standards/protocol 权威源，F-NNN 编号是冗余索引层。
>
> 本文件保留为**历史 redirect 索引**：500+ 个仓库内 F-NNN 引用通过本表追溯到当前权威源，便于后续 PR 批量替换为直接引用。新规则不再使用 F-NNN 编号，按 M-003 §2 决策树（standards / templates / hooks / scripts / M-001~M-006 / skill 末位）选择归宿。

## 全量退役 redirect 表

| 退役编号 | 原规则名 | 权威源（替换为直接引用）|
|---|---|---|
| F-001 | Git 工作流纪律 | `docs/protocol.md` § Git 工作流 |
| F-002 | （早期合并）| `docs/standards/engineering.md` 原则 2 + `docs/KNOWLEDGE_MAP.md` 路由 |
| F-003 | （早期合并）| `docs/DOC_DEPENDENCY_MAP.md` |
| F-004 | 内测不做 Schema 迁移 | `docs/standards/migration-policy.md`（待建）或 `docs/protocol.md` 临时段 — 见下方「F-004 timeboxed policy 处理」|
| F-005 | 对抗性审查 | `docs/protocol.md` § Code Review |
| F-006 | 审计深度验证 | `.claude/skills/verify-audit-report/SKILL.md` |
| F-007 | CI 双时点门禁 | `docs/standards/ci-gates.md`（如有）+ `.claude/hooks/` |
| F-008 | 三方相同完整任务 | `docs/templates/cross-audit-workflow.md`（cross-audit skill 已 DOWNGRADE）|
| F-009 | （早期合并）| `docs/standards/review-prompt-guide.md`（如有）|
| F-010 | （早期合并）| `docs/protocol.md` |
| F-011 | 审计期间三方只读 | `docs/templates/cross-audit-workflow.md` |
| F-012 | 全量做不偷懒 | `.claude/skills/verify-audit-report/SKILL.md` |
| F-013 | Scope 膨胀拆分 | `docs/templates/sprint-contract.md` |
| F-014 | 跳过测试门禁 | `docs/templates/sprint-contract.md` |
| F-015 | （早期合并 → F-007）| 同 F-007 |
| F-016 | 质疑方批准 | `docs/templates/cross-audit-workflow.md` |
| F-017 | UI/SDK 调研 | `.claude/skills/api-research/SKILL.md`（如有）或 `docs/standards/api-research.md` |
| F-018 | 编码前契约 | `docs/templates/sprint-contract.md` |
| F-019 | 反模式回流 | `.claude/skills/post-merge/SKILL.md`（如有）|
| F-020 | （早期合并 → F-005）| 同 F-005 |

## F-004 timeboxed policy 处理

F-004 是唯一在 feedback.md 本地权威定义的 policy（内测不做 Schema 迁移，App Store 上架后废止）。退役后内容迁移至 `docs/standards/migration-policy.md`（待 #022 后续 PR 创建）或临时保留在 `docs/protocol.md`。Timebox 不变：`review_after: 2026-07-01` / `sunset: App Store 上架后`。

**临时归宿**（本次 commit）：保留在本文件下方「F-004 临时定义段」，待 standards/migration-policy.md 建立后迁移。

## F-004 临时定义段（待迁移）

**规则**：内测期（App Store 上架前）SwiftData 模型变更不走 schema migration，直接 reset 本地数据库。任何破坏性 Model 改动只需保证编译通过 + 测试通过，不需要写 `SchemaMigrationPlan`。

**理由**：内测用户少 + 数据无价值，写 migration 是反 ROI；上架后真实用户数据进入才需要严肃迁移。

**触发**：改 `Packages/*/Models/*.swift` 或任何 `@Model` 类型的字段时。

**Timebox**：`review_after: 2026-07-01`，`sunset: App Store 上架后强制废止`。届时本段删除，启用正式 migration 流程。

## 后续 PR 批量替换计划

500+ 处 `F-NNN` 引用按以下顺序分批替换为直接引用（每批独立 commit）：

1. **批 1**：高频 F-005（124 refs）+ F-018（90 refs）→ 替换为 `docs/protocol.md § Code Review` 与 `docs/templates/sprint-contract.md`
2. **批 2**：F-008（74 refs）+ F-001（58 refs）→ 替换为 templates/cross-audit-workflow.md 与 docs/protocol.md § Git 工作流
3. **批 3**：F-012/F-013/F-014/F-017/F-019（中频）→ 替换为对应权威源
4. **批 4**：F-006/F-011/F-016（剩余）+ F-007（残留）→ 替换 + 检查零残留

替换完成后本文件可整体归档至 `docs/archive/audits/F-rules-redirect/`。

## 编号规则（已废止）

~~格式 `F-NNN`（三位数字零 padding）。编号单调自增，退役不复用。~~

**新规则不再使用 F-NNN 编号**。按 M-003 §2 决策树选择归宿：standards / templates / hooks / scripts / M-001~M-006 派生 / skill（末位优选）。
