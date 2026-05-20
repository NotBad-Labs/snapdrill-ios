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

| 文件 | 范围 | 审计周期 | 审计员（auditor） | 复核员（reviewer） | 关联 ADR | superseded_by |
|---|---|---|---|---|---|---|
| `audit-ledger-2026-05.tsv` | 文档体系深度清洁 Phase 0-9 + Round 9 全集覆盖补审，**217** 条文件级 verdict（含 Round 9 新增 14 governance skill + 11 构建/CI/meta-audit/GitHub 配置，并将 6 个已退役/已归档路径标 STALE_OR_INVALID） | 2026-05-18 ~ 2026-05-20 | Claude Opus 4.7（主线裁决）+ Codex GPT-5.5（5 batch 三方对抗 + Round 1-6 独立验证）+ Gemini CLI（5 batch 三方对抗）；Round 9 25 条增量为 Claude 单家裁决（待 Round 9 独立验证 Codex + Gemini） | 用户 chramboliao（PO，终审 + 工具选型决策） | `docs/decisions/ADR-004-doc-system-deep-clean.md` | — |

> `superseded_by` 列说明：当本 ledger 被新一轮深度清洁产物覆盖时，在此填入新 ledger 文件名（例如 `audit-ledger-2026-12.tsv`）；旧 ledger 文件物理上保留不删除。当前为 `—` 表示仍是 Active 状态。

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

## 命名规则

- 默认按月：`audit-ledger-YYYY-MM.tsv`
- 同月多轮：追加版本后缀 `audit-ledger-YYYY-MM-v2.tsv`（罕见，正常情况一轮深度清洁数周完成）
- 跨年长期审计：用区间 `audit-ledger-YYYY-MM-to-YYYY-MM.tsv`

## Retention / Lifecycle

| 阶段 | 触发 | 动作 |
|---|---|---|
| **Active** | 创建后 0-180 天 | 作为 SSOT 被引用；frontmatter `last_verified` 维持；如发现 verdict 漂移可追加 README 勘误段，**不修改 ledger 行** |
| **Stale Review** | `max_age_days: 180` 到期（约半年） | 起一个新审计周期；走 ADR-004 方法论 Phase 0 接管旧 ledger；判定旧 verdict 是否仍有效 |
| **Superseded** | 新 ledger 发布且覆盖范围与旧 ledger 重叠 | 在本 README「当前归档」表标 `superseded_by:`；旧 ledger 文件保留不删除（git 历史 + 审计追溯需要） |
| **Archive** | 项目重大转向（如产品下线、技术栈重建） | 整体移入 `docs/archive/audits/`；本 README 同步移除条目并加历史指针 |

ledger 文件物理上**永不删除**——审计 ledger 的可追溯性是合规底线，git 历史 + 文件本身双重保险。

## 维护

- 单个 ledger 一旦定稿即冻结，不再追加新行；勘误走 README 附录或新 ledger 文件
- ledger 文件本身是 TSV（无 frontmatter），元信息靠本 README 承担
- **SSOT 是 repo 内的 `docs/audits/*.tsv`；不再保留 `~/.claude/plans/` 私有副本作为 working cache**（迁移完成后已删除，避免双源漂移；如临时需要本地副本，请显式 cp 出来用完即删）

## 关联

- 方法论 SSOT：`docs/decisions/ADR-004-doc-system-deep-clean.md`
- 跨 agent 入口：`AGENTS.md` → `docs/KNOWLEDGE_MAP.md`
- 触发条件与复审节奏：ADR-004 「何时再触发本方法论」段
