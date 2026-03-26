---
name: pr-review-workflow
description: PR 创建后的 review 工作流。写 Xcode 提示词、核实 finding、合并后更新 STATUS。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Edit
---

# PR Review 工作流

## 触发条件

`gh pr create` 成功后执行。

## 流程

### 1. 写 Xcode Review 提示词

为 Xcode Intelligence 撰写 review 提示词，输出给用户复制。
提示词应包含：PR 变更范围、重点检查项、项目约束（.claude/rules/coding.md 要点）。

### 2. 核实每条 Finding

无论 Xcode 还是其他 reviewer 的结论，必须独立核实：
1. 读源文件确认问题是否真实存在
2. 确认是否在 diff 范围内（reviewer 经常审 diff 之外的代码）
3. 对照 CLAUDE.md 确认是否属于已批准例外

### 3. 采纳有价值的建议

采纳后推送 fix commit。

### 4. 合并后更新 STATUS.md

执行 `/update-status` 直接推送到 develop。

## Gotchas

- **禁止自审自批**：fix 后必须让原 reviewer 验收
- **STATUS.md 合并后立即推送**：不等下一个 PR
- **Review 查两处**：`gh pr view --json comments` + `--json reviews`
