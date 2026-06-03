# 什么是"最优解耦"？——一个资深架构师的判断框架

## TL;DR
- **"最优解耦"不是一个固定结构，而是一个动态平衡点：在"会独立变化的接缝处"切开，在"会一起变化的地方"合并；判据是"未来最可能的那类变更"的成本最低，而非抽象层最多。** 用 John Ousterhout 的话说，目标是让模块"深"（deep modules：简单接口 + 丰富实现），而非制造大量"浅"模块。Parnas 的原始判据至今未变：按"可能变化的设计决策"分解，而非按流程步骤分解。
- **判断"恰好/过头/不足"靠可观测信号，而非教条：** 过度解耦的症状是"单实现接口泛滥、pass-through 层、改一个功能要跳 5+ 文件、抽象里堆条件参数"；不足解耦的症状是"change amplification（改一处要动很多处）、shotgun surgery、循环依赖、认知负荷爆炸"。可量化指标包括 Martin 的 Instability/Abstractness/Distance、Chidamber-Kemerer 的 CBO、连接度（connascence）的强度×局部性×度。
- **在"多 AI agent 协作"模式下，最优点确实向"更显式的边界与契约"方向移动，但不向"更多抽象层"移动。** 实证证据（MAST、SEMAP、The Specification Gap）显示：多 agent 失败的最大单一来源是规格/设计问题（41.8%），而显式契约是恢复成功率的决定性杠杆。结论：**提高契约的显式度（接口、类型、文档、模块物理边界），但继续用 YAGNI 压制投机性抽象。**

---

## Key Findings

1. **"最优"由变化驱动，不由对称驱动。** Parnas（1972）确立的判据是：以"难的或可能变化的设计决策"为单位分解系统，让每个模块隐藏一个"秘密"——"one begins with a list of difficult design decisions or design decisions which are likely to change. Each module is then designed to hide such a decision from the others." 接缝应当画在"变化率不同"或"信任/稳定边界不同"的地方，而不是画在流程图的步骤之间（Parnas 原话："it is almost always incorrect to begin the decomposition of a system into modules on the basis of a flowchart"）。

2. **解耦本身有成本，过度解耦是真实的反模式。** Fowler 把"speculative generality（投机性通用化）"列为代码坏味道；XP 的 YAGNI（Ron Jeffries："always implement things when you actually need them, never when you just foresee that you will need them"）正是为压制它而生。Sandi Metz 的名言"duplication is far cheaper than the wrong abstraction"指出：错误的抽象比重复更贵，因为它通过参数+条件分支不断腐烂。

3. **存在可观测、半量化的判据。** Ousterhout 的三个复杂度症状（change amplification、cognitive load、unknown unknowns）是最实用的"日常体检"。Martin 的包度量（I、A、D = |A+I−1|）给出"痛苦区/无用区"的坐标。连接度（Page-Jones）给出比"松/紧"更细的标尺，并配 Weirich 两条规则："把强连接度转弱"、"距离越远用越弱的连接度"。

4. **AI/多 agent 维护会移动最优点——向显式契约方向，而非向更多层方向。** 这是有实证支撑的独立判断，详见下文第 3 节。

---

## Details

### 1. CRITERIA / SIGNALS——怎么知道"恰好"、"过头"、"不足"

**根本判据（先记这一条）：** Kent Beck —"for each desired change, make the change easy (warning: this may be hard), then make the easy change." 一个解耦良好的系统，是让"明天最可能的那类变更"变得局部、低风险。如果你的解耦没有让任何真实变更变容易，它就是装饰性的。

**"不足解耦"（big ball of mud 方向）的症状清单：**
- **Change amplification（Ousterhout）**：一个看似简单的改动要在多处修改（"a seemingly simple change requires code modifications in many different places"）。对应 Fowler 的 "Shotgun Surgery" 坏味道。
- **可量化：每个功能变更触碰的文件/模块数**持续偏高且发散。
- **循环依赖**（违反 Martin 的 Acyclic Dependencies Principle："the dependency structure for released components must be a directed acyclic graph"）。
- **高 CBO（Coupling Between Objects，Chidamber & Kemerer）**：经验研究（Basili et al. 1996 等）反复发现 CBO 与缺陷倾向、维护工作量正相关，且在生命周期早期就是优于传统代码度量的 fault-proneness 预测器。
- **强连接度跨越模块边界**（如 Connascence of Meaning/Position 出现在两个不同组件之间）。
- **位于 Martin 的 "Zone of Pain"**：A≈0、I≈0（高度具体且被大量依赖，既难改又难扩展——"rigid... cannot be extended because it is not abstract, and very difficult to change because of its stability"）。

**"过度解耦"（over-engineering / speculative abstraction 方向）的症状清单：**
- **单实现接口泛滥**：每个 class 都有一个对应的 protocol/interface，却只有一个实现且没有测试替身需求。这是 Swift 项目里最常见的"protocol soup"。
- **Pass-through 方法/层（Ousterhout 的红旗）**：某层只是把调用原样转发给下一层，接口复杂度上升但功能没增加（"a pass-through method... increases the interface complexity of a module, without increasing the total functionality"）。
- **Shallow modules**：接口几乎和实现一样复杂，抽象没带来净收益。
- **错误抽象的腐烂信号（Sandi Metz）**：共享代码里不断增加参数和条件分支去伺候不同调用者——"If you find yourself passing parameters and adding conditional paths through shared code, the abstraction is incorrect."
- **位于 Martin 的 "Zone of Uselessness"**：A≈1、I≈1（极度抽象却无人依赖）。
- **抽象层深度 vs. 交付价值不成比例**：interface + abstract class + concrete class 三件套套在每个概念上，"以防万一"。

**半量化的体检指标（建议作为 CI/审查参考，不作为硬门禁）：**
- **Martin Distance D = |A + I − 1|**：越接近 0 越好；持续远离 main sequence 的包要审查。
- **单实现接口比例**：统计"只有 1 个生产实现且无测试 mock 需求"的 protocol 占比，偏高即过度抽象。
- **每个功能/缺陷变更的平均触碰文件数**：趋势上升 = 解耦不足或边界画错。
- **CBO / 扇出（efferent coupling Ce）**：异常高的类是重构候选。
- **圈复杂度（cyclomatic complexity）**：用于发现"深但乱"的实现（深模块允许实现复杂，但不允许混乱到不可测）。

关键提醒：这些数字是**信号不是目标**（Goodhart 定律）。Ousterhout 明确指出"sometimes an approach that requires more lines of code is actually simpler, because it reduces cognitive load"——所以"行数最少/抽象最多"都不是优化目标，**认知负荷与变更成本才是**。

### 2. LAWS / PRINCIPLES——在哪些接缝解耦，哪些不要

**应该解耦的接缝（DO）：**

1. **不同变化率 / 不同变化原因的接缝。** 这是 Parnas 信息隐藏的核心，也是 Martin 的 Common Closure Principle（CCP）："gather into components those classes that change for the same reasons and at the same times." 反过来：会因不同原因、不同时间变化的东西要分开。这是 SRP 在组件级的版本。

2. **稳定性/信任边界。** Martin 的 Stable Dependencies Principle："depend in the direction of stability"——依赖应指向更稳定的方向；Stable Abstractions Principle：越稳定的组件越应该抽象。把"会变的具体实现"放在依赖图的叶子，把"稳定的抽象/领域核心"放在被依赖的中心。

3. **真正需要多实现的地方。** 当下确实存在 2 个以上实现（如平台差异、测试替身、A/B 策略）才引入接口。这与 DDD 的边界一致：Evans 的 Aggregate 是"一致性/事务边界"，Bounded Context 是"模型一致性边界"（"delimits the applicability of a particular model so that team members have a clear and shared understanding of what has to be consistent"）——在模型语义会冲突的地方切开。

4. **外部依赖/不可控的第三方边界。** 在 iOS 中，第三方库（认证、网络 SDK）应通过一个适配模块隔离，"simplify the interface of the library and adapt it to the needs of our application"——这是 Parnas"隐藏会变的设计决策"的直接应用。

**不应该解耦的地方（DON'T）：**

1. **不要为"将来可能"而解耦（YAGNI）。** Fowler 的 speculative generality：为尚不存在的需求加钩子、参数、抽象层，几乎总是净负债。

2. **不要在还没看清模式时强行去重（Rule of Three）。** Fowler 推广的"Rule of Three"：第一次写，第二次重复时忍住，第三次出现才抽象。Metz 更激进：宁可重复，也不要错误抽象——错误抽象的退出成本极高（"when the abstraction is wrong, the fastest way forward is back"，要先 inline 回重复才能重来）。

3. **不要加没有净收益的层。** 每一个 pass-through 层、每一个 shallow wrapper 都增加接口复杂度而不增加功能。Ousterhout："different layers should have different abstractions"——如果相邻两层抽象几乎相同，说明这个层是多余的（information leakage 的红旗）。

4. **不要把强连接度从局部变成跨模块。** Weirich 规则：随着元素间距离增大，使用更弱的连接度。同一函数内的 Connascence of Position（参数顺序）无伤大雅；跨模块的 Connascence of Meaning（双方约定 1=true）是定时炸弹。

**核心张力与我的判断（evolutionary vs. upfront）：**
Fowler 在 "Is Design Dead?" 中给出了我认同的立场：纯演进式设计在"有纪律（持续重构 + 测试）"时优于大型前期设计，但他自称"cowardly XPer"——对于"事后很难用重构加进来"的少数决策（如是否有数据库、核心模块边界），仍应做少量前期设计："I would make an initial decision about the presence of a database and go from there, but I would still evolve most of the design." **我的执行规则：** 对"可逆、易重构"的决策走演进式（默认不抽象，等 Rule of Three）；对"不可逆、跨越整个依赖图"的决策（持久化、模块物理边界、核心领域模型）做最小但明确的前期设计。Beck 的"make the change easy then make the easy change"是把两者缝合的操作手法——先做"准备性重构（preparatory refactoring）"把接缝挪到对的地方，再做功能改动。

### 3. AI / MULTI-AGENT MAINTENANCE——最优点会移动吗？

**我的独立结论：会移动，方向是"提高边界与契约的显式度（explicitness）"，但不是"增加抽象层数或更激进地 DRY"。** 也就是说，在 Parnas/Ousterhout 的"高内聚、深模块、强信息隐藏"这条轴上，AI 协作把最优点往"边界更清晰、契约更显式、模块物理隔离更强"的方向推；但在"抽象层数量"这条轴上，YAGNI 反而应当被更严格地执行，因为 AI 廉价地生产抽象的能力会放大 speculative generality 的风险。

**为什么向"更显式契约"移动——实证证据：**

- **多 agent 失败的最大单一来源就是规格/设计问题。** Cemri et al.（UC Berkeley Sky Computing Lab）的论文《Why Do Multi-Agent LLM Systems Fail?》（arXiv:2503.13657，NeurIPS 2025 Datasets & Benchmarks Track）构建了 MAST 失败分类法，基于对 1,642 条多 agent 执行轨迹的标注，分类法"validated by high inter-annotator agreement (κ = 0.88)"。三大类失败的精确占比为：**specification and system design 41.8%、inter-agent misalignment 36.9%、task verification 21.3%**；覆盖的 7 个框架（MetaGPT、ChatDev、HyperAgent、AppWorld、AG2、Magentic-One、OpenManus）失败率高达 41%–87%。更关键的是干预实验：**仅改进 ChatDev 的角色规格（同 prompt、同 GPT-4o）就带来 +9.4 个百分点的成功率提升**；加一个高层目标验证步骤——"[adding high-level objective verification] to ChatDev yields a +15.6% improvement in task success on ProgramDev"。

- **显式契约是恢复成功率的决定性杠杆。** Chacón Sartori 的《The Specification Gap》(arXiv:2603.24284, 2026 预印本) 在 51 个类生成任务上，让两个有相反结构偏好的 agent 协作：随着规格从完整文档退化到裸签名，**双 agent 集成准确率从 58% 跌到 25%，而单 agent 基线只从 89% 跌到 56%**，留下 25–39 个百分点的"协调鸿沟"。决定性发现：**只要把完整规格交给合并 agent，就能恢复到 89% 的单 agent 上限**——"specification alone recovers the single-agent ceiling (89%), while providing conflict reports adds no measurable benefit." 这个鸿沟可分解为协调成本 +16pp 与信息不对称 +11pp，二者近似独立可加。

- **显式 SE 契约能大幅降低失败。** SEMAP（arXiv:2510.12120, 2026）把"显式行为契约 + 结构化消息 + 生命周期验证"引入多 agent 系统，相对 MetaGPT 基线在函数级开发上**失败数最多减少 69.6%**，部署级减少 56.7%；论文明确把基线问题归因为"loosely coupled prompts and informal, ad hoc role specifications"（松耦合 prompt 与非正式、临时的角色规格）。

- **上下文越大、越分散，编辑准确率越差。** SWE-bench（Jimenez et al., ICLR 2024, arXiv:2310.06770）指出真实代码库平均规模巨大——"codebases consist of many more tokens (438K lines on average) than can typically be fit into an LM's context window"，被迫依赖检索；该基准含 2,294 个真实问题、12 个 Python 仓库，发表时最佳模型 Claude 2 仅能解决 1.96% 的问题。更近的 SWE-PRBench（2026 预印本）发现 8 个前沿模型"随上下文扩大单调退化——2,000-token 的结构化 diff 提示在每个模型上都优于 2,500-token 的全上下文提示"，机制是长上下文下的"注意力稀释"。这直接对应 Ousterhout 的 change amplification 和 cognitive load：AI agent 也有"认知负荷"，而且其窗口是硬上限。

**把这些翻译成对最优点的影响：**

1. **物理模块边界（Swift Package / target）的价值上升。** 一个隔离良好的模块可以"在单一上下文中被理解、修改、测试"，agent 不必递归拉入整个依赖图。在 iOS 中，用 SPM 把功能切成本地 package、并通过"interface 模块"让实现彼此隔离（SwiftRocks 的做法：依赖 `HTTPClientInterface` 而非 `HTTPClient`，"changes to the actual HTTPClient will have no repercussions on the other modules"），既改善并行 agent 的冲突隔离，又改善编译时间。这等于把"模块边界"同时变成"agent 的工作隔离边界"。

2. **契约要显式：类型、协议、文档注释、明确的输入输出。** AI 不擅长隐式约定（implicit conventions）——Connascence of Meaning/Convention 这类"双方心照不宣"的耦合，对 AI 比对人更危险，因为 AI 看不到团队口头传统。把强/隐式连接度转成弱/显式连接度（Weirich 规则）在 AI 时代收益更大。

3. **但不要增加抽象层。** 反方论点是成立的：AI 廉价地写样板代码、AI 重构更快、AI 对 DRY 的依赖更低（重复代码对 AI 的"维护痛苦"低于对人）。这些都成立——但它们的结论是"容忍更多重复、容忍更长但直白的实现（deep module）"，**不是**"加更多接口层"。每个投机性接口都增加 agent 必须读懂的契约面积，是认知负荷的净增加。Metz 的"错误抽象比重复贵"在 AI 维护下更成立：AI 会忠实地沿着错误抽象继续加参数和条件，把腐烂加速。

4. **一个值得注意的反向风险：** Foote & Yoder 曾观察到"inscrutable code may have a survival advantage over good code, by virtue of being difficult to comprehend and change"——在 AI 时代这条被反转了。难懂、隐式、强耦合的代码现在会在每一次 agent 交互中收"利息"。所以 AI 协作实际上提高了"保持显式与解耦"的回报率。

**净判断：** 对你这个"单人 + 一个编排 agent + 多个外部 review/实现 agent"的 iOS 项目，最优点 = **Parnas/Ousterhout 的深模块 + 显式契约 + 物理 package 边界**，配上**比纯人类团队更严格的 YAGNI**。给 agent 的不是"更多抽象"，而是"更清楚的边界和更明确的合同"。

### iOS / Swift 具体落点
- **默认不为单实现引入 protocol。** 只有当真的需要测试替身或多实现时才抽象。Chris Eidhof："don't start with a protocol just for the sake of protocol-oriented programming... Let the problem drive the solution, not the other way around." 很多看似需要 protocol 的场景（如可测的网络层）可以用把可变部分提取成值类型（`Resource<A>`）来更简单地解决。
- **用 SPM 本地 package 作为主要解耦接缝**，按 feature 切（CCP：一起变的放一起），feature 之间不互相 import，通过 interface 模块或依赖注入解耦。这同时服务于：编译时间、并行 agent 隔离、清晰契约。
- **警惕 modularization 反噬**：模块过多、依赖图过深会让编译变慢（Runway/iFood 的经验：把依赖图"压平"使其尽量水平，让实现变化不波及接口）。模块数量本身不是目标。

---

## Recommendations

**阶段 0（现在就做，定义"完成"的标准）：** 写下你这个项目"未来 3–6 个月最可能的 5 类变更"（如：换持久化、加一个新 feature 屏、换网络层、改主题、加 IAP）。这份清单就是你画接缝的依据（Parnas）。任何不服务于让这些变更变容易的解耦，都先不做。

**阶段 1（结构骨架，少量前期设计）：**
- 用 SPM 按 feature 切本地 package；feature 间不直接依赖，共享能力（网络、存储、设计系统）下沉到被依赖的稳定模块。
- 对第三方库一律加适配模块隔离。
- 为每个 package 写一页 `README`/契约说明（给 AI agent 当显式上下文——这正是 MAST/SEMAP 证据指向的最高杠杆点）。
- **不做**：不给单实现加 protocol，不加 pass-through 层，不搭三件套。

**阶段 2（演进式，靠信号驱动重构）：** 引入轻量度量到 CI 作为参考（非门禁）：每个 PR 触碰的文件数、单实现 protocol 比例、循环依赖检测、CBO/扇出 Top-N 报告。出现下列触发器才重构：
- 同一类变更连续两次触碰 5+ 文件 → 边界画错，做准备性重构。
- 某共享抽象开始加第 2 个布尔参数/条件分支 → 按 Metz 把它 inline 回重复，重新观察。
- 出现循环依赖 → 立即用依赖反转或新建共享组件打破（ADP）。
- 某 agent 反复在同一模块产生集成冲突 → 该模块契约不够显式，补类型/文档/缩小接口（参照 The Specification Gap：补全规格是恢复成功率的决定性手段）。

**会改变上述建议的阈值/基准：**
- 若项目从单人扩为多人团队，或模块数超过约 20–30 个导致编译显著变慢 → 重心从 CCP 转向压平依赖图与 interface 模块。
- 若 AI agent 的集成失败率（参照 MAST 三类别）以"规格/设计类"为主（在原研究中占 41.8%）→ 投资点是契约显式度（文档、类型、缩小接口），而非加抽象。
- 若你发现自己在为"可能的未来"辩护某个抽象 → 触发 YAGNI，删掉它。

---

## Caveats
- **度量是信号不是目标。** CBO、Distance、触碰文件数都可能被 game；它们用来"发现可疑点"，最终判断仍靠"认知负荷与变更成本"这个人类判断（Ousterhout）。Henderson-Sellers、Hitz-Montazeri 等也对 CK 度量的测量理论基础提出过批评，LCOM 在多项研究（如 Basili et al. 1996）中预测力弱。
- **多 agent 实证证据多为 2025–2026 的新成果。** MAST 已在 NeurIPS 2025 经同行评审，较权威；但《The Specification Gap》是单作者预印本、n=51 任务、未独立复现，SEMAP 自称"preliminary evaluation"且报告的是"失败数下降"而非成功率。方向性结论稳健，具体数字应按预印本对待。
- **"最优解耦"没有全局唯一解。** 它依赖于变化的分布（你预测的变更清单）和团队/agent 的能力。本框架给的是判断方法和触发器，不是一套固定层数。
- **Big Ball of Mud 在早期原型阶段是可接受的**（Foote & Yoder："it's okay if the system looks at first like a big ball of mud, at least until you know better"）——解耦的时机本身也要 YAGNI，等领域 grain 显现再固化边界。

---

### 引用的权威来源（人物 / 著作）
- **David Parnas**, *On the Criteria To Be Used in Decomposing Systems into Modules* (1972) — 信息隐藏、按"可能变化的设计决策"分解。
- **Larry Constantine & Edward Yourdon**, *Structured Design* (1979) — 耦合谱（content > common > control > stamp > data）与内聚谱（功能内聚最佳）。
- **Robert C. Martin** — SOLID、组件三原则（REP/CCP/CRP）、耦合三原则（ADP/SDP/SAP）、I/A/D 度量与 main sequence、*Clean Architecture*。
- **Martin Fowler** — *Refactoring*（speculative generality、Rule of Three、preparatory refactoring）、YAGNI、*Is Design Dead?*（演进式 vs 前期设计）。
- **John Ousterhout**, *A Philosophy of Software Design* — deep vs shallow modules、complexity = dependencies + obscurity、change amplification / cognitive load / unknown unknowns、information leakage。
- **Edsger Dijkstra** — separation of concerns。
- **Eric Evans**, *Domain-Driven Design* — Bounded Context（模型一致性边界）、Aggregate（一致性/事务边界）。
- **Brian Foote & Joseph Yoder**, *Big Ball of Mud* (1997)。
- **Sandi Metz**, *The Wrong Abstraction* —"duplication is far cheaper than the wrong abstraction"。
- **Kent Beck** — 简单设计四规则、"make the change easy, then make the easy change"。
- **Meilir Page-Jones**（连接度）+ **Jim Weirich**（degree/locality 两条规则）。
- **Chidamber & Kemerer** — CK 度量套件（CBO 等）及其 fault-proneness 实证（Basili et al. 1996）。
- **Cemri et al.**, *Why Do Multi-Agent LLM Systems Fail?* (MAST, NeurIPS 2025, arXiv:2503.13657)；**Chacón Sartori**, *The Specification Gap* (arXiv:2603.24284, 2026)；**Mao et al.**, *SEMAP* (arXiv:2510.12120, 2026)；**Jimenez et al.**, *SWE-bench* (ICLR 2024, arXiv:2310.06770)。