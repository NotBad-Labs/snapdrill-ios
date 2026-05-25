---
last_verified: 2026-05-25
layer: principle
scope: meta
freshness:
  max_age_days: 180
  decay_trigger: [meta_audit, downstream_rules_drafted, external_shock, false_negative_incident]
override_rationale: |
  本文是 M-001~M-006 派生体系的依赖底座，必须同时承载：
  (1) 可操作质量判据的完整定义（§A-§J 十项不可约，任何一项缺失会导致其他派生规则无法引用判据接口）；
  (2) 八条用户裁决（D1~D8）的精确措辞落地，不得偏离阈值或边界；
  (3) 四家独有亮点的融合（Claude prompt injection 信号、Codex Verdict 三分制与路径污染 5 条、Gemini 实证档案路径与双向流程）；
  (4) #010 字数原则升级的同 PR 落地路径（§J 必须同时给出 M-000 §6 修订方案、frontmatter 删除方案、Overrule #009 R2 的显式写法）；
  (5) 与 M-001/M-002/M-004/M-006 的精确边界（§3 分工表约 200 nwc 但可防止下游越界起草浪费）；
  (6) 物理隔离主笔候选背景下的自反性要求（§H 的轮换原则本身将被自己的规则检验）。
  以上六项不能下沉到任何下游 standards/skills/tools，不能压缩为抽象原则列表，不能省略任何一条历史实证的上下文。全文每段信息密度已最大化，无装饰性论证。
  v2 含 Codex sign-off BLOCK 4 处修复：§G.2/§G.4 统一 D5 阈值（AND 条件 + 20%）、§D.4 新增 #013 三层错实证、§C.4 增加 mode 消歧注释、§E.3 补 #009/#010 实证索引。
---

# M-005 质量判据与退化检测

> M-005 定义「什么是合格元规则产出」的可操作判据、退化识别信号、审计 check 设计原则，以及密度优先的字数治理。M-001/M-002/M-004/M-006 直接引用本文件的判据接口。本文是 M-001~M-006 中最早 ratify 的派生规则（依据 [#012](user-decision-log.md#012-m-005-起草启动--主笔轮换-deepseek--010-字数升级同-pr-落地) Q1「依赖拓扑优先」）。

---

## §1 定位

M-005 为所有派生规则提供三样东西：

1. **质量标尺**：什么算「合格」的规则产出（§A）。
2. **退化雷达**：智能体「物理可用但逻辑不可用」的识别信号（§C）。
3. **审计 check 设计规范**：docaudit 哪些 check 必须阻塞、哪些可降级、如何新增（§G）。

M-005 不取代任何下游的验证脚本、CI 门禁或 human review——它定义这些工具应检测什么，以及检测结果如何被裁决。

适用范围：所有受 M-000 v2.0 §3 默认多方异源约束的产出（含元规则起草、ADR 提案、第一性原理审计、cross-audit、sign-off）。M-005 不约束「单方执行窗口」内的低风险机械操作（豁免清单由 M-001 定义）。

## §2 与 M-000 PRIMARY 的接口

M-000 v2.0 §2 的 8 条 PRIMARY 内核中，与 M-005 直接挂钩的如下：

| PRIMARY | M-005 相关章节 | 关联说明 |
|---|---|---|
| P1（相同完整任务） | §B 伪共识识别 | 任务拆分后各方的独立完整性是判断伪共识的前提 |
| P2（用户最高裁决权） | §I 越权防线 | 结构性决定必须显式批准，否则侵犯 P2 |
| P3（默认多方异源） | §B.3 否决权阈值 | 异源反对的客观判据防止 P3 被滥用为否决权通胀 |
| P4（同源警告） | §B.1 触发信号清单 | 同源警告的升级条件由 §B 定义 |
| P5（物理隔离） | §B.2 隔离失效检测 | 隔离是否有效需可检查信号 |
| P6（sanity check 自反性） | §F 自反性 sanity check | M-005 自身也需被 §F 约束 |
| P7（净化提示词） | §B.2（泄漏检测） | 提示词污染是隔离失效的一种形式 |
| P8（Overrule） | §J（Overrule #009 R2） | 字数原则升级的 Overrule 写法由 §J 承载 |

## §3 与 M-001/M-002/M-004/M-006 的分工边界

| 规则 | M-005 给出的 | 由对方给出 |
|---|---|---|
| M-001（协作工作流） | 主笔轮换原则（§H）、静默退化识别触发工作流重启（§C） | 主笔轮换具体流程、物理隔离操作规程、单方执行窗口 |
| M-002（分歧裁决） | 否决权阈值（§B.3）、sanity check 自反性原则（§F）、日志可追溯性判据（§A.1） | 双核同意适用域、Overrule 写法细节、裁决日志结构、撤回复审流程 |
| M-004（降级操作） | 静默退化 → 回退用户的判定路径（§C.5），外部事实失效的处理（§D.3） | 不可逆动作具体清单（含 iOS 特有）、降级幅度定义、用户不可达的等待判据 |
| M-006（数据治理） | 伪共识识别中的同源数据分析限制（§B.1 训练谱系判断） | prompt injection 防御技术、数据共享边界、脱敏策略默认值 |

多余交集：M-005 不重复定义 M-002 的裁决结构，不重复 M-001 的物理隔离操作步骤，不重复 M-004 的不可逆后果分析，不重复 M-006 的脱敏算法。但 M-005 为所有这些提供「质量判据」引用点。

---

## §A 产出度量

每条元规则（包括 M-005 自身）必须同时满足以下四项判据，否则视为未通过结构质量门。缺任一项 → sign-off CONDITIONAL；缺两项以上或关键条款不可验伪 → BLOCK。

### A.1 可追溯性

**规则**：每条规则必须能回到某个具体证据、案例、用户裁决、或第一性原理论证。

- **违反信号**：规则正文或注记为「按惯例」「经验上」「通常」而无引用编号或实证描述。
- **可接受形式**：引用 `user-decision-log` # 编号 + 条款；引用 backlog MC 编号；引用 M-000 PRIMARY 内核编号（P1-P8）；引用第一性原理论证（如「若 X 则不 Y」的演绎链，需显式写出前提）。
- **下沉证明**：若某规则的依据可完全由下游 skills/tools 验证（如「URL 格式应为 https」），则该依据不构成可追溯性判据——只有指向「谁在什么证据下裁决了该判据」的核心引用才属于 M-005 层。

### A.2 可验伪性

**规则**：每条规则有可识别的「违反信号」——能列出什么样的产出/行为构成违反。

- **违反信号**：规则只有抽象陈述（如「应保持高质量」）而无具体违规模式。
- **设计要求**：每条规则的 enforcement 应能被脚本或人工 reviewer 以 yes/no 判定。若只能模糊判断（如「是否过于冗长」），必须同时定义测量方法（如「override_rationale 未列明任何不能下沉的理由 → 视为违反密度原则」）。
- **下沉证明**：可验伪的具体脚本规则（如「frontmatter 缺少 `last_verified` → 判违反」）属于工具层，M-005 只定义「每个 check 必须有可操作的真值判定」原则。

### A.3 下沉证明

**规则**：每条规则必须能说明「为什么不能下沉到下游 standards/skills/tools」。

- **违反信号**：规则内容完全由操作步骤、模板、例子、命令、检查脚本、或当前状态的快照组成，且不涉及元规则层面的约束。
- **标准写法**：在每章或每条规则末尾（可注记形式）说明该规则的下沉边界。例如「编号引用格式可工具化，但『什么算引用』的判据属于 M-005 层，因不同派生规则对不同证据类型要求不同」。

### A.4 目的关联

**规则**：每条规则必须与 M-000 PRIMARY 内核（P1-P8）之一显式关联，或与产品愿景直接对接。

- **违反信号**：规则在正文或 frontmatter 中找不到关联的 PRIMARY 编号或产品愿景引用。
- **例外**：§3 分工边界段落不需要目的关联——它是元规则之间的契约，不是面向下游的约束。

---

## §B 伪共识识别

承接 M-000 §3「结构性同源一致是伪共识风险」。本章将 M-000 的警告信号升级为可操作的判定规则。

### B.1 触发信号清单

§B.1 触发信号分两类：

- **升级类信号**（信号 1~4）：当任一信号出现时，**同源警告升级为自动用户裁决**，不等待异源方显式反对。
- **折扣类信号**（信号 5）：在折叠报告中显式标注权重折扣，**不自动升级用户裁决**；若异源方同时提反对意见，按 §B.3 否决权阈值处理。

1. **连续同源主笔**：同一 vendor 连续担任主笔 ≥ 3 版（实证：M-000 v1.0/v1.1/v1.2/v2.0 连续 4 版 Codex 主笔，[#012 Q2](user-decision-log.md#012-m-005-起草启动--主笔轮换-deepseek--010-字数升级同-pr-落地) 裁决轮换 DeepSeek）。
2. **多实例同训练 cutoff**：来自同一 cutoff 日期的多个模型实例给出方案同向，而异源方给出具体反对。
3. **同 vendor 的多端点聚合**：同一厂商的多个 API endpoint（如 GPT 系列 / Claude 系列）被当作「多家异源」使用——这是 [#004](user-decision-log.md#004-m-000-v12-四家最终-sign-off-ratified) 实证的「互换身份反向证据」：若两模型自称对方，则证明训练谱系重叠或 prompt 敏感度差，不能算异源。
4. **thinking/reasoning 模式加剧的自我身份漏泄**：开 reasoning/thinking 模式后模型更频繁自称为其他 vendor（[#004](user-decision-log.md#004-m-000-v12-四家最终-sign-off-ratified) 实证 DeepSeek/Gemini 互换身份），此时该模型的独立判断**建议折扣 0.5 权重**；折扣应在折叠报告显式标注，**不强制阻塞**。合规授权下 thinking 模式仍是有效推理。
5. **主笔消费偏向**（路径 C [#019](user-decision-log.md#019-路径-c-stage-5-批量执行完成--skill-生态-52--11) / [#020](user-decision-log.md#020) 实证）：当主笔在自审中给某个治理 skill / 工具 / 流程 KEEP/REWRITE 判定，且该主笔在历史会话中消费过该 skill / 工具 / 流程时，**KEEP/REWRITE 判定建议折扣 0.5 权重**；折扣应在折叠报告显式标注，**不强制阻塞**。
   - 实证：Claude 路径 C Stage 2 给 cross-audit / sprint-contract / decision-closeout / knowledge-health KEEP（4 个 Claude 主分支会话用过的治理 skill），[#017](user-decision-log.md#017-skill-审计-stage-35--45-项分歧裁决--大规模重构方向) 帅哥裁决全部 DOWNGRADE/MERGE/DELETE。Claude 同源偏向被异源 + 用户裁决纠偏。
   - 触发动作：折叠主笔在 consensus 报告中显式列出"主笔自审 + 自己消费过的组件"配对，提示帅哥关注同源偏向。
   - 与 §G.5.4 衔接：[§G.5.4](#g5-skill-升降级机制路径-c-019-实证扩展) 主笔消费偏向警示与本第 5 条信号双向引用——§B 给同源信号，§G 给 skill 审计场景的具体折扣应用。
   - 与信号 4 可叠加：thinking 模式身份漏泄 + 消费偏向时，权重 = 0.5 × 0.5 = 0.25 原权重（等效折扣 0.75），折叠报告分开注明各折扣来源。

### B.2 物理隔离失效检测

即使 worktree 隔离（不同目录、分支、上下文），仍可能发生以下泄漏。检测方法（5 条路径污染）：

| 泄露类型 | 检测信号 | 验证方法 |
|---|---|---|
| 提示词污染 | 任务定义中包含「参考其他方结论」「注意其他家观点」「我们之前决定」等措辞 | 净化提示词 check（M-000 §7 P7）：audit 任务定义书的净化版本 vs 原始版本 |
| git 历史横向引用 | 某份草案的 commit message 提到其他家的文件路径或编号 | docaudit `git log --oneline <branch>` 交叉检查 |
| Claude.md / memory 横向扩散 | 同一工作空间的 .claude.md 或 memory 缓存记忆了其他家的产出 | 检查 .claude.md 是否存在跨目录引用；物理隔离期间应使用独立 worktree（非复用 session） |
| agent 内部推理链泄漏 | 模型在输出中引用自己「之前在其他任务中看到的某家观点」（[#010](user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft) 实证 Codex 把私下对话当作全局 Overrule） | 主笔候选产出需附 reasoning 摘要（仅限验证推理来源，不强制披露全部 thinking tokens） |
| 产物相似性 | 高度相似的章节、例子、错误、编号和比喻，若无法由任务定义书解释，应标为伪共识风险 | 折叠阶段结构一致性检测 |

**判定层级**：以上信号中任一条触发 → 标记该次独立产出为「辅助视角」而非「强独立证据」。若该视角原本是关键证据（如异源否决），则自动升级至用户裁决。

### B.3 否决权阈值（承接 MC-10）

异源方的「强烈、具体、可证伪反对」可触发双核失效（M-000 §3）。但为防止否决权滥用造成注意力通胀（MC-10），定义以下客观判据：

- **「强烈反对」的构成要素**（缺一不可）：
  1. **引用具体事实错误**：指出事实层错误，而非「我觉得不对」。
  2. **提出可证伪的反假设**：给出「如果 X 则 Y 成立，否则 Z」的可检验替代方案。
  3. **指出明确风险路径**：列出不采用该方案的具体可观测后果（如「若采用 A 方案，则下游脚本 B 的 status 消费将漏检 ADR，如 [#008](user-decision-log.md#008-round-2-sanity-check-撤回-r1-status_enum-修改-工程兼容性优先) 实证」）。

- **滥用判据**：24 小时内同一异源方触发否决权升级 ≥ 3 次，且在至少 2 次升级中其反对不满足上述三要素 → 自动触发对该异源方的静默退化扫描（§C）。若退化扫描确认，则按「逻辑不可用」处理。

---

## §C 静默退化识别（承接 MC-1）

定义「物理可用但逻辑不可用」的智能体退化信号。静默退化信号适用于所有智能体产出（包括 M-005 自身的主笔产出、reviewer sign-off 等）。

### C.1 格式崩溃

- **信号**：输出结构断裂（章节号重复/缺失）、frontmatter 残缺（必需字段缺位）、标题层级混乱（如跳级、无编号、或任意改变格式规范）。
- **判定**：硬信号（单次出现即标逻辑不可用，等同物理不可用回退用户）。
- **实证锚定**：无特定用户裁决，但每种格式异常均有具体事故（如 [#005](user-decision-log.md#005-docsmeta-归档治理--归档路径用户显式批准) 中 Claude 自作主张的归档路径命名未用标准日期格式——虽然不属输出，但显示格式纪律薄弱）。

### C.2 自相矛盾

- **信号**：同一产出内不同段落给出对立结论，或产出与同一 session 前次推理矛盾而不注明撤回。
- **判定**：硬信号。任何对立结论出现均视为自相矛盾，除非在首次出现后立即显式撤回并写明原因（[#008](user-decision-log.md#008-round-2-sanity-check-撤回-r1-status_enum-修改-工程兼容性优先) 范式：Round 2 sanity check 撤回 Round 1 建议，写明了原因和 Overrule 范围）。
- **实证锚定**：[#008](user-decision-log.md#008-round-2-sanity-check-撤回-r1-status_enum-修改-工程兼容性优先) 中 Gemini 在 Round 2 撤回自己在 Round 1 的判断——虽然是正面案例（自反性成功），但也证明自相矛盾如果不撤回就是退化。

### C.3 偏离任务

- **信号**：输出主题与任务定义书大量不符（完成率 < 70% 的必须覆盖项），或者在没有用户授权的情况下自行切入无关议题。
- **判定**：硬信号。若任务定义书列明 10 项必须覆盖章节，产出漏了 ≥ 3 项且未在 frontmatter 或 §A 下沉证明中说明排除理由 → 判定偏离任务。
- **实证锚定**：[#005](user-decision-log.md#005-docsmeta-归档治理--归档路径用户显式批准) 中 Claude 自行归档 docs/meta/ 未经用户批准——属于「未授权决策」偏离任务授权范围。

### C.4 身份误识别

- **信号**：模型自称其他 vendor 或其他模型（[#004](user-decision-log.md#004-m-000-v12-四家最终-sign-off-ratified) 实证 DeepSeek 自称 Gemini 2.5 Pro、Gemini 自称 Claude 3.5 Sonnet），且该误识别出现在严肃输出中（非指代模糊）。
- **判定**：硬信号。一次身份误识别即可触发「逻辑不可用」回退流程。
- **实证锚定**：[#004](user-decision-log.md#004-m-000-v12-四家最终-sign-off-ratified) 详细描述了 reasoning/thinking 模式下的身份互换实证。

**消歧注释**（下文 §B.1.4 / #014 D8 关系处理）：
- **非 thinking/reasoning 模式**下身份误识别 → 本条 C.4 硬信号判定（逻辑不可用，回退用户）。
- **thinking/reasoning 模式**下身份误识别 → 按 §B.1.4 D8 处理（建议折扣 0.5 权重，折叠报告显式标注，不强制阻塞）。
- **两者不冲突**：§C.4 处理「普通 mode 退化」，§B.1.4 处理「thinking mode 权重判断」。同一现象（身份误识别）+ 不同条件（mode）= 不同处置。

### C.5 输出污染识别（prompt injection / 上下文污染）

智能体输出含以下信号 → 触发「输入污染」嫌疑：
- 突然引用任务定义书中未出现的具体路径 / 编号 / 决策
- 输出风格断裂（前后段语言风格 / 立场显著切换）
- 自我引用未发生的对话（「如你之前所说」但实际无此对话）
- 拒绝任务但理由含明显非任务相关内容

触发动作：保留产物作为 M-006 prompt injection 防御的实证案例，但本轮裁决不采纳该方意见，并触发 M-006 复审。

### C.6 触发动作（硬信号 vs 局部段落退化）

- **硬信号**：格式崩溃、自相矛盾、偏离任务、身份误识别（非 thinking 模式）→ 立即标为「逻辑不可用」，等同物理不可用回退用户（按 M-004 降级流程）。
- **局部段落退化**：上述信号仅在产出局部出现（如某一段出错但整体结构完整）→ 要求该方重做并保留退化证据（归档至 `docs/archive/audits/m005-static-degradation-evidence/`），不立即升级为逻辑不可用。
- **sign-off 阶段**：任一退化信号（不论硬信号还是局部退化）出现，立即暂停 sign-off 并通知用户。

---

## §D 外部事实验证纪律（承接 MC-2 + [#002](user-decision-log.md#002-ai-模型工具版本信息一律-websearch-验证)）

### D.1 默认必须验证的事实类型

以下类型信息必须通过 WebSearch / 官方来源 / 实时 API 验证，**不允许依赖训练记忆**：
- AI 模型 ID（如 `gemini-3.5-flash-ga`）、版本号、能力变更
- 工具 CLI 版本（如 `gemini-cli version`）、API endpoint、model ID 枚举
- 厂商官方声明（训练谱系、数据治理政策、服务状态页面）
- 价格、费率、限制值（为防范 [#002](user-decision-log.md#002-ai-模型工具版本信息一律-websearch-验证) 式误判）

### D.2 异源训练谱系判断的纪律

- 异源判断（用于 §B 伪共识）时必须基于厂商公开声明或可信第三方审计，**不依赖智能体的自我宣称**（[#004](user-decision-log.md#004-m-000-v12-四家最终-sign-off-ratified) 实证：两家模型互换身份，若信了自我宣称就会错误认定为同源）。
- 如果一个模型无法稳定提供自己的 vendor 信息（即身份误识别频率 > 5%），那么它的自我宣称在异源判断中权重 = 0，只能依赖外部源。

### D.3 `agent-cli-models.md` 刷新机制

- 文档 frontmatter 的 `freshness.max_age_days` 当前为 30。
- 触发刷新的条件（不仅仅是时间）：
  - 感知到发版事件（Google IO / WWDC / OpenAI DevDay / 厂商 blog 发布新模型）
  - 任何智能体在推理中引用该文档且距离上次验证 > 20 天
  - 任何验证过程发现文档内任一记录与实际不符 → 触发全文刷新而非单行修改
- 失效处理路径：
  1. 如果刷新不可用（API 不可达 / 网络受限），将整个文档标记为 `freshness: expired`，并在引用它的产出中显式注明「基于过期快照的推断可能不准确」。
  2. 如果已验证数据与文档冲突，优先使用最新验证结果而非文档记录，同时并行提交 PR 更新文档。

### D.4 #013 三层错实证判据化（SSOT 注入 + subagent 验证 + 代码同步）

引用 [#013](user-decision-log.md#013-gemini-主笔候选-model-误用事故--直接-api-修复--scriptsgemini_utilspy-ssot-同步) 三层连环错实证，判据化为以下三条纪律。违反任一条即可触发 §C 静默退化扫描。

**D.4.1 调度方必须强制注入 SSOT**

当主分支调度 subagent（或任何代理执行单元）执行涉及模型 ID、工具版本、API endpoint 的任务时，**必须**将 `docs/tech/reference/agent-cli-models.md` 的 SSOT 锚点（路径、关键记录行）显式注入 prompt，禁止「让 subagent 自己探索 CLI 用法」——后者会把 SSOT 退化为「建议参考」，违反 §D 原则。

- **违反信号**：调度 prompt 中无 SSOT 引用，或只写了「请参考 agent-cli-models.md」而无具体路径或记录行。
- **实证锚定**：[#013](user-decision-log.md#013-gemini-主笔候选-model-误用事故--直接-api-修复--scriptsgemini_utilspy-ssot-同步) 第 (1) 层：Claude 主分支调度 general-purpose subagent 让其"自己探索 CLI 用法"，但 SSOT 早已明示 `gemini-3.5-flash` 的 CLI 不可达。

**D.4.2 subagent 返回 model ID / API endpoint / 工具版本必须 grep SSOT 验证**

subagent 向上回报的任何事实声明（含模型 ID、工具版本、CLI 可用性判断）在纳入对话上下文或向上级复述前，**主分支必须 grep SSOT 验证**。subagent 报告本身也属于「外部事实陈述」范畴，受 [#002](user-decision-log.md#002-ai-模型工具版本信息一律-websearch-验证) WebSearch 纪律约束。

- **违反信号**：主分支直接采纳 subagent 的模型 ID / 版本声明而未与 SSOT 比对。
- **实证锚定**：[#013](user-decision-log.md#013-gemini-主笔候选-model-误用事故--直接-api-修复--scriptsgemini_utilspy-ssot-同步) 第 (2) 层：subagent 报告 `gemini-2.5-flash` 为实际可用 ID 时，Claude 主分支未 grep SSOT 验证，直接向用户复述。

**D.4.3 代码 SSOT 与文档 SSOT 必须同步刷新**

消费 SSOT 字段的代码（如 `Scripts/gemini_utils.py` 中的 MODELS 列表）必须与文档 SSOT 同时更新。文档刷新但代码不刷新构成「二次漂移」——即使消费方引用 SSOT，也引用的是过期快照。

- **违反信号**：`docs/tech/reference/agent-cli-models.md` 已更新某记录，但消费该字段的代码（如 MODELS 列表、CLI 参数表、schema 验证枚举）未同步。
- **修复方法**：在文档刷新 PR 中添加 grep 步骤，查找消费该字段的全部代码路径并同步更新。若无法即时同步，至少添加注释指向最新 SSOT 记录。
- **实证锚定**：[#013](user-decision-log.md#013-gemini-主笔候选-model-误用事故--直接-api-修复--scriptsgemini_utilspy-ssot-同步) 第 (3) 层：`agent-cli-models.md` 已更新 GA model ID，但 `Scripts/gemini_utils.py` MODELS 列表停在 2026-03-07。

**归档路径**：上述三层实证的原始产出已归档至 `docs/archive/audits/m005-static-degradation-evidence/`，文件名为 `M-005-quality-criteria-gemini-WRONG-MODEL-2.5-flash.md`。

---

## §E 目的优先原则的古德哈特防御

承接 M-000 §9「目的优先」+ [#009 R6](user-decision-log.md#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草)（改名「目的优先」删经济学借词）。本章定义：

### E.1 形式 vs 目的的判据

「形式削弱目的」的识别信号：
1. **流程合规但没回答核心问题**：产出通过了所有 check、模板填写完整，但 key findings 缺失或模糊。
2. **指标代替判断**：reviewer 说「检查项全部通过」而不对产出内容做实质性评估。
3. **历史先例绑架**：以「以前这么写过」为由拒绝改进，而环境和目的已经变化。
4. **古德哈特循环**：某个度量指标在连续 3 次使用中被优化（指标值提升）但对应的真实质量下降（[#006](user-decision-log.md#006-round-1-boot-序列重构--异源-sanity-check-价值实证) 实证：同源激进方案通过简化流程提升了产出速度但引入了 3 项硬伤）。

### E.2 指标反向塑形检测

当一个 check / 度量 / reviewer 结论已经成为优化对象而非诊断信号时，触发以下处理：
1. 暂停该 check 作为阻塞门。
2. 在 3 轮独立产出中改由人工裁决代替代。
3. 评估：若去掉该 check 后真实质量无下降，则该 check 降级为可选（§G.3）。

### E.3 历史实证索引

- **[#006](user-decision-log.md#006-round-1-boot-序列重构--异源-sanity-check-价值实证)**：同源激进方案（删 workflow / 删 STATUS）被异源纠偏 3 项硬伤——形式简化（减少文件）看似提升效率，实际掩盖了可追溯性损失。
- **[#007](user-decision-log.md#007-adr-004005-异源评估--激进拆分--盲点识别批量入库)**：ADR 拆分争议中同源倾向保守（只加 banner），异源倾向激进拆分——用户裁决接受异源激进版本。证明「反对形式变化」不一定是目的优先。
- **[#008](user-decision-log.md#008-round-2-sanity-check-撤回-r1-status_enum-修改-工程兼容性优先)**：sanity check 撤回自己的 R1 建议——指标（STATUS_ENUM 扩展）被工程兼容性否决，证明指标不应凌驾于验证脚本的消费端正确性。
- **[#009](user-decision-log.md#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草)**：M-000 第一性原理审计识别 ~70% 内容为 ANALOGY 外壳（非 PRIMARY）——证明元规则体系自身也可被形式塑形，需要古德哈特防御。
- **[#010](user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft)**：字数 `default_word_budget` 字段被进一步识别为非第一性惯性——证明「默认预算」本身也可能成为优化对象，渐进废弃路径（#001 1500→#003 2500→#009 R2 软上限→#010 不预设）是古德哈特识别的实战范例。

（不允许引用未发生的假设场景——上述五个实例均为真实用户裁决。）

---

## §F 自反性 sanity check 原则（承接 [#008](user-decision-log.md#008-round-2-sanity-check-撤回-r1-status_enum-修改-工程兼容性优先) 实证）

### F.1 Round N → Round N-1 复盘 prompt 设计

在每轮 sanity check 开始前，必须添加以下复盘提示（可内化到执行流程）：
> 「请反思你之前一轮（Round N-1）给哪些反馈。这些反馈你现在是否仍然同意？若不同意，请具体说明撤回理由和 Overrule 范围。」

[#008](user-decision-log.md#008-round-2-sanity-check-撤回-r1-status_enum-修改-工程兼容性优先) 实证了这种 prompt 的有效性：Gemini 在复盘时基于第一性原理（status 二元生命周期 + 下游兼容）撤回自己在 Round 1 的建议。

### F.2 sanity check 不是终审

- 异源 sanity check 共识也可被后续 sanity check 撤回（[#008](user-decision-log.md#008-round-2-sanity-check-撤回-r1-status_enum-修改-工程兼容性优先) 的正规化）。
- 撤回时必须显式写出 Overrule 范围：哪些先前的建议被覆盖（[#008](user-decision-log.md#008-round-2-sanity-check-撤回-r1-status_enum-修改-工程兼容性优先) 只覆盖 `status` 字段写法，不覆盖 [#007](user-decision-log.md#007-adr-004005-异源评估--激进拆分--盲点识别批量入库) 其他裁决）。
- 若一轮 sanity check 未通过（即产生 BLOCK），该产出不自动销毁，而是加上 `sanity_check_blocked` 标记后回退用户裁决。

### F.3 工程兼容性 vs 元数据美学

当下游脚本/工具消费端兼容性与语义纯粹性冲突时，**工程兼容性优先**：
- 实证：[#008](user-decision-log.md#008-round-2-sanity-check-撤回-r1-status_enum-修改-工程兼容性优先) 中保持 `status: active` + `supersession_status` 侧通道方案，而不是修改 `status` 枚举值，因为后者会导致 CI 脚本漏检。
- **例外**：此原则不适用于 P2（用户裁决权）与 P8（Overrule 显式性）——那些不可因工程兼容性打折扣。P2/P8 是 PRIMARY 内核，不容工程权衡覆盖（[#014 D4](user-decision-log.md#014-m-005-p3b-八处分歧裁决)）。

---

## §G docaudit 核心与可选 check 的设计原则

M-000 v2.0 §8 已列出 6 项核心 check（frontmatter schema / link integrity / verdict sync / external freshness / rule usage trace / skill provenance）及其来源。M-005 不重复该表，而是定义如何设计新的 check。

### G.1 每个 check 必须有真实事故来源或风险模型

- **核心 check**：必须来自至少 1 次真实事故（用户裁决、ADR、bug report），且该事故不可通过简单培训规避。
- **可选 check**：可来自风险推理（如「随着时间的推移可能产生术语漂移」），但必须注明假设条件和验证方法。
- **违反信号**：一个 check 在提案文档中找不到任何事故编号或风险模型描述 → 不得进入阻塞门。

### G.2 核心 check 进入阻塞门的判据

一个 check 从设计阶段到成为阻塞门，必须满足：
1. 在 ≥ 3 次独立审计中成功识别真实问题。
2. 不可机械绕过（即没有「只要故意避免就能通过」的 loophole）。
3. **误报率 < 20%**（与 §G.4 升级条件阈值一致；若仅用于长期阻塞门稳定性评估，可参照本条 <20% 标准。核心 check 的长期稳定标准为 <10%，但 §G.4 升级触发条件统一为 <20%——参见 §G.4 注释）。
4. 所有下游消费端（CI / validation script / human review）均对齐。

**注释**：§G.2 是核心 check 长期阻塞门标准，误报率目标 <20%（与 §G.4 升级条件阈值一致）；升级到 core 后若实际误报率持续 >20% 且无改善趋势，按 §G.4 降级条件处理。

### G.3 可选 check 的存在价值

可选 check 并非价值低，只是当前未满足 G.2 条件。可选 check 的用途：
- 实验：测试一个新的检测模式是否能无副作用运行。
- 低频但高代价：如整体结构一致性 audit（频率低但一旦违反维护成本极高）。
- 依赖人工裁决：如术语一致性检查，无法自动判定时可保留为人工必选。

### G.4 新增 check 的提案流程（升级与降级双向）

**可选 → 核心（升级）**：
1. 提案者（任何智能体）提交 `docs/audits/proposed-check-<name>.md`，包含：目的、事故/风险来源、检测方法、误报率估算、预期消费端。
2. 至少 1 家异源方评估后，标记为「可选」并加入 docaudit 可选列表。
3. 经过 **≥ 3 次审计运行 + 30 天观测 + 误报率 < 20%**（三个条件并列 AND 关系），且满足 G.2 条件后，升级为「核心」并进入阻塞门。
4. **同步消费端文档**：升级 core 必须同步 `docs/standards/execution-gates.md`、相关脚本 README、docaudit policy 和消费端文档（[#014 D5](user-decision-log.md#014-m-005-p3b-八处分歧裁决)）。

**核心 → 可选（降级）**：
- 若核心 check 连续 180 天无有效拦截 → 自动降级为可选或候选（[#014 D5](user-decision-log.md#014-m-005-p3b-八处分歧裁决)）。
- **退役原则**：「已有实现」不构成永久保留理由（[#014 采纳 Codex 亮点](user-decision-log.md#014-m-005-p3b-八处分歧裁决)）。

**阈值注释**：§G.2 与 §G.4 的误报率阈值均为 <20%，来源于 [#014 D5](user-decision-log.md#014-m-005-p3b-八处分歧裁决)：「≥3 次审计运行 + 30 天 + 误报率 < 20%」。此阈值是升级到 core 的触发条件；升级后若误报率持续 >20%，启动降级评估。

### G.5 skill 升降级机制（路径 C [#019](user-decision-log.md#019-路径-c-stage-5-批量执行完成--skill-生态-52--11) / [#020](user-decision-log.md#020) 实证扩展）

skill 升降级采用与 docaudit check 升降级（§G.1~§G.4）**同源**的双轨机制。skill 特有判据：

**§G.5.1 6 种 Verdict 体系**（路径 C [#017](user-decision-log.md#017-skill-审计-stage-35--45-项分歧裁决--大规模重构方向) 实证）：

- **KEEP**：保留 skill 形态。要求：需要 LLM 动态判断 + 不可下沉到 standards/template/hook + 触发频率高 + 元规则对齐分 ≥4
- **REWRITE**：保留 skill 形态但内容重写。要求：方向正确但措辞过期/不一致
- **MERGE**：合并到容器 skill 或 standards/template 文件。要求：与另一组件功能重叠 + 合并后认知负担更低
- **PROMOTE_TO_STANDARDS**：内容升 standards/，删除 skill。要求：内容是规则/约束/规范 + 不需 LLM 介入
- **DOWNGRADE_TO_TEMPLATE**：内容降 templates/，删除 skill。要求：内容是纯模板/代码片段 + trigger 条件不需推理
- **DELETE**：归档至 docs/archive/skills/`<date>`/。要求：装饰性 / 过时 / 形式合规但实质空洞 / 已被其他组件覆盖

**§G.5.2 skill 触发周期审计**：

- 每 90 天审计一次 .claude/skills/ active 清单
- 连续 ≥2 个季度无实际触发的 skill → 自动降格为候选（标 skill_audit_verdict: candidate）
- 候选 ≥1 季度仍无触发 → 升降级提案

**§G.5.3 大规模 skill 重构的 baseline + expires_on 机制**：

- skill 大规模重构（如路径 C，影响 ≥10 个 skill）期间，docaudit 必然抓出 frontmatter/links/skill-* 类批量 error
- 修复策略：legacy_whitelist 加豁免 + expires_on（≤30 天）+ reason 引用 user-decision-log #编号
- expires_on 强制周期性复审，避免技术债隐藏（路径 C [#019](user-decision-log.md#019-路径-c-stage-5-批量执行完成--skill-生态-52--11) 实证 2 项豁免）

**§G.5.4 主笔消费偏向警示**（与 §B 联动）：

- 主笔（含 Claude 主分支会话）对自己消费过的治理 skill 自审时，KEEP/REWRITE 判定**默认折扣 0.5 权重**（参 [§B.1 信号 5](#b1-触发信号清单)）
- 路径 C 实证（[#017](user-decision-log.md#017-skill-审计-stage-35--45-项分歧裁决--大规模重构方向)）：Claude Stage 2 给 cross-audit / sprint-contract / decision-closeout / knowledge-health KEEP，帅哥裁决全部 DOWNGRADE/MERGE/DELETE——Claude 同源偏向被异源 + 用户裁决纠偏。

**§G.5.5 与 M-001 主笔轮换的衔接**：

skill 审计的主笔提名规则与 M-005 §H 主笔轮换原则同源——避免连续同源主笔审 skill 累积同源偏向。M-001 ratify 后会承接 skill 审计主笔的具体提名流程。

### §G.6 derived_from frontmatter check（[#024](user-decision-log.md#024) 新增，可选 → 核心待 30 天观测）

**事故来源**：[#022](user-decision-log.md#022) 后路径 C 深度审计发现 102/103 文件 frontmatter 缺 `derived_from` 字段（D1 维度缺失率 95%+），M-000 §11 SSOT 注册表完整但「派生锚未传导到文档自身」——构成 §11.10 schema 设计 vs 实施落差。

**检测方法**（按 §G.4「可选 → 核心」升级路径）：

1. 扫描所有 `docs/**/*.md`（排除 `docs/product/` + `docs/archive/`）
2. 若 frontmatter 缺 `derived_from:` 字段：
   - 含 `scope: product-support` → 豁免（§11.7 产品支撑类）
   - 否则报 warning（30 天宽限期内）或 error（过期后）
3. 若 `derived_from:` 字段格式不合 schema（参 M-000 §11.10）→ 一律 error
4. 若 `derived_from:` 引用的 M-NNN §N 在 M-000 / M-001~M-006 中不存在 → error

**误报率估算**：< 10%（schema 明确，机械可校验，主要误报来自 §11.7 边界判断）。

**预期消费端**：
- `Scripts/audit/docaudit.py`（新增 `--check derived-from-required`）
- `docs/standards/execution-gates.md`（同步登记）
- M-000 §11.10 schema 规则

**升级路径**：
- 起始：可选 check，30 天观测期（≤2026-06-25），warning 级
- 满足 §G.2 条件（≥3 次审计运行 + 30 天 + 误报率 <20%）后升核心 + error 级
- 升核心时同步更新 `execution-gates.md` core_checks 表（[#014 D5](user-decision-log.md#014-m-005-p3b-八处分歧裁决)）

---

## §H 主笔轮换机制（承接本任务自身）

### H.1 同源风险累积

- 连续同源主笔的风险：M-000 v1.0 ~ v2.0 连续 4 版 Codex 主笔，导致：
  - 主笔自身盲点无法被同源 context 暴露（[#010](user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft) 中 Codex 私下接受字数 Overrule 但主分支不知情）。
  - 主笔的结构性假设（如字数默认预算）成为体系惯性（[#009](user-decision-log.md#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草) 审计识别默认预算为非第一性）。
- **轮换阈值**：同一 vendor 连续主笔 ≥ 3 版（同系列版本升级，如下一代版本）则下一版必须轮换给不同 vendor（[#014 D2](user-decision-log.md#014-m-005-p3b-八处分歧裁决)）。实证阈值：M-000 v1.0/v1.1/v1.2 = 3 版 Codex 才触发 v2.0 轮换。

### H.2 主笔候选裁决的物理隔离要求

- 主笔候选一旦确定，主笔方不得参与 sign-off 初审（只能事后 reviewer 角色，如 [#012](user-decision-log.md#012-m-005-起草启动--主笔轮换-deepseek--010-字数升级同-pr-落地) 中 Codex 转辅助 reviewer）。
- 主笔方收到的任何用户私下 Overrule 必须在主分支 `user-decision-log` 同步落档（**不给硬时限**，仅规定「必须同步」原则，具体时限下沉 M-001，[#014 D3](user-decision-log.md#014-m-005-p3b-八处分歧裁决)）。若未同步，其他方在 sign-off 时检测到不一致可触发 §C 静默退化扫描。

### H.3 主笔不是独享特权

- 3 家 sign-off 中任一家给出 BLOCK 时，主笔产出回炉。
- BLOCK 的条件：
  - 必须引用 §A 质量判据（可追溯 / 可验伪 / 下沉 / 目的关联）的违反信号。
  - 必须具体指出违反发生在哪个段落或字段。
- 不满足以上条件的 BLOCK 视为无效，不予回炉，但记录在 sign-off 日志中作为否决权滥用候选。

### H.4 主笔轮换与同 PR 修订的衔接

主笔轮换发生时，若同 PR 涉及元规则修订（如本轮 M-005 ratify 同 PR 修订 M-000 §6 + frontmatter），新主笔有权重写修订条款，但必须显式 Overrule 旧主笔的对应条款（M-002 流程）。[#014 采纳 Claude 亮点](user-decision-log.md#014-m-005-p3b-八处分歧裁决)

---

## §I 「自作主张越权」防线（承接 [#005](user-decision-log.md#005-docsmeta-归档治理--归档路径用户显式批准) + [#010](user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft)）

### I.1 结构性决定的范围

以下动作属于「结构性决定」，必须经用户显式批准：

- 归档路径的决定（[#005](user-decision-log.md#005-docsmeta-归档治理--归档路径用户显式批准) 实证：Claude 未批准自行归档 docs/meta/ 到日期名路径）
- 目录重命名、跨目录文件移动（[#005](user-decision-log.md#005-docsmeta-归档治理--归档路径用户显式批准) 归档治理中涉及的路径重命名）
- 批量 frontmatter 修改（如全部文档的 `layer` 字段迁移）
- 删除文件（无论是否归档）
- 修改验证脚本的 STATUS_ENUM（[#010](user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft) 中 Codex 修改 `validate_frontmatter.py` 增加 `draft` 值，虽然本次被接受但属结构性决定——注意：接受不代表没越权，需区分合规授权 vs 越权）

### I.2 私下授权 vs 主分支可见性

- 主笔在独立 worktree 中收到的用户私下授权（如 [#010](user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft) 字数 Overrule），必须同步到主分支的 `user-decision-log`（原则，时限由 M-001 定义）。
- 同步内容：授权内容、授权范围（全局 / 仅当前任务）、用户对话截图或摘要（前提是用户同意）。
- 若未同步，其他参与方在 sanity check 中可判定该授权无效。

### I.3 误触发 vs 真违纪的辨别（三分 + 三种处置 + 联动 + PR 作废）

| 状态 | 定义 | 处置 |
|---|---|---|
| **误触发** | 用户事后追认 + 行为本身合规（如 [#010](user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft) STATUS_ENUM 修改被接受） | 不进入违纪记录，但要求未来主分支同步落档 |
| **真违纪** | 用户事后追认但行为不合规（如归档路径选择实际未经批准） | 进入「治理失误」记录，要求方法论复盘（[#005](user-decision-log.md#005-docsmeta-归档治理--归档路径用户显式批准) 体例） |
| **争议状态** | 证据不足时 | 上交用户裁决，保留日志，不私下补叙为合规 |

- **§I↔§H 联动**：重复犯同类违规 → 升级为真违纪并触发主笔轮换（按 §H 流程）（[#014 D7](user-decision-log.md#014-m-005-p3b-八处分歧裁决)）。
- **PR 作废**：PR 中夹带结构性变更但无相应日志记录 → 自动作废该 PR（[#014 D7](user-decision-log.md#014-m-005-p3b-八处分歧裁决)）。

---

## §J 正向质量判据 + 字数原则升级（[#010](user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft) 落地）

### J.1 核心原则：密度决定字数，不预设上限

从 M-000 第一性原理审计（[#009 R2](user-decision-log.md#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草)）到用户显式 Overrule（[#010](user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft)），字数原则的演进路径：
- v1.2: `hard 2500 nwc`
- v2.0: `soft 2500 nwc + override_rationale`
- M-005: **无预设字数上限，正由 override_rationale 单独承载密度证明**

「不预设上限」意味着：
- 没有 `default_word_budget` 字段，没有默认值。
- 文档作者根据信息密度自然决定字数。
- 唯一约束：每一段的不可压缩性需在 `override_rationale` 证明。

### J.2 override_rationale 的正向作用（[#021](user-decision-log.md#021) v2 精化：分层 + 触发）

`override_rationale` 不再是「破例」，而是**分层密度证明**。v2 采用两个可机械区分的粒度（消除 v1「每一段」歧义，路径 C Stage 7.4-7.8 实证）：

1. **章节级 logical unit**（mandatory）：由 `##` / `###` 标题、`§N` 编号章节、附录标题界定。每个 logical unit 必须说明：
   - **不能下沉**：为何不能沉到 standards / skills / tools / templates。
   - **不能省略**：删去后会断裂哪条依赖链、证据链或裁决链。

2. **段级 grammatical paragraph / structured block**（mandatory on trigger）：由空行分隔的散文段；表格、列表、代码块按一个 structured block 计算。**触发条件三选一**：
   - 正文超**参考篇幅** 2500 nwc（非硬上限，仅触发参考值；§J.1 「不预设上限」仍优先，参考篇幅纯为审计触发器）
   - sign-off 指出具体冗余点
   - 作者主动主张段级 override

   触发后必须说明：**不能压缩**——为何不能表格化、合并、删重、下沉模板化，且无重复定义、装饰性论证、空洞合规句。**超参考篇幅时，override_rationale 应至少示例 1-2 段最长或最可能冗余的段落，说明已考虑压缩可能**（[#021](user-decision-log.md#021) D-J2=C 裁决 + DeepSeek 原作者 CONDITIONAL）。

3. **§J.1 优先**：字数不是硬上限；参考篇幅只触发密度证明，不自动否决。仅证明「结构重要」但不回应段级压缩信号，或仅逐段删重但不证明章节级必要性，均不足以成立 override。

违反信号（v2 扩充）：
- `override_rationale` 为空，或只有「因为超字数」「按长度需要」。
- 只按章节证明不可省略，却回避已指出的段级可压缩点。
- 正文存在重复定义、可模板化段落、可脚本生成清单、或无信息量宣示句。
- 字数声明与机械实测不一致（参 §J.7 机械验证标准），导致密度证明对象不确定。
- 「形式合规但实质空洞」：通过所有 check 但产出后无实质影响。

### J.3 冗余检测信号（表格化）

| 信号 | 检测方法 | 严重级 |
|---|---|---|
| 重复定义 | 语义相同段落出现在不同章节 | 黄色警告，若 > 3 处则升级为红色 |
| 可下沉段落 | 段落内容完全由操作步骤或工具命令组成 | 红色（违反 §A.3） |
| 装饰性论证 | 无实质内容的描述性话语 | 黄色警告，若 > 5% 字符量则升级 |
| 形式合规但空洞 | 通过了所有 check 但产出后无实质影响（例：写了 3000 字但未解决任何用户提出的问题） | 红色（可被 sign-off 时拒绝） |

### J.4 删除代码块预算和英文译本乘数

根据 [#010](user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft) 和 [#014](user-decision-log.md#014-m-005-p3b-八处分歧裁决)，代码块独立预算和英文译本固定乘数不再作为默认规则保留。若未来代码块或译本过长，应由该文档自己的 `override_rationale` 或译本说明处理，不设立独立预算。

### J.5 下游脚本兼容性处理

`default_word_budget` 字段删除后，下游消费该字段的脚本可能受影响。M-005 ratify 同 PR 必须：
1. 全仓 grep `default_word_budget` 找消费点。
2. 受影响脚本同步修订（不消费该字段 / 改消费 `override_rationale` 存在性）。
3. 若发现消费点但本轮无法修订，落 user-decision-log「字数升级后续 PR backlog」条目，不阻塞本轮 ratify。
4. 按 §F.3 工程兼容性优先：若删除阻碍其他工作流，可暂保留 `default_word_budget` 字段值为 `null`（语义为「不预设」），单独 PR 完成最终删除。

### J.6 同 PR 落地路径（M-005 ratify 时执行）

**步骤 1**：修订 M-000 v2.0 §6 章节。

当前文本：
> M-000 默认正文预算为 2500 non-whitespace chars；这是可读性和冷启动成本的设计目标，不是自动否决线。超过默认预算时，frontmatter 必须写 `override_rationale`……

修订为：
> M-000 无预设字数上限。正文密度由 frontmatter `override_rationale` 单独承载——作者必须在该字段中证明正文每段的不可下沉性、不可压缩性和不可省略性。代码块、译本等不单独设立预算，由同一密度证明覆盖。

**步骤 2**：删除 M-000 v2.0 frontmatter 中的 `default_word_budget: 2500` 字段。

**步骤 3**：在 `user-decision-log` 录入新条目，显式 Overrule [#009](user-decision-log.md#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草) R2 处理方式：

```
Overrule 关系：Overrule <user-decision-log #009 R2>
Overrule 对象：R2「default_word_budget 字段保留」处理方式
Overrule 范围：仅 #009 R2 中的字段保留处理；#009 其他裁决（删除宪法叙事 / layer 简化 / docaudit 裁剪 / phases 缩减 / 古德哈特改名 / KM 软信号）全部保留生效。
理由：#010 已宣告字数原则不应预设上限，#010 的进一步改造在 M-005 §J 落地。M-005 同 PR 修订 M-000 v2.0 §6 + frontmatter 已完成，旧字段不再有意义。
Overrule 生效时刻：本条目录入时同步生效。
```

### J.7 机械字数验证标准（[#021](user-decision-log.md#021) D-J4=A 新增）

主笔自报字数失真已成系统性偏差（路径 C 实证：DeepSeek M-003 v1 自报 2480 实测 4958 / v2 自报 2412 实测 5132，两次约 2× 错估）。M-005 v2 起 frontmatter `word_count_actual` 字段必须**可机械验证**：

**标准计算口径**：
- **目标**：正文非空白 **Unicode 字符数**（nwc），**不计 frontmatter**
- **标准工具组合**：`awk` 抠 body + `tr` 去空白 + `wc -m`（UTF-8 字符 aware，不是字节）
- **参考实现**（M-001~M-006 文档适用，macOS / Linux 兼容）：
  ```bash
  awk 'BEGIN{c=0} /^---$/{c++;next} c>=2 {print}' <文件> | tr -d ' \t\n' | wc -m
  ```
  - `awk` 第 1 个 `---` 开 frontmatter，第 2 个 `---` 关；body 部分原样输出
  - `tr -d ' \t\n'` 去掉空格 / tab / 换行
  - `wc -m` 按 Unicode 字符计数（**关键**：`awk length()` 在 macOS 默认按字节，中文按 3 字节，会高估约 2× — Stage 7.9 实测）
- **structured block 计数**（与 §J.2 段级触发对应）：表格 / 列表 / 代码块按一个 block 计算（不细分行）

**违规判定**（强结构约束）：
- frontmatter `word_count_actual` 与上述 awk 实测**差 > 5%** → 违反 §J.2 第 4 条违反信号 → 自动降级为 CONDITIONAL（sign-off 要求修正）
- 主笔产 draft 后未跑机械校验直接 commit → 视为 sign-off 入口失败（按 task definition 强约束）

**主笔工作流要求**：
- DeepSeek API zero-context 主笔无 wc 工具 → 后置由 Claude 主分支或 sign-off 入口代查（v1/v2 已实证）
- Codex CLI / GUI 主笔可自跑 wc，但仍须独立校验
- 任何主笔产 draft 后 frontmatter 字段必须包含实测值（不接受估算）

---

## §K 修订与复审

1. M-005 的复审周期为 `freshness.max_age_days: 180`，但以下情况自动触发提前复审：
   - 用户裁决发生涉及质量判据的冲突（如 sign-off 时对 §A 某条判据的违反认定产生分歧）
   - M-002 或 M-001 起草时发现需要 M-005 补充判据
   - 出现 §C 静默退化信号在智能体中大规模爆发（如同一天内 ≥ 5 条退化报告）
2. 修订 M-005 必须满足 M-000 §12 自我修订的 4 点要求，且额外要求：
   - 在 §A 增加新判据时，必须同时提供该判据不能下沉到下游 standards/skills 的证明
   - 在 §B 增加新触发信号时，必须引用新的实证事故
3. M-005 本身不适用字数原则升级（§J 对其自身生效——即 M-005 的 `override_rationale` 已包含密度证明）。本章 §K 的加入不是因为必须包含，而是因为元规则本身需要生命周期管理，且不可下沉到 M-002（因为 M-002 不负责质量判据的复审）。

---