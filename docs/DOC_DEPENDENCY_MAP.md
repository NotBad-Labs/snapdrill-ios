<!-- last updated: 2026-04-14 -->
<!-- freshness: max_age_days=14, decay_trigger=[doc_change,adr_change,workflow_change], layer=pattern -->
# SnapDrill 文档上下游依赖图

> 目的：把"谁定义事实、谁消费事实、改一处要同步哪里"写清楚，避免返工。
> 本文件不替代 `docs/workflow.md` 的裁决顺序；它补充的是上下游传播关系。

---

## 治理范围与排除

- 本依赖图仅治理第一方文档（仓库内由 SnapDrill 团队维护的文档）。
- 第三方开源项目文档默认排除在治理范围外，不作为本图上下游节点。
- `.claude/worktrees/**` 下的镜像文档默认排除（临时工作树副本，不作为治理事实源）。
- 若第一方文档引用第三方资料，仅记录"依赖关系/约束来源"，不对第三方原文做重构或规范改写。

---

## 1. 依赖总图（从源头到快照）

```text
product-vision（产品根定义）
  ├─> product-design ─┬─> product-requirements（含用户旅程）──> product-cases
  │                    └─> product-business
  └─> product-glossary

engineering（工程哲学根）
  └─> workflow

ADR-* + requirements + compliance + NFR
  └─> 代码实现

Codebase + ADR
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
| `docs/product/product-vision.md` | 产品根定义 | — | design、requirements、business、cases、glossary、compliance |
| `docs/product/product-design.md` | 体验与交互原则 | vision | requirements、cases、business |
| `docs/product/product-requirements.md` | 功能规格与状态（含用户旅程） | vision、design | cases、business |
| `docs/product/product-cases.md` | 验收规格（GWT/Boundary） | design、requirements | QA 用例、workflow DoD 检查 |
| `docs/product/product-business.md` | 商业化与分层 | vision、design、requirements、ADR-001 | compliance、StoreKit 相关实施 |
| `docs/product/product-glossary.md` | 术语单一源 | vision | 全部产品/技术文档的术语一致性 |
| `docs/decisions/ADR-*.md` | 正式决策 | 问题背景 + 三方研究 | business、compliance、实现代码 |
| `docs/tech/compliance.md` | 合规口径源 | vision、business、ADR-002 | deployment、审核材料 |
| `docs/tech/non-functional-requirements.md` | 非功能约束源 | requirements、architecture、compliance | 实现验收基准、性能/稳定性测试 |
| `docs/tech/architecture.md` | 实现结构映射 | 代码、ADR | NFR、新同学上手、实现评审 |
| `docs/tech/api-reference.md` | API 快照 | 代码（public 接口） | 测试同步、集成调用方 |
| `docs/tech/deployment.md` | 发布与 CI 流程 | workflow、compliance、NFR | 发布执行、审核提交流程 |
| `docs/tech/release-checklist.md` | 发版前检查清单 | deployment | 发版执行 |
| `docs/principles/engineering.md` | 工程哲学 | — | workflow、coding、testing、shared-constraints |
| `docs/workflow.md` | 协作规则源 | engineering、collaboration | 所有开发与评审流程 |
| `docs/principles/*.md` | 执行约束 | engineering（部分）、workflow | 智能体行为、委派上下文质量 |
| `docs/KNOWLEDGE_MAP.md` | 知识分层与裁决索引 | workflow、现有文档体系 | 文档检索顺序、更新触发规则 |
| `CLAUDE.md` / `CODEX.md` | 智能体执行入口 | workflow、STATUS、KNOWLEDGE_MAP | 智能体启动上下文 |
| `STATUS.md` | 进度快照 | PR 合并结果、issue 状态 | 会话启动上下文、排期决策 |
| `docs/memory/*.md` | 交接快照 | STATUS、issue/PR、审计结论 | 跨会话接手效率、审计可追溯性 |

---

## 3. 变更传播规则（防返工）

| 改动源头 | 最少同步清单 |
|---|---|
| `product-vision.md` | design + requirements + business + cases + glossary + compliance |
| `ADR-*` | 相关 product/tech 文档 + 相关实现代码与测试 |
| `product-design.md` / `product-requirements.md` | cases + business（若边界变化） |
| `compliance.md` / `NFR.md` | deployment（若发布口径变化） |
| 代码 public 接口 | `docs/tech/api-reference.md`（必要时 architecture） |
| PR 合并 / issue 状态变化 | `STATUS.md` + `docs/memory/handoff.md` |

---

## 4. 操作建议（接手顺序）

1. 先读 `product-vision.md`，确认产品定位和原则。
2. 再读 `product-design.md` + `product-requirements.md`，确认"做什么/怎么做"。
3. 再读 `ADR-*` + `compliance.md` + `non-functional-requirements.md`，确认硬约束。
4. 实现后同步 `architecture.md` / `api-reference.md` / `STATUS.md` / `docs/memory/*.md`。
