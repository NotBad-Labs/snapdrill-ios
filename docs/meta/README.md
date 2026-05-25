---
last_verified: 2026-05-25
layer: pattern
scope: meta
freshness:
  max_age_days: 365
  decay_trigger: [meta_vision_change]
---
# docs/meta/ — 元规则区

> 智能体协作的元规则及其元规则。本目录最顶层文档与产品 vision 平级。

## 活跃文档

| 文件 | 角色 | 备注 |
|---|---|---|
| [M-000-meta-vision.md](./M-000-meta-vision.md) | **Layer 0 顶层宪法**（v1.2 ratified） | 元规则的元规则，≤ 2500 non-whitespace chars 硬上限（user-decision-log #003） |
| [user-decision-log.md](./user-decision-log.md) | 用户裁决日志（append-only） | M-000 §5 规定的机制，含 Overrule 关系记录 |
| [M-001-to-M-006-followup-backlog.md](./M-001-to-M-006-followup-backlog.md) | 10 条 Minor Concerns 归并到下游派生起草 backlog | 4-way sign-off (#004) 产出 |

## 起草模板（已归档至 docs/archive/audits/m000-v2/，#022）

M-000 v2.0 起草过程的 4 个 prompt 模板已归档（路径 C 后元规则起草不再走 round-by-round 模式，改为「task definition → 主笔 → sign-off → ratify」体例 — 参 M-005 v2 / M-003 v1 实证）：

| 原阶段 | 现归档位置 |
|---|---|
| Round 1 入口 | [archive/audits/m000-v2/M-000-input-prompt.md](../archive/audits/m000-v2/M-000-input-prompt.md) |
| Round 2 入口 | [archive/audits/m000-v2/M-000-round2-input.md](../archive/audits/m000-v2/M-000-round2-input.md) |
| Final 主笔 | [archive/audits/m000-v2/M-000-final-prompt.md](../archive/audits/m000-v2/M-000-final-prompt.md) |
| Round 3 入口 | [archive/audits/m000-v2/M-000-round3-review-prompt.md](../archive/audits/m000-v2/M-000-round3-review-prompt.md) |

## 历史归档

M-000 v1.0~v1.2 完整起草过程材料（21 份文件：round 1 草案 + round 2 收敛 + round 3 review + 4-way sign-off + 字数定义裁决 + v1.1/v1.2 一次性任务包 + cross-analysis）归档在：

[docs/archive/research/M-000-meta-vision/](../archive/research/M-000-meta-vision/)

归档原因和清单见 [docs/archive/README.md](../archive/README.md)。

## 层级关系

```
Layer 0: M-000 Meta-Vision（顶层宪法，≤ 2500 non-whitespace chars）
   ↓ 派生
Layer 1: M-001~M-006 元规则（中层，触发场景驱动，4 周试用期）
   ↓ 派生
Layer 2: skill / 配置（长尾，按需加载）
```

M-001~M-006 六项主干及其职能见 M-000 §8。
