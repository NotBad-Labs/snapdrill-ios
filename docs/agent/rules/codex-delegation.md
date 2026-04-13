---
paths:
  - "CODEX.md"
  - "STATUS.md"
  - "docs/agent/rules/shared-constraints.md"
---

<!-- last verified: 2026-04-13 -->
# Codex 委派规范

## 核心事实

- 每次委派都是新上下文，不会自动继承当前会话推理链。
- prompt 必须自包含目标、范围、约束、输出格式。

## 委派前必做

1. 明确任务边界（只读审计 / 代码修改 / 文档治理）。
2. 指定必须读取的文件（最少：`STATUS.md`、`docs/workflow.md`、任务相关文档）。
3. 内联 `shared-constraints.md` 关键约束。
4. 指定交付物格式（结论、风险分级、文件路径、验证命令）。

## 无记忆污染调用（强制）

- Claude CLI 委派统一使用：

```bash
claude -p --model claude-opus-4-6 --bare --no-session-persistence "<prompt>"
```

- 禁止参数：`-c/--continue`、`-r/--resume`、`--from-pr`。
- 委派 prompt 首段必须包含：
  - “仅以本次给定文件清单为事实源”
  - “禁止引用历史会话、历史 issue 结论或私有记忆目录”

## 输出质量要求

- 发现项必须给出锚点（文件 + 行号或函数名）。
- 提供可执行验证步骤，不给空泛建议。
- 不可用“可能”“大概”替代证据。

## 常见反模式

- 只给文件路径，不给审计目标。
- 不给项目约束，导致输出与实际架构脱节。
- 把多个不相关目标塞进一次委派，降低结果可用性。
