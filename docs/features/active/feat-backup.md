---
id: feat-backup
title: 备份与 CSV 导入导出
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-05-30
---

# Feature: 备份与 CSV 导入导出

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys / tech 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：本地存储意味着 App 是用户数据的唯一守护者。免费用户没有 iCloud 同步，换机或卸载 = 数据永久丢失。`.zip` 手动备份是免费用户的生命线——让换机迁移成为可执行路径，确保数据可携带、不被平台锁定。
- **定位**：`.zip` 是免费用户换机的数据迁移出口，**不是象征性导出**；CSV 导入定位为**数据可携带权场景**（从其他工具迁移进 SnapDrill），不是主推录入路径，不应在 UI 上与拍照同级展示。
- **原则归属**：P4 数据属于用户（隐私是核心差异化）+ 其数据安全子条款「保存可靠、删除可撤销、备份可用」。导出/备份是「数据属于用户」的体现而非口号——可导出、可打印、可带走。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **手动备份**：`.zip` ZIP 文件，打包**全部 Profile**（题目主数据、图片、元数据、复习进度、配置性数据），通过系统分享面板导出。
- **全 Profile 覆盖**：备份覆盖设备上所有 Profile，**不支持单 Profile 导出**（简化操作，避免用户漏备）。
- **恢复安全规范**：仅在文件完整性与版本兼容性满足要求时执行恢复；不满足时必须**拒绝恢复且保持现有数据不变**。
- **向后兼容规范（S0）**：`.zip` 是免费换机迁移出口，新版本 App 必须能恢复旧版本备份；任何违反该承诺并导致数据永久丢失的情形按 S0 处理。
- **元数据原子 vs 图片 best-effort 差异化**：元数据（题目记录、字段配置、复习进度、Profile 列表）原子恢复（全成功或全回滚）；图片 best-effort 恢复，单张解压失败不阻断整体，缺图题目仍可恢复（OCR 文字保留），UI 显示「图片缺失」占位。
- **CSV 导出**：结构化字段与 OCR 文本摘要，可用 Excel 打开，以实际导出字段清单为准；**双入口**——隐私设置页 或 题库导出面板。
- **CSV 导入**：RFC 4180 合规导入，用于从其他工具迁移数据。
- **边界 / 不做**：不做自动本地备份（增加存储负担）；不做云端备份（那是 Pro iCloud 同步的职责）；导入文件损坏/不可读时提示重新选择，不破坏现有数据。
- **前置依赖**：无。备份/恢复经 `AppActivityTracker` 互斥保护（关键操作期间禁止切换 Profile）。
- **商业分层**：`.zip` 手动备份/恢复 + JSON/CSV 导出/导入**全部免费**，不作为订阅门槛——付费解锁的是「增值体验」（多设备流转、图片处理增强、高级导出），不是「基础能力」。iCloud 自动同步是 Pro 的不同职责（定价见 `../../explanations/business-model.md`）。

## 3. 技术设计 (How)
- **模块归属**：
  - 备份引擎 `SnapDrillData`（`BackupService` 做 `.zip` 备份/恢复，actor 隔离；`BackupDTO` 备份数据传输对象；依赖 `ZIPFoundation`）。
  - Schema 版本判定走 `MigrationPlan`（SwiftData Schema 版本迁移）/ `ProfileMigration`（Profile 结构迁移，老版本升级）。
  - CSV 解析 `SnapDrillFeatureSettings/CSVParser.swift`（RFC 4180，enum 纯函数，与 ViewModel 状态分离）；JSON/CSV 导出 `SnapDrillFeatureSettings/DataExporter.swift`（含 `=+-@` 前缀防注入）；导入流程编排 `SettingsViewModel.swift`（解析 + 字段映射 + 写入 repository）。
- **关键机制 / 数据流**：
  - `.zip` 备份包必须包含 Schema 版本号、Migration Plan 等元数据，供恢复流程判定直接导入 / 触发本地迁移 / 拒绝恢复。
  - **恢复前校验**：先验证文件可读性、结构完整性、版本兼容性，校验失败直接拒绝并保持现有数据不变。
  - **恢复前安全网（自动备份）**：执行恢复前自动将当前数据快照到沙盒临时目录（带时间戳的 `.zip`），失败时一键回滚到操作前状态；成功后保留临时备份至下次启动自动清理。用户看不到此步，但失败 Alert 文案明确告知「您的原数据已自动备份在内部临时目录」。
  - **多 Profile 提交策略**：`SettingsViewModel.restoreFromBackup` 按 Profile sequential 提交（逐个 Profile DB → 图片）；自动备份回滚仅对当前活跃 Profile 有效。**多 Profile 全局原子恢复待实现**（追踪：未来增量 issue）。
  - **CSV 注入防护（导出）**：导出 CSV 时以 `=+-@` 开头的值前加 tab。
  - **CSV 解析（导入）**：严格 RFC 4180——引号转义、CRLF/LF 兼容、字段数不匹配则整行拒绝并提示用户。
- **State & Concurrency**（Swift 6 strict）：备份/恢复流程由 `SettingsViewModel`（`@Observable`，`@MainActor`）编排；`.zip` 打包/解包重活在 `BackupService`（actor 隔离）执行，不阻塞主线程；单 Profile 内 DB 恢复经 `RepositoryContainer` 单次 saveContext（失败 rollback）。`CSVParser` 为无状态纯函数层，与 ViewModel 状态分离。
- **设计裁决（仅本模块）**：恢复目标是「完整成功或完整失败」，当前实现达成**单 Profile 维度原子**（DB 事务原子 + 图片 best-effort），**多 Profile 全局原子事务尚未实现**——这是已知与目标的差距，单 Profile 安全网兜底，不外推为已达成全局原子。

## 4. 验证标准 (Verify)
- **Success path (GWT)**（承接 cases UC6）：Given 设备存在至少一个含数据的 Profile，When 用户在设置发起手动备份，Then 系统打包全部 Profile（题目、图片引用、元数据、复习进度）为 `.zip` 并交用户保存/分享；Given 用户持有 `.zip`，When 选择文件发起恢复且校验（可读性/结构完整性/版本兼容性）通过，Then 导入全部 Profile 数据，题库 / Dashboard / Review / 设置与备份内容一致。
- **边界 / 异常**：
  - 备份文件损坏/不可读 → 拒绝恢复，现有本地数据完全不变（Boundary B04, S0）。
  - 备份版本高于当前 App → 拒绝恢复并提示版本不兼容、建议升级 App（Boundary B09）。
  - 备份版本低于当前 App 但在兼容范围内 → 允许迁移恢复；失败时不得破坏现有本地数据。
  - 恢复写入中途失败 → 提示恢复失败、尽力回滚；目标不留半恢复状态，当前图片为 best-effort，可能 DB 有记录但图片缺失，须在结果摘要明确提示（Boundary B05, S0）。
  - 多 Profile 恢复中途某 Profile 失败 → 已成功 commit 的 Profile 数据保留，活跃 Profile 自动备份回滚生效，未触达 Profile 不动。
  - 磁盘空间不足 → 恢复前检查可用空间，不足则拒绝开始恢复并提示。
  - CSV/JSON 导出磁盘写满 → 提示导出失败、清理临时文件，不生成损坏文件，原数据不受影响（Boundary B07, S1）。
  - 导入文件损坏/不可读 → 提示文件不可用、允许重新选择，现有数据不变（Boundary B08, S1）。
  - 缓存清理 → 只清理 `Caches/` 临时文件，不触碰 `Documents/` 或 `Application Support/`；不得导致题目原图、备份文件、SwiftData 数据丢失（Boundary B23, S0）。
- **数据保证**：
  - 备份生成失败不得产生「文件已导出」假象。
  - 恢复必须保留 Profile 隔离关系；一个 Profile 的恢复不得污染其他 Profile。
  - 单 Profile 内：DB 恢复事务原子（`RepositoryContainer` 单次 saveContext，失败 rollback），图片 best-effort。
  - 任何恢复失败均不得损坏**该 Profile 恢复前的现有本地数据**（单 Profile 维度保证）；图片 best-effort 恢复失败必须在结果摘要明确提示，不得静默跳过。
  - CSV/JSON 导出以实际导出字段清单为准，不得静默宣称为全字段导出；导出为只读操作，不修改题目主数据/复习状态/统计。
- **NFR**：
  - 性能：备份打包 < 30 秒（500 题 + 图片，点击备份到 ShareSheet 弹出）；CSV 导入 < 5 秒（1000 行，选择文件到入库完成）。
  - 内存：备份/恢复 < 200MB（流式 ZIP 写入，不全量加载）；CSV 导入（1000 行）< 80MB（解析流逐行处理，不全文加载到内存）。
  - 中断恢复：恢复前自动备份当前数据作为安全网（备份完整性）。

## Provenance（迁移期审计用，全量封板后可删）
| 本 spec 内容 | 来源（旧文档章节 / UC / ADR） |
|---|---|
| Why（生命线 / 数据迁移出口 / CSV 可携带权定位 / P4） | vision §4 数据属于用户 + 数据安全子条款 + §1 主路径必须是图片（CSV 定位）；design §备份与恢复设计·核心理念 |
| What（备份范围 / 全 Profile / 恢复安全 / 向后兼容 / 元数据原子 vs 图片 best-effort） | requirements §备份与恢复 + §数据可携带权矩阵；design §备份与恢复设计·设计决策与不做 |
| What（CSV 导出/导入 / 双入口 / RFC 4180） | requirements §导出与打印能力 + §功能全景·导出与备份；design §导出与打印设计 |
| What（商业分层：备份/CSV 全免费） | business §免费层完整定义 + §免费版体验完整性保障 |
| How（BackupService / BackupDTO / MigrationPlan / CSVParser / DataExporter 归属） | tech/architecture §SnapDrillData + §数据导入/导出归属 |
| How（Schema 版本 / 校验 / 恢复前安全网 / 多 Profile sequential / 注入防护） | design §备份与恢复设计·兼容机制+安全网；cases UC6 Exceptions；tech/non-functional §CSV 注入防护/解析 |
| Verify（success / 边界 / 数据保证） | cases UC6 + UC5（导出）+ Boundary B04/B05/B07/B08/B09/B23 |
| Verify（NFR 性能/内存） | tech/non-functional §性能 + §内存 + §兼容性·备份完整性 |
| 旅程印证 | journeys 旅程 10：免费用户换机恢复 |

## 关联
- 原则：`../../explanations/vision.md`（P4 数据属于用户 / 数据安全子条款）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 10：免费用户换机恢复）
- 商业分层：`../../explanations/business-model.md`
- 相关 / 上位 feature：`feat-review.md`（复习进度随备份一并迁移）
