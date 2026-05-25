---
last_verified: 2026-05-25
layer: pattern
---
# SnapDrill 知识地图

> 全局知识索引。三层分类：原则（极少变）、模式（偶尔变）、快照（频繁变）。
> 原则层不包含具体版本号；快照层必须声明 freshness 元数据。
>
> **互补视图**：`docs/DOC_DEPENDENCY_MAP.md` 描述"谁定义事实、谁消费事实"的上下游传播关系。本地图是知识分层索引，不替代依赖图。

---

## 原则层（Closed — 变更需 PO 决策）

| 文件 | 核心内容 | 依赖于 |
|---|---|---|
| `docs/product/product-vision.md` | 产品定位、价值链、用户画像 | — |
| `docs/product/product-business.md` | 商业模型、定价、隐私承诺 | vision |
| `docs/standards/engineering.md` | 工程哲学：7 条核心原则（判断方向、删减、YAGNI、编译拦截、边界契约、状态流、可逆性） | — |
| `docs/protocol.md` | 开发闭环、Git 工作流、S0-S3、DoD | engineering |

## 模式层（Semi-Open — 随版本迭代调整）

| 文件 | 核心内容 | 依赖于 | 演进触发 |
|---|---|---|---|
| `docs/tech/architecture.md` | 包结构、DI、模块边界 | vision, engineering | 架构重构 |
| `docs/product/product-design.md` | UI/UX 模式、信息架构 | vision | HIG 更新 |
| `docs/product/product-requirements.md` | 功能规格、版本路线图 | vision, design | 新功能 |
| `docs/product/product-cases.md` | 验收标准、异常路径 | requirements | 新功能 |
| `docs/product/product-journeys.md` | 用户旅程（具体人物、场景、验证点） | vision, design, requirements | 新功能/新用户反馈 |
| `docs/product/product-competitive-analysis.md` | 竞品分析（行业格局、差异化定位、替代威胁） | vision, business | 竞品动态/新进入者 |
| `docs/product/product-analytics.md` | Analytics 事件字典（事件定义、触发条件、参数） | vision（成功信号） | 新增/修改事件 |
| `docs/product/product-onboarding.md` | Onboarding 内容规格（页面内容、文案方向、触发规则） | vision, design | 用户反馈/产品pivot |
| `docs/product/product-glossary.md` | 术语定义 | vision | 概念变更 |
| `docs/product/appstore-metadata.md` | App Store 元数据（ASO 文案、类别、隐私 URL、审核备注） | vision, business, compliance | Apple 提交准备/版本更新 |
| `docs/standards/apple-native.md` | Apple 原生 UI 模式 | — | HIG/WWDC |
| `docs/standards/coding.md` | 编码规范、SwiftLint 规则 | engineering | Swift 版本 |
| `docs/standards/testing.md` | 测试策略 | engineering | XCTest 更新 |
| `docs/standards/ux-design.md` | UX 设计原则、用户体验终审 | vision, design | HIG 更新 |
| `docs/standards/collaboration.md` | 智能体协作架构（Claude/Codex/Gemini CLI/Xcode） | — | 工具更新 |
| `docs/standards/harness-recall.md` | 自进化闭环：扫描 handoff.md Risks 段 → 3 次触发 propose 新 F-0XX 规则 | handoff, feedback | phase-closeout |
| `docs/standards/codex-delegation.md` | Codex 子 agent 委派规范（agent-agnostic） | — | 插件/模型更新 |
| `docs/standards/gemini-delegation.md` | Gemini CLI 委派规范（agent-agnostic） | — | CLI/模型更新 |
| `docs/standards/shared-constraints.md` | 委派共享约束（单一源） | — | 约束变更 |
| `docs/standards/memory-routing.md` | 知识/记忆路由规则（哪类内容写哪里） | KNOWLEDGE_MAP | 路由争议 |
| `docs/standards/permission-model.md` | Tool / Bash 命令 / Skill allowed-tools 权限矩阵（SSOT） | settings.json, hooks, skills | 权限配置变更 |
| `docs/standards/skill-architecture.md` | Agent Skills 目录架构、计数口径、迁移规则 | AGENTS, Claude adapter, permission-model | skill 新增/迁移/退役 |
| `docs/standards/skill-source-ledger.md` | Skill 来源/提供方/许可证清单 | skill-architecture | 新增/退役 vendored skill |
| `docs/standards/audit-rubric.md` | 文档审计判定标准（VALID/STALE_OR_INVALID/NEEDS_REVISION） | engineering, workflow | 审计流程演化 |
| `docs/standards/execution-gates.md` | 执行门禁总表（每个门禁 → 上游文档 → 执行器 → 豁免方式） | permission-model, workflow, engineering | 门禁新增/修改/退役 |
| `docs/standards/worktree-audit-workflow.md` | 三方对抗任务的物理隔离工作流（Phase 11+ 标准）| F-008, audit-rubric, single-vendor-audit-prompt-template | 控制变量法方法论演进 |
| `docs/standards/README.md` | standards/ 目录索引 | 本目录所有文件 | 新增/退役 standards 文件 |
| `docs/tech/compliance.md` | 隐私合规、App Store 审核 | vision, business | 政策变更 |
| `docs/tech/deployment.md` | CI/CD、发布流程 | — | 工具更新 |
| `docs/tech/non-functional-requirements.md` | 性能、内存、存储 | architecture | 设备更新 |

## 快照层（Open — 外部驱动频繁变化）

| 文件 | 核心内容 | max_age_days | 演进触发 |
|---|---|---|---|
| `STATUS.md` | 当前工作状态 | 7 | 每次 PR 合并 |
| `docs/tech/apple-limits.md` | Apple API 能力边界 | 60 | WWDC / iOS 更新 |
| `docs/tech/api-pitfalls.md` | API 踩坑记录 | 60 | 开发中发现 |
| `docs/tech/reference/` (7 files) | AI 工具链/环境参考（`docs/tech/reference/reference_ai_toolchain_specs.md` 等 7 个文件）。入 git，所有智能体共享 | 60 | 工具/环境更新 |

## 记忆层（双层架构）

### 项目级记忆（`docs/memory/`，入 git，所有智能体共享）

| 文件 | 内容 | 分层归属 |
|---|---|---|
| `feedback.md` | 项目纪律与反馈（F-NNN 条目，具体数量见文件） | 模式层 |
| `decisions.md` | 项目决策记录 | 模式层 |
| `handoff.md` | 智能体交接状态 | 快照层 |

### 智能体私有记忆（各智能体目录，不入 git）

| 智能体 | 存储位置 | 内容 |
|---|---|---|
| Claude | Claude 私有 memory 目录（不入 git） | 用户偏好、工具特有配置 |
| Codex | (由 Codex 自行管理) | Codex 特有状态 |
| Gemini | (由 Gemini 自行管理) | Gemini 特有状态 |

## 分层判定标准

| 维度 | 原则层 | 模式层 | 快照层 |
|---|---|---|---|
| 半衰期 | >2 年 | 6-24 个月 | <6 个月 |
| 依赖于 | 业务逻辑、团队共识 | 框架版本、设计范式 | 外部 API 版本、定价、工具版本 |
| 变更触发 | PO 决策 | 版本迭代 | 外部发布 |
| freshness 元数据 | 不需要 | 可选（建议有） | 所有快照层文档必须声明 `max_age_days` 和 `decay_trigger` |
| 元数据头部 | `last_verified` + `layer` | `last_verified` + `layer` | `last_verified` + `layer` + `freshness` |

## 文档生命周期（入口 + 退出）

### 入口（新文档如何进来）

| 类型 | 入口条件 | 审批 |
|---|---|---|
| 产品决策 | 三方研究 + PO 批准 → 创建 ADR → 更新受影响文档 | PO |
| 新 skill / rule 定义 | 识别到重复性约束（3 次以上相同反馈）→ 在对应 SKILL.md / rule 文件定义权威正文，并同步 feedback 索引 | 开发者 |
| 新共享 skill | 候选 skill 满足 `skill-architecture.md` 迁移规则 → 放入 `.agents/skills/` 或先保留 Claude adapter | 开发者 |
| 新产品文档 | 新功能模块需要独立规格 → 评估是否合并到现有文档 | PO |
| 新技术文档 | 新技术栈/架构引入 → 评估是否合并到现有文档 | 开发者 |

**原则**：优先合并到现有文档，新建文件是最后手段。新建时必须同步更新 KNOWLEDGE_MAP。

**新增文档前置门槛**（避免无人引用的死文档诞生）：
- 新增 docs/ 第一方文档前，必须先在 issue/PR 描述中列出**至少 1 个预期引用方**（哪个 skill / hook / workflow / 其他文档会主动引用它）
- 4 周内无任何 incoming refs 的新增文档自动转入 `docs/archive/` 候选名单（由 phase-closeout 检查）
- 软上限触线（≥ 45）时，新增必须配套退役一个旧文档（一进一出）

### 退出（文档如何退役）

当知识不再适用时，不删除，标记退役：
- 在 YAML frontmatter 中设置 `status: archived` 和 `reason:`（`docs/decisions/ADR-003-yaml-frontmatter.md` 后 HTML comment 不再使用）
- 从 KNOWLEDGE_MAP 对应表格中移除，归入下方"已退役"小节
- feedback 被内化到 `docs/standards/` 或 `docs/memory/feedback.md` 后即可退役
- api-pitfalls 条目被框架修复后标记退役
- ADR 被新 ADR 取代时标记为"已废弃"并指向替代 ADR

**文件数量软上限**：活跃知识文件 ~50 个（当前 docs/ 下第一方 md 45，不含 archive/ 与 tech/reference/；2026-05-20 实测）。已到 90% 触线。超过 ~45 时优先合并或退役而非新增；超过 ~50 必须先退役才能新增。

## 架构决策记录（ADR）

决策存放在 `docs/decisions/` 目录，编号管理。

- 模板：`docs/decisions/ADR-TEMPLATE.md`
- 状态流转：提议 → 已决策 → 已废弃
- 每个重要的产品/架构决策创建 ADR，STATUS.md 的决策表改为索引指向 ADR
- 三方研究的完整结论记录在 ADR 中，不在 STATUS.md 压缩

已落地 ADR（索引）：

- `docs/decisions/ADR-003-yaml-frontmatter.md` — 用 YAML frontmatter 替代 HTML comment 元数据
- `docs/decisions/ADR-004-doc-system-deep-clean.md` — 文档体系深度清洁方法论（结构层活性 SSOT；Phase 0-9 实施历史见 `docs/archive/audits/structural-cleanup-historical-record.md`）

## 审计归档（docs/audits/）

事实裁决 ledger 和审计报告。与 ADR 同级，承载「过程产物 + 三方裁决」类文档。

- `docs/audits/README.md` — 目录元信息、TSV 字段语义、阅读口径、命名/retention 规则
- `docs/audits/audit-ledger-2026-05.tsv` — 文档体系深度清洁 Phase 0-9 的 192 条文件级 verdict（关联 `docs/decisions/ADR-004-doc-system-deep-clean.md`）

## 知识卫生规则

1. **升级 Xcode/iOS**：检查 `apple-limits.md`、`apple-native.md`
2. **模型/工具更新**：检查 `reference_ai_toolchain_specs.md`、`codex-delegation.md`
3. **WWDC 后**：全量审计模式层和快照层
4. **每次对话启动**：Claude 检查快照层 `last_verified` 是否超期
5. **更新知识文件时**：grep 其他文件中对同一主题的引用，确认无矛盾（冲突检测）
6. **修复非预期问题后**：评估是否需要录入 `api-pitfalls.md` 或 feedback（踩坑即录入）
7. **docs 结构性漂移**：`Scripts/audit/docaudit.py` 提供机械化审计（`docaudit all` 共 11 check：`policy.yaml checks:` 段 10 项 links / archived-refs / orphans / home-path-refs / rule-usage / skill-inventory / skill-links / skill-provenance / verdict-sync / external-gap-expiry，外加 `frontmatter` subprocess 1 项）。策略源 `Scripts/audit/policy.yaml`，用法见 `Scripts/audit/README.md`。CI `docs` job（ubuntu-latest 并行）+ PostToolUse hook（Edit docs）+ PreToolUse hook（git push / gh pr merge 前）自动触发；对话场景用 `/knowledge-health` skill 扫描 CI 不可见的 Claude 私有空间 + private memory，产出分层修复 plan，不改文件
