---
last_verified: 2026-05-18
layer: pattern
---
# Harness Recall — 自进化闭环（错误→永久修复）

> 补上 Harness Engineering 研究 P2 缺失的最后一环。
> 来源：Hashimoto "Engineer the Harness" 原则 + `docs/archive/research/harness-engineering-study-20260418.md`

## 一句话

每次 phase-closeout / 接手新会话时，Claude 扫描 `docs/memory/handoff.md` 的 Risks 段和 anti-pattern-scan 警报，检查重复模式。同类问题出现 ≥3 次 → 主动 propose 新 F-0XX 规则供用户裁决。

## 触发时机

1. **phase-closeout**：更新 handoff.md 前，扫描现有 Risks 段
2. **接手新会话**：读 `docs/memory/handoff.md` 后，扫描 Risks 段重复项
3. **用户说 "体检 / 知识体系审计 / /knowledge-health"**：纳入检查范围

## 执行步骤

### Step 1: 收集信号

```bash
# handoff.md 的 Risks 段
grep -A 50 '^## Risks' docs/memory/handoff.md

# 检查重复关键词
grep -n '重复\|recur\|again\|再次\|又出现' docs/memory/handoff.md

# anti-pattern-scan 历史（若有留存）
# 当前为实时 stderr 输出，无持久化日志；Claude 靠 session 记忆回溯
```

### Step 2: 归类去重

将信号按问题类别归并（如 "test evasion"、"scope creep"、"concurrency 违规"、"文档过期"），统计每类出现次数。

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

## 与 F-019 的关系

F-019 定义 **anti-pattern-scan → 警报 → 人工确认升级** 管道。Harness Recall 是 "确认升级" 到 "规则提案" 的执行器。

## 限制

- **不自动修改规则**：Recall 只 propose，人类批准是硬门槛
- **不跨 session 自动记忆**：anti-pattern-scan 的 stderr 输出瞬时，Claude 须在 phase-closeout 时主动回溯
- **假阳性容忍**：Risks 段可能包含已解决条目，判断 "重复" 时须确认条目当前状态
