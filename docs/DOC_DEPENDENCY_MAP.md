<!-- last updated: 2026-04-12 -->
<!-- freshness: max_age_days=14, decay_trigger=[doc_change,adr_change,workflow_change], layer=pattern -->
# SnapDrill 文档上下游依赖图

> 目的：把“谁定义事实、谁消费事实、改一处要同步哪里”写清楚，避免返工。
> 本文件不替代 `docs/workflow.md` 的裁决顺序；它补充的是上下游传播关系。

---

## 治理范围与排除

- 本依赖图仅治理第一方文档（仓库内由 SnapDrill 团队维护的文档）。
- 第三方开源项目文档默认排除在治理范围外，不作为本图上下游节点。
- `.claude/worktrees/**` 下的镜像文档默认排除（临时工作树副本，不作为治理事实源）。
- 若第一方文档引用第三方资料，仅记录“依赖关系/约束来源”，不对第三方原文做重构或规范改写。

---

## 0. 文档属性判定规则（内容优先，不看文件名）

判定一份文档属于“源头 / 设计 / 映射 / 快照”，按内容语义而不是文件名：

1. 若文档定义“产品范围、边界、承诺、必须/禁止”，归为源头（如 vision/PRD/ADR）。
2. 若文档定义“方案与取舍、状态流、风险与验证”，归为设计收敛层（TDD）。
3. 若文档主要记录“当前实现结构或接口签名”，归为映射层（architecture/api-reference）。
4. 若文档主要记录“当前进展、时间线、接手状态”，归为快照层（STATUS/memory）。

若“文件名”和“内容语义”冲突，以内容语义为准，并执行两步修正：
- 先在文件头补充 `使用边界/上游依赖`，防止继续误用。
- 再评估是否拆分或重构内容，把错位内容迁回正确层级。

---

## 1. 依赖总图（从源头到快照）

```text
product-vision
  ├─> product-design ─┬─> product-requirements（含用户旅程）──> product-cases
  │                    └─> product-business
  └─> PRD（当前版本执行入口，收口范围/边界/承诺）

ADR-* + PRD + compliance + NFR
  └─> docs/tech/design/*.md（技术方案收敛层）

Codebase + TDD + ADR
  ├─> docs/tech/architecture.md（结构映射）
  └─> docs/tech/api-reference.md（接口快照）

workflow + KNOWLEDGE_MAP
  ├─> CLAUDE.md / CODEX.md / docs/principles/*.md（执行规则）
  ├─> STATUS.md（当前状态快照）
  └─> docs/memory/*.md（跨会话交接快照）
```

---

## 2. 文档依赖矩阵（上游 / 下游）

| 文档 | 角色 | 上游依赖（读谁） | 下游影响（改后要同步谁） |
|---|---|---|---|
| `docs/product/README.md` | 产品文档入口索引 | workflow、vision、PRD、requirements、design | 新成员上手路径、产品文档读取顺序 |
| `docs/product/product-vision.md` | 产品根定义 | — | PRD、design、requirements、business、journeys、cases、glossary、compliance |
| `docs/product/PRD.md` | 当前版本执行入口 | vision、design、requirements、business、compliance、NFR、ADR | requirements、cases、journeys、TDD、architecture（边界描述） |
| `docs/product/product-design.md` | 体验与交互原则 | vision | requirements、cases、journeys、PRD |
| `docs/product/product-requirements.md` | 功能规格与状态 | vision、design、PRD | cases、journeys、PRD、business、TDD |
| `docs/product/product-cases.md` | 验收规格（GWT/Boundary） | PRD、design、requirements、journeys | QA 用例、TDD 验证段、workflow DoD 检查 |
| _(已合并到 requirements.md)_ | 用户旅程 | — | — |
| `docs/product/product-business.md` | 商业化与分层 | vision、design、requirements、ADR-001 | PRD、requirements、compliance、StoreKit 相关实施 |
| `docs/product/product-glossary.md` | 术语单一源 | vision、PRD、design、requirements | 全部产品/技术文档的术语一致性 |
| `docs/decisions/ADR-*.md` | 正式决策 | 问题背景 + 三方研究 | PRD、business、compliance、TDD、实现代码 |
| `docs/tech/compliance.md` | 合规口径源 | vision、PRD、business、ADR-002 | TDD（analytics-consent）、deployment、审核材料 |
| `docs/tech/non-functional-requirements.md` | 非功能约束源 | PRD、requirements、architecture、compliance | TDD、实现验收基准、性能/稳定性测试 |
| `docs/tech/design/*.md` | 技术方案收敛层 | PRD、ADR、compliance、NFR、requirements | 代码实现、architecture、api-reference、测试用例 |
| `docs/tech/architecture.md` | 实现结构映射 | 代码、TDD、ADR、PRD（边界） | NFR、新同学上手、实现评审 |
| `docs/tech/api-reference.md` | API 快照 | 代码（public 接口） | 测试同步、集成调用方 |
| `docs/tech/deployment.md` | 发布与 CI 流程 | workflow、compliance、NFR | 发布执行、审核提交流程 |
| `docs/workflow.md` | 协作规则源 | engineering rule、collaboration rule | 所有开发与评审流程、CODEX.md |
| `docs/KNOWLEDGE_MAP.md` | 知识分层与裁决索引 | workflow、现有文档体系 | 文档检索顺序、更新触发规则 |
| `CLAUDE.md` / `CODEX.md` / `docs/principles/*.md` | agent 执行约束 | workflow、STATUS、KNOWLEDGE_MAP | 智能体行为、委派上下文质量 |
| `STATUS.md` | 进度快照 | PR 合并结果、issue 状态 | 会话启动上下文、排期决策 |
| `docs/memory/*.md` | 交接快照 | STATUS、issue/PR、审计结论 | 跨会话接手效率、审计可追溯性 |
| `docs/archive/2026-04-baseline-v1/*.md` | 历史审计证据归档 | 当时文档与代码快照 | 后续修复 issue、经验沉淀（不可反向裁决） |

---

## 3. 变更传播规则（防返工）

| 改动源头 | 最少同步清单 |
|---|---|
| `product-vision.md` | PRD + design + requirements + business + journeys + cases + glossary + compliance |
| `PRD.md` | requirements + cases + journeys + 相关 TDD + architecture 边界说明 |
| `ADR-*` | PRD + 相关 product/tech 文档 + 相关实现代码与测试 |
| `product-design.md` / `product-requirements.md` | cases + journeys + PRD（若边界变化） |
| `compliance.md` / `NFR.md` | 相关 TDD + PRD（若承诺变化）+ deployment（若发布口径变化） |
| `docs/tech/design/*.md` | 代码实现 + architecture + api-reference + 测试 |
| 代码 public 接口 | `docs/tech/api-reference.md`（必要时 architecture） |
| PR 合并 / issue 状态变化 | `STATUS.md` + `docs/memory/handoff.md` |

---

## 4. 操作建议（接手顺序）

1. 先读 `docs/product/README.md`，确认产品文档入口与边界。
2. 再读 `product-vision.md` + `PRD.md`，确认“做什么/不做什么”。
3. 再读 `ADR-*` + `compliance.md` + `non-functional-requirements.md`，确认硬约束。
4. 开发前读对应 `docs/tech/design/*.md`（无则补）。
5. 实现后同步 `architecture.md` / `api-reference.md` / `STATUS.md` / `docs/memory/*.md`。
