---
last_verified: 2026-05-26
layer: snapshot
scope: audit-archive
freshness:
  max_age_days: 180
  decay_trigger: [audit_round]
derived_from: [M-000]
---
# docs/audits/ — 入口索引

> ⚠️ **2026-05-25 系统性归档**（[#022](../meta/user-decision-log.md#022)）：本目录从 75 个文件减至核心 active 集合。所有已 ratified 流程的起草过程产物归档至 `docs/archive/audits/<sub-dir>/`。详见下方归档索引。
>
> **2026-05-26 更新**（Goal H3）：M-001~M-006 全 ratify 后，sign-off 报告 + Path-D + H7 series 一并纳入 inventory（消除 docaudit orphans）。

## Active 入口与工具

| 文件 | 用途 |
|---|---|
| README.md | 本入口索引 |
| [single-vendor-audit-prompt-template.md](./single-vendor-audit-prompt-template.md) | 单家审计 prompt 模板（被 standards/cross-audit-workflow 引用）|
| `./audit-ledger-2026-05.tsv` | 224 条文件级 verdict（路径 C Phase 0-9，详见下方 TSV 字段语义）|
| `./audit-ledger-semantic-2026-05.tsv` | 语义层 verdict（Phase 10 7 维度）|

## Audit Reports（路径/Phase/Goal 级审计）

| 文件 | 范围 | 关联裁决 |
|---|---|---|
| [skill-audit-final.md](./skill-audit-final.md) | 路径 C skill 体系最终主笔产物 | [#018](../meta/user-decision-log.md#018) |
| [path-d-skill-derivation-audit-20260526.md](./path-d-skill-derivation-audit-20260526.md) | 路径 D skill 派生锚结构性整改 | [#028](../meta/user-decision-log.md#028) |
| [h7-standards-content-audit-20260526.md](./h7-standards-content-audit-20260526.md) | Goal H7 docs/standards/ 内容级 traceability（揭出 40% 标注问题） | Goal H |
| [h7-batch2-content-audit-20260526.md](./h7-batch2-content-audit-20260526.md) | Goal H7 第二批 templates+ADR+tech+sign-off（揭出 agent 自身污染 55%） | Goal H |
| [three-goals-cross-source-review-20260526.md](./three-goals-cross-source-review-20260526.md) | 三件套 push 前异源 review（Codex+DeepSeek+agy+Claude） | Goal A/B/D |
| [h6-skill-links-upstream-issue-20260526.md](./h6-skill-links-upstream-issue-20260526.md) | Goal H6 — swiftui-pro 上游 SKILL.md 引用 bug 决策（长期豁免） | Goal H |
| [h7-p0-verify-20260526.md](./h7-p0-verify-20260526.md) | Goal H7 P0 异源 verify（agy+DeepSeek 双家 agreement，主笔自审 0% 准确率实证） | Goal H |
| [proposed-check-derived-from-required.md](./proposed-check-derived-from-required.md) | M-005 §G.6 docaudit check 提案（derived_from_required） | [#024](../meta/user-decision-log.md#024) |

## Sign-off Reports（异源 review 落地实证）

### M-000 v2 GUI 起草（[#023 #024](../meta/user-decision-log.md#023) ratify）

| 文件 | 内容 |
|---|---|
| [signoff-antigravity-gui-023-024.md](./signoff-antigravity-gui-023-024.md) | Antigravity GUI sign-off |
| [signoff-codex-gui-023-024.md](./signoff-codex-gui-023-024.md) | Codex GUI Round 1 |
| [signoff-codex-gui-023-024-rerun.md](./signoff-codex-gui-023-024-rerun.md) | Codex GUI Round 2 |
| [signoff-codex-gui-023-024-rerun2.md](./signoff-codex-gui-023-024-rerun2.md) | Codex GUI Round 3 |

### M-001 协作工作流（[#027](../meta/user-decision-log.md#027) ratify）

| 文件 | 内容 |
|---|---|
| [signoff-task-definition-m001.md](./signoff-task-definition-m001.md) | 任务定义书（净化版） |
| [signoff-codex-cli-m001.md](./signoff-codex-cli-m001.md) | Codex CLI Round 1 BLOCK |
| [signoff-codex-cli-m001-rerun.md](./signoff-codex-cli-m001-rerun.md) | Codex CLI Round 2 |
| [signoff-codex-cli-m001-rerun2.md](./signoff-codex-cli-m001-rerun2.md) | Codex CLI Round 3 PASS |
| [signoff-agy-cli-m001.md](./signoff-agy-cli-m001.md) | AGY CLI Round 1 |
| [signoff-agy-cli-m001-rerun.md](./signoff-agy-cli-m001-rerun.md) | AGY CLI Round 2 PASS |

### M-002 分歧裁决（[#025](../meta/user-decision-log.md#025) ratify）

| 文件 | 内容 |
|---|---|
| [signoff-task-definition-m002.md](./signoff-task-definition-m002.md) | 任务定义书 |
| [signoff-codex-cli-m002.md](./signoff-codex-cli-m002.md) | Codex Round 1 |
| [signoff-codex-cli-m002-rerun.md](./signoff-codex-cli-m002-rerun.md) | Codex Round 2 |
| [signoff-codex-cli-m002-rerun2.md](./signoff-codex-cli-m002-rerun2.md) | Codex Round 3 PASS |
| [signoff-agy-cli-m002.md](./signoff-agy-cli-m002.md) | AGY Round 1 |
| [signoff-agy-cli-m002-rerun.md](./signoff-agy-cli-m002-rerun.md) | AGY Round 2 PASS |

### M-004 降级手册（[#028](../meta/user-decision-log.md#028) ratify）

| 文件 | 内容 |
|---|---|
| [signoff-task-definition-m004.md](./signoff-task-definition-m004.md) | 任务定义书 |
| [signoff-codex-cli-m004.md](./signoff-codex-cli-m004.md) | Codex Round 1 |
| [signoff-codex-cli-m004-rerun.md](./signoff-codex-cli-m004-rerun.md) | Codex Round 2 PASS |
| [signoff-agy-cli-m004.md](./signoff-agy-cli-m004.md) | AGY Round 1 PASS |

### M-006 数据治理（[#026](../meta/user-decision-log.md#026) ratify）

| 文件 | 内容 |
|---|---|
| [signoff-task-definition-m006.md](./signoff-task-definition-m006.md) | 任务定义书 |
| [signoff-codex-cli-m006.md](./signoff-codex-cli-m006.md) | Codex Round 1 |
| [signoff-codex-cli-m006-rerun.md](./signoff-codex-cli-m006-rerun.md) | Codex Round 2 |
| [signoff-codex-cli-m006-rerun2.md](./signoff-codex-cli-m006-rerun2.md) | Codex Round 3 PASS |
| [signoff-agy-cli-m006.md](./signoff-agy-cli-m006.md) | AGY Round 1 |
| [signoff-agy-cli-m006-rerun.md](./signoff-agy-cli-m006-rerun.md) | AGY Round 2 PASS |

> **中间轮次 rerun 报告保留理由**：sign-off 中间轮次（rerun / rerun2）记录主笔→ reviewer→ rerun 的修复 trace，是治理实证（哪些 BLOCK 被修复 / 哪些 reviewer 模式重复发现）。保留作为元规则修订证据，不归档。

## 归档索引（2026-05-25 #022 重组）

| 归档子目录 | 内容 | 文件数 | 关联裁决 |
|---|---|---|---|
| [path-c-stage-7/](../archive/audits/path-c-stage-7/) | 路径 C Stage 7 M-003 v1 ratify | 30+ | [#021](../meta/user-decision-log.md#021) |
| [path-c-stage-6/](../archive/audits/path-c-stage-6/) | 路径 C Stage 6 反思 + patch + sign-off | 5 | [#020](../meta/user-decision-log.md#020) |
| [path-c-skill-audit/](../archive/audits/path-c-skill-audit/) | 路径 C skill audit 起草过程 | 9 | [#018](../meta/user-decision-log.md#018) |
| [m000-first-principles/](../archive/audits/m000-first-principles/) | #009 第一性原理审计 | 6 | [#009](../meta/user-decision-log.md#009) |
| [m000-v2/](../archive/audits/m000-v2/) | M-000 v2.0 起草 + sign-off | 5 | [#011](../meta/user-decision-log.md#011) |
| [m005-v2/](../archive/audits/m005-v2/) | M-005 v2 起草 + sign-off | 8 | [#015](../meta/user-decision-log.md#015) |
| [semantic-audit/](../archive/audits/semantic-audit/) | 7 维度语义层审计（Phase 10）| 14 | pre-#009 |
| [S-D-series/](../archive/audits/S-D-series/) | 早期 D4/D7 worktree 审计 | 25 | pre-#009 |

---

## 历史锚点重定向字典 (Anchor Redirection Map, 2026-05-23)

> ⚠️ 历史路径迁移：本目录历史审计文件中对 `docs/workflow.md` 的引用已失效。该路径已迁移至 `docs/protocol.md`（user-decision-log #006）。本目录文件保留历史原貌不改动，引用追溯请使用新路径。

## 历史锚点重定向字典 (Anchor Redirection Map)

ADR-004/005 激进拆分后（user-decision-log #007），以下旧锚点重定向至归档：

| 旧位置 | 新位置 |
|---|---|
| `docs/decisions/ADR-004-doc-system-deep-clean.md#三方对抗参与` | `docs/archive/audits/structural-cleanup-historical-record.md#三方对抗参与历史记录` |
| `docs/decisions/ADR-004-doc-system-deep-clean.md#工具稳定性观察` | `docs/archive/audits/structural-cleanup-historical-record.md#工具稳定性观察` |
| `docs/decisions/ADR-004-doc-system-deep-clean.md#工具选型决策` | `docs/archive/audits/structural-cleanup-historical-record.md#工具选型决策2026-05-19-旧立场` |
| `docs/decisions/ADR-004-doc-system-deep-clean.md#phase-0-3-实施总结` | `docs/archive/audits/structural-cleanup-historical-record.md#phase-0-3-实施总结` |
| `docs/decisions/ADR-004-doc-system-deep-clean.md#已落地本会话-commits` | `docs/archive/audits/structural-cleanup-historical-record.md#已落地本会话-commits` |
| `docs/decisions/ADR-005-doc-semantic-layer-audit.md#维度-1-收官观察2026-05-20` | `docs/archive/audits/phase10-semantic-audit-snapshot.md#维度-1-收官观察2026-05-20` |
| `docs/decisions/ADR-005-doc-semantic-layer-audit.md#维度-2-收官观察2026-05-20` | `docs/archive/audits/phase10-semantic-audit-snapshot.md#维度-2-收官观察2026-05-20` |
| `docs/decisions/ADR-005-doc-semantic-layer-audit.md#维度-3-收官观察2026-05-20` | `docs/archive/audits/phase10-semantic-audit-snapshot.md#维度-3-收官观察2026-05-20` |
| `docs/decisions/ADR-005-doc-semantic-layer-audit.md#维度-3-元教训meta-finding` | `docs/archive/audits/phase10-semantic-audit-snapshot.md#维度-3-元教训meta-finding` |
| `docs/decisions/ADR-005-doc-semantic-layer-audit.md#维度-4-收官观察2026-05-21` | `docs/archive/audits/phase10-semantic-audit-snapshot.md#维度-4-收官观察2026-05-21` |
| `docs/decisions/ADR-005-doc-semantic-layer-audit.md#维度-4-工作流改进` | `docs/archive/audits/phase10-semantic-audit-snapshot.md#维度-4-工作流改进` |
| `docs/decisions/ADR-005-doc-semantic-layer-audit.md#维度-5-收官观察2026-05-21` | `docs/archive/audits/phase10-semantic-audit-snapshot.md#维度-5-收官观察2026-05-21` |
| `docs/decisions/ADR-005-doc-semantic-layer-audit.md#维度-6-收官观察2026-05-21` | `docs/archive/audits/phase10-semantic-audit-snapshot.md#维度-6-收官观察2026-05-21` |
| `docs/decisions/ADR-005-doc-semantic-layer-audit.md#维度-7-收官观察--phase-10-全局收官2026-05-21` | `docs/archive/audits/phase10-semantic-audit-snapshot.md#维度-7-收官观察--phase-10-全局收官2026-05-21` |
| `docs/decisions/ADR-005-doc-semantic-layer-audit.md#模型版本注2026-05-20-基线易变事实复审触发见下方-gap_due` | `docs/archive/audits/phase10-semantic-audit-snapshot.md#模型版本注2026-05-20-历史快照` |
| `docs/decisions/ADR-005-doc-semantic-layer-audit.md#phase-10-全局收官` | `docs/archive/audits/phase10-semantic-audit-snapshot.md#phase-10-全局收官` |
| `docs/decisions/ADR-005-doc-semantic-layer-audit.md#文档新陈代谢约束连续性-vs-更新的协调机制` | `docs/archive/audits/phase10-semantic-audit-snapshot.md#phase-10-维度收尾纪律历史快照` |

# Audits

> 项目治理审计产物存放地点。与 `docs/decisions/` (ADR) 同级，承载「事实裁决记录」类文档。

## 当前归档

| 文件 | 范围 | 审计周期 | 审计员（auditor） | 复核员（reviewer） | 关联 ADR | superseded_by |
|---|---|---|---|---|---|---|
| `audit-ledger-2026-05.tsv` | 文档体系深度清洁 Phase 0-9 + Round 9 全集覆盖补审 + Codex Round 9 反馈修订，**224** 条文件级 verdict | 2026-05-18 ~ 2026-05-20 | Claude Opus 4.7（主线裁决）+ Codex GPT-5.5（5 batch 三方对抗 + Round 1-9 独立验证，Round 9 矫正 4 verdict）+ Gemini CLI（5 batch 三方对抗，全周期最终复核待用户触发） | 用户 chramboliao（PO，终审 + 工具选型决策） | `docs/decisions/ADR-004-doc-system-deep-clean.md` | — |

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
- **Codex/Gemini 列空 = 该条目以 Claude 单家裁决落地**（Phase 5+ 与 Round 9 增量为节省 API 费用未跑完整三方对抗；详见 `docs/decisions/ADR-004-doc-system-deep-clean.md` 元数据段）
- **Confidence=RESOLVED** 表示 Final_Decision 已落地；旧版数据可能有 PENDING（Phase 2 残留，已在 2026-05-20 全部 RESOLVED）

### Final_Decision = STALE_OR_INVALID 双语义

本 ledger 中 `STALE_OR_INVALID` 同时表示两种情况，凭 `Reason` 区分：

1. **物理 stale**：路径在 repo 中已不存在（已删除/已归档/已合并）。例：`.claude/skills/biometric-auth/SKILL.md`（Phase 5 退役）
2. **逻辑 stale**：路径仍存在但不应作为 active 事实源（如 dead duplicate / 历史残留）。例：`Configs/Debug.xcconfig`（Round 9 Codex 发现未被 xcodeproj 引用，留着只会引起 SSOT 误用）

后续清理时两种语义都允许，但物理删除前必须确认 build/CI/IDE 任何环节都不消费该路径。

### 覆盖率口径（Round 9 Codex 矫正后）

本 ledger 当前 **224 条**覆盖 SnapDrill iOS **第一方非源代码文件 + 关键 governance/build/CI/meta 配置**。

**不等于** `git ls-files` 全集——刻意排除以下子集：

| 排除范围 | 例 | 原因 |
|---|---|---|
| Swift / Obj-C 源代码 | `Packages/*/Sources/**/*.swift`、`SnapDrill/**/*.swift` | 源代码由 swiftlint + AllTests 测试体系覆盖，不纳入文档审计 |
| Xcode 自动生成 | `*.xcuserstate`、`*.xcuserdata` | 用户本地编辑器状态，gitignore 内或非人工维护 |
| `reports/` | docaudit TSV 输出 | gitignore，可重生成 CI artifact |
| `DerivedData/` `TestResults.xcresult/` | 构建产物 | gitignore |
| 上游社区 skill body | `.agents/skills/<community>/*` 非顶层 SKILL.md 的支援文件 | 由 `skills-lock.json` 完整性校验覆盖，不重复 verdict |

口径之外发现新的第一方文件应通过新一轮深度清洁的 Phase 0 接管入 ledger，而不是悄悄加行。

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
- 跨 agent 入口：`AGENTS.md` → `docs/meta/M-000-meta-vision.md` §11 SSOT 注册表
- 触发条件与复审节奏：ADR-004 「何时再触发本方法论」段
