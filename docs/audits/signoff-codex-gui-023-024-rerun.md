---
last_verified: 2026-05-26
layer: snapshot
scope: audit
derived_from: [M-005 §A, M-002 §5.2]
freshness:
  max_age_days: 180
  decay_trigger: [meta_audit, rerun_requested]
---

# Codex GUI Sign-off RERUN — #023 + #024 (BLOCK 修复后)

## Verdict 总览

整体 verdict: BLOCK

4 项已修复，1 项残留 BLOCK：M-005 §G.6「状态明示」第一段仍把 proposed → optional → core 的门槛写乱，与同节后续升级路径矛盾。

## 5 项修复验证

### B1 PASS

`.claude/skills/app-description-writer/SKILL.md` 与 `.claude/skills/screenshot-planner/SKILL.md` 均已改为 `derived_from: [M-003 §11.1]`，符合 M-000 §11.10 array schema。

### B2 PASS

`docs/audits/proposed-check-derived-from-required.md` 已存在，包含目的、事故来源、风险模型、检测方法、误报率估算、预期消费端、四阶段升级路径与异源评估状态。满足 §G.4 proposed-check 文档要求。

### B3 PASS

M-005 §G.6 检测方法第 1 步已写明扫描 `docs/**/*.md` 时排除 `docs/product/**`、`docs/archive/**`、`docs/tech/**`，且说明 `docs/tech/**` 为 §11.7 产品支撑路径硬豁免，不依赖 scope 字段。

### B4 BLOCK

M-000 §11.10 已清楚写明 `derived_from_required` 当前为「设计 ratify，未实施于 docaudit」。但 M-005 §G.6 状态明示第一段仍写：`docaudit` 子命令 + `execution-gates` 登记 + ≥3 次审计运行 + 30 天观测 + 误报率 <20% 后方进入可选 check 列表。该句把 §G.4 的 core 升级条件误写成 optional 入列条件；同节后文又写第二阶段 optional、第三阶段升 core，内部矛盾。

### C1 PASS

`docs/audits/skill-audit-final.md` frontmatter 已改为 `derived_from: [M-003, M-002]`，与 §11.5「M-003 实证锚（M-002 派生）」一致。

## 残留 concern（如有）

- 仅 B4 残留：把 M-005 §G.6 状态明示第一段改为「实现 docaudit + execution-gates + ≥1 家异源评估后进入 optional；≥3 次审计运行 + 30 天 + 误报率 <20% 后再升 core」。

## 最终结论

BLOCK → 残留 BLOCK 为 M-005 §G.6 状态明示流程门槛表述错误。
