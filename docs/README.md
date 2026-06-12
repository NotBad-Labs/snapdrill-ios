# SnapDrill 文档

> 采用 **feature-spec 一元化 + Diátaxis 分层**（docs 重组 B，2026-05-30）。
> 单个功能的 Why / What / How / Verify 高内聚在一个 feature spec；跨功能的解释/参考/操作按 Diátaxis 分层。
>
> **当前事实入口**：先读根 `README.md` 的“当前状态”与根 `AGENTS.md`。冲突时遵循 `PO 最新决策 > 当前代码/构建实证 > 当前入口文档 > feature spec/ADR > 私有记忆/历史研究`。`research/` 与旧审计保留 provenance，不是当前状态源。

## 结构

- **`features/`** — 功能规格（一元化，每功能一文件，承载 Why/What/How/Verify）
  - `active/` — 已实现功能
  - `backlog/` — 未实现/阻塞功能（`mode: lightweight`，How/Verify 待实现补）
  - `features/template.md` — 新建 feature spec 模板
- **`explanations/`** — 为什么（vision 愿景 / design-principles 设计原则 / business-model 商业模式 / architecture 架构 / assumptions 待验证假设 / competitive-analysis 竞品 / user-journeys 用户旅程 / privacy-compliance 隐私合规）
- **`reference/`** — 查阅（feature-status 功能状态 SSOT / glossary 术语 / analytics-events 埋点 / apple-platform-limits 平台边界 / non-functional-requirements NFR / scope-and-roadmap 范围路线 / api-pitfalls / appstore-metadata ASO）
- **`how-to/`** — 操作指南（**shape-up 我们怎么工作·Shape Up 单人版** / release-and-ci 发布与 CI）
- **`pitches/`** — Shape Up pitch（每个周期的赌注，5 段：Problem/Appetite/Solution/Rabbit holes/No-gos）
- **`decisions/`** — 架构决策记录（ADR-001~005）

## 关键入口

| 我想… | 去 |
|---|---|
| **看当前生产基线 / 产品定位 / 已落地架构事实** | 根 `README.md` + 根 `AGENTS.md` |
| **看三路 agent 的文件边界与交接方式** | `how-to/parallel-lanes.md` |
| **怎么工作 / 决定下一步做什么** | **`how-to/shape-up.md`**（Shape Up 单人版：shaping→betting→building→cool-down + 当前赌注 + Parked）|
| 看当前周期在赌什么 | `pitches/`（最新 pitch = 当前 cycle 的 bet）|
| 看某功能完整规格 | `features/active\|backlog/feat-*.md` |
| 查所有功能当前状态 | `reference/feature-status.md`（自动生成，**勿手改**）|
| 理解产品为什么这么做 | `explanations/vision.md` + `explanations/design-principles.md` |
| 新建一个功能规格 | 复制 `features/template.md` |
| 看商业化 / 定价 | `explanations/business-model.md` |
| 发布上架流程 | `how-to/release-and-ci.md` |
| 架构决策依据 | `decisions/ADR-*.md` |

## 状态单一真理源（B 方案 · 自动单写）

功能状态写在各 feature spec 的 frontmatter（`status` / `tier` / `blocked_by` / `mode`）；`reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 扫描 frontmatter **自动生成**。

改状态 = 改对应 spec 的 frontmatter → 重跑 `python3 Scripts/generate_feature_status.py`（pre-commit 自动校验是否最新）。
