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
| [M-000-meta-vision.md](./M-000-meta-vision.md) | **Layer 0 顶层宪法**（v1.0 定稿，v1.1 修订中） | 元规则的元规则，≤ 2000 字硬上限（2026-05-22 Overrule 1500） |
| [user-decision-log.md](./user-decision-log.md) | 用户裁决日志（append-only） | M-000 §5 规定的机制，含 Overrule 关系记录 |

## 起草模板（pattern layer）

未来 M-001~M-005 起草可复用这套四步流程：

| 阶段 | 模板 | 用途 |
|---|---|---|
| Round 1 入口 | [M-000-input-prompt.md](./M-000-input-prompt.md) | 用户口述原话 + 议题清单（多家独立起草启动包）|
| Round 2 入口 | [M-000-round2-input.md](./M-000-round2-input.md) | 冲突匿名化二次思考收敛 |
| Final 主笔 | [M-000-final-prompt.md](./M-000-final-prompt.md) | 已收敛决策 + 异源主笔起草任务包 |
| Round 3 入口 | [M-000-round3-review-prompt.md](./M-000-round3-review-prompt.md) | v1.0 定稿后三方独立 review |
| v1.1 修订 | [M-000-v1.1-prompt.md](./M-000-v1.1-prompt.md) | round 3 用户 24 项裁决落实任务包 |
| v1.2 微调 | [M-000-v1.2-prompt.md](./M-000-v1.2-prompt.md) | 字数定义 B+ 精化（user-decision-log #003） |

## Round 3 Review 产物（v1.0 已发布后的独立 review）

| 文件 | Reviewer |
|---|---|
| [M-000-round3-review-codex.md](./M-000-round3-review-codex.md) | Codex (GPT-5.5 Thinking) |
| [M-000-round3-review-antigravity.md](./M-000-round3-review-antigravity.md) | Antigravity (Gemini) |
| [M-000-round3-review-claude-desktop-code.md](./M-000-round3-review-claude-desktop-code.md) | Claude Desktop Code (Opus 4.7 同源) |
| [M-000-round3-review-deepseek.md](./M-000-round3-review-deepseek.md) | DeepSeek V4-Pro (zero-context API) |
| [M-000-round3-analysis.md](./M-000-round3-analysis.md) | Round 3 收敛分析（中立主笔 Claude CLI） |
| [M-000-字数定义-multi-agent-裁决.md](./M-000-字数定义-multi-agent-裁决.md) | v1.1 后字数计量单位多家裁决（DeepSeek C / Codex B / Gemini 3.5 Flash GA B / 3:1 B） |

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
