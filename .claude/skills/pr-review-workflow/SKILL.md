---
name: pr-review-workflow
description: PR 创建后的完整 review 工作流。当 gh pr create 完成后自动激活。包含 Gemini 轮询、review 提示词撰写、核实流程、合并后 STATUS.md 更新。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Edit
---

# PR Review 工作流

## 触发条件

`gh pr create` 成功后自动执行以下流程。

## 完整流程（6 步）

### 1. 后台轮询 Gemini Review

```bash
for i in $(seq 1 12); do
  result=$(gh pr view {PR_NUMBER} --json comments --jq '.comments | length')
  if [ "$result" -gt 0 ]; then
    gh pr view {PR_NUMBER} --json comments --jq '.comments[0].body'
    exit 0
  fi
  sleep 15
done
```

**自动执行，不需要用户下命令。**

### 2. 核实每条 Finding

无论 Gemini 还是外部 reviewer 的结论，必须独立核实：
1. 读源文件确认问题是否真实存在
2. 确认是否在 diff 范围内（Gemini 经常审 diff 之外的代码）
3. 对照 CLAUDE.md 确认是否属于已批准例外

### 3. 判断是否需要 Antigravity/Xcode Review

**需要**：新业务逻辑、新跨模块依赖、新文件（非纯结构性）
**不需要**：纯文档、纯测试修复、纯结构性改动（rename/import/access control）

### 4. 采纳有价值的建议

采纳后推送 fix commit，等 Gemini re-review。

### 5. 合并后立即更新 STATUS.md

**事件驱动的自动行为，不问用户。**
- 更新线 A/B 状态表
- 添加到「近期完成」
- 提交为独立 PR 或打包到下一个改动中

### 6. Review 轮询查两处

```bash
gh pr view {N} --json comments  # PR comment
gh pr view {N} --json reviews   # PR review
```

## Gotchas

### Gemini 经常审 diff 之外的代码
Gemini 的"严重"问题有很高概率是 pre-existing 问题，不在当前 PR 范围内。每条 finding 必须确认是否在 diff 中。

### STATUS.md 在 git checkout 时会被覆盖
本地未提交的 STATUS.md 改动会在 `git checkout develop` 时丢失。STATUS.md 的改动应该作为 PR 的一部分提交，或合并后立即单独 PR。

### 禁止自审自批
修复 review finding 后，必须让原 reviewer 验收。不能自己宣布可合并。

## 参考

- `workflow.md`：Code Review 铁律 + PR 全流程纪律
- `review-prompt-guide.md`：Antigravity/Xcode 提示词撰写规范
