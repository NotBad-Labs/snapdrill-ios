---
last_verified: 2026-05-13
layer: pattern
---
# Harness Recall — 自进化闭环（错误→永久修复）

> 补上 Harness Engineering 研究 P2 缺失的最后一环。
> 来源：Hashimoto "Engineer the Harness" 原则 + `docs/archive/research/harness-engineering-study-20260418.md`

## 一句话

每次 phase-closeout / 接手新会话时，Claude **必须**扫描近期 checkpoints 的 Risks 段和 anti-pattern-scan 警报，检查是否有重复模式。同类问题出现 ≥3 次 → 主动 propose 新 F-0XX 规则供用户裁决。

## 触发时机

1. **phase-closeout**：生成 checkpoint 前，必须执行 Harness Recall 检查
2. **接手新会话**：读 `docs/memory/handoff.md` 后，扫描 Risks 段重复项
3. **用户说 "体检 / 知识体系审计 / /knowledge-health"**：纳入检查范围

## 执行步骤

### Step 1: 收集信号

```bash
# 近 30 天所有 checkpoint 的 Risks 段
grep -A 20 '^## Risks' docs/memory/checkpoints/2026-*-*.md

# 检查 handoff.md 记录的重复问题
grep -A 10 '重复\|recur\|again\|再次\|又出现' docs/memory/handoff.md

# anti-pattern-scan 历史（若有留存）
# 当前为实时 stderr 输出，无持久化日志；Claude 靠 session 记忆回溯
```

### Step 2: 归类去重

将信号按问题类别归并（如 "test evasion"、"scope creep"、"concurrency 违规"、"文档过期"），统计每类在最近 checkpoints / handoff / session 中出现的次数。

### Step 3: 三击判断（F-019 升级版）

| 出现次数 | 行为 |
|---|---|
| 1 次 | 记录在当前 phase checkpoint 的 Risks 段 |
| 2 次 | Risks 段注明 "重复出现，观察中" |
| **≥3 次** | **触发 Recall：向用户 propose 新 F-0XX 规则** |

### Step 4: 起草规则提案

当触发 Recall 时，Claude 向用户输出：

```
## Harness Recall 规则提案

**问题模式**: <一句话描述重复出现的问题>
**出现证据**:
  - <checkpoint/日期>: <具体描述>
  - <checkpoint/日期>: <具体描述>
  - <checkpoint/日期>: <具体描述>
**提案 F-0XX**: <规则名称>
**建议位置**: docs/memory/feedback.md 或 docs/principles/<file>.md
**建议内容**:
  - 触发条件
  - 必须/禁止行为
  - Why / How to apply

请用户裁决：批准 / 修改后批准 / 拒绝（附理由）/ 继续观察
```

### Step 5: 落地或记录

- 用户批准 → 写入 feedback.md（F-0XX）或对应 principles 文件 → 更新 KNOWLEDGE_MAP.md
- 用户拒绝 → 记录到 decisions.md，注明拒绝理由，避免日后重复提案
- 用户选择继续观察 → 在当前 checkpoint Risks 段注明 "Harness Recall 已触发，用户指令继续观察"

## 与 F-019 的关系

F-019 定义了 **anti-pattern-scan → 警报 → 人工确认升级** 的管道。Harness Recall 是该管道中从 "确认升级" 到 "规则提案" 的**执行器**。

```
anti-pattern-scan.sh → stderr 警报
        ↓
post-merge-checkpoint hook → 提醒 /phase-closeout
        ↓
Harness Recall（本文档）→ 跨 checkpoint 去重归类 → 3 次触发 propose
        ↓
F-019 升级决策 → 人类批准 → 写入 feedback.md / principles
```

## 限制

- **不自动修改规则**：Recall 只 propose，不直接写 feedback.md。人类批准是硬门槛。
- **不跨 session 自动记忆**：anti-pattern-scan 的 stderr 输出是瞬时的。Claude 必须在 phase-closeout 时主动回溯 checkpoints 做去重。
- **假阳性容忍**：checkpoint Risks 段可能包含已解决的条目。Claude 判断 "重复" 时必须确认条目的当前状态。
