---
id: feat-advanced-stats
title: 高级统计（候选，商业分层未定）
status: backlog
tier: undecided
blocked_by: []
mode: lightweight
last_updated: 2026-07-12
intent_refs:
  - vision:P3
  - vision:P5
release_refs:
  - release-1:section-7
---

# Feature: 高级统计（候选，商业分层未定）

> 人读摘要：📋 候选 backlog，产品范围与商业分层未定；旧 #479 不再是产品重入条件。派生自上方 frontmatter；frontmatter 仅是本功能候选实现状态的单一来源，不构成产品批准或发布承诺。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys / ADR-001 / architecture 聚合（docs 重组 B）。
> `mode: lightweight`（backlog）：How / Verify 仅承载当前已确认事实，未实现/未定的不编造。
>
> **商业规范偏差（2026-07-12）**：Product Constitution B6-A 已取代 ADR-001 的 Pro 分层，frontmatter 已改为 `tier: undecided`。本能力在新的商业裁决与 Release Product Contract 生效前不得实现或公开承诺。

## 1. 候选价值假设 (Why)

- 趋势图、薄弱排行和动态维度交叉筛选可能帮助用户从资料与可选回顾数据中获得决策依据。
- 当前没有外部使用或付费证据；高级统计是否进入产品、与 SmartPaper 是否联动、未来如何商业化均未裁决。
- 若未来回归，数字只显示事实，不做完成度比较或焦虑诱导，也不能抢占核心价值链。

## 2. 候选范围与当前约束 (What)

- 候选能力包括分类趋势、薄弱排行和动态维度 × 时间窗筛选；具体指标、入口与 SmartPaper 联动等待独立 shaping。
- Release 1 不展示模糊预览、Pro 引导、付费锁态或“稍后推出”卡片。当前 Dashboard teaser 是待隐藏实现偏差。
- 若未来回归，只能聚合唯一资料库中可解释的数据；数据不足时不得伪造趋势。
- B6-A 下没有免费 / Pro 分层、订阅取消或价格规则；ADR-001 的 Hybrid 方案仅作历史证据。

## 3. 技术设计 (How)
> backlog · lightweight：以下只记录当前代码位置；产品、入口和商业规则均未获授权。

- **模块归属**：数据源 `SnapDrillData/RepositoryContainer` 各 Repository 聚合查询；聚合层 `SnapDrillFeatureDashboard/DashboardAnalyticsViewModel`；图表渲染用 SwiftUI Charts 框架（iOS 16+，原生可视化）。
- **当前实现偏差**：代码通过 `ProEntitlementProvider` 控制可见性，`isProUser` 当前为 false；该 gating 不构成未来产品要求。
- **State & Concurrency**（Swift 6 strict）：待实现补 / 随 #567 落档（统计聚合查询应走 Repository → `DataExecutor` actor，不阻塞主线程；与 `../active/feat-review.md` Dashboard 字段同一聚合路径——具体 @Observable 归属与 actor 边界以实现为准，避免编造）。

## 4. 验证标准 (Verify)

> 当前不在 Release 1 范围，禁止从本 spec 启动实现。新的 Product / Release Contract 生效后再补 GWT、数据口径、性能与 AX 验收；在此之前唯一用户可见要求是隐藏现有 teaser / upsell。


## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P3 免费层完成核心闭环 / P5 成人生产力工具） | 基础统计永久免费、不锁基础能力；数字只显示事实、不贩卖焦虑 |
| Release 1 Contract | `../../reference/release-1-contract.md` §7 (`release-1:section-7`) | 高级统计是 Release 1 明确非目标；该引用只固定隐藏边界，不表示候选纳入 |
| 产品政策 / ADR | `../../explanations/business-model.md`（B6-A） | 当前无有效 Pro 层；隐藏 teaser / upsell，不公开承诺候选能力 |
| 待验证假设 | `../../explanations/business-model.md` H8 | 验证附加价值，不预设转化模式 |
| 验收证据 | 当前无 Release GWT；等待新 contract | 不把不可达代码当产品 oracle |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（P3 免费层完成核心闭环 / P5 成人生产力工具 · 不贩卖焦虑）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 当前用户旅程：`../../explanations/user-journeys.md`（无高级统计旅程承接；SmartPaper 联动仅是 ADR-001 历史构想）
- 历史决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（已被 B6-A 取代）
- 依赖 / 相关 feature：`../active/feat-review.md`（SM-2 复习数据，被依赖方）、`feat-smartpaper.md`（薄弱排行 → 智能组卷联动）
