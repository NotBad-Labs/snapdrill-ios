---
last_verified: 2026-04-17
layer: pattern
---
# Codex 子 agent 委派规范

> 本文件是 agent-agnostic 的委派规范。任何主线程（Claude Code、Xcode、其他）委派 Codex 子 agent 时遵循本规则。
> 位置迁移自 `.claude/rules/codex-delegation.md`（2026-04-17 PR #642 迁移，遵循 engineering.md:72 SSOT：docs/principles/ 为源，.claude/rules/ 作指针）。

Codex 作为主线程的子 agent 运行（插件 v1.0.3，源码 `openai/codex-plugin-cc`），不自动继承 `CLAUDE.md` / `CODEX.md`、`docs/principles/`、产品文档体系。
委派 prompt 的质量直接决定 Codex 输出是否符合项目约束。

## 模型与参数选择

| 任务类型 | 模型 | effort | 理由 |
|---|---|---|---|
| 研究/审计（只读） | `--model gpt-5.4` | `--effort high` | 对抗性审查要求深度，high 提供更可靠的分类判断（2026-04-17 从 medium 升级） |
| 对抗性 Review | `--model gpt-5.4` | `--effort high` | 同上，多文件 diff 审查和独立视角验证需要 high 保证质量 |
| 代码实现/修复 | 默认（不指定） | 默认（不指定） | 让 Codex 自选最优模型 |
| 快速迭代/实时 | `--model spark` | 默认 | 1000+ tok/s，适合小改动 |
| 快速 lint/格式校验 | `--model gpt-5.4` | `--effort medium` | 低智能敏感度任务，medium 省 token |

历史注记：GPT-5.3-Codex 时代因搜索循环曾推荐 medium。GPT-5.4 + Codex CLI v0.121.0 后该问题显著改善，2026-04-17 起默认升级 high。

## 委派 prompt 必须包含

### 1. 文件读取指令

根据任务类型，在 prompt 中明确要求 Codex 先读取：

| 任务类型 | 必读文件 |
|---|---|
| 全部任务 | `STATUS.md`、`docs/workflow.md`（DoD + S0-S3 + Git 工作流） |
| 产品/设计相关 | `docs/product/product-vision.md`、`docs/product/product-design.md`、`docs/product/product-requirements.md`、`docs/product/product-cases.md`（按需选读） |
| 代码实现 | `CODEX.md`（执行入口）、相关 `docs/principles/*.md`（coding/testing/apple-native 等）、**相关产品文档**（铁律：改代码前必须先读产品文档确认需求） |
| 审计/Review | 被审对象的全部上下文 + 上游依赖文档 |

### 2. 关键约束摘要

构造委派 prompt 前，先读取 `docs/principles/shared-constraints.md` 并将其全文内联到 prompt 中。
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
