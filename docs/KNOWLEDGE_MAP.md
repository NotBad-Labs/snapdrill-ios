---
last_verified: 2026-05-15
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
| `docs/workflow.md` | 开发闭环、Git 工作流、S0-S3、DoD | engineering |

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
| `docs/standards/harness-recall.md` | 自进化闭环：跨 checkpoint 去重 → 3 次触发 propose 新 F-0XX 规则 | handoff, checkpoints, feedback | phase-closeout |
| `docs/standards/codex-delegation.md` | Codex 子 agent 委派规范（agent-agnostic） | — | 插件/模型更新 |
| `docs/standards/gemini-delegation.md` | Gemini CLI 委派规范（agent-agnostic） | — | CLI/模型更新 |
| `docs/standards/shared-constraints.md` | 委派共享约束（单一源） | — | 约束变更 |
| `docs/standards/memory-routing.md` | 知识/记忆路由规则（哪类内容写哪里） | KNOWLEDGE_MAP | 路由争议 |
| `docs/standards/permission-model.md` | Tool / Bash 命令 / Skill allowed-tools 权限矩阵（SSOT） | settings.json, hooks, skills | 权限配置变更 |
| `docs/standards/apple-extension.md` | App Extension 约束 | — | Extension 变更 |
| `docs/tech/compliance.md` | 隐私合规、App Store 审核 | vision, business | 政策变更 |
| `docs/tech/deployment.md` | CI/CD、发布流程 | — | 工具更新 |
| `docs/tech/non-functional-requirements.md` | 性能、内存、存储 | architecture | 设备更新 |

## 快照层（Open — 外部驱动频繁变化）

| 文件 | 核心内容 | max_age_days | 演进触发 |
|---|---|---|---|
| `STATUS.md` | 当前工作状态 | 7 | 每次 PR 合并 |
| `docs/tech/api-reference.md` | 内部 API 签名 | 30 | 代码变更 |
| `docs/tech/apple-limits.md` | Apple API 能力边界 | 60 | WWDC / iOS 更新 |
| `docs/tech/api-pitfalls.md` | API 踩坑记录 | 60 | 开发中发现 |
| `docs/tech/traceability-matrix.md` | 需求-代码 traceability（UC ↔ file ↔ test ↔ NFR ↔ ADR） | 30 | UC/源码/ADR 变更（epic #766） |
| _(Claude 私有) reference_ai_toolchain_specs.md_ | Claude/Codex/Xcode 规格（不入 git） | 30 | 模型/工具发布 |

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
| Claude | `~/.claude/projects/.../memory/` | 用户偏好、工具特有配置 |
| Codex | (由 Codex 自行管理) | Codex 特有状态 |
| Gemini | (由 Gemini 自行管理) | Gemini 特有状态 |

## 技术演进线

追踪关键技术的演进轨迹，帮助预判下一步方向。

### Vision / 文本识别
```
iOS 11  Vision Framework（VNRecognizeTextRequest，印刷体）
iOS 15  VisionKit LiveText（交互式，系统级）
iOS 26  Foundation Models（@Generable，语义理解）
→ 趋势：从"识别字符"到"理解语义"
→ 决策触发：当 Foundation Models 支持结构化输出且延迟 < 500ms 时，评估替换 Vision OCR 做拆题
```

### 数据持久化
```
Core Data（成熟但重）
iOS 17  SwiftData（声明式，与 SwiftUI 深度集成）
→ SnapDrill 已选 SwiftData
→ 决策触发：当 SwiftData 原生支持 CloudKit 公共数据库时，评估替代自建同步方案
```

### AI 编码工具
```
2025-06  Claude in Xcode（coding intelligence，Sonnet 4）
2025-09  Claude Code CLI
2026-02  Xcode 26.3 agentic coding（Claude Agent + Codex，MCP 20 tools）
2026-03  GPT-5.4 取代 GPT-5.3-Codex 成为推荐模型
2026-03  Claude 1M context GA 标准定价
2026-04  Gemini CLI v0.37.0 集成（Google One AI Pro，三方终端内审计闭环）
→ 趋势：从"代码补全"到"验证闭环"。三方交叉审计（Anthropic/OpenAI/Google）是质量拐点
→ 决策触发：当 Xcode agentic coding 支持自定义 rules 文件加载时，评估从 CLI 迁移核心工作流
```

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
| 新 rules 文件 | 识别到重复性约束（3 次以上相同反馈）→ 从 feedback 提升为 rule | 开发者 |
| 新产品文档 | 新功能模块需要独立规格 → 评估是否合并到现有文档 | PO |
| 新技术文档 | 新技术栈/架构引入 → 评估是否合并到现有文档 | 开发者 |

**原则**：优先合并到现有文档，新建文件是最后手段。新建时必须同步更新 KNOWLEDGE_MAP。

### 退出（文档如何退役）

当知识不再适用时，不删除，标记退役：
- 在 YAML frontmatter 中设置 `status: archived` 和 `reason:`（ADR-003 后 HTML comment 不再使用）
- 从 KNOWLEDGE_MAP 对应表格中移除，归入下方"已退役"小节
- feedback 被内化到 `docs/standards/` 或 `docs/memory/feedback.md` 后即可退役
- api-pitfalls 条目被框架修复后标记退役
- ADR 被新 ADR 取代时标记为"已废弃"并指向替代 ADR

**文件数量软上限**：活跃知识文件 ~50 个（当前 docs/ 下第一方 md 46，不含 archive/checkpoints/）。超过 ~50 时优先合并或退役，而非继续新增。

## 架构决策记录（ADR）

决策存放在 `docs/decisions/` 目录，编号管理。

- 模板：`docs/decisions/ADR-TEMPLATE.md`
- 状态流转：提议 → 已决策 → 已废弃
- 每个重要的产品/架构决策创建 ADR，STATUS.md 的决策表改为索引指向 ADR
- 三方研究的完整结论记录在 ADR 中，不在 STATUS.md 压缩

## 知识卫生规则

1. **修改代码后**：检查 `api-reference.md` 是否需要同步
2. **升级 Xcode/iOS**：检查 `apple-limits.md`、`apple-native.md`
3. **模型/工具更新**：检查 `reference_ai_toolchain_specs.md`、`codex-delegation.md`
4. **Package.swift 变更**：检查 `api-reference.md`、`architecture.md` 版本锚点
5. **WWDC 后**：全量审计模式层和快照层
6. **每次对话启动**：Claude 检查快照层 `last_verified` 是否超期
7. **更新知识文件时**：grep 其他文件中对同一主题的引用，确认无矛盾（冲突检测）
8. **修复非预期问题后**：评估是否需要录入 `api-pitfalls.md` 或 feedback（踩坑即录入）
9. **docs 结构性漂移**：`Scripts/audit/docaudit.py` 提供机械化审计（6 子命令：links / archived-refs / orphans / home-path-refs / rule-pointer-sync / rule-usage）。策略源 `Scripts/audit/policy.yaml`，用法见 `Scripts/audit/README.md`。CI `docs` job（ubuntu-latest 并行）+ PostToolUse hook（Edit docs）+ PreToolUse hook（git push / gh pr merge 前）自动触发；对话场景用 `/knowledge-health` skill 扫描私有空间（CI 不可见的 `~/.claude/plans/` + private memory），产出分层修复 plan，不改文件
