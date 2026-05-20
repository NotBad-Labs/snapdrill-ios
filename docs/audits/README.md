---
last_verified: 2026-05-20
layer: snapshot
freshness:
  max_age_days: 180
  decay_trigger: [audit_round]
---
# Audits

> 项目治理审计产物存放地点。与 `docs/decisions/` (ADR) 同级，承载「事实裁决记录」类文档。

## 当前归档

| 文件 | 范围 | 产生时间 | 关联 ADR |
|---|---|---|---|
| `audit-ledger-2026-05.tsv` | 文档体系深度清洁 Phase 0-9，192 条文件级 verdict（Claude + Codex + Gemini 三方裁决 + Final_Decision） | 2026-05-18 ~ 2026-05-20 | `docs/decisions/ADR-004-doc-system-deep-clean.md` |

## TSV 字段语义

`audit-ledger-*.tsv` 第一行为表头，字段如下：

| 列 | 含义 |
|---|---|
| `ID` | A001 起单调递增 |
| `Path` | 被审计文件相对仓库根路径 |
| `Category` | 文件分类（产品 / 技术 / Claude-LOCAL / Scripts / Archive 等） |
| `Declared_Purpose` | 文件自称用途 |
| `Actual_Current_Purpose` | 实测实际用途 |
| `Incoming_Refs` / `Outgoing_Refs` | 入引用 / 出引用统计 |
| `Code_Config_Evidence` / `Process_Evidence` / `Product_Evidence` | 三类证据 |
| `Verdict` | 文档自我声明状态（VALID / VALID_WITH_GAP / NEEDS_REVISION / STALE_OR_INVALID） |
| `Confidence` | 三方裁决置信状态（RESOLVED / PENDING） |
| `Reason` / `Recommended_Action` / `Revision_Scope` / `Owner` | 决议元信息 |
| `Risk_If_Unchanged` / `Risk_If_Deleted` | 风险评估 |
| `Evidence_Gaps` | 证据缺口 |
| `Claude_Verdict` / `Codex_Verdict` / `Gemini_Verdict` | 三方独立裁决 |
| `Final_Decision` | 三方汇总后的最终裁决（cross-audit-consensus skill 产出） |

## 阅读口径

- **Final_Decision 是 SSOT**，三方独立裁决列是过程记录
- **Codex/Gemini 列空 = 该条目以 Claude 单家裁决落地**（Phase 5+ 增量条目为节省 API 费用未跑完整三方对抗；详见 `docs/decisions/ADR-004-doc-system-deep-clean.md` 元数据段）
- **Confidence=RESOLVED** 表示 Final_Decision 已落地；旧版数据可能有 PENDING（Phase 2 残留，已在 2026-05-20 全部 RESOLVED）

## 维护

- 单个 ledger 一旦定稿即冻结，不再追加新行；新一轮深度清洁开新文件 `audit-ledger-YYYY-MM.tsv`
- frontmatter `max_age_days: 180` 用于触发半年级 freshness 复审
- ledger 文件本身是 TSV（无 frontmatter），元信息靠本 README 承担
- Claude 私有工作副本仍可保留在 `~/.claude/plans/audit-ledger.tsv` 作 working cache，但 repo 版本为 SSOT

## 关联

- 方法论 SSOT：`docs/decisions/ADR-004-doc-system-deep-clean.md`
- 跨 agent 入口：`AGENTS.md` → `docs/KNOWLEDGE_MAP.md`
- 触发条件与复审节奏：ADR-004 「何时再触发本方法论」段
