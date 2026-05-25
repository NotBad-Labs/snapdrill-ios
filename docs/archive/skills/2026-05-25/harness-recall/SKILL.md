---
last_verified: 2026-05-25
layer: archive
status: archived
skill_audit_verdict: archived  # user-decision-log #017/#018
name: harness-recall
description: 自进化闭环执行器。扫描 handoff.md Risks 段 + anti-pattern-scan 警报，检查重复问题模式。同类问题 ≥3 次 → propose 新 F-0XX 规则。当 phase-closeout / 接手新会话 / 用户说"体检/harness recall/自检重复问题"时触发。
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

# /harness-recall — 自进化闭环（错误→永久修复）

## 一句话

扫描 `docs/memory/handoff.md` 的 Risks 段和 anti-pattern-scan 警报，检查重复模式。同类问题出现 ≥3 次 → 主动 propose 新 F-0XX 规则供用户裁决。

> 权威源：`docs/standards/harness-recall.md`。本 skill 为执行器。

## 触发时机

1. **phase-closeout**：更新 handoff.md 前，扫描现有 Risks 段
2. **接手新会话**：读 `docs/memory/handoff.md` 后
3. **用户说 "体检 / 知识体系审计 / harness recall / 自检重复问题"**

## 执行步骤

### Step 1: 收集信号

```bash
# handoff.md 的 Risks 段
grep -A 50 '^## Risks' docs/memory/handoff.md

# 检查重复关键词
grep -n '重复\|recur\|again\|再次\|又出现' docs/memory/handoff.md

# anti-pattern-scan
bash Scripts/anti-pattern-scan.sh
```

### Step 2: 归类去重

将信号按问题类别归并（"test evasion"、"scope creep"、"concurrency 违规"、"文档过期"等），统计每类出现次数。

### Step 3: 三击判断（F-019 升级版）

| 出现次数 | 行为 |
|---|---|
| 1 次 | 记录在 handoff.md 的 Risks 段 |
| 2 次 | Risks 段注明 "重复出现，观察中" |
| **≥3 次** | **触发 Recall：向用户 propose 新 F-0XX 规则** |

### Step 4: 起草规则提案

```
## Harness Recall 规则提案

**问题模式**: <一句话描述>
**出现证据**: <handoff.md 位置 + 日期>: <描述> ×3
**提案 F-0XX**: <规则名称>
**建议位置**: docs/memory/feedback.md 或 docs/standards/<file>.md

请用户裁决：批准 / 修改后批准 / 拒绝（附理由）/ 继续观察
```

### Step 5: 落地或记录

- 用户批准 → 写入 feedback.md（F-0XX）→ 更新 KNOWLEDGE_MAP.md
- 用户拒绝 → 记录到 decisions.md，注明理由
- 继续观察 → handoff.md Risks 段注明 "已触发 Recall，用户指令继续观察"

## 限制

- **不自动修改规则**：Recall 只 propose，人类批准是硬门槛
- **不跨 session 自动记忆**：anti-pattern-scan 的 stderr 输出瞬时，须在 phase-closeout 时主动回溯
- **假阳性容忍**：Risks 段可能包含已解决条目，判断 "重复" 时须确认条目当前状态

## 上游文档

- `docs/standards/harness-recall.md` — 自进化闭环权威定义
- `docs/memory/feedback.md` — F-019 反模式回流
- `docs/standards/execution-gates.md` — 门禁总表
