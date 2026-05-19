---
name: post-merge
description: PR 合并后必做清单。CI post-merge 检查 → STATUS.md 更新 → anti-pattern-scan → 文档同步检查。当用户说"合并了/post-merge/合并后/收尾"或 PR 刚合并后自动触发。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Edit
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /post-merge — PR 合并后收尾

## 一句话

PR 合并不是终点。合并后有 4 个必做步骤，少一个都会让项目状态漂移。

## 触发场景

- PR 刚合并（`gh pr merge` 完成后）
- 用户说："合并了 / post-merge / 合并后 / 收尾 / cleanup"
- CI 跑完后确认 develop 分支状态

## 工作流

### Step 1：Post-merge CI 检查（F-007 时点 2）

合并后等 30 秒让 CI 触发，然后检查：

```bash
sleep 30
gh run list --branch develop --limit 3
```

如果有 failure：
- **立即停下手头所有工作**
- 排查 failure 原因
- 修复后推新的 fix commit
- CI 不绿不推进下一个 PR

如果 CI 仍在 QUEUED（Mac mini 排队中），等 runner 分配到自己。

### Step 2：更新 STATUS.md

```bash
# 回到 develop 分支
git checkout develop && git pull --ff-only origin develop
```

更新 STATUS.md 的内容：
- 本轮完成的 PR 列表
- 当前 Open Issue 数
- 编译/测试状态
- 当前阶段焦点

然后推送：

```bash
# 只 add STATUS.md
git add STATUS.md
git commit -m "status: <描述本次更新>

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
git push origin develop
```

**只 add STATUS.md**。不提交其他文件。

### Step 3：运行反模式扫描

```bash
bash Scripts/anti-pattern-scan.sh
```

如果命中警报：
- 记录在 handoff.md 或下次 phase-closeout 的 Risks 段
- 不自动修改规则 — 人工确认后才能升级（F-019 + Harness Recall）

### Step 4：文档同步检查

按 `docs/DOC_DEPENDENCY_MAP.md` §3 变更传播规则，检查本次 PR 是否需要同步下游：

```bash
# 检查 product-requirements.md last_verified 日期
grep "last_verified" docs/product/product-requirements.md

# 改了 public 接口 → 检查 architecture.md
grep "last_verified" docs/tech/architecture.md

# 改了合规/性能边界 → 检查 deployment.md
grep "last_verified" docs/tech/deployment.md
```

如有未同步项 → 调用 `dependency-propagation` skill 或手动补充。

### Step 5：检查 handoff.md

```bash
# handoff.md 是否需要更新
grep "last_verified" docs/memory/handoff.md
```

如果超过 7 天或本次有重大变更，更新 handoff.md。

## 输出清单

完成后报告：

```markdown
## Post-merge 完成

- [x] CI 绿（run #xxx）
- [x] STATUS.md 已更新并推送
- [x] anti-pattern-scan 无命中（或命中 X 条，已记录）
- [x] 文档同步无遗漏
```

## 反模式

- ❌ 合并后直接开下一个 PR，不检查 CI — 违反 F-007 时点 2
- ❌ 合并后不更新 STATUS.md — 项目状态漂移
- ❌ 用 `git add -A` 推送 STATUS 时混入其他文件
- ❌ anti-pattern-scan 命中后不记录 — 信号丢失

## 关联规则

本 skill 是 F-007 和 F-019 的权威执行器。`docs/memory/feedback.md` 仅保留索引指针。

- `docs/standards/harness-recall.md`（自进化闭环）
- `docs/workflow.md` §DoD（完整 DoD 检查表）
