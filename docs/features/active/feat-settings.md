---
id: feat-settings
title: 设置与个性化
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-05-30
---

# Feature: 设置与个性化

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys / 技术文档聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：家长不需要理解 App 内部概念。设置服务于个性化，不服务于复杂度——昵称/头像/座右铭/每日目标让用户感受到"这是我的工具"，增强归属感。
- **选择权交给用户**：默认不推送通知，但提供完整的提醒设置——有人需要提醒，有人不需要，产品不替用户做决定。
- **海外华人场景**：App 内语言直选（不依赖系统设置）是海外华人家长的核心需求——系统语言英文、练习内容中文时仍能用中文界面。
- **原则归属**：P5 家长友好（零学习曲线、不贩卖焦虑）+ P2 简洁（设置克制，不堆复杂度）+ P4 零注册（个性化资料纯本地、不外传）。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **用户资料（纯本地，不上传）**：昵称（Dashboard 问候语）、座右铭、头像（预设组或相册自定义）、每日复习目标（用户自定，无硬性范围）。与 PV-4「不收集可识别个人信息」一致，是本地个性化定制而非注册信息。
- **复习卡片外观**：正/反面字号独立可调（滑杆，默认正面 32pt、反面 16pt），对齐三选项（左/居中/右，默认左对齐），实时预览。与系统 Dynamic Type 互不依赖。
- **通知设置**：默认不推送；每日复习提醒开关 + 时间选择（时/分）+ 声音开关；**不使用 App 图标角标**（vision P2「不贩卖焦虑」）；通知权限**仅在用户主动开启提醒开关时**请求（HIG：用户理解价值后才请求，不在首次启动时弹窗）。
- **外观模式**：跟随系统（默认）/ 浅色 / 深色三选项。
- **语言设置**：App 内直接切换中文/英文，不依赖系统设置。
- **存储维护**：媒体缓存清理——只清 App 运行产生的临时文件（OCR 临时图片、PDF 渲染缓存），不触碰用户题目数据。
- **使用数据开关（Analytics + 崩溃报告）**：国内版（当前 shipping）Firebase-Free 不采集任何数据，设置内开关为架构预留、对国内版无实际效果；海外版（C 路径，未来）两个独立开关默认不采集、用户可 opt-in（ADR-004）。
- **设置页承载的其他入口（深度/合规）**：字段管理器（系统字段开关 + 选项 CRUD，详见 `feat-library.md`）、Profile 管理入口（`feat-profile.md`）、隐私设置页的 JSON/CSV 导出（`feat-export.md`）、手动备份/恢复入口（`feat-backup.md`）、帮助中心外链（外部网页 FAQ）、卸载数据丢失提醒、关于（隐私政策 / 服务条款 / 开源许可展示）。
- **边界 / 不做**：不在 App 内构建帮助搜索系统（仅外链 FAQ）；角色预设套件仅作设置页可选模板入口、**不进入 Onboarding**（不增加首次配置摩擦）；用户资料不外传、不做账号体系。
- **前置依赖**：无。设置是承载入口的容器层，所托管的导出/备份/Profile/字段管理各自有独立 feature spec。
- **商业分层**：设置与个性化整体属**免费层**（家长友好基础体验），无付费墙。设置内"使用数据开关"是架构预留（国内版无效）/ 海外版 opt-in，与 Pro 无关；定价见 `../../explanations/business-model.md`。

## 3. 技术设计 (How)
- **模块归属**：`Packages/SnapDrillFeatures/SnapDrillFeatureSettings`（依赖 Library）。通知能力经 `SnapDrillCore` 的 `NotificationServiceProtocol`（ServiceContainer 注入）；复习卡片字号经 `@AppStorage(UDKey.cardFrontFontSize / cardContextFontSize)`，Per-Profile 隔离。
- **关键机制 / 数据流**：
  - 用户资料、复习目标、字段配置等 per-Profile 偏好由 `ProfileManager` 通过 `perProfileKeys` 机制管理（切换 Profile 时自动 save/load），存 per-profile UserDefaults。
  - Onboarding 完成、VoiceOver 等设置为**全局状态**，不随 Profile 切换。
  - 通知权限延迟请求：仅在用户翻开提醒开关时触发系统授权弹窗；权限被拒后再次开启 → 引导跳转系统设置，不静默失败。
  - 媒体缓存清理只作用于 `Caches/` 临时文件，绝不触碰 `Documents/` 或 `Application Support/`。
- **State & Concurrency**（Swift 6 strict）：设置页交互由 `@Observable` `SettingsViewModel`（`@MainActor`）与 `@AppStorage` 驱动；复杂写操作（CSV 导入、备份/恢复编排）在 ViewModel 内编排，落库经 Repository → `DataExecutor`（actor），不阻塞主线程。备份/恢复期间 `SettingsViewModel` 接入 `AppActivityTracker.begin/end` 以阻塞 Profile 切换。`SettingsViewModel` 是 `Notification.Name.reviewDataDidChange` 的发布方之一（字段/选项变更触发跨模块刷新）。
- **设计裁决（仅本模块）**：外观提供"跟随系统 / 浅色 / 深色"三选项——HIG 建议跟随系统，但三选项是行业惯例（Telegram / Bear / Notion），Apple 不因此拒审；本裁决仅限外观设置、不外推。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：
  - **个性化**：Given 用户在设置页，When 修改昵称/头像/每日目标，Then 资料纯本地保存、Dashboard 问候语随之更新，不发生任何外传。
  - **语言切换（旅程 7）**：Given 系统语言为英文，When 用户在设置中切换到中文界面，Then App 界面立即变中文且不依赖系统语言设置。
  - **通知开启**：Given 用户首次开启每日复习提醒开关，When 系统弹出通知授权且用户允许，Then 按所选时间/声音调度本地通知（无角标）。
- **边界 / 异常**：
  - 通知权限被系统拒绝后再次开启提醒开关（B21）→ 提示权限已被拒绝并引导跳转系统设置；不发送本地通知。
  - 媒体缓存清理（B23）→ 只清 `Caches/` 临时文件，绝不删除题目原图、备份文件或 SwiftData 数据（S0）。
- **数据保证**：用户资料/偏好纯本地存储、不外传（与 PV-4 / P4 一致）；缓存清理对题目数据零影响（任何缓存清理不得导致题目原图、备份、SwiftData 数据丢失）；per-Profile 偏好仅作用于当前 Profile，切换时正确 save/load 互不污染。
- **NFR**：VoiceOver 全模块覆盖（含 Settings）所有常见任务可完成；复习卡片自定义字号为 App 独立设置（非 Dynamic Type），范围按代码实现；国内版 Analytics/Crashlytics 不适用（Firebase-Free，OSLog 实测零网络出境，ADR-004）。

## Provenance（迁移期审计用，全量封板后可删）
| 本 spec 内容 | 来源（旧文档章节 / UC / ADR） |
|---|---|
| Why（个性化理念 / 选择权 / 海外华人 / P5·P2·P4） | design §设置与个性化设计概要 + requirements §通知细节 + vision 原则 P2/P4/P5 + journeys 旅程 7 |
| What · 用户资料 | requirements §设置与个性化·用户资料 + design §设置个性化设计 |
| What · 复习卡片外观 | requirements §复习卡片外观 + non-functional-requirements §复习卡片自定义字号 |
| What · 通知设置 | requirements §通知细节 + design §设置个性化（通知权限延迟请求） |
| What · 外观/语言/缓存/使用数据开关 | requirements §外观 / §语言设置 / §存储维护 / §使用数据 + non-functional-requirements §兼容性·无障碍 |
| What · 其他入口（隐私设置/帮助/关于/合规） | requirements §引导与帮助·帮助中心 + §功能全景·隐私与合规 + §设置与个性化 |
| 商业分层 | business §免费层完整定义 |
| How（模块/机制/State&Concurrency/裁决） | architecture §SnapDrillFeatureSettings + §Multi-Profile 实现 + §Environment 注入点 + design §外观三选项 |
| Verify（success / 边界 / 数据保证 / NFR） | cases UC 权限相关 + Boundary B21 / B23 + non-functional-requirements §无障碍 + journeys 旅程 7 + ADR-004 |

## 关联
- 原则：`../../explanations/vision.md`（P2 简洁 / P4 零注册 / P5 家长友好）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 7：海外华人双语整理 / 旅程 10：免费用户换机恢复）
- 决策：`../../decisions/ADR-004-china-build-firebase-free.md`（国内版 Firebase-Free，使用数据开关无效）
- 相关 / 承载入口 feature：`feat-export.md`（JSON/CSV 导出）、`feat-backup.md`（备份/恢复）、`feat-profile.md`（Profile 管理）、`feat-library.md`（字段管理器）、`feat-review.md`（复习卡片外观字段口径）
