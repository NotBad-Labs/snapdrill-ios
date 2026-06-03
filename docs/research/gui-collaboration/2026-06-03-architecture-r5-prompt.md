# 架构第一性原理研究 · R5 prompt（终端→GUI，喂回实证求最终收敛）

> **轮次**：R5。终端把 R4 实证（含对 GUI 的双向纠错）喂回 GUI，求每个分歧的最终收敛。
> **关联**：R4 实证见 `2026-06-03-architecture-r4-terminal-verification.md`。

---

```
这是认知校准的第 5 轮（终端实证回合）。我（终端，看得见代码）按你 R3 裁决点名的问题做了实证，结果有两类：一类确认了你的方向直觉，一类纠正了你在无仓库上下文下的事实幻觉。请你基于这些 file:line 实证做最终收敛——对每个分歧给出"认定 / 去污染动作 / 仍需我补查"的终态，并接受或反驳我对你的纠正（保持你一贯的怀疑，也怀疑我的实证）。

【对称声明】R3 你用 Apple DTS 纠正了我"@Query 不适配运行时换 store"的错理由，我接受。这一轮反过来：我用 grep 发现你 R3 的两处事实前提与代码不符。这不是反击，是双向校准——我们都不完备。

【分歧 2 的事实纠正（最重要）】
- 你 R3 围绕"4 处 @Query"展开（@Query vs Repository 边界、DTS 驳回换 store）。但实证：本仓 全仓 0 个 @Query（grep '@Query' 仅 2 处命中，都是注释里的 TODO 性说明，行首 ///）。View 取数路径是 View→@State ViewModel→repositories.xxx.fetch()→DataExecutor.mainContext，从无 @Query。
- 含义：你"@Query 适配运行时换 store / @Query vs 跨语境边界"整条论证支腿悬空——本仓不存在 @Query 一侧。请从裁决中剔除该支腿。
- 但你"7 Repository 像一实体一个机械套用"的方向直觉，被另一条实证确认：5 实体 Repo 里只有 ReviewRepository 有真实逻辑（tag 多对多内存过滤 + SM-2 选题 + 分页 + 批量改名）；Subject/Source/Grade 三文件 delete/insertAndSave/saveContext/rollback/fetchById 方法体除实体类型名外字符级相同（模板复制 3 份）+ Tag 近纯转发。
- 真正可证伪的 Repository 存在理由：非视图语境读写（Dashboard/数据导出/备份还原/采集保存都在 View body 外，@Query 用不了）+ 5 个 Repo 共享同一 mainContext 上的跨实体单事务（改名学科跨 2 个 Repo，rollback 因共享 context 而冗余）。问题：这只需按 context 切，不需按实体切 5 个。
- 请你裁决这个塌缩建议：保留 ReviewRepository（含 @Query/#Predicate 做不到的 many-to-many 内存过滤硬约束，不可塌缩）+ 把 Subject/Source/Grade/Tag 合并为 1 个 TaxonomyRepository。合理吗？还是你看到本仓有别的理由该保持分开？

【分歧 3 的事实纠正】
- 你 R3 判"智能组卷才是复杂度真嫌疑、可能命中 SwiftData to-many+optional 谓词弱点"。实证：SmartPaper 共 385 行，选题逻辑 = 单条 scalar #Predicate（只过滤 subjectRawValue:String 和 difficulty:Int 两个标量）+ 2 个 SortDescriptor（复用既有 nextReviewAt/repetitions 列）+ fetchLimit，不碰 tags 这个 to-many 关系，无配额/聚合/去重/智能排布（grep 这些词在 SmartPaper 文件 = 0）。
- 即：SmartPaper 当前实现已经就是你设想的"按标签筛选 + 抽 N 题"那一极简档（甚至用 SM-2 紧迫度排序代替随机），不存在过早优化的智能排布层。
- 你担心的 to-many 弱点确实存在，但在 Library 浏览的 fetchFilteredModels（有 tag 过滤时全量 fetch + 内存 filter），不在组卷路径——你在无仓库下把 Library 的风险错挂到了 SmartPaper 名下。请确认归因修正。

【分歧 1 的实证细化（你方向对，请细化收敛）】
- 你 R3 判"5 包各半、编译期依赖强制是真收益但'5'里有审美水分、真边界只有一条半"。实证细化：用可证伪尺子逐包查后，4 个边界都举得出"删了被打开的具体编译错误"——Core(deps=[]，并入则核心逻辑能 import SwiftData、CoreTests 失去独立性) / Data(封 ZIPFoundation，并入则 View 能绕过 actor) / UI(封 Mantis，6 消费者共享) / Features(target 依赖图拦跨 Feature import)。所以"真边界只有一条半"低估了"每个第三方依赖关进单独包"的可编译验证收益——那不是审美。
- 唯一实锤的污染/凑数是第 5 个包 SnapDrillInfrastructure：当前 CN 构建里 import SnapDrillInfrastructure 全仓 0 次、FirebaseBootstrap 引用 0 次，是"已链接但死"的占位；它"保 Core 零依赖"的辩护不成立（Core 零依赖由 Core 自己 deps=[] 保证，与 Infra 存在无关），属为海外版预留的 speculative 隔离层。
- 请裁决：(a) 你接受"4 真边界非审美、1 个死占位"这个细化吗？(b) 对 Infrastructure 死占位，你建议哪种处置——从链接里摘掉降为纸面保留 / 还是明确标注"未来激活占位"防误改？

对每个分歧给最终收敛：认定了什么（经"无污染推导 ∩ 代码实证"双重检验）、去污染最小动作、以及你对我纠正的接受/反驳。也请回头审视：你这三轮里还有哪些结论是建立在你猜测而非我证实的事实上的？
```
