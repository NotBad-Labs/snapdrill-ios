---
id: feat-backup
title: 备份与 CSV 导入导出
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-07-12
intent_refs:
  - vision:P4
---

# Feature: 备份与 CSV 导入导出

> **产品重基线（2026-07-12）**：B4-A 将手动备份 / 恢复确立为永久数据权利，但 frontmatter 与下文只记录当前实现。B5-A 已取消用户可见 Multi-Profile；现有 Profile wire、恢复语义和旧备份兼容如何收敛，必须由 Gate C 后的数据 / Release Contract 单独裁定。下文 iCloud 与 Pro 分层只作历史 / 规范偏差追溯，不得驱动新工作。

> 人读摘要：✅ 已实现（免费）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys / tech 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：local-first 意味着用户必须有可靠的数据携带出口；换机、卸载或设备损坏都可能导致仅存本机的资料丢失。`.zip` 手动备份让迁移成为可执行路径，确保数据可携带、不被平台锁定。
- **定位**：`.zip` 是免费用户换机的数据迁移出口，**不是象征性导出**；CSV 导入定位为**数据可携带权场景**（从其他工具迁移进 SnapDrill），不是主推录入路径，不应在 UI 上与拍照同级展示。
- **原则归属**：P4 数据属于用户（隐私是核心差异化）+ 其数据安全子条款「保存可靠、删除可撤销、备份可用」。导出/备份是「数据属于用户」的体现而非口号——可导出、可打印、可带走。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **手动备份**：`.zip` ZIP 文件覆盖唯一资料库的主数据、图片、元数据、回顾进度和必要配置，通过系统分享面板交给用户保存。
- **完整覆盖**：备份默认覆盖完整资料库，不提供容易造成漏备的局部容器选择。
- **恢复安全规范**：仅在文件完整性与版本兼容性满足要求时执行恢复；不满足时必须**拒绝恢复且保持现有数据不变**。
- **向后兼容规范（S0）**：`.zip` 是免费换机迁移出口，新版本 App 必须能恢复旧版本备份；任何违反该承诺并导致数据永久丢失的情形按 S0 处理。
- **元数据原子 vs 图片 best-effort 差异化**：元数据（资料记录、字段配置、回顾进度）原子恢复（全成功或全回滚）；图片 best-effort 恢复，单张解压失败不阻断整体，缺图资料仍可恢复（OCR 文字保留），UI 显示「图片缺失」占位。
- **CSV 导出**：结构化字段与 OCR 文本摘要，可用 Excel 打开，以实际导出字段清单为准；入口由 Gate C 决定。
- **CSV 导入**：RFC 4180 合规导入，用于从其他工具迁移数据。
- **边界 / 不做**：不做自动本地备份（增加存储负担）；Apple 私有同步是未来候选，不属于当前备份职责；导入文件损坏 / 不可读时提示重新选择，不破坏现有数据。
- **前置依赖**：无。备份 / 恢复经 `AppActivityTracker` 互斥保护，关键操作期间阻止破坏性数据操作。
- **商业政策**：手动备份 / 恢复是 B4-A 的永久免费数据权利，不得成为订阅门槛。B6-A 下 Release 1 免费、无广告、无 IAP；iCloud、图片增强和高级导出都只是候选假设。

## 3. 技术设计 (How)
- **模块归属**：
  - 备份引擎 `SnapDrillData`（`BackupService` 做 `.zip` 备份/恢复，actor 隔离；`BackupDTO` 备份数据传输对象；依赖 `ZIPFoundation`）。
  - Schema 版本判定走 `MigrationPlan`（SwiftData Schema 版本迁移）/ `ProfileMigration`（Profile 结构迁移，老版本升级）。
  - CSV 解析 `SnapDrillFeatureSettings/CSVParser.swift`（RFC 4180，enum 纯函数，与 ViewModel 状态分离）；JSON/CSV 导出 `SnapDrillFeatureSettings/DataExporter.swift`（含 `=+-@` 前缀防注入）；导入流程编排 `SettingsViewModel.swift`（解析 + 字段映射 + 写入 repository）。
- **关键机制 / 数据流**：
  - `.zip` 备份包必须包含 Schema 版本号、Migration Plan 等元数据，供恢复流程判定直接导入 / 触发本地迁移 / 拒绝恢复。
  - **恢复前校验**：先验证文件可读性、结构完整性、版本兼容性，校验失败直接拒绝并保持现有数据不变。
  - **恢复前安全网（自动备份）**：执行恢复前自动将当前数据快照到沙盒临时目录（带时间戳的 `.zip`），失败时一键回滚到操作前状态；成功后保留临时备份至下次启动自动清理。用户看不到此步，但失败 Alert 文案明确告知「您的原数据已自动备份在内部临时目录」。
  - **当前 Multi-Profile 提交策略（待 Data Contract 重基线）**：`SettingsViewModel.restoreFromBackup` 按 Profile sequential 提交；这是 `develop` 实现事实，不是目标产品行为。单资料库后的 wire、提交和回滚策略不得在 Gate C 前从本 spec 推导。
  - **CSV 注入防护（导出）**：导出 CSV 时以 `=+-@` 开头的值前加 tab。
  - **CSV 解析（导入）**：严格 RFC 4180——引号转义、CRLF/LF 兼容、字段数不匹配则整行拒绝并提示用户。
    - **⚠ 实现现状（GAP-R6，代码债）**：当前 `CSVParser` 按表头列尽力映射（缺列填空、多列丢弃），**未对字段数不匹配做严格校验与整行拒绝/提示**。需求不变（数据完整性优先，严格拒绝 + 提示哪些行被拒），待 code 债修复。
- **State & Concurrency**（Swift 6 strict）：备份/恢复流程由 `SettingsViewModel`（`@Observable`，`@MainActor`）编排；`.zip` 打包/解包重活在 `BackupService`（actor 隔离）执行，不阻塞主线程；单 Profile 内 DB 恢复经 `RepositoryContainer` 单次 saveContext（失败 rollback）。`CSVParser` 为无状态纯函数层，与 ViewModel 状态分离。
- **设计裁决（仅本模块）**：恢复目标是「完整成功或完整失败」，当前实现达成**单 Profile 维度原子**（DB 事务原子 + 图片 best-effort），**多 Profile 全局原子事务尚未实现**——这是已知与目标的差距，单 Profile 安全网兜底，不外推为已达成全局原子。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：Given 唯一资料库中有数据，When 用户发起手动备份，Then 系统打包资料、图片引用、元数据、回顾进度和必要配置为 `.zip` 并交用户保存 / 分享；Given 用户持有兼容 `.zip`，When 发起恢复且校验通过，Then 资料库内容与备份一致。
- **边界 / 异常**：
  - 备份文件损坏/不可读 → 拒绝恢复，现有本地数据完全不变（Boundary B04, S0）。
  - 备份版本高于当前 App → 拒绝恢复并提示版本不兼容、建议升级 App（Boundary B09）。
  - 备份版本低于当前 App 但在兼容范围内 → 允许迁移恢复；失败时不得破坏现有本地数据。
  - 恢复写入中途失败 → 提示恢复失败、尽力回滚；目标不留半恢复状态，当前图片为 best-effort，可能 DB 有记录但图片缺失，须在结果摘要明确提示（Boundary B05, S0）。
  - 当前 Multi-Profile 备份恢复的中途失败行为属于实现风险清单，必须在单资料库 Data Contract 中明确收敛，不能继续作为目标验收。
  - 磁盘空间不足 → 恢复前检查可用空间，不足则拒绝开始恢复并提示。
  - CSV/JSON 导出磁盘写满 → 提示导出失败、清理临时文件，不生成损坏文件，原数据不受影响（Boundary B07, S1）。
  - 导入文件损坏/不可读 → 提示文件不可用、允许重新选择，现有数据不变（Boundary B08, S1）。
  - 缓存清理 → 只清理 `Caches/` 临时文件，不触碰 `Documents/` 或 `Application Support/`；不得导致题目原图、备份文件、SwiftData 数据丢失（Boundary B23, S0）。
- **数据保证**：
  - 备份生成失败不得产生「文件已导出」假象。
  - 恢复不得读写资料库之外的数据；DB 元数据恢复失败必须 rollback，图片 best-effort 失败必须在结果摘要明确提示。
  - 任何恢复失败均不得损坏恢复前的现有本地数据。
  - CSV/JSON 导出以实际导出字段清单为准，不得静默宣称为全字段导出；导出为只读操作，不修改题目主数据/复习状态/统计。
- **NFR**：
  - 性能：备份打包 < 30 秒（500 题 + 图片，点击备份到 ShareSheet 弹出）；CSV 导入 < 5 秒（1000 行，选择文件到入库完成）。
  - 内存：备份/恢复 < 200MB（流式 ZIP 写入，不全量加载）；CSV 导入（1000 行）< 80MB（解析流逐行处理，不全文加载到内存）。
  - 中断恢复：恢复前自动备份当前数据作为安全网（备份完整性）。


## 5. Contracts（备份 / 恢复 / 数据导入导出）

### A. 操作状态

- 备份、恢复、CSV 导入、CSV 导出必须区分 idle / running / success / failure；运行中要有可见进度或明确等待反馈。
- 用户取消不等于失败；系统失败必须展示可理解错误，不只写日志。
- 同一时间只能有一个破坏性或长耗时数据操作；并发请求应禁用或排队。

### B. 数据边界

- 完整备份必须包含唯一资料库的必要数据和图片引用；恢复前必须先校验 schema / version，不得部分写入后才报错。
- CSV/JSON 导入导出属于本地文件操作，不暗示云同步或远程备份。
- 已知缺口：GAP-R6 指出 `CSVParser` 对字段不匹配不够严格；在修复前，UI 不应宣称 CSV 导入已覆盖所有格式错误。

### C. 隐私与安全

- 导出文件可能包含用户资料内容；分享前必须由系统 share sheet 或文件选择器显式交给用户确认。
- CSV 导出必须继续保留 formula injection 防护；图片备份不得重新引入 EXIF GPS/位置信息。

### D. Enforcement

| 契约项 | Enforcement |
|---|---|
| 备份/恢复四态 | Settings UI test / 手动实测 |
| schema/version 预校验 | Data 层契约测试 |
| CSV 字段严格性 | GAP-R6 后续修复测试 |
| 导出隐私防护 | Export/Backup 流程 review + dogfood |

## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P4 用户拥有数据·数据安全子条款） | `.zip` 是免费换机迁移出口；恢复前校验、失败不破坏现有数据、结果透明 |
| 产品政策 / ADR | `../../explanations/business-model.md`（B6-A） | 手动备份 / 恢复永久免费；Apple 私有同步只是候选假设 |
| 待验证假设 | `../../explanations/assumptions.md` H10（用户仅保存有权处理的个人资料） | 备份 / 导出边界与版权提示 |
| 验收证据 | §4 验证标准 GWT + AllTests | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（P4 数据属于用户 / 数据安全子条款）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 7：备份 / 恢复）
- 商业政策：`../../explanations/business-model.md`
- 相关 / 上位 feature：`feat-review.md`（复习进度随备份一并迁移）
