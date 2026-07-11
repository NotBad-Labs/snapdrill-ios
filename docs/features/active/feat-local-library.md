---
id: feat-local-library
title: 单一资料库
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-07-11
intent_refs:
  - vision:P2
  - vision:P4
  - vision:P5
  - positioning-and-audience
---

# Feature: 单一资料库

> 人读摘要：已实现（免费）。派生自上方 frontmatter；全局状态以 frontmatter 为唯一真理源。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。

## 1. 为什么做 (Why)

- SnapDrill 的核心价值链是采集、管理、导出/打印。零用户阶段的 Multi-Profile 为所有数据流引入了切换、隔离、偏好搬运、跨库备份和故障恢复复杂度，却没有已验证需求。
- 2026-07-11 PO 裁决：产品只维护一个本地资料库，取消 Profile 创建、切换、删除和数据隔离；不迁移旧 Profile 数据，也不兼容旧 Profile 备份。
- 个人头像、昵称、每日目标和个人备注仍是全局个性化偏好，不构成第二个资料库或账号。
- 该裁决落实 P2 简洁、P4 用户拥有数据和 P5 成人生产力定位。版本历史与 Git tag/commit 是回滚边界。

## 2. 需求规则 (What)

- App 生命周期内只有一个 `LibrarySession`、一个 SwiftData `ModelContainer`、一个 `RepositoryContainer` 和一个图片目录。
- 用户界面不提供资料空间的创建、切换、删除或重命名入口；Dashboard 头像只打开设置/个人资料。
- 分类、字段可见性、自动推断历史、复习目标、卡片外观和功能提示均为设备级偏好，不做 per-profile 搬运。
- 草稿固定存放在唯一草稿目录；采集、回顾、导出、打印、存储统计和备份都直接访问同一资料库。
- 新基线不读取或迁移旧 `profiles.json`、旧 Profile 目录、旧 `activeProfileId`，也不提供旧备份 schema 兼容层。
- 数据安全能力不因简化而降低：保留 store 损坏隔离、空库恢复入口、图片路径校验、EXIF 位置剥离、备份恢复回滚和 ZIP 解压上限。

## 3. 技术设计 (How)

- `LibraryLayout` 定义固定根目录 `Application Support/SnapDrill/Library`：
  - `default.store`
  - `images/`
  - `corrupted/`
- `LibrarySession` 是 App 生命周期 owner，异步创建 `DataExecutor`，再构造 `RepositoryContainer` 和 `ImageStorage`。
- `AppRootView` 只注入当前 session 的 `ModelContainer` 与 repositories，不再通过视图 identity 切换整个依赖图。
- store 打不开时，`DataExecutor` 把 store/WAL/SHM 隔离到 `corrupted/<timestamp>/`，重建磁盘 store，并通过 `StoreRecoveryEvent` 显示恢复或空库继续路径。
- 备份 wire 使用 schema v3：`data.json` 顶层直接包含 `reviewItems`、`dimensions`、`categoryValues`；图片位于 ZIP 的 `images/`。任何非 v3 schema 在写入前拒绝。
- SwiftData schema 的 `MigrationPlan` 仍保留，用于单资料库模型版本演进；它不承担旧 Profile 布局迁移。

## 4. 验证标准 (Verify)

- Given 全新安装，When App 启动，Then 只创建一个固定资料库，Dashboard/Library/Capture/Review/Settings 共享同一 repository graph。
- Given 任意用户流程，When 搜索可见 UI 与路由，Then 不存在资料空间新增、切换、删除入口。
- Given 旧 `activeProfileId` 或旧 Profile 文件残留，When App 启动，Then 新资料库不读取这些状态，行为与无旧状态时一致。
- Given store 损坏，When session 创建，Then 原文件被隔离且用户可从 v3 备份恢复或以空资料库继续。
- Given v1/v2 或未知版本备份，When 用户发起恢复，Then 在任何数据库或图片写入前拒绝。
- Given v3 备份恢复中途失败，When 自动回滚完成，Then 恢复前的资料、分类和图片保持可用。
- `swiftlint --strict`、AllTests build、Data/Core/Settings targeted tests 与 Accessibility Audit 必须通过。

## 5. Contracts

| 契约 | Enforcement |
|---|---|
| 唯一资料库路径无身份分区 | `LibraryLayoutTests` |
| session owner 与损坏 store 恢复 | `LibrarySessionTests` / `ModelExecutorTests` |
| v3 直连 payload，旧 schema 拒绝 | golden fixtures / `BackupDTOTests` / Settings restore tests |
| 图片路径、EXIF、解压上限 | `ImageStorageTests` / `BackupServiceSizeLimitTests` |
| UI 无多资料空间入口 | XCUITest 路由巡检 + L10n grep |

## 意图追溯

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| PO 裁决 | 2026-07-11：取消 Multi-Profile；零用户，不做迁移 | 唯一资料库、旧布局与旧备份不兼容 |
| Vision | `../../explanations/vision.md` P2/P4/P5 | 简化核心闭环，同时保留本地数据安全与成人生产力定位 |
| 产品定位 | `../../explanations/positioning-and-audience.md` | 不建立儿童/家庭成员账号体系 |
| 验收证据 | §4 + AllTests + dogfood | 见本 spec Verify |

## 关联

- 备份：`feat-backup.md`
- 设置与个性化：`feat-settings.md`
- 架构：`../../explanations/architecture.md`
- PO 决策索引：`../../decisions/po-decision-log.md`
