---
last_verified: 2026-05-25
layer: contract
scope: drafting-consensus
freshness:
  max_age_days: 30
  decay_trigger: [m005_ratified]
---

# M-005 起草 P3 折叠报告

> 4 家异源独立草案 → 折叠为 final 主笔（DeepSeek reasoner）的起草输入。
> 帅哥裁决 D1~D8 八处分歧后，DeepSeek 主笔产 final 候选。

## 4 家产物索引

| 家 | 文件 | bytes | 正文 nwc | model | 风格特征 |
|---|---|---|---|---|---|
| Claude | [docs/meta/M-005-quality-criteria-claude.md](../meta/M-005-quality-criteria-claude.md) | 34761 | **16445** | Opus 4.7 (1M) | 最长，每章细分 §X.1/§X.2 子节，表格密集，密度高（会话上下文已知 #001~#013 全集） |
| Codex | [docs/meta/M-005-quality-criteria-codex.md](../meta/M-005-quality-criteria-codex.md) | 20377 | 7805 | GPT-5 | 最短，散文体，无章节末子节编号，密度高度浓缩，每章末说明边界 |
| **DeepSeek** | [docs/meta/M-005-quality-criteria-deepseek.md](../meta/M-005-quality-criteria-deepseek.md) | 28773 | **11367** | reasoner | **主笔候选**。中等长度，表格 + 编号清单结合，§3 边界表双向列对方责任，结构最齐 |
| Gemini | [docs/meta/M-005-quality-criteria-gemini.md](../meta/M-005-quality-criteria-gemini.md) | 22920 | 8800 | **gemini-3.5-flash GA**（直接 API 实测）| 简洁，星号+斜体，章节末加历史实证锚定；唯一在 §C.1 主动落档 #013 实证档案路径 |

字数密度洞察：Claude 多 5078 nwc 主要在 §B/§C/§D/§J 细分子节 + 详细历史实证表格；Codex 散文体浓缩但视觉冲击低；DeepSeek 表格化 + 双向边界表是元规则"可机械引用"特征的最佳风格；Gemini 时序最晚跑（在 #013 落档后），所以主动把 §C 静默退化实证档案路径写进正文。

## 起草过程实证

- **Codex worktree commit**: `cface70c docs: draft codex M-005 quality criteria`（drafting/codex-m005 分支）
- **Gemini model 误用三层错**: 见 [user-decision-log #013](../meta/user-decision-log.md#013-gemini-主笔候选-model-误用事故--直接-api-修复--scriptsgemini_utilspy-ssot-同步)，旧 gemini-2.5-flash 草案归档至 `docs/archive/audits/m005-static-degradation-evidence/`，重做用 3.5 Flash GA 直接 API
- **DeepSeek 主笔候选**: 走 `https://api.deepseek.com/v1/chat/completions` + `deepseek-reasoner`，第一次因 max_tokens=16000 截断，调整到 32000 完整产出（completion 8065 tokens，reasoning 635 tokens，prompt cache hit 21248 tokens）

## 共识段（≥3 家一致，主笔 final 直接采纳）

### 结构层共识（4/4）

- 章节结构：§1 定位 / §2 M-000 PRIMARY 接口 / §3 与 M-001~M-006 边界 / §A~§J / §K 修订
- frontmatter：`layer: principle / scope: meta / freshness.max_age_days: 180`，decay_trigger 含 `meta_audit + downstream_rules_drafted + external_shock`
- override_rationale 改为"密度证明"语义（不再是"破例申请"）

### §A 产出度量（4/4）

- 4 项判据：**可追溯性 / 可验伪性 / 下沉证明 / 目的关联**
- 可追溯性要求引用具体 #编号（#001~#013），禁止"按惯例 / 历史经验 / 通常"
- 可验伪性要求每条规则列出"违反信号"
- 下沉证明要求说明"为什么不能下沉到 standards/skills/tools"
- 目的关联要求显式关联 P1~P8 或产品愿景

### §B 伪共识识别（4/4）

- 触发信号：同源主笔系列（实证 v1.0~v2.0 连续 4 版 Codex）/ 同 vendor 多实例 / 相似训练 cutoff 同向 / 提示词锚点泄漏 / 物理隔离失效 / 辅助方沉默
- 异源训练谱系基于厂商公开声明，不依赖智能体自我宣称（#004 实证）
- 否决权阈值 3 要素（缺一不可）：引用具体事实错误 / 提出可证伪反假设 / 指出明确风险路径

### §C 静默退化识别（4/4，承接 MC-1）

- 4 大信号：**格式崩溃 / 自相矛盾 / 偏离任务 / 身份误识别**
- 身份误识别引用 #004 实证（DeepSeek/Gemini 互换身份）
- 逻辑不可用等同物理不可用，回退用户（按 M-004 降级流程）

### §D 外部事实验证纪律（4/4，承接 MC-2 + #002）

- AI 模型 / 工具版本 / API endpoint / model ID 必须 WebSearch 强制验证
- 异源训练谱系基于厂商公开声明
- `agent-cli-models.md` 30 天 max_age_days 强制刷新
- CLI ping 失败只能证伪 CLI 路径，不能证伪模型本身存在（#002 实证）

### §E 古德哈特防御（4/4，承接 #009 R6）

- 形式 vs 目的判据：流程合规但无核心问题 / 指标代替判断 / 历史先例绑架 / 古德哈特循环
- 历史实证 #006/#007/#008/#009/#010 索引
- 不允许引用未发生的假设场景

### §F 自反性 sanity check（4/4，承接 #008）

- Round N → N-1 复盘 prompt 设计（要求 reviewer 复盘自己上一轮判断是否仍正确）
- sanity check 不是终审（异源共识也可被后续 sanity check 撤回）
- 工程兼容性 vs 元数据美学冲突时**工程优先**（#008 实证）

### §G docaudit check 设计原则（4/4）

- 不重复 M-000 §8 已列 6 项 core check
- 每个 check 必须有真实事故来源或风险模型
- core check 阻塞门条件：高频触发 / 不可机械绕过 / 误报可控 / 失败语义明确 / 有上游元规则说明
- 可选 check 价值不低于 core，只是阻塞资格未到（实验 / 低频高代价 / 依赖人工裁决）

### §H 主笔轮换（4/4，承接 #012）

- 同源主笔风险累积识别（v1.0~v2.0 连续 4 版 Codex 实证）
- 主笔轮换具体流程**下沉 M-001**（M-005 只给原则）
- 主笔候选裁决物理隔离要求（私下授权必须主分支同步）
- 主笔不是独享特权（3 家 sign-off 任一 BLOCK 主笔产出回炉）

### §I 自作主张越权防线（4/4，承接 #005 + #010）

- 结构性决定清单：归档路径 / 目录重命名 / 跨目录移动 / 批量 frontmatter 修改 / STATUS_ENUM 等 schema 扩展 / 元规则正文修订 / push 等
- #005 实证 + #010 实证（合规授权 vs 自作主张的边界）
- 误触发 vs 真违纪辨别（事后追认合规 / 撤回 + Overrule / 真违纪）

### §J 字数原则升级（4/4，承接 #010 + #012 Q3）

- **删除** M-000 v2.0 frontmatter `default_word_budget: 2500`
- `override_rationale` 改为**密度证明**（每段不能下沉 / 不能压缩 / 不能省略）
- 冗余检测信号清单：重复定义 / 可下沉段落 / 装饰性论证 / 形式合规但实质空洞
- 同 PR 修订 M-000 v2.0 §6 + frontmatter
- 显式 Overrule [#009](../meta/user-decision-log.md#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草) R2「default_word_budget 字段保留」处理方式

---

## 分歧段（8 处，需帅哥裁决）

### D1: §B 否决权阈值滥用触发的数字阈值

| 家 | 阈值 | 触发条件 | 处置 |
|---|---|---|---|
| Claude (§B.4) | 24h ≥5 次 | 强反对升级次数 | 触发「辅助方退化或滥用否决权」复审 |
| Codex | 描述但未给数字 | — | 反向检查该方是否退化 |
| DeepSeek (§B.3) | 24h ≥3 次 | 升级且 ≥2 次不满足三要素 | 触发静默退化扫描，确认后按逻辑不可用处理 |
| Gemini (§B.3) | 24h ≥5 次 | 无事实支撑强烈反对 | 自动判定该辅助方进入退化状态，屏蔽其否决权并上报用户 |

**冲突核心**：数字阈值（3 次 vs 5 次）+ 是否要求"不满足三要素"（DeepSeek 唯一加这条）+ 处置严重度

**Claude 推荐**：DeepSeek 的「≥3 次且 ≥2 次不满足三要素」更严谨——单纯次数不能区分"频繁但合理"和"频繁且滥用"；要求 ≥2 次不满足三要素能过滤合理反对者。

### D2: §H 主笔轮换阈值（连续同源主笔的版本数）

| 家 | 阈值 |
|---|---|
| Claude / Codex / Gemini | **≥3 版** 连续同源主笔 |
| DeepSeek (§H.1) | **≥2 版** 同系列升级 |

**冲突核心**：阈值（≥3 vs ≥2）。DeepSeek 更严（这是主笔候选自己的立场，可能存在"主笔愿意主动让位"的自反性）。

**Claude 推荐**：≥3 版（M-000 实际历史 v1.0/v1.1/v1.2 = 3 版才触发，v2.0 之后才轮换，是已发生的实证阈值）。

### D3: §H.2 主笔私下授权同步时限

| 家 | 时限 |
|---|---|
| Claude / Codex | 「尽快」/「立即」，无具体时间 |
| DeepSeek (§H.2) | 无明确时限 |
| Gemini (§H.2) | **1 小时内** 或 **next checkpoint 之前** |

**冲突核心**：是否给具体时限。Gemini 唯一给硬数字。

**Claude 推荐**：不给硬时限（应下沉 M-001）。M-005 只规定"必须同步"的原则，时限属流程颗粒度。

### D4: §F.3 工程兼容性 vs 元数据美学的边界

| 家 | 边界 |
|---|---|
| Claude / Codex / Gemini | 工程兼容性优先 / 绝对优先 |
| DeepSeek (§F.3) | 工程兼容性优先，**但不适用于 P2 用户裁决权 / P8 Overrule 显式性** |

**冲突核心**：是否有"工程兼容性优先"的例外（P2/P8 不可打折扣）。DeepSeek 唯一加例外。

**Claude 推荐**：DeepSeek 的例外条款保留——P2/P8 是 PRIMARY 内核，不该被工程兼容性 Overrule。这是 M-000 v2.0 §9「目的优先」的子推论。

### D5: §G 新增 check 升级流程

| 家 | 升级 → core 条件 | 降级触发 |
|---|---|---|
| Claude (§G.3) | 异源 sanity check ≥1 家确认 + 用户裁决 | §G.4：≥90 天未触发任何真实问题 |
| Codex | 升级 core 必须同步多份文档（execution-gates / 脚本 README / docaudit policy / 消费端文档） | "已有实现"不构成永久保留 |
| DeepSeek (§G.4) | 3 次审计运行 + 30 天 + 误报率 < 20% | 6 个月无 incoming reference |
| Gemini (§G.4) | 连续 ≥3 次成功拦截真实风险 + 完全机械化 | 180 天无有效拦截 |

**冲突核心**：升级阈值（异源确认 vs 3 次审计 vs 3 次拦截）+ 降级触发（90/180 天 / 6 个月 / 无 ref）+ 是否要求多份文档同步

**Claude 推荐**：折中——主笔以 DeepSeek 的「≥3 次审计 + 30 天 + 误报率」为升级骨架，吸纳 Codex 的「升级 core 必须同步消费端文档」、Gemini 的「180 天无拦截降级」。降级期限统一为 180 天。

### D6: §C 静默退化触发动作的颗粒度

| 家 | 颗粒度 |
|---|---|
| Claude (§C.3 + §C.4) | 适用范围限定为"普通可逆低副作用"，不可逆事项无论是否触发都升级用户 |
| Codex | 区分"硬信号 → 标逻辑不可用"和"局部段落退化 → 要求重做并保留证据" |
| DeepSeek (§C.5) | 三步触发：标记 → 视同物理不可用回退 → sign-off 阶段立即暂停 |
| Gemini (§C.5) | 任一信号即触发回退用户 |

**冲突核心**：是否区分硬信号 vs 局部退化（Codex 唯一）+ 是否对 sign-off 阶段特殊处理（DeepSeek 唯一）

**Claude 推荐**：吸纳 Codex 的硬信号 vs 局部退化二分（局部退化允许重做，避免过度严苛）+ DeepSeek 的 sign-off 阶段立即暂停（关键节点不让退化产物污染裁决）。

### D7: §I.3 误触发 vs 真违纪辨别的处置

| 家 | 处置 |
|---|---|
| Claude (§I.3) | 用户事后追认+合规 → 误触发；追认+不合规 → 治理失误；撤回+Overrule → 走 #005 体例 |
| Codex | 误触发 / 真违纪 / 争议状态三分 |
| DeepSeek (§I.3) | 重复犯同类 → 升级真违纪 + 触发主笔轮换（§H 联动） |
| Gemini (§I.3) | PR 中夹带结构性变更无日志 → 自动作废 PR |

**冲突核心**：重复犯错的级联（DeepSeek 唯一把 §I 和 §H 联动）+ PR 作废的强制性（Gemini 唯一）+ 争议状态处置（Codex 唯一）

**Claude 推荐**：吸纳全部四家——Codex 三分（基础结构）+ Claude 三种处置（细化）+ DeepSeek §I↔§H 联动（重复犯同类触发轮换是有力威慑）+ Gemini PR 作废条款（强约束未授权 PR）。这四个不冲突而是互补。

### D8: §B.1 thinking/reasoning 模式加剧身份误识别的权重处理

| 家 | 权重处理 |
|---|---|
| Claude / Codex / Gemini | 提到加剧但未明确权重 |
| DeepSeek (§B.1.4) | 该模型独立判断折扣为 **0.5 权重**，除非外部验证其训练谱系独立（通过厂商公开声明） |

**冲突核心**：是否引入 0.5 权重折扣

**Claude 推荐**：保留 DeepSeek 的 0.5 权重——但措辞需软化为"建议折扣"而非强制（因为合规授权下 thinking 模式仍是有效推理）。可在 §B.1 加注："开 thinking/reasoning 模式且本轮发生身份误识别时，该方判断权重建议折扣 0.5；折扣应在折叠报告显式标注，不强制阻塞"。

---

## 单家独有亮点（主笔 final 应吸纳）

### Claude 独有

- **§C.5 输出污染识别（prompt injection）**：具体信号清单（突然引用未出现路径 / 风格断裂 / 自我引用未发生对话 / 拒绝理由非任务相关）+ 触发动作（保留产物作 M-006 实证案例，本轮裁决不采纳但触发 M-006 复审）
- **§H.4 主笔轮换与同 PR 修订衔接**：新主笔有权重写修订条款但必须显式 Overrule 旧主笔对应条款
- **§J.5 下游脚本兼容性处理**：全仓 grep `default_word_budget` 找消费点 + 受影响脚本同步修订或落 backlog

### Codex 独有

- **§A 最低输出结构嵌入 Verdict 三分制**：缺任一项 → sign-off CONDITIONAL；缺两项以上或关键条款不可验伪 → BLOCK
- **§B.2 物理隔离失效检测 5 条**：路径污染（worktree 不同但远端分支 / stash / IDE 搜索 / shell glob 把禁止文件名带入）
- **§G 退役原则**："已有实现"不构成永久保留理由
- **§J.4 删除代码块独立预算和英文译本固定乘数**：这两项一并被新规取代

### DeepSeek 独有（主笔候选，本身骨架直接用）

- **§3 边界双向表**："由对方给出"列对齐 M-001/M-002/M-004/M-006 的反向责任范围
- **§B.1.4 thinking 模式 0.5 权重折扣**（D8）
- **§I.1 STATUS_ENUM 修改作为结构性决定**："接受不代表没越权，需区分合规授权 vs 越权"
- **§I.3 重复犯同类 → 升级真违纪 + 触发主笔轮换**：§I↔§H 联动

### Gemini 独有

- **§C.1 静默退化实证档案路径**：主动落档 `docs/archive/audits/m005-static-degradation-evidence/`（#013 实证编入正文）—— 因 Gemini 是最后跑的，时序上有这个优势
- **§G.4 双向流程明确化**：可选 → 核心 与 核心 → 可选 两个方向都有触发条件
- **§J.3 表格化冗余检测**（黄色 / 红色级别）

---

## 主笔产 final 输入清单

DeepSeek reasoner 主笔产 `docs/meta/M-005-quality-criteria.md`（无 vendor 后缀）时，按下列输入：

1. **本折叠报告**：共识段 + 帅哥裁决 D1~D8 后的分歧段答案 + 单家独有亮点
2. **4 家草案全文**：作为参考但不机械拼接，按融合后的结构产出
3. **DeepSeek 自己草案**：作为骨架（§3 双向表 / §I↔§H 联动等独有亮点保留）
4. **任务定义书** [`docs/audits/m005-drafting-task-definition.md`](m005-drafting-task-definition.md) §A~§J 必须承载内容（不可遗漏）
5. **同 PR 修订路径**：M-000 v2.0 §6 + frontmatter（删 `default_word_budget`），显式 Overrule [#009](../meta/user-decision-log.md#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草) R2

---

## 关联文档

- [任务定义书](m005-drafting-task-definition.md)
- [M-000 v2.0](../meta/M-000-meta-vision.md)
- [user-decision-log](../meta/user-decision-log.md) #012 启动 / #013 Gemini model 误用修复
- [4 家草案归档路径](../archive/audits/m005-static-degradation-evidence/)（gemini-2.5-flash 误用实证）
