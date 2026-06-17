---
id: feat-review
title: 回顾（SM-2 间隔调度）
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-06-17
intent_refs:
  - vision:P2
  - vision:P3
  - vision:P5
  - ADR-001
---

# Feature: 回顾（SM-2 间隔调度）

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：用户扫描、整理后的资料需要一个低摩擦的回看机制，避免重要内容只被归档而不再被处理。SM-2 间隔调度让资料库具备持续复用价值。
- **定位**：回顾是**可选留存层 / 免费附加值**，不是产品核心，**不向儿童学习、打卡或游戏化记忆工具靠拢**；若复杂度开始挤压采集/管理/导出主路径，以 vision P2 简洁裁决。
- **原则归属**：P3 免费层完成核心闭环（核心永久免费、回顾为免费附加值）+ P5 成人生产力工具（零学习曲线、不贩卖焦虑）。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **SM-2 间隔回顾**：翻卡 + 滑动评估（有印象 / 没印象）。
- **Dashboard 回顾字段**（基础统计免费；口径由 Review 定义、Dashboard 仅消费）：
  - 资料总数；**待回顾数 = `ReviewItem.dueDate ≤ now` 且资料未软删**；**已回顾数 = 至少 1 次 SM-2 评估**；今日新增；各分类分布。
  - 时间序列 / 高级统计为 Pro，见 `../backlog/feat-advanced-stats.md`。
- **复习卡片外观设置**：正/反面字号独立、对齐三选项（默认左对齐）、实时预览。
- **提醒**：默认不推送通知；用户可在设置开启频率（选择权交用户）。
- **边界 / 不做**：不做打卡、连续天数、成就弹窗；回顾入口在信息架构中不得压过采集与题库。
- **前置依赖**：无。Review 是**被依赖方**——`feat-smartpaper`、`feat-advanced-stats` 依赖 Review 产出的 SM-2 数据。
- **商业分层**：基础 SM-2 回顾 = 免费附加值，不做付费墙；SM-2 数据**驱动**的智能组卷 / 高级统计是 Pro（定价见 `../../explanations/business-model.md`）。

## 3. 技术设计 (How)
- **模块归属**：SM-2 引擎 `SnapDrillCore`（`ReviewScheduler` / `SM2State`）；Dashboard 聚合 `SnapDrillFeatureDashboard`。
- **关键机制 / 数据流**：评估依结果更新该资料的 `easeFactor / interval / nextReviewAt` 并推进下一条；正面 = 原内容（图文，**必须显示图片**，尤其图形资料），背面 = 参考答案/备注；左滑/没印象、右滑/有印象，**手势必有等价按钮**（HIG）；答案缺失仍可翻面评估。
- **State & Concurrency**（Swift 6 strict）：复习 View 由 `@Observable` ViewModel（`@MainActor`）驱动；SM-2 状态更新经 Repository → `DataExecutor`（actor）落库，不阻塞主线程；每次评估**即时持久化**（不缓存到本轮结束）。
- **回顾 UI 可达性约束**：翻卡"有印象/没印象"为主观回忆自评，UI 必须低门槛、可达——大字号、清晰可点按钮、手势必有等价按钮（HIG 无障碍基线，承接 vision P5「无障碍是基础质量」）。重构回顾 UI 不得退化此可达性（缩小按钮 / 去掉按钮等价 = 退化）。
- **设计裁决（仅本模块）**：滑动手势 vs 系统返回 edge-swipe 冲突——复习场景卡片简洁性权重高于 P6 原生优先，**仅本模块裁决、不外推**；其他模块手势冲突仍走全局 P1>…>P6。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：Given 有到期资料，When 进入 Review 并对每张卡翻面后评估（有印象/没印象，手势或按钮），Then SM-2 状态更新并推进下一张；全部完成后展示摘要（"N 条有印象，M 条需回看"）并返回。
- **边界 / 异常**：
  - 无到期资料 → Dashboard 与 Review 空状态，不进空白卡片流（Boundary B19）。
  - 某题缺答案 → 允许翻面进空答案状态，仍可评估。
  - **软删除 × 回顾队列**：资料软删除（5s undo 窗口）→ 立即从到期队列移除；undo 恢复 → 回顾状态一并恢复；过窗口永久删除 → 其 `ReviewItem` 随资料级联清理。
    - **⚠ 实现现状（GAP-R1，代码债）**：当前 `ReviewViewModel.loadDataAsync()` 已在加载队列时排除 `DeletionScheduler.pendingDeletionIDs`；但 `.reviewing` 期仍忽略 `reviewDataDidChange` 通知，进行中会话不会被外部删除即时打断。需求不变（应避免已删除资料继续处理），待后续 ViewModel 契约修复。
  - 单题状态更新失败 → 阻止标记"已完成本轮"，提示重试，避免**假完成**。
- **数据保证**：只更新当前 Profile 下被评估资料的回顾状态、不改资料主内容；每次评估只落库一次（重复手势/点击不得双重更新）；结果摘要必须与本轮成功提交的评估一致。
- **NFR**：卡片大图用降采样加载（`loadDownsampledImage`）控制延迟与内存；因每次评估即时落库，**中途退出不丢已评估进度**（仅未评估题保留到期）。

## 5. Review flagship polish checklist (2026-06-17)

**Scope**：仅处理 Review 屏族（入口概览、回顾会话、卡片正反面、底部动作、完成摘要）及其直接 L10n / a11y 文案。其它屏、发布硬化、bundle 名、TestFlight、Pro 功能、Core/Data/OCR 引擎不在本轮。

**Completion line**：
- 入口概览、加载/错误/空/完成态都应有明确用户反馈，不留空白或“点了没反应”的状态。
- 卡片会话保留“手势 + 等价按钮 + VoiceOver”三条路径；底部动作不得依赖仅红/绿或仅图标理解。
- Review 对外可见文案改为通用受众生产力语义：`回顾 / 没印象 / 有印象 / 已回顾 / 需回看`；避免儿童化、游戏化、打气式语言。
- 视觉与 Library / Capture 的基线一致：系统 grouped 背景、低阴影、清晰分割、适中圆角、克制蓝色强调；移除大面积紫蓝渐变和游戏化成功动效。
- 保留已存在的 VoiceOver 标签、a11y hints、selected traits、`accessibilityIdentifier` 相关路径。
- 若发现需要 ViewModel/Core/Data 新状态才能正确表达，应登记为跨层 blocker，不在本 UI PR 中重写逻辑。
- `swiftlint --strict` 与 `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests` 必须通过。


## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P2 简洁 / P3 免费层完成核心闭环 / P5 成人生产力工具） | 复习是可选留存层、免费附加值；不向 Anki 靠拢、不贩卖焦虑；无障碍是基础质量 |
| 产品政策 / ADR | `../../decisions/ADR-001-smart-paper-analytics-pricing.md`（SM-2 数据驱动的组卷/统计为下游 Pro） | 基础 SM-2 复习免费；SM-2 数据驱动功能为 Pro |
| 待验证假设 | `../../explanations/assumptions.md` H9（可选回顾提升复用价值但不应拖向复杂记忆工具） | 复习使用率与复杂度验证 H9 |
| 验收证据 | §4 验证标准 GWT + AllTests | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（P2 简洁 / P3 免费层完成核心闭环 / P5 成人生产力工具）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（复习作用于旅程 2 归档、旅程 5 整理后的题目；本版本未单列复习旅程）
- 决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（Pro 分层）
- 被依赖：`../backlog/feat-smartpaper.md`、`../backlog/feat-advanced-stats.md`
