---
last_verified: 2026-05-18
layer: pattern
---
# Codex 子 agent 委派规范

> 本文件是 agent-agnostic 的委派规范。任何主线程（Claude Code、Xcode、其他）委派 Codex 子 agent 时遵循本规则。
> 历史来源为旧 `.claude/rules/codex-delegation.md`（2026-04-17 PR #642 迁移）。当前权威源是本文档；`.claude/rules/` 不再作为现役指针层。

Codex 作为主线程的子 agent 运行（插件 v1.0.3，源码 `openai/codex-plugin-cc`），不自动继承 `CLAUDE.md` / `CODEX.md`、`docs/standards/`、产品文档体系。
委派 prompt 的质量直接决定 Codex 输出是否符合项目约束。

## 模型与参数选择

Codex CLI 0.130.0+ 使用 `-m` 指定模型，不支持 `--effort` 标志。

| 任务类型 | 模型参数 | 理由 |
|---|---|---|
| 研究/审计（只读） | `-m gpt-5.5` | 最新模型，深度推理，适合对抗性审查 |
| 对抗性 Review | `-m gpt-5.5` | 同上，多文件 diff 审查和独立视角验证 |
| 代码实现/修复 | 默认 | 让 Codex 自选最优模型 |
| 快速迭代/实时 | `-m spark` | 1000+ tok/s，适合小改动 |
| 快速 lint/格式校验 | `-m gpt-5.5` | 低智能敏感度任务 |

历史注记：GPT-5.4 时代 `--effort high` 曾是推荐参数；Codex CLI 0.130.0 移除该标志，模型选择替代 effort 控制。

## 委派 prompt 必须包含

### 1. 文件读取指令

根据任务类型，在 prompt 中明确要求 Codex 先读取：

| 任务类型 | 必读文件 |
|---|---|
| 全部任务 | `STATUS.md`、`docs/workflow.md`（DoD + S0-S3 + Git 工作流） |
| 产品/设计相关 | `docs/product/product-vision.md`、`docs/product/product-design.md`、`docs/product/product-requirements.md`、`docs/product/product-cases.md`（按需选读） |
| 代码实现 | `CODEX.md`（执行入口）、相关 `docs/standards/*.md`（coding/testing/apple-native 等）、**相关产品文档**（铁律：改代码前必须先读产品文档确认需求） |
| 审计/Review | 被审对象的全部上下文 + 上游依赖文档 |

### 2. 关键约束摘要

构造委派 prompt 前，先读取 `docs/standards/shared-constraints.md` 并将其全文内联到 prompt 中。
该文件是约束的唯一来源，此处不再硬编码，避免漂移。

### 3. 输出约束

- 语言：中文，技术术语保留英文
- 不加 emoji
- 明确要求输出格式（结构化报告 / 完整文件内容 / 简短结论）
- 明确说明是"只研究"还是"写代码"

## 反模式

- 只说"审计一下这个文件"而不给上下文 — Codex 会缺少项目约束做出泛泛判断
- 把 10 个文件路径丢过去不说目的 — Codex 不知道要验证什么
- 假设 Codex 了解之前对话的上下文 — 每次 Agent 调用都是全新会话
