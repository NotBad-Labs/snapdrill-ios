---
last_verified: 2026-05-21
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
| [M-000-meta-vision.md](./M-000-meta-vision.md) | **Layer 0 顶层宪法**（v1.0 定稿） | 元规则的元规则，≤ 1500 字硬上限 |

> `user-decision-log.md`（append-only 用户裁决日志）由 M-000 §5 规定，首次用户裁决时创建，未创建前不引用避免 broken link。

## 起草模板（pattern layer）

未来 M-001~M-005 起草可复用这套四步流程：

| 阶段 | 模板 | 用途 |
|---|---|---|
| Round 1 入口 | [M-000-input-prompt.md](./M-000-input-prompt.md) | 用户口述原话 + 议题清单（多家独立起草启动包）|
| Round 2 入口 | [M-000-round2-input.md](./M-000-round2-input.md) | 冲突匿名化二次思考收敛 |
| Final 主笔 | [M-000-final-prompt.md](./M-000-final-prompt.md) | 已收敛决策 + 异源主笔起草任务包 |
| Round 3 入口 | [M-000-round3-review-prompt.md](./M-000-round3-review-prompt.md) | v1.0 定稿后三方独立 review |

## 历史草案

完整起草过程材料（4 份 round 1 草案 + 4 份 round 2 草案 + 2 份 cross-analysis）归档在：

[docs/archive/research/M-000-meta-vision-roundtrip-20260521/](../archive/research/M-000-meta-vision-roundtrip-20260521/)

归档原因见 [docs/archive/README.md](../archive/README.md)。

## 层级关系

```
Layer 0: M-000 Meta-Vision（顶层宪法，≤ 1500 字）
   ↓ 派生
Layer 1: M-001~M-005 元规则（中层，4 周试用期）
   ↓ 派生
Layer 2: skill / 配置（长尾，按需加载）
```

M-001~M-005 五项主干及其职能见 M-000 §8。
