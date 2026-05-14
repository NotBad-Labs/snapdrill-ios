---
name: verify-audit-report
description: 审计报告真伪验证。接收任何审计报告（Codex/Gemini/baseline/cross-audit）后，逐条 grep + Read 源码确认 finding 真实性，输出验证报告。当用户说"核实审计/验证报告/verify audit/查证 finding"或收到审计报告后自动触发。
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

# /verify-audit-report — 审计报告真伪验证

## 一句话

审计报告里的 finding 不能直接信。每个 finding 必须用源码验证后才算数。

## 触发场景

- 收到任何审计报告后（Codex / Gemini / 基线审计 / cross-audit）
- 用户说："核实审计 / 验证报告 / verify audit / 查证 finding"
- cross-audit 三方报告到位后，汇总前（F-006 + F-012 强制）

## 核心纪律

### F-006：深度验证，不是浅层 grep

每个 finding 必须回答"代码具体怎么做的"，不只是"代码里有没有这个名字"。
- grep 找到符号后，Read 源码至少 **10-20 行上下文** 确认行为一致
- 对 "X 功能缺失" 类 finding，搜索备选实现路径（可能用不同 API 实现了相同功能）
- 验证深度标准：能向用户解释代码的实际执行路径

### F-012：全量做，不抽查

- 报告中每条 finding 逐一验证，禁止抽样后声称"基本准确"
- 超过 20 条 finding 时可分批，但必须明确告知覆盖范围
- 大量机械性检查写脚本自动化，不逐条手工

### Gemini 特别纪律

Gemini 对"功能是否实现"和"文档是否匹配"的判断不可信（已知幻觉模式）：
- Gemini 的 Critical/Warning 必须交叉验证（已知 2/2 Critical 误判历史）
- Gemini 声称"X 缺失"时，搜索是否用其他命名/路径实现了
- Gemini 声称"文档说 Y"时，在文档源文件中逐字找原文（Gemini 会编造章节号）

## 验证工作流

### Step 1：解析报告

从审计报告中提取每个 finding：
- **编号**（如 C1, X3, G2）
- **声称**（一句话描述发现了什么）
- **严重度**（Critical / Warning / Info）
- **声称位置**（文件路径 + 行号，如果有）
- **来源方**（Claude / Codex / Gemini）

### Step 2：逐条验证

对每条 finding：

```
1. grep 符号/API 名称确认存在性
2. Read 源文件 10-20 行上下文确认行为
3. 检查备选实现路径（finding 声称"缺失"时关键）
4. 对照已知例外（F-004 sunset、ADR 决策等）
5. 判定类别
```

### Step 3：分类

| 类别 | 定义 |
|---|---|
| **confirmed** | 问题真实存在，代码可复现 |
| **false-positive** | 问题不存在，auditor 误读代码 |
| **design-decision** | 问题存在但是有意设计（ADR 或 comment 可证） |
| **duplicate** | 与另一条 finding 是同一问题 |
| **needs-investigation** | 无法在当前会话确认（需真机 / Apple 文档 / 用户决策） |

### Step 4：输出验证报告

```markdown
# Audit Verification Report

**原报告**: <来源/路径>
**验证时间**: <YYYY-MM-DD>
**验证方**: Claude Code CLI

## Summary

| 总 finding | Confirmed | False Positive | Design Decision | Duplicate | Needs Investigation |
|---|---|---|---|---|---|
| N | N | N | N | N | N |

## 逐条验证

### C1: <finding 标题>
- **原判定**: Warning
- **验证结果**: **confirmed**
- **证据**: <文件路径:行号> — <代码片段>
- **说明**: <一行解释为什么确认>

### G2: <finding 标题>
- **原判定**: Critical
- **验证结果**: **false-positive**
- **证据**: <文件路径:行号> — <代码片段证明了相反行为>
- **说明**: Gemini 误判 — 功能已在 X 处实现

## 统计

- Gemini 误判率: X/N (X%)
- Codex 误判率: X/N (X%)
- 三方共识 finding 误判率: X/N (X%)
```

## 验证辅助脚本

对大量 finding，写一次性验证脚本而非逐个手工。例如：

```bash
# 批量检查 API 是否在代码中存在
for api in "DataExecutor" "PersistenceController" "recognizeDocument"; do
  count=$(grep -r "$api" --include="*.swift" . | wc -l)
  echo "$api: $count references"
done
```

## 反模式

- ❌ 收到报告后直接修复，跳过验证 — 会修不存在的 bug
- ❌ 只看 finding 标题就判断真假 — 必须读源码
- ❌ Gemini Critical 直接采信 — 已知高误判率
- ❌ 抽查 5 条说"基本准确" — 违反 F-012
- ❌ 只看 diff 不看完整文件上下文 — 可能遗漏备选路径

## 关联规则

- `docs/memory/feedback.md` F-006（深度验证）、F-012（全量做）
- `docs/memory/feedback.md` F-016（质疑方批准）
- 用户 memory `feedback_gemini_adversarial.md`（Gemini 已知幻觉模式）
