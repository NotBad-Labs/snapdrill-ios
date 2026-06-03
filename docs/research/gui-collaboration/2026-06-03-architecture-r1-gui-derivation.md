# 第一性原理推导：本类 iOS 应用的最优软件架构（第一轮·纯独立推导）

## TL;DR（三条核心结论）
- **在"单人 + 重度 AI 辅助 + ~25K 行 + 未上线（pre-PMF）"这组参数下，最优架构投资量明显偏低**：默认应为"单一 App Target + 按功能分文件夹 + 朴素 SwiftUI（`@Observable` + `@Environment`）+ 一个数据访问 actor"，而非 MVVM/Clean/VIPER/TCA/多 SPM 模块这类为"团队 + 百万行 + 成熟产品"设计的重型结构——这些在本场景多为 cargo cult（证据等级：硬约束 + 工程原则）。
- **真正驱动本应用结构分解的"基本力"只有三条**：① 隐私/合规要求的"敏感数据物理边界"（每个孩子的数据隔离 + 可彻底删除）；② Swift 6 强制并发安全要求的"数据隔离边界"（图像处理/IO 离开主线程）；③ 变化速率差异（OCR/持久化/复习算法这三块各自演化速率不同）。其余常被当作"架构理由"的东西（可测试性、可复用性、未来云同步）在当前阶段大多**不应**驱动结构（工程原则）。
- **持久化是本轮唯一需要"现在就慎重"的决策**：因为一旦未来开启 CloudKit，schema 将被锁进"只增不改不删"，所以无论选 SwiftData 还是 GRDB/SQLiteData，都应**现在就按 CloudKit 约束建模**（全部属性可选/有默认值、关系可选+有逆向、禁用 `@Attribute(.unique)`、禁用 Deny 删除规则）。"每个孩子独立 store 文件"在隐私/删除上更可辩护，但要放弃跨档案关系并需在 iOS 26 上实测多 store 可靠性（硬约束）。

---

## 关于本轮方法论与对"问题描述本身"的批判

用户要求：先批判性审视问题描述本身——哪些是真正的客观约束，哪些其实是被当成"事实"的隐含设计选择。这一步至关重要，因为**架构污染最常见的入口，就是把一个设计决策伪装成"需求"**。下面逐项标注。

**真正的硬约束（problem-domain hard constraints）：**
- iOS 26+ / Swift 6.x / 单平台原生：平台与语言是外生给定的，Swift 6 的强制并发安全是编译期事实。
- 纯客户端、无服务器、无账号：这是"当前"的事实边界，且直接决定了"没有服务端可承载业务逻辑/鉴权/合规"。
- 数据涉及未成年人、敏感：这是法律/伦理硬约束，不可协商。
- 最高频操作 = 拍照 + 轻整理；用户为非技术家长：这是真实的使用分布约束。

**被当成"事实"、实则是隐含设计选择（需要被点名）：**
1. **"自动 OCR → 多维分类 → 基于遗忘曲线的间隔复习 → 导出 PDF"这条流水线**——这是**产品功能设计**，不是领域约束。尤其"基于遗忘曲线的间隔复习"被列为"核心用例"，但同时又说"复习是增值（added value）"，二者矛盾。架构上不应为"复习"预先建造重型结构。
2. **"多维分类（按学科/来源/年级）"**——"多维 tag"是一种数据建模选择，不是需求。需求是"家长能快速找到某一类错题"。是否真的需要多对多 tag 关系，还是单层枚举 + 全文搜索就够，本身就是要被质疑的（且 SwiftData 在 to-many + optional 谓词上性能差，见下文）。
3. **"每条记录 = 图像 + OCR 文本 + 多维标签 + 复习状态"作为单一聚合**——把"复习状态"和"错题内容"耦合进同一条记录是设计选择。复习状态变化速率远高于错题内容（前者每次复习都变，后者几乎不变），这正是后文"变化速率差异"驱动拆分的关键信号。
4. **"smart test-paper assembly（智能组卷）"**——这是被悄悄塞入的高复杂度功能，与"家长拍照+轻整理"的高频主路径不在一个复杂度量级。
5. **"multi-user / 多孩子数据隔离"**——"隔离"是需求（隐私/合规），但"如何隔离"（逻辑隔离 vs 物理隔离）是设计选择，且对架构影响巨大。

> **更基本的架构问题（优先回答）：** 用户的 Part 分组其实**遗漏了一个比"要不要分模块"更基本的问题**——*"这个应用的核心价值与最高频路径，是否被架构平等对待了？"* 第一性原理上，架构资源应**极度不均衡地**向"拍照 + 落地 + 不丢失"这条主路径倾斜（捕获 > 管理 > 导出，复习增值）。绝大多数"架构污染"恰恰是把工程精力均匀摊在所有功能上、甚至向低频高复杂功能（组卷、复习算法、未来云同步）过度倾斜的结果。**这是本报告贯穿始终的判据。**

---

## Key Findings（核心发现速览）

1. **架构的第一性收益是"降低未来变更的认知与协调成本"，其成本是"当下的生产、理解与误改成本"。** 当团队规模=1、协调成本≈0 时，架构收益的一大来源（人际协调）直接消失，于是天平显著倒向"少架构"（工程原则）。
2. **AI 辅助同时降低了"抽象的生产成本"和"样板代码的打字成本"，但抬高了"误改风险"和"跨文件上下文一致性成本"。** 这意味着：AI 让"写出抽象"变便宜，却**没有**让"维护一个错误抽象"变便宜——反而因为 AI 在大上下文中容易在"远处文件"漏改而更危险（falsifiable evidence + 工程原则）。
3. **SwiftUI（iOS 17+ Observation）下，强制为每个视图配一个 ViewModel 是本场景最可能的过度架构**。Apple 的 `@Query`/`modelContext` 是 View/Environment 绑定的，强行 MVVM 包裹 SwiftData 会产生易错样板（工程原则，多位权威实践者佐证）。
4. **Swift 6 并发是"硬约束"，但 Swift 6.2 的 Approachable Concurrency 让正确答案变简单**：默认 `@MainActor`，仅把 OCR/图像处理/批量 IO 用 `@concurrent` 或专用 actor 推到后台；持久化用 `@ModelActor`（SwiftData）或 GRDB 的 DatabaseQueue（硬约束）。
5. **为单一实现创建 protocol/接口，在本场景是典型的 YAGNI 违例**；AI 辅助下其成本相对"上升"而非下降，因为它增加了 AI 必须保持一致的跨文件契约面，且 Swift 6 下 protocol 还会带来 actor 隔离一致性摩擦（工程原则）。
6. **持久化选型的本质维度**是：①查询表达力 ②迁移可控性 ③多 store/物理隔离能力 ④未来 CloudKit 就绪度 ⑤与 SwiftUI/Observation 的集成成本 ⑥widget/App Intent 可达性。SwiftData 与 GRDB/SQLiteData 在这些维度上各有明确取舍（硬约束 + 工程原则）。

---

## Details（逐题独立推导）

### PART ONE：架构的本质与边界

#### Q1. 架构在第一性原理上解决什么问题？边际收益何时转负？
**独立推导：** 软件架构的本质，是**用"当下增加的结构成本"去购买"未来变更时降低的成本"**。它的收益主要来自三处：(a) **信息隐藏**——把易变的决策封在边界内，使变更局部化（Parnas 1972 的经典命题）；(b) **认知分块**——人类工作记忆有限。Nelson Cowan, "The Magical Number 4 in Short-Term Memory: A Reconsideration of Mental Storage Capacity," *Behavioral and Brain Sciences* (2001) 24(1):87–114 的核心论断是工作记忆容量比 Miller 1956 的"7±2"更小："Others have since suggested that there is a more precise capacity limit, but that it is only three to five chunks... the smaller capacity limit is real."——即真实可同时持有的 chunk 约为 3–5 个。超过此容量后理解成本急剧上升，模块/分层本质是帮人脑分块；(c) **协调边界**——让多人/多 agent 能在不互相踩踏的情况下并行。

成本则有三处：**生产成本**（写抽象、写样板）、**理解成本**（多一层间接就多一跳）、**误改成本**（错误的抽象会把变更放大到多个调用点）。

**边际收益转负（过度架构）的条件**，可falsifiable地表述为：
- 当**协调收益≈0**（单人）时，架构的(c)项收益消失；
- 当**变更尚未发生、且需求未稳定**（pre-PMF）时，(a)项"信息隐藏"押注的"未来变化点"极可能押错——Sandi Metz 在 "The Wrong Abstraction"（博客发表于 2016 年 1 月 20 日，源自其 RailsConf 2014 "All the Little Things" 演讲）中主张"prefer duplication over the wrong abstraction"：错误抽象的成本高于重复；
- 当**单个理解单元已小于工作记忆容量**时，进一步拆分只增加(b)的跳数而不再降低单元复杂度——此时拆分是负收益。

> **证据等级：工程原则**（信息隐藏、认知负荷有实证文献——Cowan 2001 为同行评审；"错误抽象成本 > 重复"是被广泛接受的工程箴言但非随机对照实验）。
>
> **最强反方论点：** "架构是为了应对你*现在看不到*的未来变化；等痛了再改成本更高。"
> **该反方成立的条件：** 当变化点是**高确定性**的（例如：你**已经**签了合同要在 6 个月内上线云同步），且重构窗口很窄时。在本应用中，云同步等都是"future uncertain possibilities（均未实现）"——确定性低，故反方不成立。**唯一的例外是持久化 schema（见 Q6），因为 CloudKit 的"只增不改"锁定使得"事后再改"成本异常高。**

#### Q2. "单人 + 重 AI + 25K 行 + pre-PMF"把最优架构投资推向哪个方向？AI 如何改变权衡？
**独立推导：** 相比"团队 + 百万行 + 成熟产品"，本参数集在**每一个维度**上都把最优架构量往下压：
- **单人** → 协调收益归零，且"代码即文档"（六个月后你要靠代码本身回忆，而不是靠 ViewModel 分层）；
- **25K 行** → 整个代码库可被一个人（和一个 AI 上下文窗口）大致把握，远未到必须用编译边界强制隔离的规模；
- **pre-PMF** → 需求会大改，任何押注未来的抽象期望值为负；
- **重 AI 辅助** → 这是最微妙的一项，需要拆开看三种成本：
  - **抽象的生产成本 ↓**：AI 让"生成一个 protocol + mock + DI 装配"几乎零打字成本。这**诱导**人过度抽象——但生产成本低 ≠ 总拥有成本低。
  - **样板/重复的成本 ↓**：AI 让"重复三遍相似代码"也变便宜，这反而**削弱了"用抽象消除重复"的传统理由**（DRY 的部分动机是省打字，而打字不再是瓶颈）。
  - **理解/误改成本 ↑（相对而言）**：AI 在大型多文件改动中会"在远处文件漏改"或"误用不熟悉的 API"，逻辑越分散、跨文件契约越多，AI 一致性维护成本越高、误改风险越大。
  
  **净结论：AI 辅助把天平进一步推向"少而深的模块、少抽象、就近聚合逻辑、文件不要碎片化"**——即 Ousterhout 的"deep modules"方向，而非"很多浅 class/protocol"。

> **证据等级：工程原则 + 部分 falsifiable evidence**（AI 误改、上下文一致性问题有实践与初步研究佐证；具体量化收益多为厂商自述，需谨慎）。
>
> **最强反方论点：** "正因为 AI 会乱改，你更需要清晰的接口/边界/测试把它'框住'，所以应该**更多**架构与测试。"
> **该反方成立的条件：** 当抽象边界**恰好对应真实的稳定契约**（如持久化层、OCR 引擎封装）时成立——给这些**真实稳定**的边界配接口+测试确实能约束 AI。但对**易变的 UI 表现逻辑、单一实现的服务**强加 protocol，只会增加 AI 要同步的契约面，反方不成立。**判据：只在"既稳定、又有真实第二实现/真实测试需求"的边界上加抽象。**

---

### PART TWO：从约束推导结构

#### Q3. 哪些约束是真正驱动分解的"基本力"？哪些其实不影响架构？
**真正驱动分解的基本力（按本应用强度排序）：**
1. **隐私/合规的数据物理边界（硬约束）**：涉及未成年人、可能含姓名/学校/班级，受儿童信息保护法规约束。这要求"每个孩子的数据可被清晰隔离、可被彻底删除"。这是本应用**最强**的、真正源于领域的架构驱动力——它驱动**持久化层的 store 划分**与**删除路径设计**。
2. **Swift 6 强制并发安全的隔离边界（硬约束）**：编译器强制 Sendable/actor 隔离，图像处理与本地 IO 必须离开主线程。这驱动一个**清晰的"主线程 UI / 后台数据与图像处理"二分**。
3. **变化速率差异（工程原则，Parnas）**：OCR 识别、持久化/数据模型、复习调度算法这三者的演化速率显著不同（OCR 可能换引擎、算法可能从简单间隔升级到 FSRS、数据模型受 CloudKit 锁定）。**按变化速率而非按"技术分层"切边界**，是唯一有第一性依据的拆分理由。

**实则不影响（或不应驱动）本应用架构的因素：**
- **编译/构建时间**：25K 行单 target 的全量编译对单人迭代不构成瓶颈，不足以成为引入 SPM 多模块的理由（多模块的增量编译收益主要是**团队级**收益）。
- **测试隔离**：可测试性是结果而非目的；不应为"可测试"而引入大量 protocol（见 Q9）。
- **可复用性**：单 app、无第二宿主（暂不考虑 widget），跨模块复用收益≈0。

> **证据等级：硬约束（前两条）+ 工程原则（第三条）。**

#### Q4. 该不该拆多模块？独立提案（含"不拆"的论证）
**独立提案：当前不应拆分为多个 SPM 模块；应采用"单一 App Target + 按功能/变化速率分文件夹"的内部结构。** 推荐的内部边界（逻辑边界，不是编译边界）：

```
App（组装层：根视图、profile 切换、依赖装配）
├─ Capture     （相机/扫描/相册/PDF 导入 → 产出原始图像 + 元数据）
├─ Recognition （OCR 引擎封装：输入图像，输出文本 + 置信度；可替换）
├─ Persistence （数据访问层：模型定义 + 一个数据 actor；唯一与 DB 打交道处）
├─ Library     （分类/搜索/组卷：消费 Persistence 的查询）
├─ Review      （间隔复习调度：纯函数式算法 + 状态读写）
├─ Export      （PDF 生成）
└─ DesignSystem（共享 UI 组件/样式）
```

**为什么"不拆 SPM 模块"更优（第一性论证）：**
- 多模块的主要收益（并行开发、合并冲突隔离、独立测试周期、增量编译）几乎全是**团队规模收益**，单人无法兑现；
- 而其成本（Package.swift 维护、依赖图维护、跨模块可见性管理）与团队无关，照付不误；
- 更有一个**本应用特有的具体技术风险**：SwiftData 已知存在"模型按文件/模块拆分后 Release 构建崩溃（依赖文件布局的 codegen bug）"的报告——**激进地把 SwiftData 模型切到独立模块/文件，可能直接触发崩溃**。这是反对过早模块化的硬技术理由。

**何时应升级为真模块（falsifiable 触发器）：** 出现以下**任一可测量痛点**时才拆：① 全量编译时间持续 > 单人可忍受阈值（如 > 几十秒且频繁）；② 真的要做 widget/App Intent 扩展（需要共享一个轻量数据模块）；③ 引入第二位开发者。在那之前，**文件夹 + Swift 的 `internal`/`private` 访问控制**已足够。

> **证据等级：工程原则（拆分收益多为团队级）+ 硬约束（SwiftData 文件布局崩溃 bug 是具体技术约束）。**
>
> **最强反方论点：** "从第一天就用 SPM 模块能强制清晰边界、防止逻辑泄漏，且为未来 widget/订阅做好准备。"
> **该反方成立的条件：** 当你**确定**近期要做多宿主扩展（widget/watch）或确定要引入协作者时成立。本应用这些都是不确定的未来项，故反方在当前不成立——但**第一性边界（上面的文件夹划分）应当现在就清晰**，这样未来"文件夹 → 模块"的升级是机械的、低成本的。

#### Q5. 模块/层间依赖是否需要强约束（单向、无环）？
**独立推导：** "无循环依赖"是几乎免费且总是值得的（循环依赖会破坏可理解性和构建，且制造它没有任何收益）——这条应当遵守，但在单 target 内它**不需要工具强制**，靠纪律即可。而"严格单向分层 + 用 protocol 做依赖倒置（DIP）"这种**强约束**则要付出刚性与样板成本。

**第一性判据：依赖方向约束的价值 = 它保护的"易变边界"的真实波动率 × 重构成本。** 在本应用，唯一真正值得用"依赖倒置"保护的边界是 **Recognition（OCR 可能换引擎）** 和 **Persistence（DB 可能从 SwiftData 换 GRDB，或未来接 CloudKit）**。对这两处定义窄接口是合理的；对其余（UI ↔ Library ↔ Review）强加单向 protocol 依赖，在 25K 行单人项目里得不偿失。

> **证据等级：工程原则。** 无环=普适；强单向分层=规模相关。
>
> **不值得的规模阈值：** 当代码库小到一个人能完整持有心智模型（本应用即是），且没有编译边界时，"工具强制的单向依赖"的收益低于其样板成本。

---

### PART THREE：关键技术决策（独立推导 + 最强反方 + 反方成立条件）

#### Q6. 持久化方案的第一性选型维度与各候选取舍
**第一性选型维度：** ①查询表达力（谓词/聚合/join）②迁移可控性 ③多 store / 物理隔离能力 ④未来 CloudKit 就绪度 ⑤与 SwiftUI/Observation 集成成本 ⑥widget/App Intent 可达性 ⑦并发模型契合度 ⑧团队/AI 熟悉度。

**候选取舍（截至 iOS 26 / 2026 中）：**

- **SwiftData**：与 SwiftUI/Observation 集成最好（`@Query`、`@Model` 即 `@Observable`），widget/App Intent 友好，CloudKit 私有库同步"几乎免费"。但**遗留限制仍在**：谓词支持不完整（不支持 group/having/distinct）、批量读/改受限、**to-many + optional 谓词性能差**（恰好命中本应用的"多维 tag"建模）、多 ModelConfiguration 历史上有"只加载第一个 store"的 bug（Apple 称 iOS 17.4 beta 修复，但**未见 iOS 26 上的独立复测确认**——需实测）、**关系不能跨 store**、iOS 26.1 出现过 Array 属性 Transformable 迁移回归 bug。
- **Core Data**：最成熟、谓词最强、CloudKit（含 shared/public）最完整，但在现代 Swift/并发下表达落后、样板多、与 Observation 集成不自然——对单人+AI+全新项目不划算。
- **GRDB / SQLiteData（原 SharingGRDB，Point-Free）**："data is a database"哲学，直接 SQL（join/聚合/CTE），性能最好，迁移完全可控且可测试，多 store/ATTACH 是 SQLite 一等公民。`@FetchAll/@FetchOne` 提供类似 `@Query` 但更强且不限于 SwiftUI 视图。Point-Free 自述 SQLiteData 为 "a fast, lightweight replacement for SwiftData, including CloudKit synchronization (and even CloudKit sharing), built on top of the popular GRDB library."。其 CloudKit 能力的成熟路径为：post #179 "private alpha"（仅限会员）→ post #181 "public beta"（cloudkit 分支）→ SQLiteData 1.0 正式纳入（release #112 "Added: CloudKit Synchronization + Sharing"），1.6.0 文档页注明 "Last updated on 20 Feb 2026"。冲突解决策略据 BigGo News（2025-09-18）为属性级 last-write-wins："The library handles conflict resolution using a last write wins strategy applied granularly at the attribute level, which developers noted works well for most non-collaborative applications."——对本应用这类非协作场景适用。代价：需要懂 SQL/schema 设计、非 Apple 一等支持；据 Swift Package Index，该库 "In development for about 1 year, with 189 commits and 27 releases"，仍属较新依赖。
- **Realm**：第三方、被 MongoDB 收购后前景不确定，引入外部依赖与本应用"长期自持、极简"取向冲突，不推荐。

**针对本应用的独立判断：** 这是一个"结构化、关系型、需物理隔离、未来可能同步"的数据问题。**关键洞察：无论选谁，都必须现在就按 CloudKit 约束建模**（属性全部可选/默认值、关系可选+逆向、禁 `@Attribute(.unique)`、禁 Deny 删除规则、上线后只增不改不删），否则未来开启同步时要痛苦重建 schema。
- 若开发者**不熟 SQL、且看重与 SwiftUI 的零摩擦集成与官方长期支持** → **SwiftData** 是合理默认，但要回避它的 to-many+optional 谓词弱点（即重新审视"多维 tag"是否必须多对多）。
- 若开发者**看重查询表达力、迁移可控性、物理多 store 隔离、以及更干净的 CloudKit 自控** → **GRDB/SQLiteData** 在本应用的隐私/隔离/未来双区合规诉求上更可辩护。

> **证据等级：硬约束（CloudKit 的 schema 锁定、关系不能跨 store 是架构事实）+ 工程原则（选型权衡）。**
>
> **最强反方论点（针对"建议考虑 GRDB"）：** "SwiftData 是 Apple 钦定方向，单人项目应最小化技术风险、紧贴官方 API，GRDB 增加了你自维护的负担。"
> **该反方成立的条件：** 当本应用的数据查询确实简单（单层分类 + 全文搜索，不需要复杂聚合/组卷查询）、且采用"逻辑隔离（profileID 谓词）"而非物理多 store 时，SwiftData 的限制都不触发，反方成立、SwiftData 是更优解。**反方不成立的条件：** 当"智能组卷"需要复杂查询、或合规要求"物理隔离 + 彻底删除"时，SwiftData 的弱点正中要害。

#### Q7. SwiftUI（Observation）下 UI 状态与数据流的第一性原理；何时需要 View 之外的逻辑层？
**独立推导：** SwiftUI 的 View 是**值类型、轻量、会被频繁重建的状态投影**，不是 MVC 里那个长生命周期的 View 对象。Observation 框架（iOS 17+）让"模型属性变化 → 仅重绘真正读取了该属性的视图"成为默认，这**消解了引入 ViewModel 的一大历史理由**（手动管理 `objectWillChange`/`@Published` 粒度）。

**第一性的数据流 = 单一可信源（source of truth）向下流、事件向上回调。** 在本应用：
- **持久化数据**的可信源就是数据库（通过 `@Query`/`@FetchAll` 或注入的数据 actor）——**不要**把它复制进一个 ViewModel 的 `@Published var items`（这会制造"忘记同步"的经典 bug）。
- **瞬时 UI 状态**（编辑中的表单、选择、导航路径）用 `@State`/`@Bindable` 留在视图层。

**何时需要 View 之外的逻辑中间层（Store/Model 对象，而非传统 VM）：**
- 需要：当存在**跨多个视图共享、且独立于单个视图生命周期的、有副作用的业务流程**时——本应用的 **OCR 处理流水线、复习调度、组卷、导出** 都符合，应放进 `@Observable` 的服务对象（经 `@Environment` 注入），而非塞进视图。
- 多余：对"表单 + 列表 + 详情"这类纯展示/编辑视图，强配 ViewModel 是纯样板。尤其**用 ViewModel 包裹 SwiftData 几乎总是反模式**（`@Query`/`modelContext` 本就是环境绑定的）。

> **证据等级：工程原则**（多位高权威实践者——Paul Hudson、Thomas Ricouard、Fatbobman——一致认为 SwiftUI 中 blanket-MVVM、尤其 VM 包裹 SwiftData 是过度架构）。
>
> **最强反方论点：** "ViewModel 提供了一个稳定的、可单测的展示逻辑归宿，避免视图里堆业务逻辑（重蹈 Massive View Controller）。"
> **该反方成立的条件：** 当某个视图**确实**含有复杂的展示转换逻辑（日期格式化、复杂派生状态、需要被单测的状态机）时，把这部分抽到一个 `@Observable` 模型是合理的——**但应限定在根视图/复杂视图，且它是"模型"不是"每视图一个 VM 的仪式"。** Manferdini 的折中立场（ViewModel 只用于有真实收益的根视图）与此一致。

#### Q8. Swift 6 并发架构的第一性原理；隔离边界画在哪？
**独立推导：** Swift 6 的硬约束是"编译期数据竞争安全"。本应用的并发本质极简：**绝大多数是 UI（主线程）+ 偶发的重活（OCR、图像缩放、批量导出、DB 写）**。第一性原则：
- **默认 `@MainActor`**：这一"新项目默认主 actor 隔离"由 Swift Evolution SE-0466（"Control default actor isolation inference"）引入，Apple 官方提案原文为 "This proposal introduces a new compiler setting for inferring @MainActor isolation by default within the module to mitigate false-positive data-race safety errors in sequential code."；据 useyourloaf.com，用 Xcode 26 新建项目时 "MainActor default isolation and approachable concurrency [are enabled] by default"。因此 UI、视图模型对象、轻量协调都留在主 actor，省去海量 Sendable 标注。
- **仅把真正的重活推到后台**：OCR/图像处理用 `@concurrent` 函数或专用 `actor`/`@globalActor`（如 `ImageProcessing`）；持久化写入用 SwiftData 的 `@ModelActor`（或 GRDB 的 DatabaseQueue/Pool）。
- **跨边界只传 Sendable 值**：SwiftData 中只有 `ModelContainer` 和 `PersistentIdentifier` 是 Sendable，模型对象与 `ModelContext` 不是——所以跨 actor 传 `PersistentIdentifier`，在目标 actor 用本地 context 重新加载；图像跨边界传 `Data`（值类型）而非 `UIImage`（引用类型）再在使用处构造。

**隔离边界因此清晰地落在三处：** ①主 actor（UI + 协调）②一个数据 actor（所有 DB 读写串行化）③一个图像/OCR 处理 actor（CPU 重活）。这恰好与 Q3 的"基本力②"重合——并发边界**不是额外架构，而是约束本身强加的最小边界**。

> **证据等级：硬约束**（Sendable/actor 规则是编译器强制的；SwiftData 的 Sendable 边界是 API 事实；SE-0466 是官方语言演进）。
>
> **最强反方论点：** "为性能/响应，应更激进地并行化、为每类任务建独立 actor、用 detached task。"
> **该反方成立的条件：** 当出现可测量的主线程卡顿（如批量导入上千条、OCR 大图阻塞）时，引入额外后台 actor/task group 才有依据。在此之前，过度并行只增加竞态面与认知负荷。**判据：并发结构由实测卡顿驱动，不由想象驱动。**

#### Q9. 单人 + AI 下，DI 抽象与测试架构的合理程度？AI 让过度抽象成本上升还是下降？
**独立推导：** 依赖注入的**目的**是解耦与可替换，而非"到处用 protocol"。在本应用，真正需要可替换的依赖只有少数稳定边界（OCR 引擎、持久化、也许导出）。对这些用**构造器注入 + 一个窄 protocol** 是合理的；对"单一实现且无可预见第二实现"的类型造 protocol，是教科书级 YAGNI 违例（经典反例：过早为单一短信服务造 `ISmsService` 接口，往往与首个实现耦合，第二实现到来时接口反而是负债）。

**SwiftUI 原生 DI（`@Environment`）已足够**承担本应用的依赖装配，无需引入 Swinject/Resolver 这类容器（那是为大型团队/复杂依赖图设计的）。

**AI 是否改变过度抽象的成本？—— 关键的反直觉结论：AI 让"为单一实现造接口"的成本相对*上升*。** 理由：
- AI 让"生成 protocol + mock + 装配"几乎零打字成本，于是**诱导**过度抽象（成本错觉）；
- 但每多一个抽象/契约，就多一份 AI 在后续改动中**必须跨文件保持一致**的约定；AI 在大上下文中容易在"远处文件"漏改，抽象越多、误改面越大；
- Swift 6 下，`@MainActor @Observable` 类型遵从非隔离 protocol（如 Equatable）会触发隔离一致性摩擦，protocol 还引入额外的并发隔离成本。

**测试架构：** 应**测纯逻辑**（复习调度算法、组卷规则、OCR 后处理/解析、迁移），这些是纯函数或确定性输入输出，价值高且不需要 mock。**不应**为了"覆盖率"去给 UI/单一实现服务硬造 protocol 来 mock——那是为测试牺牲设计。

> **证据等级：工程原则。**
>
> **最强反方论点：** "有了 AI，写测试和接口的边际成本极低，所以应该全面 DI + 高覆盖率，把 AI 的不可靠性用测试网兜住。"
> **该反方成立的条件：** 对**纯逻辑核心**（算法、解析、迁移）成立——这里 AI 廉价生成的测试确实是高价值安全网。**不成立的条件：** 对易变 UI 与单一实现服务，廉价生成的接口/测试是"为了存在而存在"的负债，且抬高 AI 的跨文件一致性负担。**判据：抽象与测试应跟随"稳定性 + 真实可替换性 + 逻辑确定性"，不跟随"生成它有多便宜"。**

---

### PART FOUR：怀疑、证伪与判据

#### Q10. 最可能"过度架构"的三处 / 最可能"欠架构"的三处
**最可能过度架构（按概率排序）：**
1. **为每个视图配 ViewModel（尤其包裹 SwiftData）**——SwiftUI + Observation 下的头号 cargo cult（questionable convention）。
2. **过早 SPM 多模块化 / 严格 Clean 分层**——团队级收益在单人项目无法兑现，且可能触发 SwiftData 文件布局崩溃 bug（questionable convention，部分 硬约束）。
3. **为单一实现遍布 protocol + DI 容器**——YAGNI 违例，AI 下成本相对上升（questionable convention）。

**最可能欠架构（按风险排序）：**
1. **持久化 schema 未按 CloudKit 约束 + 未版本化（VersionedSchema）预先设计**——这是**唯一**"事后改成本极高"的地方（CloudKit 上线后只增不改不删），最该在第一天就做对（硬约束）。
2. **隐私/合规的删除路径与数据隔离边界未明确**——"彻底删除某个孩子的全部数据（含图像文件 + DB 记录 + 可能的同步副本）"若没有单一、可审计的实现入口，是真实的合规风险（硬约束）。
3. **主路径（拍照 → OCR → 落地）的错误/中断恢复未架构化**——最高频路径若在 OCR 失败/中途退出/存储失败时丢数据，直接摧毁产品价值；这里值得投入显式的状态机与持久化早落地（先存原图再异步 OCR）（工程原则）。

> 注意这组判断的非对称性：**欠架构的三处全部源于硬约束（隐私、数据持久性、主路径可靠性），过度架构的三处全部源于"流行约定"。** 这本身就是 idea pollution 的指纹。

#### Q11. 挑剔的资深 iOS 架构师会点名哪些"流行但对本应用是 cargo cult / YAGNI"的实践？
- **Blanket MVVM**：在 SwiftUI 里给一切配 VM，违背框架的值类型视图设计；包裹 SwiftData 更是反模式。
- **Repository 模式包裹 SwiftData/Core Data**：再加一层把 `@Query` 的环境集成优势抹掉，产出易错的手动同步样板。
- **Coordinator/Router 模式做简单导航**：SwiftUI 的 `NavigationStack(path:)` 已是声明式状态驱动导航；对本应用的导航复杂度，Coordinator 是纯增码。
- **TCA**：为本应用的状态复杂度引入大量样板与学习曲线，得不偿失（除非某个局部确有复杂状态机）。
- **Clean Architecture / VIPER 的多层 + UseCase/Interactor**：为"团队 + 复杂业务 + 高测试要求"设计，对单人 25K 行 pre-PMF 是过度（社区共识：小项目用它是 overkill）。
- **为单一实现造 protocol**：YAGNI 违例。
- **第三方 DI 容器（Swinject/Resolver）**：`@Environment` 足矣。
- **过早 SPM 模块化**：收益是团队级，成本照付，且有 SwiftData 文件布局崩溃风险。

> **证据等级：questionable convention（这些都是"流行但需被质疑"的约定）。**

#### Q12. 综合：(a) 独立推导的"第一性最优架构"概览；(b) 可证伪的架构决策判据；(c) 我最不确定、最需经验验证之处

**(a) 第一性最优架构概览（本轮独立结论）：**
> **一句话：单一 App Target，按"变化速率/功能"分文件夹的朴素分层；UI 用朴素 SwiftUI + `@Observable` 模型 + `@Environment` 注入（不强制 per-view VM）；并发用"主 actor 默认 + 数据 actor + 图像/OCR actor"三分；持久化层是唯一被窄接口保护、且现在就按 CloudKit 约束 + VersionedSchema 建模的稳定边界；架构资源极度向"拍照→OCR→可靠落地"主路径倾斜。**

具体形态：
- **结构**：上面 Q4 的 7 个文件夹（逻辑边界），单 target；无环依赖靠纪律；仅 Recognition 与 Persistence 两处用窄 protocol 做可替换边界。
- **UI/状态**：source of truth 在 DB；瞬时状态用 `@State/@Bindable`；OCR/复习/组卷/导出作为 `@Observable` 服务经环境注入。
- **并发**：`@MainActor` 默认；重活推后台 actor；跨界传 `PersistentIdentifier`/`Data`。
- **持久化**：SwiftData（若查询简单 + 逻辑隔离可接受）或 GRDB/SQLiteData（若需复杂查询/物理隔离/自控同步）；**两者都现在就按 CloudKit"全可选、无 unique、关系可选+逆向、无 Deny、只增不改不删"建模，并从第一天用 VersionedSchema。**
- **隐私**：优先考虑"每孩子独立 store 文件"的物理隔离（更可辩护的删除/合规），代价是放弃跨档案关系 + 需在 iOS 26 实测多 store 可靠性；若选逻辑隔离（profileID 谓词），必须有单一、被测试覆盖的删除入口。
- **测试**：聚焦纯逻辑（算法/解析/迁移），不为 UI/单实现硬造 mock。

**(b) 可证伪的架构决策判据（任何未来架构变更都用它检验）：**
1. **变化已发生判据**：这个抽象/模块所押注的"变化点"，是否**已经至少发生过一次**（或已有合同级确定性）？否则按 YAGNI 不做。（对应 Fowler 的 Rule of Three：第三次重复再抽象。）
2. **重复 vs 错误抽象判据**：当前是"三处可容忍的重复"还是"一个会随每次变更扩散的错误抽象"？若引入抽象后开始出现"传参数 + 加条件分支穿过共享代码"，说明抽象错了，应内联回重复（Metz 在 "The Wrong Abstraction" 中的修复处方："the fastest way forward is back"，即把抽象内联回各调用点）。
3. **协调收益判据**：这个边界带来的收益是否依赖"多人/多 agent 并行"？若是，而你仍是单人，则收益≈0。
4. **认知单元判据**：拆分后，单个理解单元是否真的落回工作记忆容量（Cowan 2001 的 3–5 chunk）以内？若拆分只增加跳数而不降低单元复杂度，则负收益。
5. **AI 一致性判据**：这个改动是增加还是减少了"AI 必须跨文件保持一致的契约面"？增加契约面 + 分散逻辑 = 抬高误改风险。
6. **稳定边界判据**：加抽象/接口的地方，是否是"既稳定、又有真实第二实现或真实测试需求"的边界？只有同时满足才值得。
7. **主路径倾斜判据**：这笔架构投入是否服务于最高频主路径（捕获→落地）的可靠性？若是为低频高复杂功能（组卷/复习/未来同步）预先重构，降权。
8. **CloudKit 锁定判据**（持久化专用）：这个 schema 变更是否会破坏未来 CloudKit 的"只增不改不删"？若是，现在就避免。

**(c) 我最不确定、最需经验验证之处（诚实披露）：**
1. **SwiftData 多 ModelConfiguration / 多 store 在 iOS 26 上的真实可靠性**：Apple 称 iOS 17.4 beta 修复了"只加载第一个 store"的 bug，但**我未找到 iOS 26 上的独立复测确认**。若计划用"每孩子独立 store"做物理隔离，**务必先在真机 iOS 26 上实测**。
2. **SwiftData 在本应用"多维 tag（to-many + optional 谓词）"上的实际性能**：文献指出这是 SwiftData 弱点，但是否在本应用数据量级（家庭级，数千条而非百万条）构成真实问题，需要用真实数据量压测后才能定。
3. **GRDB/SQLiteData 的 CloudKit 同步成熟度**：SQLiteData 1.6.0（文档页注明 Last updated 2026-02-20）已正式纳入 CloudKit 同步含 sharing，但其 CloudKit 能力起步于"private alpha"、经"public beta"，且该库整体"开发约一年、189 commits / 27 releases"，仍属较新依赖，**生产就绪度需查最新文档并实测**。
4. **AI 辅助改变架构权衡的量化证据普遍薄弱**："良好结构使 AI 迭代减少 60–70%"等多为厂商/公司自述，非对照实验；"AI 抬高误改风险"在方向上可信，但**幅度未知**。本报告对 AI 的论证应作为"方向性工程判断"而非"实证定律"对待。
5. **复习算法的选型对数据模型的反向约束**：若未来从简单间隔升级到 FSRS（需要存储 stability/difficulty/retrievability + 完整复习历史），数据模型会变——这与 CloudKit"只增不改"锁定存在张力，**值得现在就为"复习历史"预留 add-only 友好的建模**。

---

## Recommendations（分阶段、可执行）

**阶段 0（现在，未上线前——只做"事后改成本极高"的事）：**
1. **锁定持久化 schema 设计**：无论 SwiftData 还是 GRDB，**现在就按 CloudKit 约束建模**（全属性可选/默认、关系可选+逆向、禁 `@Attribute(.unique)`、禁 Deny、规划 add-only 演化），并从第一条模型起使用 VersionedSchema/可版本化迁移。**触发改变的基准：** 若你能 100% 确定永不上云，可放宽——但这是不可逆赌注，建议保守。
2. **确定隔离策略并实测**：在真机 iOS 26 上验证"多 store 隔离"是否可靠。可靠 → 采用每孩子独立 store（物理隔离，合规最稳）；不可靠 → 退回 profileID 逻辑隔离，并立刻实现**单一、被测试覆盖的"彻底删除某孩子全部数据"入口**（含图像文件）。
3. **把主路径做成"先落地后处理"**：拍照后**先持久化原图 + 占位记录**，再异步 OCR 回填文本；为 OCR 失败/中断设计显式状态（pending/failed/done）。这是对最高频路径可靠性的唯一值得的"预先架构"。

**阶段 1（构建核心，pre-PMF 迭代期）：**
4. **采用朴素 SwiftUI**：默认无 per-view ViewModel；仅把 OCR/复习/组卷/导出做成 `@Observable` 服务经 `@Environment` 注入。**触发改变的基准：** 某视图出现需要单测的复杂派生状态时，才为**该**视图抽出一个 `@Observable` 模型。
5. **并发三分**：`@MainActor` 默认 + 数据 actor + 图像/OCR actor。**触发改变的基准：** 实测出主线程卡顿才追加后台 task group/actor。
6. **抽象克制**：仅 Recognition 与 Persistence 用窄 protocol；其余直接具体类型。**触发改变的基准：** 出现真实第二实现或真实可替换需求（Rule of Three）才加接口。
7. **测试聚焦纯逻辑**：复习算法、组卷规则、OCR 解析、schema 迁移——这些用 AI 廉价生成测试是高价值安全网。

**阶段 2（接近/达到 PMF，考虑变现/同步时）：**
8. **再评估模块化**：仅当全量编译成为可测量瓶颈、或要做 widget/扩展、或引入协作者时，把"文件夹 → SPM 模块"机械升级（边界已在阶段 1 备好）。
9. **再评估持久化引擎**：若届时复杂查询（组卷）或自控同步成为刚需，评估迁移到 GRDB/SQLiteData 的成本。
10. **复习算法升级**：若要上 FSRS（其需存储 stability/difficulty/retrievability 与完整复习历史），确认数据模型的 add-only 演化路径不破坏 CloudKit 锁定。

---

## Caveats（局限与诚实声明）
- **本轮是纯独立推导，未参考你的现有架构**，因此可能与你的实现重合、也可能冲突；冲突点正是后续轮次该聚焦的"idea pollution"候选。
- **本报告对 AI 辅助影响架构权衡的论证，方向性可信但量化证据薄弱**：相关数字多为厂商/公司自述而非对照实验，请作为工程判断而非定律。
- **SwiftData 的若干结论依赖版本特定行为**（iOS 26.x 仍在演进，多 store 可靠性、to-many 谓词性能、迁移稳定性等都建议在你的真机 + 真实数据量上复测后再决策）。
- **关于持久化选型，我刻意没有给单一"标准答案"**：SwiftData 与 GRDB/SQLiteData 的最优解取决于两个你尚未明确的变量——查询复杂度（组卷有多"智能"）与隔离强度要求（逻辑 vs 物理）。这两点澄清后选型即可收敛。
- **"复习是核心还是增值"在需求描述中自相矛盾**，本报告按"增值"处理（即不为其预先重型架构）；若你实际视复习为核心，复习数据模型与算法的架构权重需上调。
- **本报告优先选择了会让你"重新思考"的判断**（如建议考虑 GRDB、点名 per-view VM 为头号 cargo cult、指出欠架构全在硬约束/过度架构全在流行约定），而非安全平庸的中立综述——这符合你的明确要求，但也意味着每条结论都附了"最强反方 + 反方成立条件"，请据此校准。