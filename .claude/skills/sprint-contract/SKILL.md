---
name: sprint-contract
description: 编码前契约强制执行（F-018）。feature Issue 动代码前，先研究代码库确定 Touches/No-Touch/Interface Delta/Test Additions/DoD 最小集，贴 Sprint Contract comment 到 Issue。当用户说"开工/开始编码/做这个 Issue/贴 contract/sprint contract"或 Issue 进入 Building 状态时触发。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /sprint-contract — 编码前契约

## 一句话

动第一行代码前，必须在 Issue 贴 Sprint Contract。编码中 contract 变更必须先改 comment 再改代码。

## 触发条件

- feature 类 Issue（`enhancement` label）进入 Building
- chore Appetite >= Medium
- 用户说："开工 / 开始编码 / 做这个 Issue / 贴 contract / sprint contract"

## 豁免

- bug_report 类（scope 天然小）
- trivial 改动（单行 typo/注释/日志，不改行为/接口/测试）
- Small Appetite 的 chore（可简化为 Touches / No-Touch / DoD 最小集三条）

## 工作流

### Step 1：读 Issue 确认范围

```bash
gh issue view <number>
```

提取：Scope、No-Go、验收标准（Given-When-Then）、MoSCoW、Appetite。

### Step 2：研究代码库

在动代码前先研究，确定实际会碰哪些文件：

```bash
# 搜相关代码
grep -r "关键词" Packages/ --include="*.swift" -l

# 确认现有接口
grep -n "public func\|public struct\|public protocol" <相关文件>

# 确认现有测试
grep -r "func test" Packages/*/Tests/ --include="*.swift" -l | grep -i "关键词"
```

### Step 3：起草 Sprint Contract（**字段化体例**，S-D7-003 共识）

按字段化体例填写（S-D7-003 落地的 `Scripts/audit/sprint_contract_gate.py` 字段解析器只认下列 key:value 格式）。**自然语言中文 bullet 格式已过时**——会被机器校验拒绝。

完整版（Medium / Large appetite）：

```markdown
## Sprint Contract

Contract Required: yes
Issue: #<num>
Issue Type: enhancement | chore
Appetite: Small | Medium | Large
Status: Building
Touches:
- <相对路径>
- <相对路径>
No-Touch:
- <相对路径 / glob>
- <相对路径 / glob>
Interface Delta:
- <public 签名 或 "none">
Test Additions:
- <测试用例名 或 "none">
DoD Minimum:
- <命令 / check>
Uncertainties:
- <已知未知 或 "none">
Contract Author: claude
```

**Appetite = Small (chore)** 简化版三字段：

```markdown
## Sprint Contract

Contract Required: yes
Issue: #<num>
Issue Type: chore
Appetite: Small
Status: Building
Touches:
- <相对路径>
No-Touch:
- <相对路径 / glob>
DoD Minimum:
- <命令 / check>
Contract Author: claude
```

**机器可读 trivial 豁免**（仅限单文件 markdown typo 类）：

```markdown
## Sprint Contract

Contract Required: exempt
Contract Exemption: trivial
Issue: #<num>
Changed Paths Checked: yes
Disallowed Paths Present: no
Exemption Rationale: <一句话原因>
Contract Author: claude
```

字段说明与豁免边界见 `.github/sprint-contract-policy.yml`。

### Step 4：贴到 Issue

```bash
gh issue comment <number> --body "$(cat <<'EOF'
<contract 内容>
EOF
)"
```

### Step 5：编码中维护

编码过程中发现 contract 与实际情况不符时：
1. **先改 Issue comment**，解释变更理由
2. **再改代码**
3. 禁止"代码和 contract 漂移"

### Step 6：PR body Review Trace 占位（S-D7-002 联动）

创建 PR 时**必须保留** `## F-005 Review Trace` 段（来自 `.github/PULL_REQUEST_TEMPLATE.md` 默认模板）。开工时 Codex/Gemini Evidence 字段可暂留空白，但 merge 前必须由 cross-audit 跑完后填充。

docs-only / trivial 类 PR 走机器可读豁免（`Review Required: exempt` + `Review Exemption: docs-only|trivial`）。Swift / source / config / CI / hook / policy 改动**不得**使用豁免。

### Step 7：Closeout（编码结束 / PR merge 前必填，S-D7-003 共识）

完成 Issue 编码后、提 PR merge 前，在 Issue 贴 Closeout comment：

```markdown
## Sprint Contract Closeout

Touches 实际触动: <列出真实改动文件>
偏离 Sprint Contract: <无 / 列出哪些 Touches/No-Touch 已变更并解释>
Test Additions 实际增加: <实际测试用例>
DoD 自检: <勾选 / 命令输出>
```

`.claude/hooks/premerge-checklist.sh` 在 `gh pr merge` 时会校验 closeout 段存在且关键字（Touches / DoD）非占位符。CI `sprint-contract-trace` job 同步校验。

### Step 0：检查现有契约（推荐先跑）

```bash
# 推导当前 Issue
python3 Scripts/audit/sprint_contract_gate.py --derive-issue

# 校验现有 contract（如已贴）
python3 Scripts/audit/sprint_contract_gate.py --file-path Packages/Foo.swift
```

如果当前 Issue 已有合规 contract，直接进入 Step 5；如果没有 → 走 Step 1-4。

## PreToolUse 编辑期硬阻断（S-D7-003 共识）

`.claude/hooks/pre-edit-sprint-contract.sh` 在 Edit/Write/MultiEdit 前阻断：

- 关联 Issue 必须有 `## Sprint Contract` comment
- Edit 文件必须在 contract Touches 范围内
- Edit 文件不能在 contract No-Touch 范围内（**Scope Creep 实时防御**）
- 占位符（`[填写]` / TBD / `...`）拒绝

紧急 override：`F018_SPRINT_CONTRACT_OVERRIDE=1 <command>`（stderr 留痕）。
路径豁免：`docs/**` / `*.md` / `STATUS.md` 不触发；详见 `.github/sprint-contract-policy.yml`。

## 反模式

- ❌ 跳过 contract 直接写代码 — 违反 F-018
- ❌ contract 写"改若干文件"而不列具体路径 — Reviewer 无法做 scope fidelity 比对
- ❌ 发现 scope 膨胀后继续写（不改 contract） — 必须停下，先更新 contract
- ❌ contract 只写 Touches 不写 No-Touch — No-Touch 是防 scope creep 的关键

## 内嵌纪律（权威源）

本 skill 是 F-018、F-013、F-014 的权威定义源。`docs/memory/feedback.md` 仅保留索引指针。


### F-013: PR scope 膨胀时必须拆分

当 PR 实际工作偏离原始目标（如从「配置修改」滚雪球成「修复 4 个编译错误 + 7 次 CI 重试」）时，必须停下来拆分为独立 PR。

**Why:** PR #597 从「CI 全量测试」膨胀到修复编译、修复环境问题、调试死锁，最终 8 次 CI 尝试。稳定通过的部分被死锁问题拖延合并。

**How to apply:** 当 PR 发现的附带问题超过 2 个、或 CI 失败超过 3 次且原因不同时，拆分为独立 PR。稳定通过的部分先合并，有问题的部分保持 open 或另开 PR。

> timeboxed: review_after 2026-07-15


### F-014: 跳过测试的合并门禁

标记测试为 `skipped` 是降级决策，合并前必须完成检查清单：(a) 创建 tracking issue，(b) 在代码中添加 `// TODO: #issue` 注释，(c) 在 PR description 中声明跳过原因，(d) PR 标题反映实际交付而非初始意图。

**Why:** PR #597 跳过 Data 测试后合并，但 tracking issue 和代码注释都是事后补的。

**How to apply:** 任何将测试标记为 skipped/disabled 的 PR，合并前检查四项清单全部完成。

> timeboxed: review_after 2026-07-15


## 关联参考

- `docs/protocol.md` §编码前契约
- `.github/ISSUE_TEMPLATE/feature_request.md` — Sprint Contract 模板源
