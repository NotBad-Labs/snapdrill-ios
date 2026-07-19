---
last_verified: 2026-07-19
layer: contract
release: 1
activation: effective_when_merged_to_develop
ratified_inputs: ["B4-A", "B5-A", "DATA-1", "DATA-1-R", "D1-B", "D3-B", "D5-A", "S1-A", "M1-A", "D4S-A"]
freshness:
  max_age_days: 180
  decay_trigger: [local_library_layout_change, backup_schema_change, recovery_state_change, compatibility_epoch]
---
# Local Library Data Contract

> 本文是 Release 1 **单一本地资料库**的存储所有权、生命周期、恢复状态与故障语义权威。
> 它承接已批准的 DATA-1 / DATA-1-R / D1-B / D3-B / D5-A / S1-A / M1-A / D4S-A，合入 `develop` 后生效。
> 当前 Multi-Profile / ZIP v2 代码只作偏差证据，不能反向改写本文。

## 1. 权威边界

本文唯一拥有：

- 单一本地资料库的语义 inventory；
- 资料文字、taxonomy、symbol 与 normalized JPEG 的产品接受边界；
- taxonomy 单值 / 多值转换的数据不变量；
- App 沙盒内的持久、可恢复、可重建和一次性存储根及其生命周期；
- live generation、破坏性替换、启动协调与 recovery incident 状态；
- complete / partial operation 分类、稳定 prestate 与 mutation barrier；
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

### 2.1 Release 1 内容与图片接受边界（S1-A）

以下是产品数据语义，不批准 Backup v3 的表名、列名、DDL 或 Swift 类型：

- 每条资料的 `content` 与 `answer_text` 语义字段各自必须是有效 UTF-8，编码后分别不超过
  1 MiB（1,048,576 byte）。
- 每个 taxonomy 名称，包括字段 / 分类定义名与可选值名，必须是有效 UTF-8，编码后不超过
  1,024 byte。
- 每个 SF Symbol 名称必须是有效 UTF-8，编码后不超过 256 byte。
- 每张写入资料库的 normalized JPEG 不超过 50 MiB（52,428,800 byte），宽和高每一维都不超过
  2,000 pixel。原始输入可以先经过不破坏用户确认内容真相的规范化；本项不要求仅因来源图片更大就
  直接拒绝。
- 除 checked integer / platform 可表示范围与实际可用存储外，Release 1 不设置额外的资料库总条数、
  总文字或总图片容量上限。性能样本和备份运行时防御值不得被解释为产品总量 cap。

所有入口、编辑、导入、恢复和正式 writer / reader 使用同一边界。无效 UTF-8、算术溢出或规范化后
仍超限时必须在 mutation 前拒绝；不得静默截断、丢字段、降采样到不可读结果或先部分写入再报错。

### 2.2 Taxonomy cardinality 转换（M1-A）

- `single -> multi` 可以直接完成，不改变已有资料关联。
- `multi -> single` 前必须对全部受影响资料做稳定检查；只有每条资料在该 taxonomy 下最多关联一个值
  时才可提交。
- 任一资料关联超过一个值时，整个 metadata mutation 在零部分变更下拒绝，并返回违反条件的资料数量。
  不得自动选择、删除或合并值，也不得只修改已满足条件的资料。

UI 文案、Swift 类型和数据库表达可以演进，但失败原子性、违反数量和关联保留语义不得改变。

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
| `AS/LocalLibrary/transactions/<uuid>/prestate.json` | `restore` / `clearLibrary` / `storeRecovery` 共享 envelope；前两者使用 closed-generation semantic inventory，`storeRecovery` 使用 unavailable-store raw inventory；D3-B 只细化 restore | 直到 commit / rollback 被验证；失败时整体转入 incident |
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

健康 active generation 在 runtime 打开时可以有 SQLite/SwiftData sidecar。进入需要 closed
generation 的 complete operation 前必须：

1. 占用唯一 complete-operation slot，并关闭新的 active-library mutation、partial-snapshot acquisition
   和 complete-operation admission；已经持久准入的 pending delete 事务仍可在原绝对期限内接受 undo，
   或在期限后执行幂等 hard delete，这两者是既有事务的终结而不是新 admission；
2. 等待已经准入的写操作结束，并让全部 pending delete / undo 仅按 D4-B 的持久绝对期限收敛；不得为
   建立快照而提前硬删除、拒绝期限内 undo 或静默撤销。settlement 超时 / 失败必须在 protected work
   前明确失败；
3. 完成保存，释放持有 store 的 runtime；
4. checkpoint 已提交 WAL，并证明 inactive generation 的 durable truth 是一个普通
   `library.store` 加 `images/`；不能把 `-wal` / `-shm` 当成未记录的必要副本；
5. 对 store 与全部图片建立稳定、闭合的 prestate，再开始 snapshot detach 或 candidate publication。

任何一步失败都在 selector 仍指向旧 generation、零 active mutation 时终止。

### 4.3 Complete operation 与 mutation barrier（D4S-A）

contract-defined complete operations 只有：

1. 生成外部完整 `.snapdrillbackup`；
2. `restore`；
3. `clearLibrary`；
4. `storeRecovery`。

健康 runtime 上的完整备份、`restore` 与 `clearLibrary` 必须先按 §4.2 关闭准入并获得稳定
inventory。`storeRecovery` 面向无法打开或证明完整的 store，不能伪造保存、checkpoint 或数据库引用
闭包；它在启动阻塞态使用 §5 的 unavailable-store raw prestate，且在 raw material durable 进入
incident 前不得发布空 generation。三种破坏性 operation 共用 `prestate.json` envelope，但使用
operation-specific closure。外部完整备份从闭合的 immutable source snapshot 生成，不得把任一内部
recovery artifact 作为用户备份。`missing-at-snapshot` 仍只属于 D3-B 明确允许的 pre-restore
semantic inventory，不扩散到其他 complete operation。

mutation barrier 从关闭准入开始，持续到以下任一可证明终点：

- 外部完整备份的 immutable source snapshot 已 durable 地 detached / finalized，不再依赖 active
  runtime；后续编码、用户提示和 share sheet 不继续阻塞资料库 mutation；
- 破坏性 publication 已验证，或 old generation 的 rollback 已验证；
- publication 与 rollback 均不能证明时，blocking incident 已 durable 建立，active runtime 不再处于
  未分类半状态，并完成进入恢复裁决面的 terminal cleanup。

protected work 开始前取消时，必须先让已经准入的 delete / undo 与 abort cleanup 到达 terminal
state；不创建 snapshot、不开始 mutation，随后才重新开放 admission 并报告取消。

同一时刻最多一个 complete operation。Settings JSON / CSV 与 selected PDF / CSV 属于 partial
exports：在 admission 关闭前已经取得 immutable snapshot 或 generation lease 的请求可以完成，并在
terminal outcome 前拥有其所需图片字节 / generation 生命周期；admission 关闭后新发起的请求立即以
`libraryOperationInProgress` 失败，不排队、不等待，也不产生输出。它们不使用共享 prestate，且不得
宣称覆盖完整资料库。D4S-A 不把 `backup` 添加为下方破坏性 journal operation，不批准 Backup v3
DDL / package / fixture 或具体并发实现。

### 4.4 Journal grammar

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

## 5. Shared prestate 与 D3-B recovery-only inventory

`prestate.json` 是 version `1` 的内部 object；shared envelope 包含 `transactionID`、`operation`、
`sourceGeneration`、`createdAt` 和 `artifactKind`，payload 必须且只能符合所属 operation 的一种
closure。它只能位于内部 transaction / incident，不能使用 `.snapdrillbackup` 扩展名，也不能进入
外部 reader。

`restore` / `clearLibrary` 使用 `artifactKind: recovery-only` 的 closed-generation semantic
inventory。payload 包含 `store` 和 `imageReferences`：`store` 固定记录 `library.store` 的 checked
64-bit byte count 与 SHA-256；`imageReferences` 对每个数据库图片引用恰有一条记录：`itemID`、
`role`（`main` / `answer`）、规范相对路径和 `state`。只有 `restore` 可以消费下述 D3-B
`missing-at-snapshot` 状态。

- `present`：还必须记录 checked byte count 与 SHA-256；文件必须是同一 generation `images/` 下的
  普通 JPEG，完整读取和 digest 后才成立。
- `missing-at-snapshot`：只能用于路径在 node lookup 时真正不存在；记录不得包含 byte count 或
  digest。

存在但不可读、symlink、非普通文件、lookup 前后身份改变、长度改变或 digest 不符都使 prestate
失败并在零 active mutation 时中止。`missing-at-snapshot` 只适用于图片；字段 / 分类引用不得缺失。
数组顺序和 JSON whitespace 不构成 wire 兼容，但 tuple 必须唯一且语义 closure 必须逐项验证。

`storeRecovery` 只使用 `artifactKind: unavailable-store-recovery`。因为 source store 无法打开或
证明完整，它不得解析数据库关系或声称 semantic inventory；payload 必须从可信 generation root
逐项冻结全部 source nodes，以 canonical root-relative path、node type、checked 64-bit byte count
和普通文件 SHA-256 证明 raw material closure，包括存在的 SQLite sidecar 与图片。symlink、
hard-link 身份异常、遍历前后替换、不可读或无法完整冻结均保持启动阻塞、selector 与 source bytes
不变。只有 byte-identical source generation 与该 inventory 已 durable 进入 DATA-1-R incident 后，
用户明确选择的空 generation 才可 publication；pending marker 只作为 raw store 内容保留，不执行、
不外传，也不被解释为已撤销或已删除。

外部完整 Backup v3 永远只接受 `external-complete`，不能识别、转换或降级接受 recovery-only
或 unavailable-store-recovery inventory。普通导出遇到缺图必须失败，而不是把内部恢复语义泄漏到
用户备份。

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
| `libraryOperationInProgress` | complete-operation admission 已关闭；新的 partial export 立即失败且不排队 |
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
- S1-A 每个 byte / pixel 边界的 limit 与 limit + 1、无效 UTF-8、checked overflow、规范化成功 / 失败，
  并证明所有拒绝都零 mutation、零静默截断；
- M1-A single -> multi 成功、multi -> single 成功、多个违反资料的精确 count，以及任一违反时 metadata
  与全部关联 byte-identical；
- 每个目录、store、图片、journal、selector 写入点失败；
- complete operation 关闭准入后 deadline 前 undo 仍成功、deadline 后只 hard delete 一次、settlement
  失败零 protected work，并覆盖稳定 inventory 与 barrier 释放点；
- barrier 前已 detached 的 partial snapshot 可完成且持有 bytes / generation 到 terminal outcome；
  barrier 后的新 partial request 立即 busy 失败、不等待、不产物；immutable backup snapshot detached
  后允许 mutation；
- store 无法打开时不执行健康 checkpoint / DB reference walk，raw generation 与 sidecar
  byte-identical 进入 incident 后才可发布明确选择的空 generation；
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

1. [Backup Wire Format](backup-wire-format.md) 的 v3 精确 DDL、SQLite defensive runtime limits 与
   fixtures 已单独获批并 effective；
2. draft、incident、Clear Library 与 hidden-capability owners 都指向本文而不复制路径表；
3. fault harness 能在独立目录逐点注入失败；
4. clean-install candidate 证明 Profile 路径零读取 / 零创建；
5. 每个实现与合并 slice 仍分别获得授权。
