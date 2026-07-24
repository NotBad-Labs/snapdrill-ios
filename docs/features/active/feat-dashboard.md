---
id: feat-dashboard
title: 首页概览（Dashboard）
status: in-progress
tier: free
blocked_by: []
mode: full
last_updated: 2026-07-14
intent_refs:
  - vision:P1
  - vision:P2
  - vision:P5
release_refs:
  - release-1:C2-Personalization
  - release-1:C3
  - release-1:C4-D
release_outcomes:
  - M1
  - M10
---

# Feature: 首页概览（Dashboard）

> **Release 1 目标（2026-07-14）**：[Release 1 PRD](../../product/release-1-prd.md) C3 规定普通启动默认进入 Dashboard，并将其收敛为核心任务入口和可执行状态概览；不批准现有卡片或五 Tab。C2-Personalization 隐藏身份装饰，C4-D 只允许 Review 在非公开实验 build 从 Library 次级入口出现。当前实现与该目标仍有偏差，合同生效不单独授权代码修改。

> 人读摘要：🛠 当前实现收敛中（当前分层：free）。派生自上方 frontmatter；frontmatter 仅是本功能实现状态的单一来源，不表示 Release 1 合同符合、公开可达或发布就绪。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 扫描各 spec 的 frontmatter **自动生成**，禁止手改（pre-commit 校验）。
> 本 spec 高内聚承载该功能 Why / What / How / Verify，不拆散到多文件（docs 重组 B）。
> 本文件于 2026-06-02 由 Batch 2 审计补建——Dashboard 代码先行存在而无 owning spec（孤儿代码，KI-03），多个 active spec（review / library / capture）消费其统计口径却无归属定义；本 spec 据 `DashboardView` / `DashboardViewModel` 实证补齐。高级统计代码与历史产品主张归 `../backlog/feat-advanced-stats.md`，不是当前商业承诺。

## 1. 为什么做 (Why) — 纯 why，不混实现/UI 细节
- **痛点 / 价值**：用户回到 App 时需要直接开始或恢复采集、找回最近资料，并进入资料库，而不是先理解统计或身份体系。Dashboard 把这些高频任务收敛为稳定起点，降低在多个功能区之间判断下一步的成本。
- **定位与原则归属**：首页是核心价值链（采集 -> 整理 / 找回 -> 导出 / 打印）的**任务入口和可执行状态概览**。Review 是可选复用能力，不能通过首页层级反向变成核心。

## 2. Release 1 规则 (What)
- **默认目的地**：onboarding 完成后的普通启动进入 Dashboard；deep link 和阻塞性 store 恢复可以覆盖。
- **核心入口**：Capture 与 Library 一次操作可达，且在视觉与 accessibility 内容顺序中先于 Review；空资料库一次操作开始 Capture。
- **可执行状态**：可以显示未完成草稿、最近资料和能直接进入对应内容的本地事实。
- **禁止表面**：不显示 Profile / Workspace、昵称 / 头像身份入口、纯趋势 / 比较 / 完成率、Dashboard analytics、Pro / IAP、locked / coming-soon。
- **Review 层级**：不得使用 Review hero、进度环、连续记录或完成庆祝主导首屏；C4-D 的非公开实验入口只位于 Library。
- **当前实现偏差**：`ReviewHeroCard`、`HeaderView` 个性化、四项统计、`DashboardAnalyticsView` 与对应 UI-freeze assertions 只记录当前 build，不是验收 oracle。
- **前置依赖**：Release 1 目标只依赖 `feat-library`（最近资料 / 资料库入口）和 `feat-capture`（草稿恢复 + 采集入口）。当前代码仍读取 `feat-review` 的待回顾 / 已回顾口径，属于 C3 / C4 对齐前的实现依赖，不构成目标架构。
- **商业政策**：B6-A 下 Release 1 免费、无广告、无 IAP；Dashboard 不承担升级转化。未来高级统计是否存在及如何商业化均未裁决。

## 3. 当前实现证据 (How) — 非 Release 1 目标设计

> 本节只解释为什么当前 build 会出现 Review hero / Bento 统计和相应依赖，供实现影响分析；§2 才是 Release 1 目标。

- **模块归属**：`Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard`（`DashboardView` / `DashboardViewModel` / `ReviewHeroCard` / `BentoCard` / `HeaderView` / `DashboardRouter`）。高级统计的 `DashboardAnalyticsView` / `DashboardAnalyticsViewModel` 同目录但属于未获当前范围授权的候选实现。新增 `@Model`：无（统计经 Repository 聚合既有资料 / `ArchiveItemModel`）。
- **关键机制 / 数据流**：`DashboardViewModel.loadData()` 经 `RepositoryContainer.archive` 取 `fetchTodayCount()` / `totalItemCount()` / 到期数 → 写入 `@Observable` 计数属性 → SwiftUI 渲染 BentoCard 网格 + Hero。进入首页（appear）时 `loadData()` 刷新统计；前台运行期间经 `Notification.Name.reviewDataDidChange` 去抖增量刷新（observer 在 `init` 建立、`onDisappear` 经 `cancelTasks()` 释放，再次 appear 重新 `loadData()`）。
- **State & Concurrency**（Swift 6 strict）：首页状态归 `DashboardViewModel`（`@Observable`，`@MainActor`）；统计读取经 Repository → `DataExecutor`（actor）取数，不阻塞主线程；`reviewDataDidChange` 观察用 `Task` 去抖（`dataChangeTask` / `pendingRefreshTask`），退出时 `cancelTasks()` 释放。
- **实现处置**：Bento / Hero 数据流不得因已经存在而反向扩大 C3；只有实现刀另获授权后，才以任务入口和可执行状态重新选择最小读取集合。
- **已登记实现 blocker**：当前 `DashboardViewModel` 的统计读取失败只记录日志，未向 View 暴露 error state；这是既有 cross-layer blocker，不因本次目标重写而丢失，也不表示对应修复或测试已经存在。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：Given onboarding 已完成且没有 deep link / 阻塞恢复，When 用户普通启动 App，Then 到达 `dashboard.root`，并能一次操作进入 Capture 与 Library；Given 资料库为空，When 用户进入首页，Then 一次操作开始 Capture。
- **边界 / 异常**：
  - 资料库为空 → 不进空白卡片流，展示「采集第一条资料」空状态引导（Boundary B19）。
  - 存在未保存草稿且用户发起采集 → 弹窗提示恢复 / 新建（承接 `feat-capture`）。
  - 统计读取失败（SwiftData 错误）→ 不崩溃、不显示假数据，保留上次成功值或零值，下次刷新重试。
- **数据保证**：首页只展示唯一资料库状态；导航本身不产生 / 修改资料或回顾记录。草稿恢复 / 丢弃等有副作用动作继续由 Capture 的既有确认流程拥有，不由 Dashboard 自行实现。
- **NFR**：首页加载与刷新不阻塞主线程；`reviewDataDidChange` 刷新去抖避免高频抖动；无额外埋点要求。


## 5. Release 1 PRD（首页概览 / 统计 / 锁态）

### A. 首页状态与导航

- Dashboard 必须区分 loading / empty / content / error 四类状态；读取失败不得展示伪造数据。
- 空状态应引导用户去采集或导入资料，不使用教育化、儿童化或游戏化激励。
- 普通启动、Capture / Library 一次操作可达和 forbidden-surface 缺席必须有 UI / AX 断言。

### B. 统计与不可用能力隐藏

- 首页只展示能进入对应内容的本地事实；Release 1 不展示趋势、完成率、高级统计、Pro、付费或“稍后推出”锁态。
- 隐藏候选能力不得阻断免费核心闭环，也不得暗示当前用户数据已经上传或云端分析。

### C. 导航与共享 L10n

- Capture / Library 入口只做导航；草稿恢复 / 丢弃使用 Capture 拥有的确认流程，不由 Dashboard 静默执行。
- 已知共享 key：`L10n.Library.categoryManager` 被 Dashboard 使用。后续应迁入 Common/Shared 或显式登记共享。

### D. Enforcement

| 契约项 | Enforcement |
|---|---|
| Dashboard 四态 | 计划中的 UI review + ViewModel error-state test；当前 error state 是 blocker |
| 默认启动 + 一步入口 | 计划中的 UI tests：`dashboard.root` -> `capture.root` / `library.root` |
| 禁止表面缺席 | 计划中的 UI / AX assertions + 文案 grep |
| 导航不静默写入 | 计划中的 UI test + Capture draft confirmation tests |
| 共享 L10n 归属 | 批量 L10n 归属整理 PR |

## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../product/vision.md`（P1 采集摩擦最低 / P2 简洁 / P5 成人生产力工具） | 首页直接服务采集、续作和找回，不用统计或可选 Review 主导入口 |
| Release 1 PRD | `../../product/release-1-prd.md` C2-Personalization / C3 / C4-D | 普通启动默认 Dashboard；Capture / Library 一步可达；禁止 Profile / Pro / analytics / Review hero |
| 产品政策 / ADR | `../../explanations/business-model.md`（B6-A：Release 1 免费、无广告、无 IAP） | 隐藏高级统计、Pro 与“稍后推出”锁态，不承担升级转化 |
| 待验证假设 | 无（只读聚合，不独立验证假设） | — |
| 验收证据 | §4 验证标准 GWT + AllTests | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../product/vision.md`（导航极简 / 核心价值链）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 相关 / 依赖 feature：`feat-review.md`（SM-2 待回顾/已回顾口径）、`feat-library.md`（资料库总数 / 字段管理）、`feat-capture.md`（草稿恢复 / 采集入口）、`../backlog/feat-advanced-stats.md`（未获当前范围授权的候选）
