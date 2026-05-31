# SnapDrill 文档

> 采用 **feature-spec 一元化 + Diátaxis 分层**（docs 重组 B，2026-05-30）。
> 单个功能的 Why / What / How / Verify 高内聚在一个 feature spec；跨功能的解释/参考/操作按 Diátaxis 分层。

## 结构

- **`features/`** — 功能规格（一元化，每功能一文件，承载 Why/What/How/Verify）
  - `active/` — 已实现功能
  - `backlog/` — 未实现/阻塞功能（`mode: lightweight`，How/Verify 待实现补）
  - `features/template.md` — 新建 feature spec 模板
- **`explanations/`** — 为什么（vision 愿景 / design-principles 设计原则 / business-model 商业模式 / architecture 架构 / assumptions 待验证假设 / competitive-analysis 竞品 / user-journeys 用户旅程 / privacy-compliance 隐私合规）
- **`reference/`** — 查阅（feature-status 功能状态 SSOT / glossary 术语 / analytics-events 埋点 / apple-platform-limits 平台边界 / non-functional-requirements NFR / scope-and-roadmap 范围路线 / api-pitfalls / appstore-metadata ASO）
- **`how-to/`** — 操作指南（release-and-ci 发布与 CI）
- **`decisions/`** — 架构决策记录（ADR-001~004）

## 关键入口

| 我想… | 去 |
|---|---|
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
