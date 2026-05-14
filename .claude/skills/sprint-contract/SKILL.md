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

## 反模式

- ❌ 跳过 contract 直接写代码 — 违反 F-018
- ❌ contract 写"改若干文件"而不列具体路径 — Reviewer 无法做 scope fidelity 比对
- ❌ 发现 scope 膨胀后继续写（不改 contract） — 必须停下，先更新 contract
- ❌ contract 只写 Touches 不写 No-Touch — No-Touch 是防 scope creep 的关键

## 关联规则

- `docs/memory/feedback.md` F-018（编码前契约纪律）
- `docs/workflow.md` §编码前契约
- `.github/ISSUE_TEMPLATE/feature_request.md` — Sprint Contract 模板源
