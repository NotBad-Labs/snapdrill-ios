---
last_verified: 2026-07-15
layer: contract
release: 1
activation: effective_when_merged_to_develop
ratified_inputs: ["B4-A", "B5-A", "DATA-1", "DATA-1-R", "D1-B", "D3-B", "D5-A"]
freshness:
  max_age_days: 180
  decay_trigger: [local_library_layout_change, backup_schema_change, recovery_state_change, compatibility_epoch]
---
# Local Library Data Contract

> 本文是 Release 1 **单一本地资料库**的存储所有权、生命周期、恢复状态与故障语义权威。
> 它承接已批准的 DATA-1 / DATA-1-R / D1-B / D3-B / D5-A，合入 `develop` 后生效。
> 当前 Multi-Profile / ZIP v2 代码只作偏差证据，不能反向改写本文。

## 1. 权威边界

本文唯一拥有：

- 单一本地资料库的语义 inventory；
- App 沙盒内的持久、可恢复、可重建和一次性存储根及其生命周期；
- live generation、破坏性替换、启动协调与 recovery incident 状态；
- D3-B 内部 pre-restore recovery artifact 的闭合 inventory；
- Profile-free runtime、同设备偏好与 epoch 前遗留材料的边界；
- 对应错误类别、fault matrix 与实现 DoR。

[Backup Wire Format](backup-wire-format.md) 单独拥有外部 `.snapdrillbackup` 的
`application_id`、`user_version`、DDL、object allowlist、兼容转换与 golden fixtures。D1-B
只批准 SQLite container family；精确 DDL 是跨 epoch 的不可逆 wire 政策，须经独立审阅与 PO
批准后才能成为 effective。本文只提供它必须承载的 Profile-free 语义 inventory，不建立第二份 wire
schema。

本文不授权实现、修改 SwiftData `MigrationPlan`、改 v2 fixture、迁移 epoch 前 Profile 数据、删除
遗留目录、合并 PR、上传 build 或开放 TestFlight。

## 2. 单一资料库 inventory

Release 1 恰有一个隐式本地资料库，没有用户可见或 wire 可见的 Profile ID、名称、数量、选择或切换状态。

资料库 inventory 包含：

1. 所有已保存资料的稳定 ID、文字、创建时间和答案文字；
2. 每条资料引用的 App-managed 主图和答案图字节；
3. 用户分类 / 字段定义、字段值和全部关联；
4. 已存在的 Review 状态，包括明确的 `neutral`（从未初始化）与已调度状态；隐藏 Review 不得丢弃已有状态，也不得为普通新资料自动创建调度；
5. 解释上述内容所需的 schema 与完整性 metadata。

以下内容不属于资料库 inventory：未保存草稿、设备偏好、可重建缓存、导出 scratch、诊断数据、
recovery incident、外部用户文件。D5-A 的 Clear Library 只能删除资料库 inventory；其他所有权类继续
遵循各自生命周期。

完整 inventory 必须满足引用闭包：ID 在所属表内唯一；每个字段值恰好属于一个存在的字段；每条
资料-字段值关联两端均存在且不重复；每个声明为存在的图片引用恰好解析到一个普通 JPEG 文件。不得以
`flatMap` / `compactMap` 或置空路径的方式把损坏关系解释为成功。

## 3. 路径与生命周期

`AS` 表示通过 `FileManager` 获取的 Application Support URL，再追加固定组件
`com.snapdrill.global`；不得手拼 sandbox 绝对路径。`Caches` 与 `temporaryDirectory` 同样通过
`FileManager` 获取。

| 固定路径 | 所有内容 | 生命周期与设备备份 |
|---|---|---|
| `AS/LocalLibrary/active-generation` | 当前 generation 的规范 UUID selector | 持久；普通文件；不得排除设备备份 |
| `AS/LocalLibrary/generations/<uuid>/library.store` | 当前或可回滚 SwiftData store | 持久；active 可由 runtime 打开，inactive 必须不可变；不得排除设备备份 |
| `AS/LocalLibrary/generations/<uuid>/images/` | 该 generation 的 App-managed JPEG | 与 store 同一 generation；不得排除设备备份 |
| `AS/LocalLibrary/transactions/<uuid>/journal.json` | 一个破坏性操作的确定性 journal | 直到 commit / rollback 被验证；不得排除设备备份 |
| `AS/LocalLibrary/transactions/<uuid>/prestate.json` | D3-B recovery-only inventory | 直到 commit / rollback 被验证；失败时整体转入 incident |
| `AS/LocalLibrary/transactions/<uuid>/input.snapdrillbackup` | 用户选择文件的隔离副本 | operation 期间持久、排除设备备份；绝不是唯一 rollback 材料 |
| `AS/LocalLibrary/transactions/<uuid>/candidate/` | 尚未发布的新 generation | operation 期间持久、排除设备备份；发布前移入 `generations/` |
| `AS/RecoveryIncidents/<uuid>/` | incident metadata、journal、prestate、原始 / candidate 材料 | 未解决时不按时间、数量或空间自动淘汰；不得排除设备备份；仅 DATA-1-R 明确动作可删 |
| `AS/Drafts/` | 未保存采集草稿 | 独立于资料库；崩溃可恢复；排除设备备份；叶子格式由 Capture contract 维护 |
| `AS/Diagnostics/MetricKit/` | 有界端侧诊断 | 排除设备备份；不依赖 App Group；不属于 Backup 或 Clear Library |
| `Caches/com.snapdrill.global/` | 只含可重建派生物 | 系统管理且可清；删除不得影响任何已保存或可恢复内容 |
| `temporaryDirectory/com.snapdrill.global/<uuid>/` | 可丢弃导出 / 导入 construction | terminal outcome 后删除；不得放唯一 rollback 副本或未解决 journal |
| 用户选择 URL / 系统 share destination | 最终 `.snapdrillbackup` 或 PDF | 用户所有；App 内部 live 目录永不作为文档位置暴露 |
| `Documents/profiles*` | epoch 前开发遗留 | 正常启动不得读取、创建、选择或自动删除 |

所有 App-owned 固定节点必须是预期类型的普通文件或目录；任一级 symlink、hard-link 身份异常、未知
固定名、越界标准化路径或 node-type 不符均 fail closed。生产持久文件显式采用
`completeUntilFirstUserAuthentication` data protection；用户导出的文件遵循目标 URL / 系统
surface 的保护策略。可重建和一次性材料不得因方便而升级为用户数据真相。

## 4. Runtime 与 generation

生产环境只有一个 concrete local-library runtime，统一拥有 `DataExecutor`、`ModelContainer`、
repositories、`ImageStorage`、上述路径和启动恢复状态。不得通过通用 storage protocol、manager
层级或临时 executor 产生第二个未观测 runtime。

### 4.1 Selector grammar

`active-generation` 恰为一个小写 canonical UUID 加一个 LF，共 37 个 ASCII byte；不得含 BOM、空格、
第二行或相对路径。它只可指向 `generations/<same-uuid>/`。

仅当 selector、generation、transaction 和 incident 全部不存在时，启动才可判定为真正 first
launch，并创建初始空 generation。其余 selector 缺失、损坏或悬空均为恢复阻塞，禁止自动发布一个
新空库或退化为 production in-memory store。

### 4.2 Closed generation

active generation 在 runtime 打开时可以有 SQLite/SwiftData sidecar。进入破坏性操作前必须：

1. 阻止新写入并等待 `AppActivityTracker` 中在途写操作结束；
2. 完成保存，释放持有 store 的 runtime；
3. checkpoint 已提交 WAL，并证明 inactive generation 的 durable truth 是一个普通
   `library.store` 加 `images/`；不能把 `-wal` / `-shm` 当成未记录的必要副本；
4. 对 store 与全部图片建立 D3-B prestate inventory，再开始 candidate publication。

任何一步失败都在 selector 仍指向旧 generation、零 active mutation 时终止。

### 4.3 Journal grammar

`journal.json` 是 version `1` 的具体 JSON object，至少包含：`transactionID`、
`operation`（`restore` / `clearLibrary` / `storeRecovery`）、`phase`、`oldGeneration`、
`newGeneration`、`createdAt` 和 `updatedAt`。UUID 使用小写 canonical form，时间使用 UTC RFC 3339。
路径全部由 ID 和固定根推导，journal 不接受任意路径字段。解析未知 version、operation、phase、字段
类型或 ID 时进入 `blocked`，不得猜测。

同一时刻最多一个 non-terminal transaction。启动必须先协调 journal，之后才可构建
`ModelContainer`。

| Phase | selector / 必须行为 |
|---|---|
| `prepared` | selector 仍为 old；old 已关闭并通过 prestate 验证；new 已完全构造和验证 |
| `published` | selector durable 地指向 new；只允许打开并验证这个 generation |
| `rollingBack` | 正在 durable 地把 selector 恢复为 old；随后只打开并验证 old |
| `committed` | new runtime 已打开且验证；old / prestate cleanup 幂等；journal 最后删除 |
| `rolledBack` | old runtime 已打开且验证；new cleanup 幂等；journal 最后删除 |
| `blocked` | 前滚和回滚均不能证明；全部材料原样转入一个 incident，不发布健康空库 |

selector 的替换是唯一 commit point。写 selector 的 API 只有在进程于任意指令后终止并重启时，磁盘上
仍必然得到完整 old 或完整 new selector，才可报告成功；实现可选择具体 durable-write primitive，
但必须用 fault injection 证明这一结果。

重启遇到 `prepared`：selector=old 时回滚且不改 active inventory；selector=new 时按 `published`
前滚。遇到其他、缺失、第三个或 malformed selector 值时进入 `blocked`。所有 cleanup 可重复执行，
但只有目标 runtime 重新打开并通过验证后才能删除 journal。

## 5. D3-B recovery-only inventory

`prestate.json` 是 version `1`、`artifactKind: recovery-only` 的具体 JSON object，包含
`transactionID`、`sourceGeneration`、`createdAt`、`store` 和 `imageReferences`。它只能位于内部
transaction / incident，不能使用 `.snapdrillbackup` 扩展名，也不能进入外部 reader。

`store` 固定记录 `library.store` 的 checked 64-bit byte count 与 SHA-256。`imageReferences` 对每个
数据库图片引用恰有一条记录：`itemID`、`role`（`main` / `answer`）、规范相对路径和 `state`。

- `present`：还必须记录 checked byte count 与 SHA-256；文件必须是同一 generation `images/` 下的
  普通 JPEG，完整读取和 digest 后才成立。
- `missing-at-snapshot`：只能用于路径在 node lookup 时真正不存在；记录不得包含 byte count 或
  digest。

存在但不可读、symlink、非普通文件、lookup 前后身份改变、长度改变或 digest 不符都使 prestate
失败并在零 active mutation 时中止。`missing-at-snapshot` 只适用于图片；字段 / 分类引用不得缺失。
数组顺序和 JSON whitespace 不构成 wire 兼容，但 tuple 必须唯一且语义 closure 必须逐项验证。

外部完整 Backup v3 永远只接受 `external-complete`，不能识别、转换或降级接受 recovery-only
inventory。普通导出遇到缺图必须失败，而不是把内部 D3-B 语义泄漏到用户备份。

## 6. Recovery incident

incident metadata version `1` 至少包含 incident UUID、来源 transaction、创建时间、稳定 error code、
当前 `status` 和所含固定材料清单。status 只有：

- `decisionRequired`：启动或 destructive operation 被阻塞，用户必须选择恢复或空库继续；
- `retained`：用户已明确以空库继续，但 DATA-1-R 材料仍保留并可管理。

metadata 缺失、损坏、未知 version 或清单与节点不符时按 unclassified blocking incident 处理，不得
隐藏或删除。失败 / 取消导出不改变 status；显式删除只删所选 incident；“导出并删除”必须在目标文件
durable 成功后才删。四个以上 incident 仍须 byte-identical 保留，不得 count-prune。

## 7. 偏好与 legacy epoch

单资料库 runtime 不读写 `activeProfileId`、`profiles.json`、Profile 名称或 `preferences.json`。同设备
升级继续保留 Release 1 支持的全局偏好：`AppleLanguages`、`appearanceMode`、`appTintColor`、
`hasCompletedOnboarding`、`captureFieldAnswer` 和 `capture_dim_visible_*`。当前已隐藏的身份、Review、
SmartPaper 配额与提醒键不能驱动 Release 1 行为；D5-A 也不得借 Clear Library 删除语言 / 外观或
其他仍存在的设备偏好。

epoch 前 `Documents/profiles*`、per-Profile preferences、draft 和 Backup v1/v2 没有迁移承诺。正常
启动不得扫描、导入、合并、选择或自动删除它们。v1/v2 用户选择文件须在任何 extraction、SQLite
mutation 或 active-library mutation 前，以稳定的 `developmentBackupUnsupported` 结果明确拒绝；
不得保留一个通用 ZIP parser 只为走到 manifest 后才失败。

## 8. 稳定错误类别

实现类型名和本地化文案可变，但测试与 UI 必须保留以下语义类别：

| Code | 语义 |
|---|---|
| `libraryRootUnsafe` | 固定根、node type 或路径身份不可信 |
| `activeSelectorInvalid` | selector 缺失、malformed、悬空或指向未知 generation |
| `libraryStoreUnavailable` | 目标 store 不能打开或不能证明完整，禁止假空库 |
| `prestateSnapshotFailed` | old generation 或 D3-B inventory 不能在零 mutation 时冻结 |
| `recoveryInventoryMismatch` | store / 图片 digest、长度、引用或 missing 声明不一致 |
| `developmentBackupUnsupported` | epoch 前 v1/v2 开发备份被明确拒绝 |
| `backupFormatUnsupported` | 外部 application ID / version 不受支持 |
| `backupIntegrityFailed` | 外部文件结构、schema、digest 或图片解码失败 |
| `backupReferenceMismatch` | duplicate / dangling / nil taxonomy 或图片关系 |
| `insufficientStorage` | checked capacity preflight 或写入遇到空间不足 |
| `publicationFailed` | new generation 未能 durable 发布；尝试确定性 rollback |
| `rollbackFailed` | old generation 也无法恢复；创建 blocking incident |
| `recoveryDecisionRequired` | incident 必须由用户选择后才能继续普通启动 |

原始底层错误只进入隐私安全日志 / incident metadata，不直接代替可理解的用户结果。

## 9. 验证与实现 DoR

实现必须以 deterministic fault injection 覆盖：

- fresh install 创建一个根、一个 generation，且不读 / 建任何 Profile artifact；
- 每个目录、store、图片、journal、selector 写入点失败；
- prestate 任一步失败时 selector 与 active inventory byte-identical；
- 进程在每个 phase 和 selector replacement 前后终止；
- database commit 与图片 publication 各自先失败；
- D3-B 合法 missing、谎报 missing、present 不可读、digest / 长度变化；
- duplicate ID、nil / unknown dimension、unknown value、duplicate join 与图片引用不闭合；
- disk-full、symlink、node substitution、malformed metadata、多个 non-terminal journal；
- 前滚、回滚和双失败重启；四个以上 incident 不被淘汰；
- v1/v2 在 mutation 前得到具体拒绝；同版正式 writer 输出总能通过同版 reader 并恢复；
- production 没有临时 executor、in-memory fallback 或自动 empty-store publication 路径。

Backup / restore 全程内存须低于 [NFR](non-functional-requirements.md) 的 200 MB，图片使用增量 I/O；
writer / reader 不能设置一个小于产品可创建资料库的隐藏总量上限。具体 Swift 类型、actor 隔离、SQLite
wrapper、statement batching、BLOB chunk size、进度 UI 和低层 durable-write primitive 由实现选择，
但不得改变本文可观察状态或引入通用 manager / protocol 层。

在以下条件满足前，不得开始 production switch：

1. [Backup Wire Format](backup-wire-format.md) 的 v3 精确 DDL / limits / fixtures 已单独获批并 effective；
2. draft、incident、Clear Library 与 hidden-capability owners 都指向本文而不复制路径表；
3. fault harness 能在独立目录逐点注入失败；
4. clean-install candidate 证明 Profile 路径零读取 / 零创建；
5. 每个实现与合并 slice 仍分别获得授权。
