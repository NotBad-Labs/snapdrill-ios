---
last_verified: 2026-07-22
layer: contract
release: 1
activation: effective_when_merged_to_develop
ratified_inputs: ["B4-A", "B5-A", "DATA-1", "DATA-1-R", "D1-B", "D3-B", "D5-A", "S1-A", "M1-A", "D4S-A", "P1-A", "P2-B-A", "P2-C-A", "P2-D-A", "P2-E-A", "P2-F-A", "P2-G-A"]
freshness:
  max_age_days: 180
  decay_trigger: [local_library_layout_change, backup_schema_change, recovery_state_change, compatibility_epoch]
---
# Local Library Data Contract

> 本文是 Release 1 **单一本地资料库**的存储所有权、生命周期、恢复状态与故障语义权威。
> 它承接已批准的 DATA-1 / DATA-1-R / D1-B / D3-B / D5-A / S1-A / M1-A / D4S-A / P1-A / P2-B-A / P2-C-A / P2-D-A / P2-E-A / P2-F-A / P2-G-A，合入 `develop` 后生效。
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

### 2.3 Taxonomy 身份与内建基数（P2-B-A）

- taxonomy 字段与可选值的身份只由稳定 UUID 决定；名称不是关系键，也不得用于恢复时合并、覆盖或重连记录。
- 字段名与可选值名必须非空。字段名在资料库内、可选值名在所属字段内按保存的 UTF-8 字节精确唯一；不做大小写折叠或 Unicode normalization。字节不同但视觉近似的合法名称可以并存，UI 与 wire 必须逐字节保留。
- 资料库恰有 `category`、`source`、`level`、`tag` 四个内建 system key，各一个且不可删除或替换。`tag` 固定为多值；其余三个固定为单值。内建基数不可编辑；未来改变必须先升级产品与 wire contract。

默认显示名称、默认图标、默认颜色和排序值不由本项决定；显示字段的保存语法见 §2.8。

### 2.4 资料正文空值（P2-C-A）

`content = NULL` 表示用户未提供正文，`content = ""` 表示用户明确保存了空正文，两者必须可区分并原样往返。每条资料仍必须至少具有一个非空 UTF-8 正文或一张 App-managed 主图片；空字符串只有在主图片存在时合法。答案文字的语义见 §2.7。

### 2.5 Review 状态保真（P2-D-A）

已有 Review 字段分别保真：`lastReviewedAt` 与 `nextReviewAt` 独立可空，不要求彼此或与次数、间隔满足额外跨字段组合；`easeFactor` 必须是有限数，`repetitions` 必须非负，`interval` 只接受 `0...365` 天。现存值超过 365 天时，正式 writer 必须在报告用户备份成功前拒绝并给出可修复结果；不得静默 clamp、改写或丢弃 Review 状态。reader 对同版 artifact 执行相同边界。

### 2.6 Active image canonicalization（P2-E-A）

- 图片在进入正式资料库前完成方向烘焙与颜色管理：三通道输出转为 8-bit sRGB，单通道输出转为 DeviceGray；带透明度的输入以不透明纯白背景合成后再编码。保存结果必须满足 owning Backup Wire 版本冻结的 metadata-free canonical JPEG grammar。
- Backup 只读取并验证 active image，不重新编码、修复、补 metadata 或改变像素。任何非 canonical active image 都使完整备份在报告成功前失败，并保留原资料库不变。
- SnapDrill 仍处于零上架、零用户 epoch；不建立旧图片迁移或用户可见 repair surface。production switch 的顺序必须先让所有正式图片 writer 只产出 canonical JPEG，并用 fixture 证明方向、颜色与透明度路径，再允许 v3 Backup writer 对外可达。此后违反项是内部一致性错误，不得用导出时修复掩盖。

### 2.7 答案文字与图片基数（P2-G-A）

`answer_text = NULL` 表示未提供答案文字，`answer_text = ""` 表示用户明确保存了空答案文字；两者必须按 UTF-8 字节原样往返。每条资料最多关联一张主图片和一张答案图片；两种 role 各自可缺省，不能用数组顺序、文件名或重复 role 猜测身份。未知 role 或同一 role 重复必须在 mutation 前拒绝。

### 2.8 Taxonomy 显示字段（P2-G-A）

每个 taxonomy 字段和可选值都必须保存非空 SF Symbol 名称；可选值还必须保存非空颜色。保存入口先规范化并只持久化以下形式：symbol 匹配 ASCII `[a-z0-9.]+` 且不超过 §2.1 上限，颜色为大写 `#RRGGBB`。读取和 Backup 不做二次修复。设备或 OS 不认识一个语法合法的 symbol 时，UI 使用固定 fallback 显示，但不得改写已存 symbol、digest 或 wire bytes。

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
| `AS/RecoveryIncidents/<uuid>/metadata.json` | metadata-last 的 classified-incident marker | 固定名普通文件；写入前全部声明材料必须已 durable、通过身份 / 保护验证且不得排除设备备份 |
| `AS/RecoveryIncidents/<uuid>/` 的其余固定节点 | journal、prestate、source / candidate 与输入材料 | 未解决时不按时间、数量或空间自动淘汰；不得排除设备备份；仅 DATA-1-R 明确动作可删 |
| `AS/Drafts/` | 未保存采集草稿 | 独立于资料库；崩溃可恢复；排除设备备份；不按时间自动删除，仅在正式保存成功或用户明确丢弃后删除；叶子格式由 Capture contract 维护 |
| `AS/Diagnostics/MetricKit/` | 有界端侧诊断 | 排除设备备份；不依赖 App Group；不属于 Backup 或 Clear Library |
| `Caches/com.snapdrill.global/` | 只含可重建派生物 | 系统管理且可清；删除不得影响任何已保存或可恢复内容 |
| `temporaryDirectory/com.snapdrill.global/<uuid>/` | 可丢弃导出 / 导入 construction，或已获授权并完成 retire rename 的 incident trash | terminal outcome 后删除；不得放唯一 rollback 副本、未解决 journal 或仍处于 `RecoveryIncidents` 的 incident |
| 用户选择 URL / 系统 share destination | 最终 `.snapdrillbackup` 或 PDF | 用户所有；App 内部 live 目录永不作为文档位置暴露 |
| `Documents/profiles*` | epoch 前开发遗留 | 正常启动不得读取、创建、选择或自动删除 |

所有 App-owned 固定节点必须是预期类型的普通文件或目录；任一级 symlink、hard-link 身份异常、未知
固定名、越界标准化路径或 node-type 不符均 fail closed。生产持久文件显式采用
`completeUntilFirstUserAuthentication` data protection；用户导出的文件遵循目标 URL / 系统
surface 的保护策略。可重建和一次性材料不得因方便而升级为用户数据真相。

### 3.1 `LocalLibraryRelativePath` grammar

内部 inventory 的相对路径必须由同一个 Data-owned value 解析：输入是非空有效 UTF-8，使用 ASCII
`/` 分隔一个或多个非空 component；不得有首尾 `/`、连续 `/`、`.`、`..`、反斜杠，或 Unicode General
Category `Cc`（含 NUL）的 scalar。每个 component 与总路径还必须满足 owning operation 注入的
filesystem / `pathconf` byte limit。路径不做 Unicode normalization、大小写折叠或 separator
替换；身份、唯一性和 canonical 排序都按解码后的 UTF-8 byte 比较。

runtime I/O 仍须从已打开的可信根执行 node type、link count、descriptor identity 与 containment
检查，合法 lexical path 不等于可信 filesystem node。`storeRecovery` 若遇到无法用本 grammar 表达的
既存名称，必须保持 selector 与 source bytes 不变并阻塞恢复；不得改名、跳过或规范化后继续。

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

### 4.4 Internal recovery JSON v1 grammar

`journal.json`、`prestate.json` 与 incident `metadata.json` 共用一个严格 scanner。输入必须是有效 UTF-8
JSON，top level 恰为一个 object；BOM、invalid UTF-8 / lone surrogate、raw control character、完整
object 后的 trailing byte 均拒绝。scanner 是唯一 parser truth：不得先扫描再交给
`JSONDecoder` / `JSONSerialization` 作第二次语义解释。object key 先完成合法 JSON escape 解码再比较，
因此 `"a"` 与 `"\u0061"` 是 duplicate key。

v1 允许 object、array、string、boolean 与 unsigned decimal integer；不允许 illegal JSON escape、
`null`、负号 / 正号、fraction、exponent，或除 literal `0` 外的 leading zero。`version` 恰为 integer
literal `1`；checked
byte count 是 `0...Int64.max`。UUID 恰为 36-byte 小写 canonical form；timestamp 恰为 20-byte
`YYYY-MM-DDTHH:MM:SSZ` 且通过 Gregorian UTC 校验，不接受 fraction、offset、lowercase 或 leap
second。SHA-256 恰为 64-byte 小写 hexadecimal。clock rollback 合法，因此 `updatedAt` 不承担
大于等于 `createdAt` 的时序不变量。

每种 typed object 使用本文列出的精确 key set：missing / unknown / duplicate key、错误类型、未知 closed
enum 与重复 semantic identity 都是 violation。canonical encoder 按本文字段顺序写 key；string 对
`"`、`\` 使用 `\"`、`\\`，对 BS / HT / LF / FF / CR 使用 `\b` / `\t` / `\n` / `\f` / `\r`，
其他 U+0000...U+001F 使用小写 `\u00xx`，其余 scalar 直接写 UTF-8，`/` 不转义。所有 string / path
长度都是 JSON escape 解码后的 UTF-8 byte 长度。decoder 可接受
任意无语义差别的 object / array 顺序与合法 JSON escape；只有 encoder bytes 是 canonical bytes。
canonical encoder 在任何 token 前后或 token 之间都不写 whitespace，成员间只写一个 `,`、key 与
value 间只写一个 `:`，array / object 直接以 `[]` / `{}` 包围内容。由固定 key / array order、number
lexeme 与上述 string escaping 共同保证同一 typed value 只有一份 canonical byte representation。

scanner 必须接受注入的 byte、nesting-depth、token 与 string-length budget，并对大数组提供 streaming
event；budget exhaustion 是可重试的执行防御，不是产品 item / byte cap。streaming event 在完整 artifact
通过 key closure、数组身份唯一性和 family validation 前只是 provisional，不得驱动 mutation。无产品
上限的 identity index 可由 consuming operation 使用有界内存 / external index 实现。codec 返回结构化
`family + fieldPath + reason` violation；bootstrap / incident consumer 再映射为 `blocked` 或
unclassified，不得由 parser 猜测恢复结果。

### 4.5 Journal identity 与 exact object

`journal.json` 的 key 顺序与 exact key set 是：`version`、`transactionID`、`operation`、`phase`、
`oldGeneration`、`newGeneration`、`createdAt`、`updatedAt`。全部字段必填且不得为 null；version 为
`1`，operation 只允许 `restore` / `clearLibrary` / `storeRecovery`，phase 只允许 `prepared` /
`published` / `rollingBack` / `committed` / `rolledBack` / `blocked`。old / new generation 必须不同。
路径全部由 ID 和固定根推导，journal 不接受任意路径字段。

phase 的 durable 含义固定为：`prepared` 表示 old / new / prestate 已验证而 selector 尚未确定完成发布；
`published` 表示 selector 已 durable 指向 new；`rollingBack` 表示已决定恢复 old；`committed` 表示 new
runtime 已重新打开并验证；`rolledBack` 表示 old runtime 已重新打开并验证；`blocked` 表示无法证明
前滚或回滚且不得打开普通 runtime。writer 只能在对应事实 durable 后写入该 phase。

transaction directory UUID 必须等于 `transactionID`。存在或所属 phase 要求的 `prestate.json` 必须与
journal 的 `transactionID`、`operation`、`oldGeneration == sourceGeneration` 相等；source generation
目录必须等于 old，candidate / published generation 必须等于 new。incident directory UUID 必须等于
metadata 的 `incidentID`，其 `sourceTransactionID`、operation 与所含 journal / prestate 相等。任一
identity、location 或 node-type 不一致都阻塞，不得按某一份 artifact 猜测。

同一时刻最多一个 non-terminal transaction。启动必须先协调 journal，之后才可构建
`ModelContainer`。selector 的替换是唯一 publication commit point；只有进程在任意指令后终止并重启
时仍必然得到完整 old 或完整 new selector，替换 API 才可报告成功。

### 4.6 Startup reconciliation table

transaction root 与合法 journal 对每个 typed phase 都必需。`prepared` / `published` /
`rollingBack` 还要求 old、new 与 prestate 全部存在且有效；`committed` 要求 new，old / prestate 可已
删除或作为 residue 存在；`rolledBack` 要求 old，new / prestate 可已删除或作为 residue 存在。
任何 optional residue 一旦存在仍须通过 §3.1、§4.4、§4.5 与所属 inventory 验证。phase 所需 node
缺失、malformed 或身份不符直接阻塞。

在上述前置验证通过后，唯一 pure decision table 为：

| journal phase | selector = old | selector = new | selector 缺失 / malformed / 第三个 UUID |
|---|---|---|---|
| `prepared` | rollback | roll forward | block |
| `published` | block | roll forward | block |
| `rollingBack` | continue / complete rollback | continue / complete rollback | block |
| `committed` | block | idempotent cleanup | block |
| `rolledBack` | idempotent cleanup | block | block |
| `blocked` | remain blocked；不打开 runtime | remain blocked；不打开 runtime | remain blocked；不打开 runtime |

roll forward 只有在 new runtime 重新打开且验证后才进入 `committed`；rollback 只有在 old runtime
重新打开且验证后才进入 `rolledBack`。cleanup 可重复，且 terminal phase 合法允许已清除的 optional
residue；journal 最后删除。任何 publication / rollback 双失败先 durable 建立 §6 classified incident，
不得发布健康空库。R2-0A 只能实现并复用本表，后续 transaction executor 不得另写第二张决策表。

## 5. Shared prestate 与 D3-B recovery-only inventory

`prestate.json` 的 envelope key 顺序与 exact key set 是：`version`、`transactionID`、`operation`、
`sourceGeneration`、`createdAt`、`artifactKind`、`payload`。version 为 `1`；其 ID / operation 必须
满足 §4.5 的交叉身份。payload 必须且只能符合所属 operation 的一种 closure。它只能位于内部
transaction / incident，不能使用 `.snapdrillbackup` 扩展名，也不能进入外部 reader。

`restore` / `clearLibrary` 使用 `artifactKind: recovery-only` 的 closed-generation semantic
inventory。payload 的 exact key set 是 `store`、`imageReferences`。store record 的 exact key set 是
`relativePath`、`byteCount`、`sha256`，且 `relativePath` 必须是 literal `library.store`。
`imageReferences` 对每个数据库图片引用恰有一条 record；共同 exact key 是 `itemID`、`role`、
`relativePath`、`state`；itemID 使用 §4.4 canonical UUID，role 只允许 `main` / `answer`，relativePath
以 source generation root 为基准，必须是 §3.1 grammar 下的 `images/<one-or-more-components>`。只有
`restore` 可以消费下述 D3-B `missing-at-snapshot` 状态。

- `present`：exact key set 在共同 key 后增加 `byteCount`、`sha256`；文件必须是同一 generation
  `images/` 下的普通 JPEG，完整读取和 digest 后才成立。
- `missing-at-snapshot`：只能用于路径在 node lookup 时真正不存在；exact key set 只有共同 key，
  禁止 `byteCount` / `sha256`。

存在但不可读、symlink、非普通文件、lookup 前后身份改变、长度改变或 digest 不符都使 prestate
失败并在零 active mutation 时中止。`missing-at-snapshot` 只适用于图片；字段 / 分类引用不得缺失。
canonical encoder 按 `(itemID 的 16-byte UUID value, role main < answer)` 排序；decoder 可接受其他
顺序，但 `(itemID, role)` 必须唯一且语义 closure 必须逐项验证。

`storeRecovery` 只使用 `artifactKind: unavailable-store-recovery`，payload 的 exact key set 只有
`nodes`。因为 source store 无法打开或证明完整，它不得解析数据库关系或声称 semantic inventory；
payload 必须从可信 generation root 逐项冻结全部 descendant（含 empty directory）。每个 node record
共同 exact key 是 `relativePath`、`nodeType`：`directory` 禁止 `byteCount` / `sha256`，
`regular-file` 必须增加 checked `byteCount` / `sha256`；其他 node type 不可编码。path 必须符合 §3.1
且按 decoded UTF-8 bytes 唯一；canonical encoder 也按该 bytes 排序。该 raw closure 包括存在的
SQLite sidecar 与图片。symlink、
hard-link 身份异常、遍历前后替换、不可读或无法完整冻结均保持启动阻塞、selector 与 source bytes
不变。只有 byte-identical source generation 与该 inventory 已 durable 进入 DATA-1-R incident 后，
用户明确选择的空 generation 才可 publication；pending marker 只作为 raw store 内容保留，不执行、
不外传，也不被解释为已撤销或已删除。

外部完整 Backup v3 永远只接受 `external-complete`，不能识别、转换或降级接受 recovery-only
或 unavailable-store-recovery inventory。普通导出遇到缺图必须失败，而不是把内部恢复语义泄漏到
用户备份。

数组 streaming output 在 envelope、全部 record、唯一性 index 与最终 token 都验证前不是完整
`prestate.json`；取消、budget exhaustion 或中途 I/O 不能留下一个可被 reconciliation 接受的 prefix。

## 6. Recovery incident

incident `metadata.json` 的 key 顺序与 exact key set 是：`version`、`incidentID`、
`sourceTransactionID`、`operation`、`revision`、`createdAt`、`updatedAt`、`errorCode`、`status`、
`materials`。typed v1 只接受 `(revision: 1, status: decisionRequired)` 或
`(revision: 2, status: retained)`：前者阻塞普通启动并等待用户选择，后者表示用户已明确以空库继续但
材料仍保留。唯一状态转换是 atomic durable replacement `1/decisionRequired -> 2/retained`；
`version`、两个 ID、operation、createdAt、errorCode 与 materials 全程 byte-identical，updatedAt 可因
clock rollback 不单调。失败 / 取消 export 不改 metadata；显式 delete 也不先写第三个 revision。

materials 是 nonempty exact `{kind, nodeType}` object 的 array，不含任意路径。kind 唯一并按下表顺序
编码，位置与 node type 固定：`journal` -> `journal.json` `regular-file`；`prestate` ->
`prestate.json` `regular-file`；
`sourceGeneration` -> `source-generation/` directory；`candidate` -> `candidate/` directory；
`inputBackup` -> `input.snapdrillbackup` `regular-file`。metadata 自身不是 material member。metadata-last
publication 前，每个声明材料都必须 durable 到位，且 journal / prestate / generation 身份满足 §4.5。

只有下表三种 operation / cause / material closure 可成为 classified v1 incident：

| operation | errorCode | required materials | forbidden materials |
|---|---|---|---|
| `storeRecovery` | `libraryStoreUnavailable` | journal, prestate (`unavailable-store-recovery`), sourceGeneration | candidate, inputBackup |
| `restore` | `rollbackFailed` | journal, prestate (`recovery-only`), sourceGeneration, candidate, inputBackup | none |
| `clearLibrary` | `rollbackFailed` | journal, prestate (`recovery-only`), sourceGeneration, candidate | inputBackup |

`storeRecovery` journal 的 newGeneration 可以是 prospective ID，但仍禁止 candidate material。其他
operation / errorCode 组合一律 unclassified；尤其 busy、cancelled、timeout、unsupported、Backup
validation / reference / integrity、prestate 或其他 pre-mutation failure 不得伪装成 incident。metadata
缺失、损坏、未知 version，或 material 清单 / node 不符，同样按 unclassified blocking incident
保留，不隐藏、不删除、不打开普通 runtime。四个以上 incident 必须 byte-identical 保留，不得
count-prune。

incident adoption 必须在 metadata commit 前递归清除来源继承的 device-backup exclusion，并验证所有
固定 node 的类型、身份与 `completeUntilFirstUserAuthentication` protection；rename 本身不构成
classified publication。

### 6.1 Retained incident retirement 与 export boundary

R2-0B 只拥有 revision `2/retained` incident 的显式 delete retire seam；`decisionRequired` 不得直接
删除。一次 retire 必须绑定用户明确授权、所选 `incidentID + revision`、可信 source / trash 根和 incident
directory 的 `(st_dev, st_ino)`；两个已打开根必须同 `st_dev`，destination 必须不存在，并在 exclusive
rename 前后重新验证身份与 containment。iOS implementation 使用公开 `renameatx_np` 加
`RENAME_EXCL | RENAME_NOFOLLOW_ANY | RENAME_RESOLVE_BENEATH`，不得以较弱 rename 替代。跨 volume
或任一 identity 变化 fail closed，不得 fallback 为 `RecoveryIncidents` 下的 recursive delete，也不得
建立通用 filesystem manager / protocol。

destination parent 先 durable sync，source parent 后 durable sync；source-parent sync 是逻辑 delete
commit point。commit 前失败时 incident 仍必须按 source 身份可见；commit 后 temporary trash 丢失是已
授权删除，不改变用户结果；中间 outcome-uncertain 状态由重启检查 source 是否仍存在来协调。trash 的
后续 recursive cleanup 只是幂等卫生工作，不拥有删除成功语义。

DATA-1-R 的“导出并删除”不属于 F0 或 R2-0B：它必须等待一份具名、effective 的 recovery-export
representation / receipt contract，并把 durable receipt 绑定到 `incidentID + revision` 后才能复用 retire
seam。该 representation 不得复用或伪装成 Backup v3。合同生效前只能保留或显式删除，不得把普通 share
成功当成 export-and-delete 授权。

## 7. 偏好与 legacy epoch

单资料库 runtime 不读写 `activeProfileId`、`profiles.json`、Profile 名称或 `preferences.json`。同设备
升级继续保留 Release 1 支持的 App-owned 全局偏好：App 内语言选择、`appearanceMode`、`appTintColor`、
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
| `backupValidationTimedOut` | 校验在持续无进展期限内未完成；可重试，不把源文件永久判为损坏 |
| `insufficientStorage` | checked capacity preflight 或写入遇到空间不足 |
| `publicationFailed` | new generation 未能 durable 发布；尝试确定性 rollback |
| `rollbackFailed` | old generation 也无法恢复；创建 blocking incident |
| `recoveryDecisionRequired` | incident 必须由用户选择后才能继续普通启动 |

原始底层错误只进入隐私安全日志 / incident metadata，不直接代替可理解的用户结果。

Backup / restore 的可观察生命周期固定为 `idle`、`running`，以及 terminal
`completed` / `cancelled` / `failed`。`cancelled` 是非错误终态；进入 selector commit barrier 后才观察到
的取消或 timeout 必须由 transaction reconciliation 吸收并返回已证明的 publication / rollback 结果，
不能覆盖成 `cancelled` 或 `backupValidationTimedOut`。

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
- escaped-key collision、nested duplicate key、BOM、invalid UTF-8 / surrogate、raw control、非法
  number lexeme、timestamp / UUID / digest 边界，以及 depth / token / string / byte budget exhaustion；
- 每个 phase 对 old / new / missing / malformed / third selector 的 pure reconciliation table 全覆盖，
  并证明 terminal optional residue 已删除仍可 cleanup、存在则必须验证；
- streaming prestate 在大于内存预算的 inventory 上保持有界内存，prefix / duplicate identity / 最终
  closure 失败时零 mutation、零可接受 artifact；
- classified incident 的三种 operation/cause/material closure、全部 forbidden material、交叉 ID / 目录
  不一致、revision 组合与唯一 `1 -> 2` metadata replacement；
- adoption 的 backup-exclusion / protection 递归验证，以及 retire 在 destination occupied、cross-volume、
  symlink、inode substitution、rename 前后和两个 parent sync 点的 fault；
- retire commit 前 source incident 保留，commit 后 trash 丢失仍为已授权删除；没有 recovery-export
  receipt contract 时不存在 export-and-delete 路径；
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
