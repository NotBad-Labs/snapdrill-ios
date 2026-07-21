# SnapDrill 文档

> 采用 **feature-spec 一元化 + Diátaxis 分层**（docs 重组 B，2026-05-30）。
> 单个功能的 Why / What / How / Verify 高内聚在一个 feature spec；跨功能的解释/参考/操作按 Diátaxis 分层。
>
> **认知入口**：第一层 Product Constitution 位于 `explanations/vision.md`，第二层是当前 Release
> Product Contract（同时是该次发布的唯一 PRD），第三层是 feature spec；不另建平行 `PRD.md`。
> PO 对话先进入 `exploration -> shaped candidate -> ratified -> effective -> superseded`；只有
> 归属权威合入 `develop` 后才替换 tracked baseline。实现状态由代码、测试、构建与发布实证确认，
> 不能反向改写产品目标。

## 结构

- **`features/`** — 功能规格（一元化，每功能一文件，承载 Why/What/How/Verify）
  - `active/` — live 实现或当前收敛中的功能；不等于 Release 1 已符合或公开可达
  - `backlog/` — 未实现/阻塞功能（`mode: lightweight`，How/Verify 待实现补）
  - `features/template.md` — 新建 feature spec 模板
- **`explanations/`** — 为什么（vision = Product Constitution / design-principles 设计原则 / business-model 商业政策 / architecture 架构 / assumptions 待验证假设 / competitive-analysis 竞品 / user-journeys 用户旅程 / privacy-compliance 隐私合规）
- **`reference/`** — 查阅（release-1-contract 当前发布契约 / local-library-data-contract 本地资料库数据契约 / feature-status 实现状态索引 / document-control 文档角色与生命周期 / intent-traceability 意图追溯索引 / glossary 术语 / analytics-events 埋点 / apple-platform-limits 平台边界 / non-functional-requirements NFR / backup-wire-format 外部备份 wire / scope-and-roadmap 范围路线 / api-pitfalls / appstore-metadata ASO）
- **`how-to/`** — 操作指南（definition-of-ready 开工入口 / **shape-up 我们怎么工作·Shape Up 单人版** / parallel-lanes 协作边界与分支生命周期 / release-and-ci 发布与 CI）
- **`decisions/`** — 决策记录（PO 决策台账 + typed ADR；ADR-001 已被 B6-A 取代，ADR-003 为挂起路线，ADR-004 已被 ADR-005 取代）
- **`ui-redesign/`** — 已取代的历史 UI 实现 / 截图证据；不再是当前合同或 release checklist
- **`reference/audits/`** — 按 base commit 固定的仓库审计证据、checkpoint 与已复核 finding；不替代功能状态或产品意图 SSOT

## 意图可追溯

SnapDrill 同时维护两条链，避免把产品目标和当前实现混为一谈：

```text
规范链：PO exploration → shaped candidate → ratified → Product Constitution effective → Release Contract → Feature Spec → 验收标准
实证链：代码 → 测试 / 构建 / 真机 / 发布证据 → 实现状态文档
执行链：历史工作制品（证据）→ Current Admission → bet / write / frozen queue
```

- `vision.md` 是 Product Constitution 的固定路径，也是仓库内最高产品权威；PO ratify 后仍须合入该归属权威才 effective。
- Release Contract 同时承担该次发布的唯一 PRD，定义 Must outcomes、非目标与结果级验收；
  feature-status、独立 `PRD.md` 或当前实现都不能替代它。
- 下游文档必须指出其上游依据。找不到上游依据的需求是孤儿需求，不应直接实现。
- 每个 feature spec 在 frontmatter 用 `intent_refs` 声明耐久 Vision / 产品政策 / ADR 归属，并用 `release_refs` 声明当前 Release Contract 消费边；生成器校验精确 ID、受限 §7 引用，并拒绝没有 Feature / operations consumer 的 ratified decision，但字段存在仍不证明语义正确、实现符合或候选纳入。
- 代码与测试证明“现在是什么”；Product Constitution、Release Contract 与 spec 约束“应该是什么”。不一致时必须显式记录偏差。
- issue、PR、审计、报告、聊天交接、label、历史评论 / 授权和旧 CI 无论编号、时间或状态，
  默认都只提供证据。任务只有通过
  [`Current Admission`](how-to/definition-of-ready.md#current-admission)，以精确 live base、effective
  SSOT、当前实证和显式接受 / 拒绝的继承假设重建后，才能进入执行队列；该准入不新增产品
  SSOT，也不替代 PO 的 bet、merge 或发布裁决。
- [Release 1 Contract](reference/release-1-contract.md) 承载截至 2026-07-20 ratify 的 Gate C 与后续精确裁决；[Local Library Data Contract](reference/local-library-data-contract.md) 承接单一本地资料库的 inventory、接受边界、路径、generation / journal、complete-operation barrier 与恢复生命周期。分支 / PR 副本仍是批准候选，合入 `develop` 后才 effective。feature spec 中旧 Multi-Profile、Pro、CloudKit、Word、iPad、五 Tab 或公开可达 Review / SmartPaper 仍属于已知下游漂移 / 实现刻画，不得覆盖合同，也不得在没有独立实现授权时启动投入。
- 私有记忆、历史研究、旧 pitch 和关闭任务不参与当前裁决；需要历史证据（含已删除的 research/ 与历史 pitch）时使用 Git 历史或 GitHub 记录。

## 私有记忆与文档边界

私有记忆不是产品的来源，也不能描绘产品。它只服务研发效率：缓存稳定偏好、常用命令、已知坑点和当前协作路由。产品意图必须经过决策生命周期，并沉淀到本仓库的 Product Constitution、Release Contract、产品政策、typed decision 或 feature spec 中。

当私有记忆与仓库文档冲突时，先按「当前真相优先级」核对 live 代码、构建、GitHub 和 SSOT 文档；确认私有记忆过时后，删除或改成指向当前权威文档的短指针。不要把私有记忆当成文档归档系统。

历史 ADR 可以保留为证据，但必须在 frontmatter 标明 `current_status`、`historical_record: true` 和 `current_authority`。已挂起或已取代的历史路线不得在当前产品、架构或合规判断中继续充当依据。

文档机械门禁由两部分组成，均随 pre-commit 和 CI 运行：

- `Scripts/validate_document_control.py --check`：覆盖所有 repository Markdown 的角色 / 生命周期，
  检查历史降级提示、本地链接和 alias。
- `Scripts/validate_docs.py --check`：检查历史 ADR、过时路线、定位 / 术语和 feature intent。

两者不能替代人工语义 review 或外部事实新鲜度核查。

## 关键入口

| 我想… | 去 |
|---|---|
| **人工复核 Product Constitution v1** | `explanations/vision.md` |
| **人工复核当前 Release 1 PRD / Contract** | `reference/release-1-contract.md` |
| **查单一本地资料库路径、inventory 与恢复状态** | `reference/local-library-data-contract.md` |
| **看当前生产基线 / 已落地架构事实** | 根 `README.md` + `explanations/architecture.md` + 当前代码 / 构建 / 发布实证；`AGENTS.md` 只作入口路由 |
| **看 Agent / 窗口角色、文件边界与交接方式** | `how-to/parallel-lanes.md` |
| **看历史 UI 实现和截图证据** | `ui-redesign/`；当前要求仍从 Release Contract + owning feature spec 读取 |
| **怎么工作 / 决定下一步做什么** | **`how-to/shape-up.md`**（Shape Up 单人版：shaping→betting→building→cool-down；PO 接受 bet 后，每个执行 slice 仍须通过 Current Admission）|
| **开工前确认目标、scope、验收和验证等级** | `how-to/definition-of-ready.md` |
| **判断旧 issue / PR / 审计能否进入当前执行队列** | `how-to/definition-of-ready.md#current-admission`；默认只作证据，按当前 base 重建 |
| 看某功能完整规格 | `features/active\|backlog/feat-*.md` |
| 查所有功能当前实现状态 | `reference/feature-status.md`（自动生成，**勿手改**；不等于合同符合或发布就绪）|
| 判断一份文档能否指导当前工作 | `reference/document-control.md` + `reference/document-control.json` |
| 查 Vision / ADR 如何落到功能 | `reference/intent-traceability.md`（自动生成，**勿手改**）|
| 理解产品为什么这么做 | `explanations/vision.md` + `explanations/design-principles.md` |
| 新建一个功能规格 | 复制 `features/template.md` |
| 看商业化 / 定价 | `explanations/business-model.md` |
| 发布上架流程 | `how-to/release-and-ci.md` |
| 查 PO 决策台账 | `decisions/po-decision-log.md` |
| 架构决策依据 | `decisions/ADR-*.md` |
| 看全仓审计方法与本次进度 | `how-to/repository-audit.md` + `reference/audits/2026-07-repository/README.md` |
| 看 Agent 控制面历史评审 | `reference/audits/2026-07-agent-control-plane-review.md`（fixed-base evidence） |

## 实现状态单写（B 方案）

实现状态写在各 feature spec 的 frontmatter（`status` / `tier` / `blocked_by` / `mode`）；
`implemented` 只表示代码路径存在，不表示 Release 1 合同符合、公开可达或发布就绪。`tier` 允许
`free` / `pro` / `undecided`，其中 `pro` 只有在 effective 商业与 Release Contract 存在时才能使用，
未裁决候选必须用 `undecided`。`reference/feature-status.md` 由
`Scripts/generate_feature_status.py` 扫描 frontmatter **自动生成**。

意图追溯写在各 feature spec 的 frontmatter `intent_refs` / `release_refs` / `release_outcomes`；发布运维消费边与 M1-M10 结果 oracle / DRI 写在 `how-to/release-and-ci.md`。`reference/intent-traceability.md` 由 `Scripts/generate_intent_traceability.py` **自动生成**。Release 精确决策 ID 与 Must ID 从 effective contract 读取；索引只证明消费边、active owner 与 proof-plan 声明完整，不替代人工语义 review、实现实证、候选 inclusion 或已执行证据。

改状态 = 改对应 spec 的 frontmatter → 重跑 `python3 Scripts/generate_feature_status.py`（pre-commit 自动校验是否最新）。

改意图 / Release 追溯 = 改对应 spec 的 `intent_refs` / `release_refs` / `release_outcomes`，或发布运维文档的 `release_refs` / M1-M10 oracle 表 → 重跑 `python3 Scripts/generate_intent_traceability.py`（pre-commit 自动校验是否最新）。
