---
id: feat-backup
title: 备份与 CSV 导入导出
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-07-15
intent_refs:
  - vision:P4
release_refs:
  - release-1:C2-Optional
  - release-1:DATA-1
  - release-1:DATA-1-E
  - release-1:DATA-1-R
  - release-1:D1-B
  - release-1:D3-B
  - release-1:#891-copy
---

# Feature: 备份与 CSV 导入导出

> **产品重基线（2026-07-15）**：B4-A 将手动备份 / 恢复确立为永久数据权利，Release 1 Contract 的 DATA-1 / DATA-1-E / DATA-1-R 固定 epoch、完整备份、未加密提示和恢复材料保留边界。D1-B 选择 purpose-built SQLite `.snapdrillbackup`，D3-B 固定 degraded pre-restore snapshot 语义，#891 固定逐次导出提示文案。frontmatter 与技术章节仍只记录当前实现；现有 Profile ZIP wire、图片 best-effort 与自动清理是待 owning Data Contracts 收敛的偏差，不得冒充目标已实现。

> 人读摘要：🧩 当前实现存在（当前分层：free）。派生自上方 frontmatter；frontmatter 仅是本功能实现状态的单一来源，不表示 Release 1 合同符合、公开可达或发布就绪。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys / tech 聚合（docs 重组 B）。

## 1. 为什么做 (Why)
- **痛点 / 价值**：local-first 意味着用户必须有可靠的数据携带出口；换机、卸载或设备损坏都可能导致仅存本机的资料丢失。单一 `.snapdrillbackup` application document 让迁移成为可执行路径，确保数据可携带、不被平台锁定。
- **定位**：`.snapdrillbackup` 是免费用户换机的完整迁移出口，**不是象征性导出**；普通 ZIP 工具直接浏览内部图片不是 Release 1 要求。CSV 导入定位为**数据可携带权场景**（从其他工具迁移进 SnapDrill），不是主推录入路径，不应在 UI 上与拍照同级展示。
- **原则归属**：P4 数据属于用户（隐私是核心差异化）+ 其数据安全子条款「保存可靠、删除可撤销、备份可用」。导出/备份是「数据属于用户」的体现而非口号——可导出、可打印、可带走。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **手动备份（D1-B）**：purpose-built SQLite `.snapdrillbackup` application document 覆盖唯一资料库的主数据、图片、元数据、回顾进度和必要配置，通过系统分享面板交给用户保存。它不是 live SwiftData store、WAL 副本或通用 ZIP。
- **完整覆盖**：备份默认覆盖完整资料库，不提供容易造成漏备的局部容器选择。
- **恢复安全规范**：仅在文件完整性与版本兼容性满足要求时执行恢复；不满足时必须**拒绝恢复且保持现有数据不变**。
- **兼容生命周期**：DATA-1 定义正式兼容 epoch 与 epoch 前开发格式处置；不得把当前 v1 / v2 fixture 或“无测试用户”外推成永久兼容或任意破坏授权。本地 inventory / 恢复生命周期与外部 wire 分别下沉各自 Data Contract。
- **完整备份语义**：外部完整备份严格 all-or-nothing，损坏 store 的部分 salvage 是独立路径。当前元数据原子、图片 best-effort 只作实现偏差证据。
- **内部恢复快照（D3-B）**：外部完整备份仍不得缺图。内部 pre-restore recovery artifact 可以精确记录当前资料库在快照时已经缺失的图片，但必须有 recovery-only marker 和闭合的 `present` / `missing-at-snapshot` inventory；外部 reader 不得接受它作为完整备份。
- **CSV 导出**：结构化字段与 OCR 文本摘要，可用 Excel 打开，以实际导出字段清单为准；属于 C2-Optional，默认隐藏，只有冻结 manifest 显式纳入才可见。
- **CSV 导入**：Candidate optional，默认隐藏；只有 GAP-R6 字段数量严格性修复完成、冻结 manifest 显式纳入并通过数据完整性门禁后才可见。
- **边界 / 不做**：不做自动本地备份（增加存储负担）；Apple 私有同步是未来候选，不属于当前备份职责；导入文件损坏 / 不可读时提示重新选择，不破坏现有数据。
- **前置依赖**：无。备份 / 恢复经 `AppActivityTracker` 互斥保护，关键操作期间阻止破坏性数据操作。
- **商业政策**：手动备份 / 恢复是 B4-A 的永久免费数据权利，不得成为订阅门槛。B6-A 下 Release 1 免费、无广告、无 IAP；iCloud、图片增强和高级导出都只是候选假设。

## 3. 技术设计 (How)
- **模块归属**：
  - 当前备份引擎 `SnapDrillData`（`BackupService` 做 Profile ZIP v2 备份/恢复，actor 隔离；`BackupDTO` 备份数据传输对象；依赖 `ZIPFoundation`）。这是 epoch 前实现事实。D1-B 的 v3 writer / reader 必须使用 purpose-built SQLite application-file schema，不能复用 live SwiftData store。
  - 当前 backup wire 兼容 gate 只读取 `BackupManifest.schemaVersion`。`MigrationPlan` 只处理本机 SwiftData store schema，`ProfileMigration` 只处理现有开发期 Profile 结构；两者都不是 backup archive 字段或外部 wire 版本判定器。本地 inventory、generation / journal 与 D3-B 以 [Local Library Data Contract](../../reference/local-library-data-contract.md) 为唯一权威。
  - CSV 解析 `SnapDrillFeatureSettings/CSVParser.swift`（RFC 4180，enum 纯函数，与 ViewModel 状态分离）；JSON/CSV 导出 `SnapDrillFeatureSettings/DataExporter.swift`（含 `=+-@` 前缀防注入）；导入流程编排 `SettingsViewModel.swift`（解析 + 字段映射 + 写入 repository）。
- **关键机制 / 数据流**：
  - 当前 ZIP v2 备份包包含 `BackupManifest.schemaVersion` 等 [开发期 wire v2](../../reference/backup-wire-format.md) 已冻结元数据，用于恢复前判定接受或拒绝；正式 `.snapdrillbackup` wire 的 DDL、版本演进、只读 hostile-file 打开顺序、增量 BLOB I/O、digest、容量闭包与 App 内转换策略由 [Backup Wire Format](../../reference/backup-wire-format.md) 固化，不从 `MigrationPlan` 推导。
  - **恢复前校验**：先验证文件可读性、结构完整性、版本兼容性，校验失败直接拒绝并保持现有数据不变。
  - **当前恢复前安全网**：执行恢复前将当前数据快照到沙盒临时目录；现有“成功后保留到下次启动自动清理”是实现事实。DATA-1-R 要求损坏 store 与恢复前滚 / 回滚双失败后选择空库继续的 incident-bound 源材料、安全快照和只读失败态保留到用户显式删除；普通导出不清理，只有已确认且成功的“导出并删除”可以清理。普通成功 restore 只可清理 disposable staging，不得清理 incident-bound 材料。具体 retention 与状态以 [Local Library Data Contract](../../reference/local-library-data-contract.md) 为准。
  - **D3-B 快照约束**：每个图片引用必须唯一声明为 `present` 或 `missing-at-snapshot`。`present` 必须逐字节读取、digest 校验并进入快照；已有文件但不可读时在 active-library mutation 前失败。`missing-at-snapshot` 只重建原先已经缺失的状态，不能放宽 taxonomy / metadata reference closure，也不能进入外部完整 Backup。
  - **当前 Multi-Profile 提交策略（待 Data Contract 重基线）**：`SettingsViewModel.restoreFromBackup` 按 Profile sequential 提交；这是 `develop` 实现事实，不是目标产品行为。单资料库后的 wire、提交和回滚策略不得从本 spec 推导。
  - **CSV 注入防护（导出）**：导出 CSV 时以 `=+-@` 开头的值前加 tab。
  - **CSV 解析（导入）**：严格 RFC 4180——引号转义、CRLF/LF 兼容、字段数不匹配则整行拒绝并提示用户。
    - **⚠ 实现现状（GAP-R6，代码债）**：当前 `CSVParser` 按表头列尽力映射（缺列填空、多列丢弃），**未对字段数不匹配做严格校验与整行拒绝/提示**。需求不变（数据完整性优先，严格拒绝 + 提示哪些行被拒），待 code 债修复。
- **State & Concurrency**（Swift 6 strict）：备份/恢复流程由 `SettingsViewModel`（`@Observable`，`@MainActor`）编排；当前 ZIP v2 打包/解包重活在 `BackupService`（actor 隔离）执行，不阻塞主线程；单 Profile 内 DB 恢复经 `RepositoryContainer` 单次 saveContext（失败 rollback）。`CSVParser` 为无状态纯函数层，与 ViewModel 状态分离。
- **设计裁决（仅本模块）**：恢复目标是「完整成功或完整失败」，当前实现达成**单 Profile 维度原子**（DB 事务原子 + 图片 best-effort），**多 Profile 全局原子事务尚未实现**——这是已知与目标的差距，单 Profile 安全网兜底，不外推为已达成全局原子。

## 4. 验证标准 (Verify)
- **Success path (GWT)**：Given 唯一资料库中有数据，When 用户发起手动备份，Then 系统把资料、图片、元数据、回顾进度和必要配置写为一个 `.snapdrillbackup` 并交用户保存 / 分享；Given 用户持有兼容 `.snapdrillbackup`，When 发起恢复且校验通过，Then 资料库内容与备份一致。
- **边界 / 异常**：
  - 备份文件损坏/不可读 → 拒绝恢复，现有本地数据完全不变（Boundary B04, S0）。
  - 备份版本高于当前 App → 拒绝恢复并提示版本不兼容、建议升级 App（Boundary B09）。
  - 备份版本低于当前 App 但在兼容范围内 → 允许迁移恢复；失败时不得破坏现有本地数据。
  - 恢复写入中途失败 → 当前实现提示失败并尽力回滚，图片仍可能 best-effort 缺失；DATA-1 要求正式外部完整备份整包失败且原资料库不变，部分 salvage 另走明确路径（Boundary B05, S0）。
  - 当前 Multi-Profile 备份恢复的中途失败行为属于实现风险清单，必须在单资料库 Data Contract 中明确收敛，不能继续作为目标验收。
  - 当前资料库引用的图片在快照前已缺失 → recovery-only snapshot 以 `missing-at-snapshot` 记录并可继续；文件存在但不可读、inventory 撒谎或 digest / reference 不闭合 → 零 mutation 拒绝开始。
  - 磁盘空间不足 → 恢复前检查可用空间，不足则拒绝开始恢复并提示。
  - CSV/JSON 导出磁盘写满 → 提示导出失败、清理临时文件，不生成损坏文件，原数据不受影响（Boundary B07, S1）。
  - 导入文件损坏/不可读 → 提示文件不可用、允许重新选择，现有数据不变（Boundary B08, S1）。
  - 缓存清理 → 只清理 `Caches/` 临时文件，不触碰 `Documents/` 或 `Application Support/`；不得导致 App-managed 主图、备份文件、SwiftData 数据丢失（Boundary B23, S0）。
- **数据保证**：
  - 备份生成失败不得产生「文件已导出」假象。
  - 恢复不得读写资料库之外的数据；当前 DB rollback / 图片 best-effort 是实现事实，不得冒充 DATA-1 的严格完整恢复已达成。
  - 任何恢复失败均不得损坏恢复前的现有本地数据。
  - CSV/JSON 导出以实际导出字段清单为准，不得静默宣称为全字段导出；导出为只读操作，不修改题目主数据/复习状态/统计。
- **NFR**：
  - 性能：备份打包 < 30 秒（500 条 + 图片，点击备份到 ShareSheet 弹出）。CSV 导入 < 5 秒（1000 行）只在 GAP-R6 修复且冻结 manifest 纳入该 optional 后成为候选门禁。
  - 内存：备份/恢复 < 200MB；SQLite image BLOB 必须增量读写，不得把单张图片、全库图片或整个数据库物化为一个 `Data`。CSV 导入（1000 行）< 80MB 只在满足同一纳入前置后适用。
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

- Release 1 备份未加密。调用系统 share sheet / 文件选择器前，App 必须明确警告该文件可能包含私人文字与图片；系统面板中的二次确认不能替代这条 App 内提示。
- 每次导出在生成备份前展示同一提示，不提供 remembered bypass。PO 批准的精确文案为：
  - zh-Hans 标题：`导出未加密备份？`；正文：`备份文件未加密，可能包含私人文字和图片。请仅保存到可信位置，或分享给可信对象。`；主操作：`继续导出`；次操作：`取消`。
  - English title: `Export an unencrypted backup?`; message: `This backup is not encrypted and may contain private text and images. Save it only to a trusted location, or share it only with people you trust.`; primary action: `Continue Export`; secondary action: `Cancel`.
- Cancel 不创建备份、activity 或系统分享面；Continue 只生成一次并只展示一个系统分享面。分享面关闭后清理 App-owned 临时源文件；删除失败必须保留精确重试记录并显示非成功状态，不能用 `try?` 丢失未加密完整副本的所有权。
- CSV 导出必须继续保留 formula injection 防护；图片备份不得重新引入 EXIF GPS/位置信息。

### D. Enforcement

| 契约项 | Enforcement |
|---|---|
| 备份/恢复四态 | Settings UI test / 手动实测 |
| schema/version 预校验 | Data 层契约测试 |
| D1-B SQLite hostile-file / capacity closure | exact-schema、integrity、FK/reference、sidecar/symlink、incremental BLOB、writer-reader round-trip 与 adversarial corpus |
| D3-B degraded snapshot | recovery-only marker/inventory contract tests + pre-mutation fault tests |
| CSV 字段严格性 | GAP-R6 后续修复测试 |
| 未加密备份隐私提示 | UI / AX test + Export/Backup dogfood：提示先于系统分享面板且明确包含私人文字与图片 |
| 其他导出隐私防护 | Export/Backup 流程 review + dogfood |

## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P4 用户拥有数据·数据安全子条款） | `.snapdrillbackup` 是免费换机迁移出口；恢复前校验、失败不破坏现有数据、结果透明 |
| Release 1 Contract | `../../reference/release-1-contract.md` C2-Optional / DATA-1 / DATA-1-E / DATA-1-R / D1-B / D3-B / #891-copy | CSV 可携带性辅助默认隐藏；epoch、SQLite application document、完整备份、未加密提示、degraded internal snapshot、逐次提示文案与恢复材料保留已固定；现有 v2 / best-effort / 自动清理不构成目标 |
| Local Library Data Contract | `../../reference/local-library-data-contract.md` | Profile-free inventory、generation / journal、D3-B prestate 与 incident 生命周期 |
| 产品政策 / ADR | `../../explanations/business-model.md`（B6-A） | 手动备份 / 恢复永久免费；Apple 私有同步只是候选假设 |
| 待验证假设 | `../../explanations/assumptions.md` H10（用户仅保存有权处理的个人资料） | 备份 / 导出边界与版权提示 |
| 验收证据 | §4 验证标准 GWT + AllTests | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（P4 数据属于用户 / 数据安全子条款）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 7：备份 / 恢复）
- 商业政策：`../../explanations/business-model.md`
- 本地资料库数据契约：`../../reference/local-library-data-contract.md`
- 外部备份 wire：`../../reference/backup-wire-format.md`
- 相关 / 上位 feature：`feat-review.md`（复习进度随备份一并迁移）
