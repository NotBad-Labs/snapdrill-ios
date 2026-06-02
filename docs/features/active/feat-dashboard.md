---
id: feat-dashboard
title: 首页概览（Dashboard）
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-06-02
---

# Feature: 首页概览（Dashboard）

> 人读摘要派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 扫描各 spec 的 frontmatter **自动生成**，禁止手改（pre-commit 校验）。
> 本 spec 高内聚承载该功能 Why / What / How / Verify，不拆散到多文件（docs 重组 B）。
> 本文件于 2026-06-02 由 Batch 2 审计补建——Dashboard 代码先行存在而无 owning spec（孤儿代码，KI-03），多个 active spec（review / library / capture）消费其统计口径却无归属定义；本 spec 据 `DashboardView` / `DashboardViewModel` 实证补齐。**仅覆盖免费基础首页**；高级统计（学科趋势/难度分布/薄弱排行，Pro）归 `../backlog/feat-advanced-stats.md`。

## 1. 为什么做 (Why) — 纯 why，不混实现/UI 细节
- **痛点 / 价值**：家长打开 App 需要一眼看到「孩子练习题攒了多少、今天有没有要复习的、今天新录了几道」，把分散的题库/复习状态收敛成一个概览入口，降低导航成本。首页是「看数据 → 出卷子/复习 → 看进步」闭环的起点与回归点。
- **定位与原则归属**：首页是核心价值链（采集 > 管理 > 导出/打印）的**导航与状态聚合层**，本身不承载业务写操作；对应 `../../explanations/vision.md` 导航极简原则（P2）——首页只做概览 + 跳转，不堆砌功能。复习是独立附加值，首页给其显著入口但不喧宾夺主。

## 2. 需求规则 (What) — 用户可感知的规则与边界
- **核心能力**：
  - **概览统计（免费）**：题库总数（`totalCount`）、今日新增题数（`todayItemsCount`）、今日待复习题数（`dueCount`）、今日已复习题数（`reviewedTodayCount`）；口径由 `feat-review` / `feat-library` 定义，首页只读消费、不重新定义。
  - **复习入口（Hero）**：突出展示当前待复习状态，一键进入复习流（承接 `feat-review`）。
  - **空状态引导**：题库为空时不显示空白卡片，展示「采集第一道题」引导（降低首启迷失）。
  - **草稿恢复入口**：检测到未保存草稿时，首页发起采集前弹窗提示恢复 / 新建（承接 `feat-capture` 的 `CaptureDraftService`）。
  - **字段管理入口**：提供学科管理器等配置入口跳转（归属 `feat-library`）。
- **边界 / 不做**：
  - **不做高级统计**：学科趋势 / 难度分布 / 薄弱学科排行 = Pro 高级统计，归 `../backlog/feat-advanced-stats.md`（阻塞 #479），不在免费首页展开。
  - 首页不承载题目的增删改（写操作在采集/题库/复习），仅概览 + 跳转。
  - 统计口径不在本 spec 重新定义——以被消费 feature 的 spec 为准，避免口径分裂。
- **前置依赖**：`feat-review`（SM-2 待复习 / 已复习口径）、`feat-library`（题库总数与字段管理）、`feat-capture`（草稿恢复 + 采集入口）。
- **商业分层**：基础概览首页 = **免费**；高级统计 = Pro（见 `../backlog/feat-advanced-stats.md`，定价见 `../../explanations/business-model.md`）。

## 3. 技术设计 (How) — 只放实现机制，不放商业/上位 why
- **模块归属**：`Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard`（`DashboardView` / `DashboardViewModel` / `ReviewHeroCard` / `BentoCard` / `HeaderView` / `DashboardRouter`）。高级统计的 `DashboardAnalyticsView` / `DashboardAnalyticsViewModel` 同目录但归 Pro spec。新增 `@Model`：无（统计经 Repository 聚合既有题目 / `ReviewItem`）。
- **关键机制 / 数据流**：`DashboardViewModel.loadData()` 经 `RepositoryContainer.review` 取 `fetchTodayCount()` / `totalItemCount()` / 到期数 → 写入 `@Observable` 计数属性 → SwiftUI 渲染 BentoCard 网格 + Hero。跨模块刷新经 `Notification.Name.reviewDataDidChange` 触发增量刷新（采集/复习/删除后首页自动更新）。
- **State & Concurrency**（Swift 6 strict）：首页状态归 `DashboardViewModel`（`@Observable`，`@MainActor`）；统计读取经 Repository → `DataExecutor`（actor）取数，不阻塞主线程；`reviewDataDidChange` 观察用 `Task` 去抖（`dataChangeTask` / `pendingRefreshTask`），退出时 `cancelTasks()` 释放。
- **设计裁决**：无（首页为只读聚合，复用既有 Repository 与通知机制，无对全局原则的局部例外）。

## 4. 验证标准 (Verify) — GWT 风格，不复述 How 的交互细节
- **Success path (GWT)**：Given 当前 Profile 有题目，When 用户进入首页，Then 展示题库总数 / 今日新增 / 今日待复习 / 今日已复习四项概览 + 复习 Hero，点击 Hero 可进入复习流；采集/复习/删除后回到首页，统计经 `reviewDataDidChange` 自动刷新。
- **边界 / 异常**：
  - 题库为空 → 不进空白卡片流，展示「采集第一道题」空状态引导（与 `feat-review` 空状态一致，Boundary B19）。
  - 存在未保存草稿且用户发起采集 → 弹窗提示恢复 / 新建（承接 `feat-capture`）。
  - 统计读取失败（SwiftData 错误）→ 不崩溃、不显示假数据，保留上次成功值或零值，下次刷新重试。
- **数据保证**：首页为**只读聚合**，不产生 / 修改任何题目或复习记录；统计口径与被消费 feature（review / library）一致，不在首页层制造口径分裂；仅展示当前 Profile 数据，Profile 切换后重新加载。
- **NFR**：首页加载与刷新不阻塞主线程；`reviewDataDidChange` 刷新去抖避免高频抖动；无额外埋点要求（高级统计埋点归 Pro spec）。

## Provenance（迁移期审计用，全量封板后可删）
| 本 spec 内容 | 来源 |
|---|---|
| 全文 | Batch 2 审计（KI-03）据 `DashboardView` / `DashboardViewModel` 代码实证补建（孤儿代码补 owning spec）；口径引用 `feat-review` / `feat-library` / `feat-capture` |
| 高级统计边界 | `../backlog/feat-advanced-stats.md`（Pro，阻塞 #479） |

## 关联
- 原则：`../../explanations/vision.md`（导航极简 / 核心价值链）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 相关 / 依赖 feature：`feat-review.md`（SM-2 待复习/已复习口径）、`feat-library.md`（题库总数 / 字段管理）、`feat-capture.md`（草稿恢复 / 采集入口）、`../backlog/feat-advanced-stats.md`（Pro 高级统计延伸）
