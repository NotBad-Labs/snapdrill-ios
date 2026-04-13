---
paths:
  - "CODEX.md"
  - "STATUS.md"
  - "docs/agent/rules/shared-constraints.md"
---

<!-- last verified: 2026-04-13 -->
# Gemini CLI 委派规范

## 适用场景

- 需要第三方独立视角的只读审计。
- 需要对 Codex 结论进行交叉验证。

## 调用基线

```bash
gemini -p "<prompt>" --approval-mode plan 2>&1
```

- 只读审计默认不加 `--sandbox`。
- 只有在 prompt 明确要求改文件时才加 `--sandbox`。
- 禁止使用 `--resume`（避免历史会话污染当前裁决）。

## prompt 必备信息

1. 审计目标（要找什么问题）。
2. 审计范围（文件清单）。
3. 项目约束（来自 `shared-constraints.md`）。
4. 输出格式（严重度、锚点、验证建议）。

## 限制与策略

- Gemini CLI 非交互调用是无状态的，每次都要给完整上下文。
- 大批量文件应分批审计，避免单次超时和质量下降。
- 与主执行结论冲突时，以仓库可验证事实为准（代码/测试/构建结果）。
- prompt 首段必须声明“仅以下文件为事实源，不引用历史会话/缓存结论”。
