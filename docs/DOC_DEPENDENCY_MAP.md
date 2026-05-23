---
last_verified: 2026-05-19
layer: snapshot
freshness:
  max_age_days: 14
  decay_trigger: [doc_change]
---
# SnapDrill 文档上下游依赖图

> 目的：把"谁定义事实、谁消费事实、改一处要同步哪里"写清楚，避免返工。
> 本文件不替代 `docs/protocol.md` 的裁决顺序；它补充的是上下游传播关系。
>
> **互补视图**：`docs/KNOWLEDGE_MAP.md` 是知识分层索引（原则/模式/快照）。本依赖图是变更传播图。两者互补使用。


## 1. 文档依赖矩阵（上游 / 下游）

| 文档 | 角色 | 上游依赖（读谁） | 下游影响（改后要同步谁） |
|---|---|---|---|
| `docs/product/product-vision.md` | 产品根定义 | — | design、requirements、business、cases、glossary、compliance |
| `docs/product/product-design.md` | 体验与交互原则 | vision | requirements、cases、business |
| `docs/product/product-requirements.md` | 功能规格与状态 | vision、design | cases、business、journeys |
| `docs/product/product-journeys.md` | 用户旅程（具体人物、场景、动作、情绪） | vision、design、requirements | 设计验证、QA 用例 |
| `docs/product/product-cases.md` | 验收规格（GWT/Boundary） | design、requirements | QA 用例、workflow DoD 检查 |
| `docs/product/product-business.md` | 商业化与分层 | vision、design、requirements、ADR-001 | compliance、StoreKit 相关实施、competitive-analysis |
| `docs/product/product-competitive-analysis.md` | 竞品分析（行业格局、差异化、替代威胁） | vision、business | GTM 策略、差异化验证 |
| `docs/product/product-analytics.md` | Analytics 事件字典 | vision（成功信号） | 埋点实现、成功信号校准 |
| `docs/product/product-onboarding.md` | Onboarding 内容规格 | vision、design | UI 实现、Onboarding 文案 |
| `docs/product/appstore-metadata.md` | App Store 元数据 | vision、business、compliance | deployment、审核提交流程 |
| `docs/product/product-glossary.md` | 术语单一源 | vision | 全部产品/技术文档的术语一致性 |
| `docs/decisions/ADR-*.md` | 正式决策 | `docs/standards/engineering.md`（原则 7：不可逆决策）、`docs/product/product-vision.md` | business、compliance、实现代码 |
| `docs/tech/compliance.md` | 合规口径源 | vision、business、ADR-002 | deployment、审核材料 |
| `docs/tech/non-functional-requirements.md` | 非功能约束源 | requirements、architecture、compliance | 实现验收基准、性能/稳定性测试 |
| `docs/tech/architecture.md` | 实现结构映射 | `docs/decisions/ADR-*.md`、`docs/standards/engineering.md`（原则 5：跨边界先定义契约） | NFR、新同学上手、实现评审 |
| `docs/tech/apple-limits.md` | Apple 平台能力边界 | `docs/standards/apple-native.md`、`docs/standards/engineering.md`（原则 1：先判断方向）、`docs/tech/api-pitfalls.md` | coding.md、api-pitfalls.md、NFR.md |
| `docs/tech/deployment.md` | 发布与 CI 流程 | workflow、compliance、NFR | 发布执行、审核提交流程 |
| `docs/standards/engineering.md` | 工程哲学 | — | workflow、coding、testing、shared-constraints |
| `docs/protocol.md` | 协作规则源 | engineering、collaboration | 所有开发与评审流程 |
| `docs/standards/*.md` | 执行约束 | engineering（部分）、workflow | 智能体行为、委派上下文质量 |
| `docs/standards/execution-gates.md` | 门禁总表 | `docs/standards/permission-model.md`、`docs/protocol.md`、`docs/standards/engineering.md` | 门禁新增/修改/退役时同步 |
| `docs/standards/skill-architecture.md` | Skill 目录架构与迁移规则 | `AGENTS.md`、`CLAUDE.md`、`docs/standards/permission-model.md` | 新增/迁移/退役 skill 时同步 |
| `docs/standards/skill-source-ledger.md` | Skill 来源/提供方/许可证清单 | `docs/standards/skill-architecture.md` | 新增/退役 vendored skill |
| `docs/standards/audit-rubric.md` | 文档审计判定标准 | `docs/standards/engineering.md`、`docs/protocol.md` | Phase 2-6 审计流程 |
| `docs/DOC_DEPENDENCY_MAP.md` | 文档依赖图（变更传播 SSOT） | `docs/standards/engineering.md`（原则 5）、`docs/protocol.md` | KNOWLEDGE_MAP、全文档变更传播 |
| `docs/KNOWLEDGE_MAP.md` | 知识分层与裁决索引 | `docs/protocol.md`、`docs/DOC_DEPENDENCY_MAP.md` | 文档检索顺序、更新触发规则 |
| `CLAUDE.md` / `AGENTS.md` | 智能体执行入口 | `docs/protocol.md`、`docs/KNOWLEDGE_MAP.md`、`docs/standards/engineering.md` | 智能体启动上下文 |
| `STATUS.md` | 进度快照 | `docs/protocol.md`（DoD、PR 流程、S0-S3 优先级） | 会话启动上下文、排期决策 |
| `docs/memory/*.md` | 交接快照 | `docs/protocol.md`、`STATUS.md` | 跨会话接手效率、审计可追溯性 |

---

## 2. 变更传播规则（防返工）

| 改动源头 | 最少同步清单 |
|---|---|
| `product-vision.md` | design + requirements + business + cases + glossary + compliance |
| `ADR-*` | 相关 product/tech 文档 + 相关实现代码与测试 |
| `product-design.md` / `product-requirements.md` | cases + business（若边界变化） |
| `compliance.md` / `NFR.md` | deployment（若发布口径变化） |
| 代码实现中发现 API 陷阱 | `docs/tech/api-pitfalls.md` |
| 代码实现中发现 Apple 平台限制 | `docs/tech/apple-limits.md` |
| 代码新增/删除/重命名模块 | `docs/tech/architecture.md`（必要时 NFR.md） |
| PR 合并 / issue 状态变化 | `STATUS.md` + `docs/memory/handoff.md` |

---

## 3. 操作建议（接手顺序）

1. 先读 `product-vision.md`，确认产品定位和原则。
2. 再读 `product-design.md` + `product-requirements.md`，确认"做什么/怎么做"。
