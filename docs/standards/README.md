---
last_verified: 2026-05-18
layer: pattern
---
# 项目标准与约束（Agent-Agnostic）

> 本目录是 SnapDrill 项目开发原则的唯一真相源。
> 所有智能体（Claude、Codex、Gemini 等）共同遵守，人类拥有最高裁决权。
> 智能体可以辅助优化，但不能破坏项目本身的框架。

## 规则索引

| 文件 | 用途 | 触发场景 |
|---|---|---|
| [coding.md](coding.md) | 编码规范（SwiftLint 管不到的规则） | 写/改 Swift 代码 |
| [testing.md](testing.md) | 测试策略与执行规则 | 写/改测试代码 |
| [engineering.md](engineering.md) | 工程哲学与决策原则 | 架构决策、新功能设计 |
| [apple-native.md](apple-native.md) | Apple 原生 UI 模式 | UI/UX 改动 |
| [apple-limits.md](../tech/apple-limits.md) | Apple 技术能力边界 | 涉及 Vision/OCR/ML |
| [api-pitfalls.md](../tech/api-pitfalls.md) | API 易错点速查 | 调用项目内部 API |
| [collaboration.md](collaboration.md) | 多智能体协作架构 | 交叉审计、委派任务 |
| [codex-delegation.md](codex-delegation.md) | Codex 子 agent 委派规范 | 委派 Codex 做审计/实现/Review |
| [gemini-delegation.md](gemini-delegation.md) | Gemini CLI 委派规范 | 委派 Gemini 做审计/校验 |
| [ux-design.md](ux-design.md) | UX 设计原则与用户体验终审 | UI/UX 改动、用户体验评审 |
| [shared-constraints.md](shared-constraints.md) | 委派 prompt 共享约束 | 构造委派 prompt |
| [permission-model.md](permission-model.md) | Tool / Bash 命令 / Skill 权限矩阵（SSOT） | 修改 settings.json / hooks / skill allowed-tools |
| [skill-architecture.md](skill-architecture.md) | Agent Skills 目录架构与迁移规则 | 新增 / 迁移 / 退役 skill |
| [execution-gates.md](execution-gates.md) | 执行门禁总表 | 修改 CI / hook / merge gate |
| [audit-rubric.md](audit-rubric.md) | 文档系统审计评分标准 | 启动文档审计 / 交叉审计 |
| [harness-recall.md](harness-recall.md) | 自进化闭环：跨 checkpoint 去重 → 3 次触发 propose 新 F-0XX 规则 | phase-closeout / harness 自进化 |
| [memory-routing.md](memory-routing.md) | 项目知识 / 智能体记忆路由规则（agent-agnostic） | 写新文档时判断归属 docs/ vs Claude 私有空间 |

## 治理原则

1. **项目主权**：项目知识属于项目，不属于任何智能体
2. **人类裁决权**：冲突时以人类决策为准
3. **智能体对等**：所有智能体平等遵守同一套原则，不存在"主导智能体"。注意：**规则义务平等 ≠ 评分裁决权重平权**；cross-audit 场景下 Codex 始终是主锚点、Gemini/Claude-Agent 是次锚点、Claude 主线程自审作参考，见 `.claude/skills/cross-audit-consensus/SKILL.md` §2.5 评分方权重 SSOT 表
4. **指针不重复**：智能体自己的配置文件（CLAUDE.md、CODEX.md 等）指向本目录，不复制内容
