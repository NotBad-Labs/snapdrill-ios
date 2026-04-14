# 项目原则（Agent-Agnostic）

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
| [apple-limits.md](apple-limits.md) | Apple 技术能力边界 | 涉及 Vision/OCR/ML |
| [apple-extension.md](apple-extension.md) | App Extension 约束 | Share Extension 开发 |
| [api-pitfalls.md](api-pitfalls.md) | API 易错点速查 | 调用项目内部 API |
| [collaboration.md](collaboration.md) | 多智能体协作架构 | 交叉审计、委派任务 |
| [ux-design.md](ux-design.md) | UX 设计原则与用户体验终审 | UI/UX 改动、用户体验评审 |
| [review-prompt-guide.md](review-prompt-guide.md) | Xcode Review 提示词模板 | 写 Xcode Review 提示词 |
| [shared-constraints.md](shared-constraints.md) | 委派 prompt 共享约束 | 构造委派 prompt |

## 治理原则

1. **项目主权**：项目知识属于项目，不属于任何智能体
2. **人类裁决权**：冲突时以人类决策为准
3. **智能体对等**：所有智能体平等遵守同一套原则，不存在"主导智能体"
4. **指针不重复**：智能体自己的配置文件（CLAUDE.md、CODEX.md 等）指向本目录，不复制内容
