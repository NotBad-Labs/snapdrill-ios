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

### Step 3：起草 Sprint Contract

按 Issue 模板 Sprint Contract 段填写：

```markdown
## Sprint Contract

- **Touches**：会新增/修改哪些文件（路径列表，不是模块名）
- **No-Touch**：显式不动哪些文件/模块（防 scope creep）
- **Interface Delta**：新增或修改的 public 接口签名预期
- **Test Additions**：预期新增的测试用例（粒度到用例名）
- **DoD 最小集**：本 Issue 必须满足的 DoD 子集
- **预期不确定点**：哪些决策留给实现阶段自主判断
```

**Appetite = Small** 可只填 Touches / No-Touch / DoD 最小集。

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

- `docs/workflow.md` §编码前契约
- `.github/ISSUE_TEMPLATE/feature_request.md` — Sprint Contract 模板源
