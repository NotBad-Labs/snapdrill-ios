---
name: decision-closeout
description: 产品决策变更后闭环收尾。影响评估 → 下游同步 → ADR 更新 → Issue 关闭 → STATUS.md。当用户说"决策变更/决定改了/更新决策/decision closeout"或产品文档变更涉及决策变化时触发。
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

# /decision-closeout — 决策变更收尾闭环

## 一句话

产品决策变更不是改完文档就完了。必须沿依赖链传播，确保所有下游文档与决策一致。

> 权威源：`docs/workflow.md` § 决策变更收尾。本 skill 为执行器。

## 触发场景

- 产品决策变更（vision/design/requirements/ADR 修改）
- 用户说："决策变更 / 决定改了 / 更新决策 / decision closeout"
- PR 涉及 `docs/product/` 或 `docs/decisions/` 的实质性变更

## 执行步骤

### Step 1: 影响评估

```bash
# 用 dependency-propagation skill 或手动 grep
grep -r "<变更关键词>" docs/ --include="*.md" -l
```

参考 `docs/DOC_DEPENDENCY_MAP.md` 变更传播规则，列出所有受影响的文档。

### Step 2: 同步更新

对每个受影响的下游文档（按 `docs/DOC_DEPENDENCY_MAP.md` §2 主链分组）：

**产品主链**：
- `product-requirements.md` / `product-design.md` / `product-cases.md` — 功能规格同步
- `product-glossary.md` — 术语一致性
- `product-business.md` — 商业模式影响

**技术主链**：
- `docs/tech/architecture.md` — 架构影响
- `docs/tech/compliance.md` — 合规边界变更
- `docs/tech/non-functional-requirements.md` — 性能/内存/可用性边界
- `docs/tech/deployment.md` — 合规/NFR 改动触发的发布口径变化

### Step 3: ADR 更新

- 重大决策（影响架构、商业模式、数据模型）→ 创建新 ADR 或更新已有 ADR
- 格式：`docs/decisions/ADR-NNN-<slug>.md`

### Step 4: Issue 关闭

```bash
gh issue close <number> --comment "决策已落地：<简述>"
```

关联 Issue 更新状态并关闭。

### Step 5: STATUS.md 更新

更新 STATUS.md 的产品决策记录表和当前状态。

## 上报

完成后输出变更传播报告：

```markdown
## 决策变更收尾完成

**决策**: <简述>
**影响范围**: <N 个文档>
- [x] requirements / design / cases 已同步
- [x] glossary 术语一致
- [x] ADR 已更新（或 N/A）
- [x] Issue #N 已关闭
- [x] STATUS.md 已更新
```

## 上游文档

- `docs/workflow.md` § 决策变更收尾 — 完整 5 步流程权威定义
- `docs/DOC_DEPENDENCY_MAP.md` — 变更传播规则
- `dependency-propagation` skill（`.claude/skills/dependency-propagation/`）— 文档下游同步执行器
