# SnapDrill 知识地图

> 全局知识索引。三层分类：原则（极少变）、模式（偶尔变）、快照（频繁变）。
> 原则层不包含具体版本号；快照层必须声明 freshness 元数据。

---

## 原则层（Closed — 变更需 PO 决策）

| 文件 | 核心内容 | 依赖于 |
|---|---|---|
| `docs/product/product-vision.md` | 产品定位、价值链、用户画像 | — |
| `docs/product/product-business.md` | 商业模型、定价、隐私承诺 | vision |
| `.claude/rules/engineering.md` | 工程哲学：奥卡姆剃刀、先研究再动手 | — |
| `docs/workflow.md` | 开发闭环、Git 工作流、S0-S3、DoD | engineering |

## 模式层（Semi-Open — 随版本迭代调整）

| 文件 | 核心内容 | 依赖于 | 演进触发 |
|---|---|---|---|
| `docs/tech/architecture.md` | 包结构、DI、模块边界 | vision, engineering | 架构重构 |
| `docs/product/product-design.md` | UI/UX 模式、信息架构 | vision | HIG 更新 |
| `docs/product/product-requirements.md` | 功能规格、版本路线图 | vision, design | 新功能 |
| `docs/product/product-cases.md` | 验收标准、异常路径 | requirements | 新功能 |
| `docs/product/product-journeys.md` | 用户旅程 | design, requirements | 新功能 |
| `docs/product/product-glossary.md` | 术语定义 | vision | 概念变更 |
| `.claude/rules/apple-native.md` | Apple 原生 UI 模式 | — | HIG/WWDC |
| `.claude/rules/coding.md` | 编码规范、SwiftLint 规则 | engineering | Swift 版本 |
| `.claude/rules/testing.md` | 测试策略 | engineering | XCTest 更新 |
| `.claude/rules/collaboration.md` | 智能体协作架构（Opus/Haiku/Sonnet/Codex/Xcode/Antigravity） | — | 工具更新 |
| `.claude/rules/codex-delegation.md` | Codex 子 agent 委派规范 | — | 插件/模型更新 |
| `docs/tech/compliance.md` | 隐私合规、App Store 审核 | vision, business | 政策变更 |
| `docs/tech/deployment.md` | CI/CD、发布流程 | — | 工具更新 |
| `docs/tech/non-functional-requirements.md` | 性能、内存、存储 | architecture | 设备更新 |

## 快照层（Open — 外部驱动频繁变化）

| 文件 | 核心内容 | max_age_days | 演进触发 |
|---|---|---|---|
| `STATUS.md` | 当前工作状态 | 7 | 每次 PR 合并 |
| `docs/tech/api-reference.md` | 内部 API 签名 | 30 | 代码变更 |
| `.claude/rules/apple-limits.md` | Apple API 能力边界 | 60 | WWDC / iOS 更新 |
| `.claude/rules/api-pitfalls.md` | API 踩坑记录 | 60 | 开发中发现 |
| `memory/reference_ai_toolchain_specs.md` | Claude/Codex/Xcode 规格 | 30 | 模型/工具发布 |

## 记忆层（Auto Memory — 跨会话持久化）

> 存储在 `~/.claude/projects/.../memory/`，不入 git。按 MEMORY.md 索引。

| 类型 | 文件模式 | 分层归属 | 示例 |
|---|---|---|---|
| feedback_*.md | 工作流纪律、协作反馈 | 模式层 | 自主执行不等于跳流程 |
| project_*.md | 项目进展、临时状态 | 快照层 | Apple 开发者账号注册中 |
| reference_*.md | 外部工具指针 | 快照层 | AI 工具链规格 |

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
→ 趋势：从"代码补全"到"验证闭环"。Xcode MCP 是关键拐点
→ 决策触发：当 Xcode agentic coding 支持自定义 rules 文件加载时，评估从 CLI 迁移核心工作流
```

## 分层判定标准

| 维度 | 原则层 | 模式层 | 快照层 |
|---|---|---|---|
| 半衰期 | >2 年 | 6-24 个月 | <6 个月 |
| 依赖于 | 业务逻辑、团队共识 | 框架版本、设计范式 | 外部 API 版本、定价、工具版本 |
| 变更触发 | PO 决策 | 版本迭代 | 外部发布 |
| freshness 元数据 | 不需要 | 可选 | 必须 |

## 知识退役

当知识不再适用时，不删除，标记退役：
- 在文件头加 `<!-- status: archived, reason: xxx -->`
- 从 KNOWLEDGE_MAP 对应表格中移除，归入下方"已退役"小节
- feedback 被内化到 `.claude/rules/` 后即可退役
- api-pitfalls 条目被框架修复后标记退役

**文件数量软上限**：活跃知识文件 ~25 个。超过时优先合并或退役，而非继续新增。

## 知识卫生规则

1. **修改代码后**：检查 `api-reference.md` 是否需要同步
2. **升级 Xcode/iOS**：检查 `apple-limits.md`、`apple-native.md`
3. **模型/工具更新**：检查 `reference_ai_toolchain_specs.md`、`codex-delegation.md`
4. **Package.swift 变更**：检查 `api-reference.md`、`architecture.md` 版本锚点
5. **WWDC 后**：全量审计模式层和快照层
6. **每次对话启动**：Claude 检查快照层 `last_verified` 是否超期
7. **更新知识文件时**：grep 其他文件中对同一主题的引用，确认无矛盾（冲突检测）
8. **修复非预期问题后**：评估是否需要录入 `api-pitfalls.md` 或 feedback（踩坑即录入）
