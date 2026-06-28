---
id: feat-dashboard
title: 首页概览（Dashboard）
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-06-23
intent_refs:
  - vision:P2
  - vision:P5
---

# Feature: 首页概览（Dashboard）

> 人读摘要派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 扫描各 spec 的 frontmatter **自动生成**，禁止手改（pre-commit 校验）。
> 本 spec 高内聚承载该功能 Why / What / How / Verify，不拆散到多文件（docs 重组 B）。
> 本文件于 2026-06-02 由 Batch 2 审计补建——Dashboard 代码先行存在而无 owning spec（孤儿代码，KI-03），多个 active spec（review / library / capture）消费其统计口径却无归属定义；本 spec 据 `DashboardView` / `DashboardViewModel` 实证补齐。**仅覆盖免费基础首页**；高级统计（分类趋势/薄弱排行/待回顾较多分类，Pro）归 `../backlog/feat-advanced-stats.md`。

## 1. 为什么做 (Why) — 纯 why，不混实现/UI 细节
- **痛点 / 价值**：用户打开 App 需要一眼看到「资料 / 文档攒了多少、今天有没有要回顾的、今天新录了几条」，把分散的资料库/回顾状态收敛成一个概览入口，降低导航成本。首页是「看数据 → 回顾 / 整理 → 导出打印」闭环的起点与回归点。
- **定位与原则归属**：首页是核心价值链（采集 > 管理 > 导出/打印）的**导航与状态聚合层**，本身不承载业务写操作；对应 `../../explanations/vision.md` 导航极简原则（P2）——首页只做概览 + 跳转，不堆砌功能。回顾是独立附加值，首页给其显著入口但不喧宾夺主。

## 2. 需求规则 (What) — 用户可感知的规则与边界
- **核心能力**：
  - **概览统计（免费）**：资料库总数（`totalCount`）、今日新增资料数（`todayItemsCount`）、今日待回顾资料数（`dueCount`）、今日已回顾资料数（`reviewedTodayCount`）；口径由 `feat-review` / `feat-library` 定义，首页只读消费、不重新定义。
  - **回顾入口（Hero）**：突出展示当前待回顾状态，一键进入回顾流（承接 `feat-review`）。
  - **空状态引导**：资料库为空时不显示空白卡片，展示「采集第一条资料」引导（降低首启迷失）。
  - **草稿恢复入口**：检测到未保存草稿时，首页发起采集前弹窗提示恢复 / 新建（承接 `feat-capture` 的 `CaptureDraftService`）。
  - **字段管理入口**：提供分类管理器等配置入口跳转（归属 `feat-library`）。
- **边界 / 不做**：
  - **不做高级统计**：分类趋势 / 薄弱排行 / 待回顾较多分类 = Pro 高级统计，归 `../backlog/feat-advanced-stats.md`（阻塞 #479）；首页仅以 **Pro 门控 teaser**（模糊 + 稍后推出 overlay）呈现入口，完整图表为 Pro，免费首页不展开完整统计。
  - 首页不承载资料的增删改（写操作在采集/资料库/回顾），仅概览 + 跳转。
  - 统计口径不在本 spec 重新定义——以被消费 feature 的 spec 为准，避免口径分裂。
- **前置依赖**：`feat-review`（SM-2 待回顾 / 已回顾口径）、`feat-library`（资料库总数与字段管理）、`feat-capture`（草稿恢复 + 采集入口）。
- **商业分层**：基础概览首页 = **免费**；高级统计 = Pro（见 `../backlog/feat-advanced-stats.md`，定价见 `../../explanations/business-model.md`）。

## 3. 技术设计 (How) — 只放实现机制，不放商业/上位 why
- **模块归属**：`Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard`（`DashboardView` / `DashboardViewModel` / `ReviewHeroCard` / `BentoCard` / `HeaderView` / `DashboardRouter`）。高级统计的 `DashboardAnalyticsView` / `DashboardAnalyticsViewModel` 同目录但归 Pro spec。新增 `@Model`：无（统计经 Repository 聚合既有资料 / `ReviewItem`）。
- **关键机制 / 数据流**：`DashboardViewModel.loadData()` 经 `RepositoryContainer.archive` 取 `fetchTodayCount()` / `totalItemCount()` / 到期数 → 写入 `@Observable` 计数属性 → SwiftUI 渲染 BentoCard 网格 + Hero。进入首页（appear）时 `loadData()` 刷新统计；前台运行期间经 `Notification.Name.reviewDataDidChange` 去抖增量刷新（observer 在 `init` 建立、`onDisappear` 经 `cancelTasks()` 释放，再次 appear 重新 `loadData()`）。
- **State & Concurrency**（Swift 6 strict）：首页状态归 `DashboardViewModel`（`@Observable`，`@MainActor`）；统计读取经 Repository → `DataExecutor`（actor）取数，不阻塞主线程；`reviewDataDidChange` 观察用 `Task` 去抖（`dataChangeTask` / `pendingRefreshTask`），退出时 `cancelTasks()` 释放。
- **设计裁决**：无（首页为只读聚合，复用既有 Repository 与通知机制，无对全局原则的局部例外）。

## 4. 验证标准 (Verify) — GWT 风格，不复述 How 的交互细节
- **Success path (GWT)**：Given 当前 Profile 有资料，When 用户进入首页，Then 展示资料库总数 / 今日新增 / 今日待回顾 / 今日已回顾四项概览 + 回顾 Hero，点击 Hero 可进入回顾流；采集/回顾/删除后回到首页（appear）经 `loadData()` 刷新统计；前台运行期间 `reviewDataDidChange` 去抖刷新。
- **边界 / 异常**：
  - 资料库为空 → 不进空白卡片流，展示「采集第一条资料」空状态引导（与 `feat-review` 空状态一致，Boundary B19）。
  - 存在未保存草稿且用户发起采集 → 弹窗提示恢复 / 新建（承接 `feat-capture`）。
  - 统计读取失败（SwiftData 错误）→ 不崩溃、不显示假数据，保留上次成功值或零值，下次刷新重试。
- **数据保证**：首页为**只读聚合**，不产生 / 修改任何资料或回顾记录；统计口径与被消费 feature（review / library）一致，不在首页层制造口径分裂；仅展示当前 Profile 数据，Profile 切换后重新加载。
- **NFR**：首页加载与刷新不阻塞主线程；`reviewDataDidChange` 刷新去抖避免高频抖动；无额外埋点要求（高级统计埋点归 Pro spec）。


## 5. Contracts（首页概览 / 统计 / 锁态）

### A. 首页状态

- Dashboard 必须区分 loading / empty / content / error 四类状态；统计无法加载时不得展示伪造数据。
- 当前实现中 Dashboard 统计 ViewModel 只记录失败日志，未向 View 暴露错误态。本轮 UI 打磨按 PO 决策记录为 cross-layer blocker，不在 UI 层伪造错误状态。
- 空状态应引导用户去采集或导入资料，不使用教育化、儿童化或游戏化激励。

### B. 统计与 Pro 锁态

- 首页统计只展示已可解释、已存在的数据；高级统计锁态必须克制呈现为“稍后推出/高级统计”，不得弹窗诱导付费。
- 锁态卡片不能阻断免费核心闭环，也不能暗示当前用户数据已经上传或云端分析。

### C. 导航与共享 L10n

- Dashboard 的快捷入口只做导航，不启动采集、导出或删除等有副作用操作。
- 已知共享 key：`L10n.Library.categoryManager` 被 Dashboard 使用。后续应迁入 Common/Shared 或显式登记共享。

### D. Enforcement

| 契约项 | Enforcement |
|---|---|
| Dashboard 四态 | UI review + 后续 ViewModel 错误态 blocker |
| 统计不伪造 | 针对性模拟器实测 / ViewModel 数据源 review |
| Pro 锁态克制 | PR review + 文案 grep |
| 快捷入口无副作用 | UI 测试或手动实测 |
| 共享 L10n 归属 | 批量 L10n 归属整理 PR |

## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P2 简洁 / P5 成人生产力工具） | 首页只做状态概览 + 跳转、不堆功能；数字只显示中性事实、不贩卖焦虑 |
| 产品政策 / ADR | 无（高级统计 Pro 见 `../backlog/feat-advanced-stats.md` / `../../decisions/ADR-001-smart-paper-analytics-pricing.md`） | 首页仅以 Pro 门控 teaser 呈现高级统计入口 |
| 待验证假设 | 无（只读聚合，不独立验证假设） | — |
| 验收证据 | §4 验证标准 GWT + AllTests | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（导航极简 / 核心价值链）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 相关 / 依赖 feature：`feat-review.md`（SM-2 待回顾/已回顾口径）、`feat-library.md`（资料库总数 / 字段管理）、`feat-capture.md`（草稿恢复 / 采集入口）、`../backlog/feat-advanced-stats.md`（Pro 高级统计延伸）
