---
paths:
  - "CLAUDE.md"
  - "STATUS.md"
  - ".claude/rules/collaboration.md"
---

<!-- last verified: 2026-04-09 -->
# Codex 子 agent 委派规范

Codex 作为 Claude Code 的子 agent 运行（插件 v1.0.3，源码 `openai/codex-plugin-cc`），不自动继承 `CLAUDE.md`、`.claude/rules/`、产品文档体系。
委派 prompt 的质量直接决定 Codex 输出是否符合项目约束。

## 模型与参数选择

| 任务类型 | 模型 | effort | 理由 |
|---|---|---|---|
| 研究/审计（只读） | `--model gpt-5.4` | `--effort medium` | GPT-5.4 输出更稳定，medium 防止搜索循环 |
| 代码实现/修复 | 默认（不指定） | 默认（不指定） | 让 Codex 自选最优模型 |
| 快速迭代/实时 | `--model spark` | 默认 | 1000+ tok/s，适合小改动 |
| 对抗性 Review | 默认 | 默认 | Review 命令有内置 prompt |

已知问题：GPT-5.3-Codex 在长研究任务中容易陷入搜索循环导致超时（报告生成阶段卡死）。切换到 GPT-5.4 + effort medium 可缓解。

## 委派 prompt 必须包含

### 1. 文件读取指令

根据任务类型，在 prompt 中明确要求 Codex 先读取：

| 任务类型 | 必读文件 |
|---|---|
| 全部任务 | `STATUS.md`、`docs/workflow.md`（DoD + S0-S3 + Git 工作流） |
| 产品/设计相关 | `docs/product/product-vision.md`、`docs/product/product-design.md`、`docs/product/product-requirements.md`、`docs/product/product-cases.md`（按需选读） |
| 代码实现 | `CLAUDE.md`（执行铁律）、相关 `.claude/rules/*.md`（coding/testing/apple-native 等）、**相关产品文档**（铁律：改代码前必须先读产品文档确认需求） |
| 审计/Review | 被审对象的全部上下文 + 上游依赖文档 |

### 2. 关键约束摘要

构造委派 prompt 前，先读取 `.claude/rules/shared-constraints.md` 并将其全文内联到 prompt 中。
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
