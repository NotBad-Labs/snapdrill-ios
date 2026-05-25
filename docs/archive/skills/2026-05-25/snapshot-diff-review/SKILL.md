---
last_verified: 2026-05-25
layer: archive
status: archived
skill_audit_verdict: archived  # user-decision-log #017/#018
name: snapshot-diff-review
description: Snapshot 测试 baseline 变更审查。当 snapshot 测试产生新的 baseline 或 baseline 变更时，git diff 图片确认视觉变化是有意的再提交。当用户说"snapshot 变了/baseline 更新/快照测试/snapshot test/record snapshots"时触发。
allowed-tools:
  - Bash
  - Read
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /snapshot-diff-review — Snapshot Baseline 审查

## 一句话

Snapshot baseline 变更是二进制图片，git diff 看不出内容。必须逐张确认视觉变化是有意为之，再提交。

## 触发场景

- 运行 snapshot 测试后 baseline 发生变化
- `SNAPSHOT_TESTING_RECORD=1` 模式录制了新 baseline
- 用户说："snapshot 变了 / baseline 更新 / 快照测试 / record snapshots"
- CI 报告 snapshot 测试失败（baseline mismatch）

## 工作流

### Step 1：确认变更范围

```bash
# 查看哪些 baseline 文件变更了
git diff --name-only | grep -i "snapshot\|baseline\|Snapshots"

# 或查看所有未提交的 baseline 变更
git status | grep -i "snapshot\|baseline"
```

### Step 2：逐张 diff

对每个变更的 baseline 图片：

```bash
# 查看图片 diff（如果 git 支持）
git diff <path-to-baseline-image>

# 或者用 Finder 预览新旧对比
open <path-to-baseline-image>
```

基线位置通常在：
```
Packages/*/Tests/**/__Snapshots__/
```

### Step 3：判断变更是否合理

| 情况 | 处理 |
|---|---|
| **有意的 UI 改进** | 确认无误，纳入 commit |
| **无意的回归** | 回退代码变更，不更新 baseline |
| **仅环境差异**（字体渲染、分辨率） | 检查是否需要在 CI 环境 record |
| **无法判断** | 保留变更，标注待 Xcode Review 确认 |

### Step 4：确认后提交

```bash
# 如果所有变更都是有意的
git add <baseline-files>
git commit -m "test: update snapshot baselines for <reason>"
```

**禁止盲目 `SNAPSHOT_TESTING_RECORD=1` 全量录制后直接提交。** 必须逐张看过。

### Step 5：文档记录

在 PR 描述中说明 baseline 变更理由：
```
Snapshot baseline 更新：
- <文件名>: <变更原因>
```

## 注意事项

- Snapshot 图片是二进制文件，git 无法逐行 diff — 必须肉眼确认
- CI 环境的 snapshot 可能与本地不同（分辨率/字体），以 CI 为准
- 不要 `git add .` 混入 baseline 之外的变更

## 反模式

- ❌ `SNAPSHOT_TESTING_RECORD=1` 全量录制后直接 git add 所有 baseline
- ❌ 不看图片 diff 就提交 baseline 变更
- ❌ CI snapshot 失败后直接 record 覆盖，不排查原因

## 上游文档

本 skill 的上游权威定义在：
- `docs/standards/testing.md:90-97` — Snapshot 视觉回归工作流（人工审查要求、禁止盲目 record）
- `docs/protocol.md:127` — Snapshot baseline 变更必须 git diff 确认

## 关联文档

- `docs/standards/testing.md` — 测试规则
- `docs/protocol.md` §CI — CI 与本地一致性
