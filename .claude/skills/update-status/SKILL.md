---
name: update-status
description: PR 合并后将 STATUS.md 直接推送到 develop。文档化例外——状态追踪文件不需要走 PR 流程。
allowed-tools:
  - Bash
  - Read
  - Edit
---

# /update-status — 状态看板推送

## 触发条件

PR 合并后、STATUS.md 已在本地更新完成时执行。

## 执行流程

### 1. 确认在 develop 分支

```bash
current_branch=$(git branch --show-current)
if [ "$current_branch" != "develop" ]; then
  echo "⚠️ 当前不在 develop 分支（$current_branch），先切换"
  git checkout develop && git pull
fi
```

### 2. 检查是否有待推送的状态变更

```bash
git status STATUS.md
```

如果无变更，提示「STATUS.md 已是最新，无需推送」并退出。

### 3. 精确 stage + commit + push

```bash
git add STATUS.md
git commit -m "chore: 更新项目状态看板

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
git push origin develop
```

**只 add STATUS.md**，不使用 `git add .` 或 `git add -A`。

## 文档化例外

STATUS.md 是状态追踪文件，不含代码逻辑：
- 不需要 Code Review（review 的是代码，不是状态记录）
- 不需要 CI 验证（不影响编译和测试）
- 每次开 PR 只为推状态文件是流程浪费

此例外已在 `workflow.md`「Git 工作流」中文档化。

## 注意事项

- 如果 develop 有远程更新（其他 PR 刚合并），先 `git pull` 再 push
- 如果有其他未提交的代码变更混在工作区，**不要执行**——先处理代码变更
- commit message 固定为 `chore: 更新项目状态看板`，不需要关联 Issue
