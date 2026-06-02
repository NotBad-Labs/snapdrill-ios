---
id: feat-review
title: 复习（SM-2 间隔重复）
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-05-30
---

# Feature: 复习（SM-2 间隔重复）

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：用户辛苦录入的题目若不复用就"白录了"。SM-2 间隔重复让题库产生持续留存价值——录了能复习、复习有节奏。
- **定位**：复习是**可选留存层 / 免费附加值**，不是产品核心，**不向 Anki 式记忆工具靠拢**；若复习复杂度开始挤压采集/管理/导出主路径，以 vision P2 简洁裁决。
- **原则归属**：P3 免费附加值（核心永久免费）+ P5 家长友好（零学习曲线、不贩卖焦虑）。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **SM-2 间隔重复复习**：翻卡 + 滑动评估（记得 / 不记得）。
- **Dashboard 复习字段**（基础统计免费；口径由 Review 定义、Dashboard 仅消费）：
  - 题目总数；**待复习数 = `ReviewItem.dueDate ≤ now` 且题目未软删**；**已复习数 = 至少 1 次 SM-2 评估**；今日新增；各学科分布。
  - 时间序列 / 高级统计为 Pro，见 `../backlog/feat-advanced-stats.md`。
- **复习卡片外观设置**：正/反面字号独立、对齐三选项（默认左对齐）、实时预览。
- **提醒**：默认不推送通知；用户可在设置开启频率（选择权交用户）。
- **边界 / 不做**：不做打卡、连续天数、成就弹窗；复习入口在信息架构中不得压过采集与题库。
- **前置依赖**：无。Review 是**被依赖方**——`feat-smartpaper`、`feat-advanced-stats` 依赖 Review 产出的 SM-2 数据。
- **商业分层**：基础 SM-2 复习 = 免费附加值，不做付费墙；SM-2 数据**驱动**的智能组卷 / 高级统计是 Pro（定价见 `../../explanations/business-model.md`）。

## 3. 技术设计 (How)
- **模块归属**：SM-2 引擎 `SnapDrillCore`（`ReviewScheduler` / `SM2State`）；Dashboard 聚合 `SnapDrillFeatureDashboard`。
- **关键机制 / 数据流**：评估依结果更新该题 `easeFactor / interval / nextReviewAt` 并推进下一题；正面 = 原题（图文，**必须显示图片**，尤其几何题），背面 = 答案；左滑/不记得、右滑/记得，**手势必有等价按钮**（HIG）；答案缺失仍可翻面评估。
- **State & Concurrency**（Swift 6 strict）：复习 View 由 `@Observable` ViewModel（`@MainActor`）驱动；SM-2 状态更新经 Repository → `DataExecutor`（actor）落库，不阻塞主线程；每次评估**即时持久化**（不缓存到本轮结束）。
- **H2-SM2 假设约束**：翻卡"记得/不记得"主观评估**由孩子本人完成**，故 UI 必须支持低龄儿童独立操作——大字号、清晰可点按钮、手势必有等价按钮。重构复习 UI 不得违反此假设（缩小按钮 = 踩假设）。关联 requirements H2-SM2。
- **设计裁决（仅本模块）**：滑动手势 vs 系统返回 edge-swipe 冲突——复习场景卡片简洁性权重高于 P6 原生优先，**仅本模块裁决、不外推**；其他模块手势冲突仍走全局 P1>…>P6。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：Given 有到期题，When 进入 Review 并对每张卡翻面后评估（记得/不记得，手势或按钮），Then SM-2 状态更新并推进下一张；全部完成后展示摘要（"N 题掌握，M 题待加强"）并返回。
- **边界 / 异常**：
  - 无到期题 → Dashboard 与 Review 空状态，不进空白卡片流（Boundary B19）。
  - 某题缺答案 → 允许翻面进空答案状态，仍可评估。
  - **软删除 × 复习队列**：题目软删除（5s undo 窗口）→ 立即从到期队列移除；undo 恢复 → 复习状态一并恢复；过窗口永久删除 → 其 `ReviewItem` 随题目级联清理。
    - **⚠ 实现现状（GAP-R1，代码债）**：当前 `ReviewViewModel` 在 `.reviewing` 期忽略 `reviewDataDidChange` 通知，且 `ReviewRepository.fetchDue` 未过滤 `DeletionScheduler.pendingDeletionIDs`——5s 窗口内已软删除的到期题仍可能出现在进行中的复习流。需求不变（立即移除），待 code 债修复（追踪见 `../../explanations/development-process.md` §5）。
  - 单题状态更新失败 → 阻止标记"已完成本轮"，提示重试，避免**假完成**。
- **数据保证**：只更新当前 Profile 下被评估题目的复习状态、不改题目主内容；每次评估只落库一次（重复手势/点击不得双重更新）；结果摘要必须与本轮成功提交的评估一致。
- **NFR**：卡片大图用降采样加载（`loadDownsampledImage`）控制延迟与内存；因每次评估即时落库，**中途退出不丢已评估进度**（仅未评估题保留到期）。

## Provenance（迁移期审计用，全量封板后可删）
| 本 spec 内容 | 来源（旧文档章节 / UC / ADR） |
|---|---|
| Why（定位 / 不做 Anki / P3·P5） | vision 产品原则 P2/P3/P5 + business 复习定位 |
| What（SM-2 / Dashboard 字段 / 外观 / 提醒 / 分层） | requirements §Dashboard + §功能全景·复习 + business |
| What · H2-SM2 假设 | requirements §待验证假设 H2-SM2 |
| How（机制 / 交互 / 裁决） | design §复习设计 |
| Verify（success / 边界 / 数据保证 / 软删除） | cases UC4 + Boundary B19 |

## 关联
- 原则：`../../explanations/vision.md`（P2 简洁 / P3 免费 / P5 家长友好）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 5：复习到期题目）
- 决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（Pro 分层）
- 被依赖：`../backlog/feat-smartpaper.md`、`../backlog/feat-advanced-stats.md`
