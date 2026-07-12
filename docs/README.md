# SnapDrill 文档

> 采用 **feature-spec 一元化 + Diátaxis 分层**（docs 重组 B，2026-05-30）。
> 单个功能的 Why / What / How / Verify 高内聚在一个 feature spec；跨功能的解释/参考/操作按 Diátaxis 分层。
>
> **认知入口**：第一层 Product Constitution 位于 `explanations/vision.md`，第二层是当前 Release Product Contract，第三层是 feature spec。PO 对话先进入 `exploration -> shaped candidate -> ratified -> effective -> superseded`；只有归属权威合入 `develop` 后才替换 tracked baseline。实现状态由代码、测试、构建与发布实证确认，不能反向改写产品目标。

## 结构

- **`features/`** — 功能规格（一元化，每功能一文件，承载 Why/What/How/Verify）
  - `active/` — 已实现功能
  - `backlog/` — 未实现/阻塞功能（`mode: lightweight`，How/Verify 待实现补）
  - `features/template.md` — 新建 feature spec 模板
- **`explanations/`** — 为什么（vision = Product Constitution / design-principles 设计原则 / business-model 商业政策 / architecture 架构 / assumptions 待验证假设 / competitive-analysis 竞品 / user-journeys 用户旅程 / privacy-compliance 隐私合规）
- **`reference/`** — 查阅（feature-status 功能状态 SSOT / intent-traceability 意图追溯索引 / glossary 术语 / analytics-events 埋点 / apple-platform-limits 平台边界 / non-functional-requirements NFR / backup-wire-format 备份线格式 / scope-and-roadmap 范围路线 / api-pitfalls / appstore-metadata ASO）
- **`how-to/`** — 操作指南（definition-of-ready 开工入口 / **shape-up 我们怎么工作·Shape Up 单人版** / parallel-lanes 协作边界与分支生命周期 / release-and-ci 发布与 CI）
- **`decisions/`** — 决策记录（PO 决策台账 + typed ADR；ADR-001 已被 B6-A 取代，ADR-003 为挂起路线，ADR-004 已被 ADR-005 取代）
- **`ui-redesign/`** — UI 重设计日志与跨层契约（Codex + PO 决策、真机/模拟器验证、跨层发现）
- **`reference/audits/`** — 按 base commit 固定的仓库审计证据、checkpoint 与已复核 finding；不替代功能状态或产品意图 SSOT

## 意图可追溯

SnapDrill 同时维护两条链，避免把产品目标和当前实现混为一谈：

```text
规范链：PO exploration → shaped candidate → ratified → Product Constitution effective → Release Contract → Feature Spec → 验收标准
实证链：代码 → 测试 / 构建 / 真机 / 发布证据 → 实现状态文档
```

- `vision.md` 是 Product Constitution 的固定路径，也是仓库内最高产品权威；PO ratify 后仍须合入该归属权威才 effective。
- Release Contract 定义一次发布的 Must outcomes、非目标与结果级验收；feature-status 不能替代它。
- 下游文档必须指出其上游依据。找不到上游依据的需求是孤儿需求，不应直接实现。
- 每个 feature spec 在 frontmatter 用 `intent_refs` 字段 + 「意图追溯」节显式声明承接的上游 Vision 原则 / 产品政策 / ADR，便于检索与人工核对；文档健康检查会验证引用目标存在，但当前尚无自动语义校验，不得把字段存在误认为追溯已经成立。
- 代码与测试证明“现在是什么”；Product Constitution、Release Contract 与 spec 约束“应该是什么”。不一致时必须显式记录偏差。
- 当前 Release 1 Contract 尚未建立；feature spec 中旧 Multi-Profile、Pro、CloudKit、Word、iPad 或导航分层属于已知下游漂移 / 实现刻画，不得覆盖 Product Constitution，也不得启动新投入。
- 私有记忆、历史研究、旧 pitch 和关闭任务不参与当前裁决；需要历史证据（含已删除的 research/ 与历史 pitch）时使用 Git 历史或 GitHub 记录。

## 私有记忆与文档边界

私有记忆不是产品的来源，也不能描绘产品。它只服务研发效率：缓存稳定偏好、常用命令、已知坑点和当前协作路由。产品意图必须经过决策生命周期，并沉淀到本仓库的 Product Constitution、Release Contract、产品政策、typed decision 或 feature spec 中。

当私有记忆与仓库文档冲突时，先按「当前真相优先级」核对 live 代码、构建、GitHub 和 SSOT 文档；确认私有记忆过时后，删除或改成指向当前权威文档的短指针。不要把私有记忆当成文档归档系统。

历史 ADR 可以保留为证据，但必须在 frontmatter 标明 `current_status`、`historical_record: true` 和 `current_authority`。已挂起或已取代的历史路线不得在当前产品、架构或合规判断中继续充当依据。

文档健康检查由 `Scripts/validate_docs.py --check` 执行，随 pre-commit 和 CI 运行。它只拦截高风险漂移：历史 ADR 未降级、过时 Firebase 路线陈述重新进入当前文档、feature spec 缺少意图追溯或 `intent_refs` 指向不存在的上游文档。

## 关键入口

| 我想… | 去 |
|---|---|
| **人工复核 Product Constitution v1** | `explanations/vision.md` |
| **看当前生产基线 / 已落地架构事实** | 根 `README.md` + 根 `AGENTS.md` + 当前代码/构建实证 |
| **看三路 agent 的文件边界与交接方式** | `how-to/parallel-lanes.md` |
| **看 UI 重设计决策和跨层发现** | `ui-redesign/REDESIGN-LOG.md` + `ui-redesign/flagship-cross-layer-contracts.md` |
| **怎么工作 / 决定下一步做什么** | **`how-to/shape-up.md`**（Shape Up 单人版：shaping→betting→building→cool-down；当前赌注由 PO 明确接受的 live GitHub issue/PR 或具名范围文档决定，不靠"最新文件名胜出"）|
| **开工前确认目标、scope、验收和验证等级** | `how-to/definition-of-ready.md` |
| 看某功能完整规格 | `features/active\|backlog/feat-*.md` |
| 查所有功能当前状态 | `reference/feature-status.md`（自动生成，**勿手改**）|
| 查 Vision / ADR 如何落到功能 | `reference/intent-traceability.md`（自动生成，**勿手改**）|
| 理解产品为什么这么做 | `explanations/vision.md` + `explanations/design-principles.md` |
| 新建一个功能规格 | 复制 `features/template.md` |
| 看商业化 / 定价 | `explanations/business-model.md` |
| 发布上架流程 | `how-to/release-and-ci.md` |
| 查 PO 决策台账 | `decisions/po-decision-log.md` |
| 架构决策依据 | `decisions/ADR-*.md` |
| 看全仓审计方法与本次进度 | `how-to/repository-audit.md` + `reference/audits/2026-07-repository/README.md` |

## 状态单一真理源（B 方案 · 自动单写）

功能状态写在各 feature spec 的 frontmatter（`status` / `tier` / `blocked_by` / `mode`）；`tier` 允许 `free` / `pro` / `undecided`，其中 `pro` 只有在 effective 商业与 Release Contract 存在时才能使用，未裁决候选必须用 `undecided`。`reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 扫描 frontmatter **自动生成**。

意图追溯写在各 feature spec 的 frontmatter `intent_refs`；`reference/intent-traceability.md` 由 `Scripts/generate_intent_traceability.py` 扫描 frontmatter **自动生成**。它证明“已声明上游依据”，不替代人工语义 review。

改状态 = 改对应 spec 的 frontmatter → 重跑 `python3 Scripts/generate_feature_status.py`（pre-commit 自动校验是否最新）。

改意图引用 = 改对应 spec 的 `intent_refs` → 重跑 `python3 Scripts/generate_intent_traceability.py`（pre-commit 自动校验是否最新）。
