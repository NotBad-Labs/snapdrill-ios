# 架构第一性原理研究 · R4 终端实证

> **轮次**：R4（终端实证回合）。终端（看得见代码）用 GUI 的"可证伪尺子"实证回答 GUI R3 裁决点名的代码问题。
> **方法**：in-session workflow 3 finder 并行（分歧 1/2/3），每条理由标注「可证伪事实」或「只剩不可证伪措辞」。
> **关联**：R3 裁决见 `2026-06-03-architecture-r3-gui-adjudication.md`；R5 喂回 prompt 见 `2026-06-03-architecture-r5-prompt.md`。

## 总评：对称的双向纠错

R3 GUI 用 Apple DTS **纠正了终端的错理由**（"@Query 不适配运行时换 store"）。R4 终端用 grep **纠正了 GUI 在无仓库下的事实幻觉**：

> **全仓 0 个 @Query**（grep 仅 2 处注释）。GUI R3 围绕"4 处 @Query / @Query vs Repository 边界 / DTS 驳回换 store"的论证链建立在不存在的事实上，整条悬空。

这是"对抗校准"设计的活证明：终端有上下文污染、GUI 有无上下文幻觉，双方都不完备，对照后才收敛。**谁当基线都是错的。**

## 分歧 1（5 SPM 包）：可证伪尺子落成精确账目

| 包 | 真边界 | 可证伪事实（删了被打开的具体越界） |
|---|---|---|
| **Core** | ✅ 唯一硬闸 | `Core/Package.swift:27 deps=[]`；并入 Data 则 SM-2 引擎/Protocol 能 `import SwiftData`，CoreTests 失去脱离 ModelContainer 的独立性。grep 实证 Core/Sources 零第三方 import |
| **Data** | ✅ 封 ZIPFoundation | ZIP `import` 仅 Data 2 文件（BackupService/ZIPArchiver）；并入则 5 Feature 能直接 new ModelContext 绕过 actor（违 AGENTS 铁律） |
| **UI** | ✅ 封 Mantis | Mantis `import` 全仓仅 1 处（ImageCropperView）；6 消费者共享（5 Feature + App 薄壳 SnapDrillApp:14） |
| **Features** | ✅ 顶层 + target 拦截 | Capture 内 `import SnapDrillFeatureLibrary` 编译失败（Features/Package.swift:39-42 target deps 拦跨 Feature） |
| **Infrastructure** | ⚠️ **真边界但当前死占位** | `import SnapDrillInfrastructure` 全仓 **0 次**、FirebaseBootstrap 引用 **0 次**、仅"已链接但死"（pbxproj framework link 在、Swift 引用 0）。"保 Core 零依赖"理由不成立（Core 零依赖靠自己 deps=[]，不靠 Infra） |

**裁定**：GUI"真边界只有一条半"部分对（Core 是唯一与分层无关的硬闸）**但低估了"每个第三方依赖关进单独包"的可编译验证收益**——非审美。5 包删不掉任何一个不引入具体越界；唯一实锤污染 = **Infrastructure 死占位**（speculative 海外版预留）。

**去污染动作**：(1) 账目改述为"1 零依赖核心闸(Core) + 3 个各封一个第三方依赖的中间层(Data/UI/Features) + 1 待激活 Firebase 隔离层(Infra)"。(2) Infrastructure 明确处置：摘 pbxproj link 降为纸面保留 / 或 AGENTS+architecture 标注"CN 路径 import=0，未来激活占位"防误改。(3) 删文档里"模块独立测试/更清晰"纯措辞，只留 deps=[] 闸 / 第三方封印点 / target 拦截三类可证伪事实。

## 分歧 2（Repository）：GUI 方向对、事实链错；机械套用实锤

- **纠 GUI**：0 个 @Query（grep 仅 2 处注释，行首 ///）→"@Query vs Repository 边界"分歧在本仓不存在。
- **确认污染**：5 实体 Repo 里**只有 ReviewRepository 有真实逻辑**（tag 多对多内存过滤 `ReviewRepository.swift:288-332` + SM-2 选题 `:222-244` + 批量改名 `:99-149` + delete 编排 `:54-86`）；**Subject/Source/Grade 三文件字符级同构**（delete/insertAndSave/saveContext/rollback/fetchById 方法体除实体类型名外逐字相同，模板复制 3 份）+ Tag 近纯转发（唯一非转发=fetchOrCreate `TagRepository.swift:63-74`）。"一实体一 Repo"机械套用**实锤**。
- **真理由（可证伪）**：非视图语境读写（Dashboard/导出/备份/采集都在 View body 外，@Query 用不了）+ 5 Repo 共享同一 mainContext（`RepositoryContainer.swift:45-54`）上的跨实体单事务（改名学科跨 2 Repo，`SubjectManagerViewModel.swift:126-127` rollback 因共享 context 而冗余）。但这只需按 context 切、不需按实体切 5 个。
- **去污染动作**：ReviewRepository 保留（many-to-many 内存过滤是 @Query/#Predicate 做不到的硬约束，不可塌缩）；Subject/Source/Grade/Tag **塌缩成 1 个 `TaxonomyRepository`**，消除 3 份模板复制（GradeRepositoryTests 等对照测试守 oracle）。

## 分歧 3（组卷）：GUI 假设被证伪，风险错挂

- SmartPaper 共 **385 行**（View 282 + VM 103），选题 = 单条 scalar `#Predicate`（仅过滤 subjectRawValue + difficulty）+ 2 SortDescriptor（复用既有 nextReviewAt/repetitions 列）+ fetchLimit（`ReviewRepository.swift:230-244`），**不碰 to-many、无配额/聚合/去重/智能排布**（grep 这些词 = 0）。
- **纠 GUI**：它担心的"组卷命中 SwiftData to-many 弱点"是**把 Library 风险错挂到 SmartPaper**——真正全量 fetch 内存过滤的是 `ReviewRepository.fetchFilteredModels:288-332`（Library 浏览路径），不在组卷路径。
- SmartPaper **当前已是 GUI 设想的 MVP 极简档**，无过早优化层。SM-2 引擎 194 行近纯函数（struct，仅 import Foundation，唯一副作用读墙钟）。**无 SmartPaper 代码动作**，只需修正 R5 归因。

## 收敛状态（4 分歧）

| 分歧 | 收敛结论 |
|---|---|
| 1 模块化 | **认定** 4 真边界（双重检验）+ **去污染** Infra 死占位处置 + 删文档纯措辞 |
| 2 Repository | **去污染** 4 taxonomy Repo 塌缩成 1；**纠 GUI** 0 个 @Query |
| 3 组卷 | **认定** 当前极简非过早优化；**纠 GUI** to-many 风险错挂（真热点在 Library） |
| 4 采集 | **真 gap**（R4 已实证）：数据丢失（OCR 优先 + 内存暂存 + Caches 半持久），待修 |

> R4 工作流原始输出（含全部 file:line finding）：会话 transcript `tasks/w38kpp635.output`。
