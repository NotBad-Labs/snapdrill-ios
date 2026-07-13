---
id: feat-settings
title: 设置与个性化
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-07-14
intent_refs:
  - vision:P2
  - vision:P4
  - vision:P5
  - ADR-005
---

# Feature: 设置与个性化

> **产品重基线（2026-07-14）**：Release 1 用户可见面隐藏 Profile 管理、昵称、头像、座右铭以及 Review 目标、排序、外观和提醒 / 通知；同时隐藏 Pro、CloudKit、Word 等不可用升级界面。语言与 App 外观是真实通用设置。frontmatter 与技术章节仍记录当前实现，不能把已有身份或 Review 设置反推为获准范围。

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys / 技术文档聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：用户不需要理解 App 内部概念。设置服务于控制权、可理解性和信任，让用户管理语言、外观、本地数据与法律入口，不承担身份塑造、Review 留存或升级转化。
- **海外华人场景**：App 内语言直选（不依赖系统设置）是海外华人用户的核心需求——系统语言英文、内容主要为中文时仍能用中文界面。
- **原则归属**：P5 成人生产力工具（零学习曲线、不贩卖焦虑、中性成熟）+ P2 简洁（设置克制，不堆复杂度）+ P4 用户拥有数据·零注册（个性化资料纯本地、不外传）。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **身份与 Review 设置**：昵称、座右铭、头像、每日回顾目标、回顾排序、卡片外观和提醒 / 通知仍存在于当前代码，但 Release 1 必须隐藏。C4-D 只允许非公开实验 build 从 Library 的一个静态入口进入 Review，不授权第二个 Settings 入口或后台调度。
- **外观模式**：跟随系统（默认）/ 浅色 / 深色三选项。
- **语言设置**：App 内直接切换中文/英文，不依赖系统设置。
- **Release 1 数据与信任入口**：手动完整备份 / 恢复、卸载数据丢失说明、隐私政策、服务条款和开源许可可见，并与实际构建一致。
- **Candidate optional 设置**：字段管理器与 JSON / CSV 导入导出默认隐藏；只有 Release 1 Contract 已列入、冻结 manifest 显式纳入并通过对应数据 / 隐私 / AX 门禁才可见。
- **未获范围授权的当前表面**：媒体缓存清理、帮助中心、角色预设和匿名遥测开关必须隐藏，不能由 manifest 单独纳入；重入需先修改上游 contract。生产仍注入 `NoOpAnalyticsService`，端侧 MetricKit 不由旧遥测开关控制。
- **边界 / 不做**：不在 App 内构建帮助搜索系统；角色预设不进入 Onboarding；用户资料不外传、不做账号体系。现有 Profile 管理入口是 B5-A 已废止的实现遗留，必须隐藏或删除。
- **前置依赖**：无。设置是承载入口的容器层，所托管的导出、备份和字段管理各自有独立 feature spec。
- **商业政策**：B6-A 下 Release 1 免费、无广告、无 IAP；Settings 不展示 Pro、CloudKit、Word 或其他不可用升级入口。当前生产环境没有后端遥测实现。

## 3. 技术设计 (How)
- **模块归属**：`Packages/SnapDrillFeatures/SnapDrillFeatureSettings`（依赖 Library）。通知能力经 `SnapDrillCore` 的 `NotificationServiceProtocol`（ServiceContainer 注入）；复习卡片字号经 `@AppStorage(UDKey.cardFrontFontSize / cardContextFontSize)`，Per-Profile 隔离。
- **关键机制 / 数据流**：
  - 当前代码仍由 `ProfileManager` 通过 `perProfileKeys` 搬运用户资料、复习目标和字段配置等 per-Profile 偏好；Profile scope 必须按 B5-A 收敛，身份字段与 Review 设置按 C2-Personalization / C4-D 隐藏。
  - Onboarding 完成、VoiceOver 等设置为 App 全局状态；当前代码还用“不随 Profile 切换”描述其遗留边界。
  - 当前通知权限延迟请求与 Review 提醒实现只作退场影响证据；C4-D 不允许 Release 1 实验 build 暴露 Settings 提醒或后台调度。
  - 当前媒体缓存清理实现只作用于 `Caches/` 临时文件，绝不触碰 `Documents/` 或 `Application Support/`；Release 1 用户入口隐藏，但底层安全边界仍须由 targeted test 保护。
- **State & Concurrency**（Swift 6 strict）：设置页交互由 `@Observable` `SettingsViewModel`（`@MainActor`）与 `@AppStorage` 驱动；复杂写操作（CSV 导入、备份 / 恢复编排）在 ViewModel 内编排，落库经 Repository → `DataExecutor`（actor），不阻塞主线程。`AppActivityTracker.begin/end` 在长任务期间保护数据一致性；阻止 Profile 切换是当前遗留实现。`SettingsViewModel` 是 `Notification.Name.reviewDataDidChange` 的发布方之一。
- **设计裁决（仅本模块）**：外观提供"跟随系统 / 浅色 / 深色"三选项——HIG 建议跟随系统，但三选项是行业惯例（Telegram / Bear / Notion），Apple 不因此拒审；本裁决仅限外观设置、不外推。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：
  - **B5-A effective 身份边界**：Given 任一候选构建，When 用户浏览全部可达界面，Then 不出现 Profile / Workspace。
  - **Release 1 身份与 Review 边界**：When 用户浏览 Dashboard 与 Settings，Then 不出现昵称、头像、座右铭、Review 目标 / 排序 / 外观 / 提醒或通知入口。
  - **语言切换（贯穿各成人旅程）**：Given 系统语言为英文，When 用户在设置中切换到中文界面，Then App 界面立即变中文且不依赖系统语言设置。
- **边界 / 异常**：
  - 媒体缓存清理入口对 Release 1 候选完全隐藏；若底层实现暂留，targeted test 必须证明它只清 `Caches/`，绝不删除 App-managed 主图、备份文件或 SwiftData 数据（B23, S0）。
- **数据保证**：保留的设置偏好纯本地存储、不外传（与 PV-4 / P4 一致）；暂留缓存清理实现对资料数据零影响。per-Profile 搬运必须按 B5-A 退场；身份字段与 Review 设置的当前实现不构成产品规则。
- **NFR**：VoiceOver 覆盖 Settings 全部可见任务；全球生产环境不含 Firebase 或其他第三方分析 / 崩溃 SDK，逐事件调用由 NoOp 服务丢弃（ADR-005）。
  - **文案约束**：Settings 与隐私政策文案必须继续与发布构建、Privacy Manifest、App Store Privacy 标签及律师审查一致；不得声称当前版本会自动发送使用分析、崩溃报告、题目内容或设备明细。


## 5. Contracts（设置 / 诊断 / 法律入口）

### A. 设置项行为

- Settings 中每个 toggle、sheet、导航项必须表达真实行为；无实现或无副作用的控件不得伪装成已启用功能。
- 设置项保存失败必须用户可见；不能只写日志或静默恢复旧值。
- Release 1 不提供用户可见的 Profile 创建、切换、删除或管理入口；现有入口属于待重基线实现偏差。

### B. 诊断与隐私

- 生产 analytics 注入为 `NoOpAnalyticsService`；端侧 MetricKit 诊断不受 Settings 中的旧“诊断”开关控制。
- Release 1 隐藏旧诊断 / 匿名遥测 UI，且当前 manifest 不得单独纳入；移除或不可达化控件不得改变底层 MetricKit、`NoOpAnalyticsService` 或 DI 的安全行为。
- 任何隐私状态声明必须与 App Store Privacy Manifest、代码注入和公开隐私政策一致。

### C. 法律入口

- 服务条款、隐私政策、儿童隐私等法律正文属于 legal-gated 内容；Settings 只能链接、标记和路由到律师线，不自行改写正文。
- 外部链接失败、取消或无网络时应有用户可见反馈。

### D. Enforcement

| 契约项 | Enforcement |
|---|---|
| 设置项真实表达行为 | PR review + 针对性模拟器实测 |
| 诊断开关不误导 | L10n grep + Privacy/Telemetry code review |
| 法律正文不自改 | PR review + legal handoff |
| 外部链接反馈 | 手动实测 / UI test |

## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P2 简洁 / P4 用户拥有数据·零注册 / P5 成人生产力工具） | 设置服务控制权与信任；偏好纯本地不外传；中性成熟 |
| Product Constitution | `../../explanations/vision.md` B5-A / B6-A（effective） | 用户可见面不呈现 Profile / Workspace；Settings 不展示不可用升级入口 |
| Release 1 Contract | `../../reference/release-1-contract.md` C2-Personalization / C3 / C4-D | Dashboard 不呈现身份装饰；Settings 隐藏身份字段与全部 Review 设置 / 调度入口 |
| 产品政策 / ADR | `../../decisions/ADR-005-analytics-privacy-strategy.md`（全球零后端行为采集，遥测开关本地化、生产 NoOp） | 匿名遥测开关不发送逐事件行为；端侧 MetricKit 独立于该开关 |
| 待验证假设 | 无（承载容器层，所托管功能各自验证假设） | — |
| 验收证据 | §4 验证标准 GWT + AllTests | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（P2 简洁 / P4 用户拥有数据·零注册 / P5 成人生产力工具）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 7：备份 / 恢复；App 内语言切换贯穿各成人旅程）
- 决策：`../../decisions/ADR-005-analytics-privacy-strategy.md`（全球生产零后端行为采集）
- 相关 / 承载入口 feature：`feat-export.md`（JSON/CSV 导出）、`feat-backup.md`（备份/恢复）、`feat-profile.md`（B5-A 单资料库重基线）、`feat-library.md`（字段管理器）、`feat-review.md`（复习卡片外观字段口径）
