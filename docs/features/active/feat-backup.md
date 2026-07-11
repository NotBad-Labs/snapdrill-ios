---
id: feat-backup
title: 备份与 CSV 导入导出
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-07-11
intent_refs:
  - vision:P4
---

# Feature: 备份与 CSV 导入导出

> 人读摘要：已实现（免费）。派生自上方 frontmatter；状态总表由生成器维护，禁手改。

## 1. 为什么做 (Why)

- 本地存储意味着 App 必须给用户可靠的数据带走与恢复路径。ZIP 备份是完整恢复通道，CSV/JSON 是结构化数据可携带通道。
- 备份、恢复、CSV 导入导出均为免费基础能力，不作为订阅门槛。

## 2. 需求规则 (What)

- **ZIP 备份**：打包唯一资料库的资料、动态分类维度、分类值、复习字段和图片，通过系统分享面板导出。
- **恢复**：只接受当前 schema v3；先读 manifest 并验证版本，再读取 payload。旧 Profile schema 与未知 schema 直接拒绝，不做迁移。
- **完整回滚**：恢复前在资料库 `Recovery/` 目录创建当前状态的持久 ZIP 安全网。数据库或图片阶段任一失败时，用该 ZIP 回滚资料、分类和可用图片；全流程成功后才清理。
- **图片完整性**：用户主动备份遇到非法或缺失的引用图片必须失败，不产生“成功但不完整”的 ZIP；恢复在写库前校验 payload 引用的安全图片都存在于 ZIP。仅恢复前安全网允许跳过当前已缺失的图片，避免损坏库陷入备份/恢复死锁。
- **路径与体积防护**：图片 entry 只接受安全的 `images/` 相对路径；单 entry 解压上限 50MB，图片总实际提取字节上限 1GB。超限抛可捕获错误并触发回滚。
- **CSV 导出**：导出结构化字段与 OCR 文本；以 `=+-@` 开头的 cell 前加 tab，防止电子表格公式注入。
- **CSV 导入**：用于从其他工具批量迁移资料；内置维度通过稳定 `systemKey` 跨语言匹配，自定义列可生成动态维度。
- **边界**：不做自动本地备份、不做云端备份；CloudKit 同步是独立的 Pro backlog。

## 3. 技术设计 (How)

- `BackupService`（actor）负责 ZIP 创建、manifest/payload 提取、图片暂存和原子提交；依赖 ZIPFoundation。
- `BackupManifest.currentSchemaVersion == 3`。`data.json` 顶层直接包含：
  - `reviewItems`
  - `dimensions`
  - `categoryValues`
- 图片以 DTO 中的安全相对路径直接写入 ZIP，例如 `images/<uuid>.jpg`，不含 Profile ID 或目录层。
- `SettingsBackupCoordinator` 负责编排：版本/payload/图片完整性预检 → 持久安全网备份 → DB 替换 → 图片暂存/提交 → 失败回滚 → 成功清理。
- `RepositoryContainer.restore(from:)` 在一次 save 中替换资料与 taxonomy；失败 rollback context。
- 图片恢复先将全部 entry 写入 staging 目录，再逐文件替换目标；提交失败由外层持久 ZIP 回滚。SwiftData 与文件系统无法共享单一事务，进程在 DB 提交后、图片提交前被强杀仍是已知 P2 窗口；遗留 Recovery ZIP 的启动时呈现与清理策略待后续专刀。
- 解压总量按实际提取字节累计，不信任 ZIP header 的 `uncompressedSize`；header 仍用于单 entry 提前拒绝。
- CSV 解析与导入由 Settings feature 负责；当前 parser 对字段数不匹配仍是 best-effort 映射，严格 RFC 4180 行拒绝与错误摘要是已知缺口。

## 4. 验证标准 (Verify)

- Given 资料库含资料、taxonomy 与图片，When 创建 v3 备份并恢复到空库，Then 所有字段、关联和图片 round-trip 一致。
- Given 资料库只有 taxonomy、没有资料，When 恢复图片阶段失败，Then taxonomy 也从自动备份恢复。
- Given schema v1/v2/未知或高于 v3，When 恢复，Then 在写数据库前拒绝，现有资料库不变。
- Given ZIP 含 `..`、绝对路径、反斜杠或越界 entry，When 恢复，Then 不在资料库外读写文件。
- Given ZIP header 谎报体积，When 实际提取总量超过 1GB，Then 仍拒绝并回滚。
- Given 当前资料库已引用缺失图片，When 从完整 ZIP 恢复，Then 安全网备份不得阻断恢复。
- Given 输入 ZIP 在 payload 或图片完整性预检失败，When 恢复被拒绝，Then 不创建 Recovery ZIP、不改写当前资料库。
- Given CSV cell 以 `=+-@` 开头，When 导出，Then 文件打开时不会执行公式。

## 5. Wire Contract

```text
backup.zip
├── manifest.json   # schemaVersion, createdAt, appVersion, totalItemCount
├── data.json       # reviewItems, dimensions, categoryValues
└── images/
    └── <uuid>.jpg
```

- v3 是 2026-07-11 单一资料库重基线；零用户阶段明确不兼容旧 Profile wire。
- 从首个真实用户/公开测试构建开始，任何 wire 变更必须递增 schema 并先裁决兼容策略，不能再静默重置。
- golden fixtures 位于 `Packages/SnapDrillData/Tests/SnapDrillDataTests/Fixtures/BackupWireV3/`。

## 6. Enforcement

| 契约项 | Enforcement |
|---|---|
| v3 wire 字段稳定 | `BackupDTOTests` golden fixtures |
| round-trip、图片完整性与 staging | `BackupServiceTests` |
| 实际字节体积上限 | `BackupServiceSizeLimitTests` |
| DB 字段/关系恢复 | `RepositoryContainerBackupTests` |
| 旧 schema 拒绝、失败回滚 | `SettingsViewModelTests` |
| CSV 注入与动态维度 | Settings CSV/DataExporter tests |

## 意图追溯

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| PO 裁决 | 2026-07-11：单一资料库、无旧 Profile 数据迁移 | schema v3 直接 payload；旧 schema 拒绝 |
| Vision | `../../explanations/vision.md` P4 | 用户可备份、恢复、导出并带走数据 |
| 验收证据 | §4 + targeted tests | 见 Enforcement |

## 关联

- 单一资料库：`feat-local-library.md`
- iCloud 同步：`../backlog/feat-icloud-sync.md`
- 隐私与安全：`../../explanations/privacy-compliance.md`
