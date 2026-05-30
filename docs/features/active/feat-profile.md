---
id: feat-profile
title: Multi-Profile Vault（多孩子档案）
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-05-30
---

# Feature: Multi-Profile Vault（多孩子档案）

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys + tech 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：多孩家庭的家长需要在同一台设备上管理不同孩子的独立题库，互不干扰——给儿子录数学题、给女儿录英语题，题库 / 统计 / 复习进度各自独立。这是多孩家庭能直接上手使用的**刚需**（旅程 1 验证），不做就只能多孩混在一个题库里。
- **定位**：Multi-Profile 是**基础可用性**（多孩家庭场景），不是增值体验，故放免费层；切换参考 Obsidian 的 Vault 模式——轻量、本地、零注册。
- **原则归属**：P5 家长友好（零学习曲线、切换不需密码）+ P4 数据安全（Profile 是数据隔离边界，删除有保护）。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **多 Profile 隔离**：每个 Profile 拥有独立的题库、统计、复习进度、草稿、自动推断历史、字段配置、卡片字号、每日复习目标、题库排序偏好；切换 Profile 后只看到该 Profile 的数据。
- **Per-Profile 自动推断**：切换 Profile 后学科 / 来源等默认值推断基于该 Profile 自身历史，不跨 Profile 漂移。
- **创建 / 删除**：首次启动自动创建默认 Profile（用户无感）；后续可在设置中新增（昵称 / 头像）/ 删除（二次确认 + 显式输入名称，不可撤销）；新 Profile 立即生效、不复制其他 Profile 数据；删除物理目录 + 数据库文件 + per-profile UserDefaults，不影响其他 Profile。
- **最后 Profile 保护**：只剩 1 个 Profile 时禁用删除按钮，提示「至少保留一个 Profile」（阻止而非自动建空 Profile，避免"删不掉"困惑，奥卡姆剃刀）。
- **切换中断保护**：存在未保存编辑 / 草稿时提示保存或放弃、不静默切换；关键操作（导出 / 备份 / 恢复，经 `AppActivityTracker` 跟踪）期间禁止切换，UI 提示「正在导出/备份/恢复中，请稍候」；切换失败回滚到原 Profile、不留中间态。
- **全局 vs Profile 隔离状态**：TipKit tooltip 状态按 Profile 隔离（每个孩子各自看一次引导）；Onboarding 完成状态、VoiceOver / 辅助功能为全局，不随切换重置。
- **备份覆盖全 Profile**：`.zip` 备份打包设备上所有 Profile（题目 / 图片 / 元数据 / 复习进度），不支持单 Profile 导出（避免漏备）。
- **边界 / 不做**：不做家长-孩子关联账号体系；不做权限控制（家长视图 vs 孩子视图）；切换不要求密码（家长场景无安全隔离需求）；Profile 切换入口在设置页或 Dashboard 头像区域，非高频操作不占主路径。
- **前置依赖**：无。Multi-Profile 是数据隔离基座，被采集 / 题库 / 复习 / 统计 / 备份等几乎所有功能依赖。
- **商业分层**：Multi-Profile = 免费层基础可用性，不做付费墙。CloudKit 同步（Pro）以**全部 Profile** 为范围，但 UI 仍需切换 Profile 查看特定孩子题库；同步为下游 Pro 功能（见 `../backlog/feat-icloud-sync.md` / `../../decisions/ADR-001-smart-paper-analytics-pricing.md`，定价见 `../../explanations/business-model.md`）。

## 3. 技术设计 (How)
- **模块归属**：`ProfileManager`（`@Observable`，多 Profile / Vault 切换，持有 `DataExecutor`）；`ProfileMigration`（老版本结构迁移）；二者在 `SnapDrillData`。`AppActivityTracker`（`SnapDrillCore/Support`）提供切换保护。Profile-scoped 服务走 `ProfileManager` / `RepositoryContainer`，不入全局 `ServiceContainer`（`ImageStorage` 为典型 Profile-scoped 例外）。
- **关键机制 / 数据流**：采用 Vault 模式——每个 Profile 拥有独立的 SwiftData `ModelContainer` + 独立图片存储目录 + per-profile UserDefaults。切换 Profile 时重建 `ModelContainer` 与 `RepositoryContainer`。`ProfileManager.switchProfile` 先查 `AppActivityTracker.shared.switchBlockReason`，有进行中操作时拒绝切换并返回阻塞原因；`AppActivityTracker` 定义 `begin/end` 活动跟踪 API 与 `canSwitchProfile` / `switchBlockReason` 查询 API，已接入采集（`CaptureViewModel` / `CaptureResultViewModel`）、导出 / 打印、备份 / 恢复（`SettingsViewModel`）。Per-Profile UserDefaults（字段配置、自动推断历史、复习目标等）由 `ProfileManager` 内部 `perProfileKeys` / `savePreferences` / `loadPreferences` 机制在切换时自动存取。Profile 级 TipKit 状态由 `ProfileTipState`（`ReviewSwipeTip` / `FieldConfigTip`）按 Profile 隔离。
- **State & Concurrency**（Swift 6 strict）：`ProfileManager` 是 `@Observable`、持有 `DataExecutor`（actor，拥有 `ModelContainer`，`createOffMainActor()` 消除 MainActor + XPC 死锁，#599 已修复）；切换 / 落库等重活经 Repository → `DataExecutor` 在 actor 内执行，不阻塞主线程；切换期间禁止数据写入（saveContext 排队 / UI 显示 loading），完成后放行。
- **设计裁决（仅本模块）**：「禁止删除最后一个 Profile」而非自动创建空 Profile——自动创建导致"删不掉"的困惑体验且新 Profile 缺个性化信息，直接阻止更简单（奥卡姆剃刀，仅本模块裁决）。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：Given 设备上已存在 2 个及以上 Profile（首个在 Onboarding 自动创建），When 用户进入 Profile 管理并选择目标 Profile，Then 系统切换当前上下文并刷新 Dashboard / Library / Capture 默认值 / Review / 统计；此后录题 / 搜索 / 复习 / 导出只看到该 Profile 的数据，自动推断按该 Profile 历史独立。
- **边界 / 异常**：
  - 切换时存在未保存编辑或 draft → 切换前提示保存为 draft / 恢复 / 放弃，或阻止切换，避免静默丢失（Boundary B06，S0）。
  - 切换时有进行中的 OCR / 导出 / 打印任务 → 等待完成或提示中断，不静默丢弃任务结果。
  - 切换失败 → 保持原 Profile 不变，不进入部分页面已切换、部分页面未切换的混合状态。
  - 删除最后一个 Profile → 删除按钮 disabled 并提示「至少保留一个 Profile」，设备始终存在至少 1 个 Profile、不出现零 Profile 崩溃（Boundary B24，S1）。
  - 删除非最后 Profile → 二次确认；级联移除该 Profile 的题库 / 图片 / 复习进度 / 配置；若删的是当前活跃 Profile，UI 自动 fallback 到剩余 Profile 并提示；不得遗留孤儿数据或活跃 Profile 悬空（Boundary B26，S1）。
  - 切换 Profile 后 TipKit 提示状态独立（Boundary B25，#532 已修复，S2）。
- **数据保证**：Profile 是数据隔离边界，题库 / 统计 / 复习进度 / 导出结果 / draft 必须按 Profile 隔离；切换不得跨 Profile 复用搜索结果或过滤条件对应的数据集；一个 Profile 的删除 / 导出 / 恢复 / 复习更新不得污染其他 Profile；备份 / 恢复必须保留 Profile 隔离关系。备份覆盖全部 Profile，不允许只导出当前活跃 Profile 的局部数据。
- **NFR**：冷启动 < 2 秒到首屏可交互；题库列表加载 < 500ms（200 题）。卡片字号 `@AppStorage(UDKey.cardFrontFontSize / cardContextFontSize)` 为 Per-Profile 隔离存储。多 Profile 恢复当前为按 Profile sequential 提交，单 Profile 内 DB 恢复事务原子（`RepositoryContainer` 单次 saveContext，失败 rollback），图片 best-effort；**多 Profile 全局原子恢复待实现**（追踪：未来增量 issue）。

## Provenance（迁移期审计用，全量封板后可删）
| 本 spec 内容 | 来源（旧文档章节 / UC / ADR） |
|---|---|
| Why（痛点 / 多孩刚需 / 定位 Vault） | vision §细分群体「多孩家庭」+ journeys 旅程 1 + business §分层原则 |
| Why（P5·P4 原则归属） | vision §产品原则 P4 数据安全 / P5 家长友好 |
| What（隔离范围 / 创建删除 / 最后保护 / 切换保护 / 全局 vs 隔离 / TipKit） | design §多 Profile 设计 + requirements §Multi-Profile 生命周期规格 |
| What（Per-Profile 自动推断） | requirements §自动推断 Per-Profile 隔离 + design §自动推断 |
| What（备份覆盖全 Profile） | requirements §备份与恢复 + design §备份与恢复设计 |
| What（不做账号 / 权限 / 入口位置） | design §多 Profile 设计「不做什么」 |
| What（商业分层 / 同步范围） | business §分层原则 + §免费层完整定义「管理」+ design §iCloud 同步设计 |
| How（Vault / ModelContainer 重建 / AppActivityTracker / per-profile UD / TipKit / DataExecutor 并发） | tech/architecture.md §Multi-Profile 实现 + §DI 容器 + §关键类型 |
| How（设计裁决：最后 Profile 阻止删除） | design §多 Profile 设计「最后一个 Profile 删除策略」 |
| Verify（success / 边界 / 数据保证） | cases UC7 Switch Profile + Boundary B06/B24/B25/B26 |
| Verify（多 Profile 恢复原子性边界） | cases UC6 Variants & Exceptions + Data guarantees |
| NFR（启动 / 列表加载 / 字号 Per-Profile） | tech/non-functional-requirements.md §性能 + §存储 |

## 关联
- 原则：`../../explanations/vision.md`（P4 数据安全 / P5 家长友好 / P2 简洁）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 1：家长帮小学生录入 + 多孩管理）
- 决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（Pro 分层）
- 相关 / 下游 feature：`feat-review.md`（复习按 Profile 隔离）、`../backlog/feat-icloud-sync.md`（CloudKit 同步范围 = 全部 Profile，Pro，#485 阻塞）、`feat-backup.md`（`.zip` 覆盖全 Profile）
