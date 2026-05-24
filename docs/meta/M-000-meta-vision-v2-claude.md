---
last_verified: 2026-05-24
layer: principle
scope: root-rule
freshness:
  max_age_days: 180
  decay_trigger: [meta_audit, override_rationale_change]
default_word_budget: 2500
override_rationale: "v2.0 重构后落地 8 项 PRIMARY 内核 + 7 项红旗改造 + 配套基础设施收口,真实密度需要 ~2900 nwc。允许超出默认预算,理由符合本文件 §7 目的优先原则:字数上限是手段不是目的,字数挤压实质就该让步。"
---

# M-000 — 项目最高优先级协作规则 (Root Rule)

> 本文件是 SnapDrill iOS 项目所有协作规则的优先级 0 入口。其他规则(M-001~M-006、ADR、F 规则、standards)与本文件冲突时,以本文件为准;本文件与用户裁决冲突时,以 user-decision-log 为准。

## 1. 定位

- 本文件不是「宪法」或任何政治法律隐喻,而是**项目运行所需的最少必要规则集合**
- 修改本文件需走 §4 user-decision-log 流程 + 4 家异源 sign-off
- 智能体执行任何任务前应能复述本文件 §3 / §4 / §7 三段要点;复述不出 = Boot 失败,应拒绝下场

## 2. 议题清单

本文件覆盖 8 个议题,每项的执行细则由 M-001~M-006 派生承载(§9):

1. **默认多方异源**(§3)
2. **用户最高裁决 + append-only 决策日志 + Overrule**(§4)
3. **字数软上限 + override**(§5)
4. **风险接受**(§6)
5. **目的优先原则**(§7,前称「古德哈特防御」)
6. **配套基础设施约束**(§8)
7. **物理隔离 + 净化提示词 + sanity check 自反性**(§8.5/§8.6/§8.7)
8. **M-001~M-006 派生表**(§9)

## 3. 默认多方异源

### 3.1 PRIMARY 内核

任何涉及**结构性决策、跨文档影响、用户承诺、外部事实、模型能力边界不明**的议题,默认要求 ≥ 2 家**异源** LLM 独立产出,折叠后由用户裁决落地。

### 3.2 异源定义(P4 同源警告内嵌)

异源 = 不同公司 + 不同训练谱系 + 独立上下文。同公司不同模型(Claude 4.7 vs 4.6)算同源;同模型不同 prompt 算同源;不同公司但相同 fine-tune 来源算同源。

当前可用异源池:Anthropic Claude / OpenAI Codex / DeepSeek / Google Gemini。**4 不是必需数,≥ 2 家即可,但 sanity check 阶段建议 ≥ 3 家**。

### 3.3 例外

低风险机械任务(rename / 批量格式化 / typo 修复)可单家执行,无需异源。判据:**「这件事如果做错,异源会不会以不同方式做错?」** 答 yes 即走多家,答 no 单家。

## 4. 用户最高裁决 + append-only 决策日志 + Overrule

### 4.1 PRIMARY 内核

用户(项目 PO)是所有协作的最终价值函数。多智能体系统没有自洽的终局判据,质量/成本/速度/风险接受度只能由用户裁决。

### 4.2 决策日志格式

`docs/meta/user-decision-log.md` append-only。每条裁决 8 字段:时间 / 冲突描述 / 裁决 / 理由 / 是否触发元规则修订 / Overrule 关系 / 元层级注记 / (可选)关联条目。

### 4.3 Overrule

新裁决覆盖旧裁决时,必须在「Overrule 关系」字段显式声明被覆盖条目编号。否则按本文件 §4.1 新裁决无效。机械化检查:新条目含「撤回/覆盖/废弃」语义但 Overrule 字段为空 = 告警。

## 5. 字数软上限 + override

### 5.1 默认预算

- 中文正文默认 ≤ 2500 non-whitespace chars(nwc)
- 代码块独立预算 ≤ 400 nwc
- 英文翻译预算 ≤ 4000 nwc

### 5.2 override 机制

**这些数字是手段不是目的。真目的是「可一次性读完 + 信号密度高」**。当议题密度真实需要超出预算时,在 frontmatter `override_rationale` 字段说明理由即可超出。本文件自身就是 override 实证(超出 ~400 nwc,理由见 frontmatter)。

### 5.3 反向约束

不允许「为达字数硬上限而牺牲可判定性」。压缩到黑话/省略实质 = 违反 §7 目的优先原则。

## 6. 风险接受

用户可针对已识别风险显式声明 `risk_accepted: <risk_id>`,后续 LLM 不再重复警告同一风险。声明落 user-decision-log,不另立文件。

## 7. 目的优先原则(Purpose over Form)

### 7.1 PRIMARY 内核

**规则的目的优先于规则的字面**。当字面遵守规则会违背规则目的时,应违反字面遵守目的,并在 user-decision-log 落档说明。

### 7.2 经济学背景注

本原则在经济学中称「古德哈特定律」(Charles Goodhart 1975):「当一个指标变成目标,它就不再是好指标」。「古德哈特防御」是本原则的别名,可在历史文档中保留,新文档统一使用「目的优先原则」。

### 7.3 实证

- M-005 plan 起草:Claude 把 2500 nwc 当硬上限挤压议题密度,被帅哥纠正(本审计 user-decision-log #009)
- ADR-004 拆分:同源主笔保守拆分被异源激进版本 Overrule(user-decision-log #007)

## 8. 配套基础设施约束

### 8.1 frontmatter 简化 schema

文档分类枚举从 v1.2 的 6 类(principle/pattern/snapshot/archive/decision/contract)简化为 3 类:

| 新枚举 | 涵盖旧值 | 语义 |
|---|---|---|
| **principle** | principle / pattern / contract | 长期稳定的规则、模式、契约 |
| **decision** | decision | 一次性裁决记录(ADR / user-decision-log) |
| **archive** | snapshot / archive | 时间快照、历史归档 |

附加字段:`status` 仍保留 3 值 `{active, archived, deprecated}`;`supersession_status` 作为可选侧通道字段,允许 `partially_superseded`(user-decision-log #008 实证)。

### 8.2 docaudit 拆开

不预设 check 数量。新增 check 必须附「真实事故来源或风险模型」,否则视为可选。当前 11 check 中,**核心强制**:frontmatter 解析 / broken link / orphan ref / verdict-sync / freshness expiry(5 项)。**可选**:其余 6 项,按项目阶段开关。

### 8.3 起草流程 3 phases(浮动)

最少 3 phases:**P1 准备**(议题对齐 + 输入材料汇总) / **P2 独立产出**(异源多家物理隔离起草) / **P3 合并裁决**(主笔折叠 + 用户裁决 + sign-off 融入)。phase 数随议题复杂度浮动,不预设固定数。M-000 v1.0 起草用了 5 phases,M-005 plan 审 plan 用了 3 phases,都合法。

### 8.4 KNOWLEDGE_MAP 软信号

不预设硬文件数上限。文档生命周期判据(任一触发即转 archive 候选):
- 新增文档需声明 ≥ 1 个预期引用方
- 4 周无 incoming refs
- Boot 必读字符预算溢出(Boot ≤ 500 nwc / AGENTS.md ≤ 1500 nwc 等,由 docaudit 检查)

### 8.5 worktree 物理隔离(P5 PRIMARY)

多家异源任务必须物理隔离:每家独立 worktree + 独立分支 + 同一净化任务定义书。理由(实证 user-decision-log #006 Phase 10):文字封堵「不要看 Claude 产出」在 LLM 上下文会失败,LLM 会把「Claude 已抓 X」解读为分工指令。物理隔离是唯一可靠手段。

### 8.6 净化提示词(P7 PRIMARY)

外审 prompt 不得出现「Claude 已抓」「请覆盖」「参考 consensus」「不要重复 X」等分工/锚定句式。具体净化模板由 M-005 承载。

### 8.7 sanity check 自反性(P6 PRIMARY)

每轮异源 sanity check 的 prompt 必须含「复盘 Round N-1 反馈本身是否仍站得住」。允许 reviewer 自我撤回先前判断(user-decision-log #008 实证:GM 撤回 Round 1 R1)。sanity check 不是一锤定音,是带自反性的演进机制。

### 8.8 F-008 相同完整任务、不分工(P1 PRIMARY)

异源多家执行同一任务时,每家必须处理完整任务,不得切片分工。允许分段处理但每段必须由同一家在完整上下文中独立完成。理由:分工会导致观点耦合,失去独立性,异源价值蒸发。

## 9. M-001~M-006 派生表

| 派生 | 范围 | 核心议题 |
|---|---|---|
| M-001 | 工作流元规则 | 流程触发器、状态机、DoD、PR 纪律 |
| M-002 | 分歧裁决 + 双核同意适用域 | 双核默认通过的边界、连续误判熔断 |
| M-003 | 数据治理 | 文档/数据生命周期、敏感信息分级 |
| M-004 | 降级路径 | 多方失败/共识破裂/工具故障的优雅降级 |
| M-005 | 质量判据与退化检测 | 静默退化、伪共识识别、自反性、目的优先实操 |
| M-006 | 技能库与契约 | skill provenance、契约版本、外部依赖管理 |

M-001~M-006 编号是 **provisional taxonomy**(暂定分类)。起草完成后做归并审计:若某文档无独立触发场景或重度依赖另一文档,允许合并。

## 10. 修订与归档

- 本文件修改触发 §4.1 + §3 全流程(异源多家 + 用户裁决)
- v1.2 历史版本归档至 `docs/archive/meta/M-000-v1.2.md`,git 历史 + 文件双重保留
- 元层级审计(本文件自身是否仍符合第一性原理)每 6 个月或 user-decision-log 累计 ≥ 10 条新条目后触发

---

## 与本文件相关的实证(user-decision-log 索引)

- #002 训练记忆陷阱 / #004 身份误识别 — §3 异源价值实证
- #005 自作主张归档 — §4.1 用户最高裁决实证
- #006 同源 vs 异源工具选型 — §3 + §8.5 实证
- #007 ADR 拆分 — §3 异源 over 同源实证
- #008 sanity check 撤回 R1 — §8.7 自反性实证
- #009 第一性原理审计 — 本文件 v2.0 起草的总裁决
