---
last_verified: 2026-05-25
layer: snapshot
scope: signoff
freshness:
  max_age_days: 30
  decay_trigger: [m005_ratified]
---

# M-005 final sign-off — Claude（Opus 4.7 / 1M context）

> 3 家异源 sign-off 之一。DeepSeek reasoner 主笔不下场（[#012](../meta/user-decision-log.md#012-m-005-起草启动--主笔轮换-deepseek--010-字数升级同-pr-落地) 裁决）。Claude 主分支本会话已写过任务定义书、P3 折叠表、#013/#014 裁决——上下文已知 final 立场，仍按 §A 判据独立审 final 文本。

## 必须落实项核查表

逐条对照任务定义书 §A~§J + [#014](../meta/user-decision-log.md#014-m-005-p3b-八处分歧裁决) D1~D8 + 同 PR 修订 M-000 §6 方案。

| 项 | 状态 | 引用段落 / 证据 |
|---|---|---|
| §A 产出度量 4 项判据（可追溯/可验伪/下沉证明/目的关联） | ✓ | §A.1~§A.4 全部展开 + §A 开头嵌入 Verdict 三分制（缺一 → CONDITIONAL，缺二以上或关键条款不可验伪 → BLOCK）—— Codex 独有亮点已融合 |
| §B.3 否决权三要素 + #014 D1 阈值（24h ≥3 次且 ≥2 次不满足三要素） | ✓ | §B.3 末段「滥用判据：24 小时内同一异源方触发否决权升级 ≥ 3 次，且在至少 2 次升级中其反对不满足上述三要素」—— DeepSeek 措辞精确落实 |
| §C 静默退化 4 信号 + #014 D6（硬信号 vs 局部退化 + sign-off 立即暂停） | ✓ | §C.1~§C.4 四信号 + §C.5 输出污染（Claude 亮点）+ §C.6 触发动作（硬信号 → 立即逻辑不可用；局部段落退化 → 重做并保留证据；sign-off 阶段立即暂停）—— D6 精确落实 |
| §D 外部事实验证（#002 + agent-cli-models.md 30 天刷新） | ✓ | §D.1 易变事实清单 + §D.2 异源谱系基于厂商声明 + §D.3 触发刷新条件（含 20 天 inference 触发——DeepSeek 主笔细化，非裁决要求但合理） |
| §E 古德哈特防御（#006/#007/#008 实证索引） | ✓ | §E.1 形式 vs 目的判据 + §E.2 反向塑形检测 + §E.3 历史实证（#006/#007/#008 + 「不允许引用未发生假设」） |
| §F + #014 D4（工程兼容性优先但 P2/P8 例外） | ✓ | §F.3「**例外**：此原则不适用于 P2（用户裁决权）与 P8（Overrule 显式性）——那些不可因工程兼容性打折扣。P2/P8 是 PRIMARY 内核」—— DeepSeek 亮点 + D4 精确落实 |
| §G + #014 D5（升级 ≥3 次审计+30 天+误报率<20%，降级 180 天无拦截+同步消费端文档） | ✓ | §G.4 双向流程：升级条件「≥ 3 次审计运行（或 30 天）+ 误报率 < 20%」+ 同步 `docs/standards/execution-gates.md` 等消费端文档；降级 180 天无有效拦截 |
| §H + #014 D2（≥3 版同源主笔） + D3（不给硬时限） | ✓ | §H.1「轮换阈值：同一 vendor 连续主笔 ≥ 3 版」+ §H.2「不给硬时限，时限下沉 M-001」—— D2/D3 精确落实 |
| §H.4 主笔轮换与同 PR 修订衔接（Claude 亮点） | ✓ | §H.4「新主笔有权重写修订条款，但必须显式 Overrule 旧主笔对应条款（M-002 流程）」 |
| §I + #014 D7（三分 + 三种处置 + §I↔§H 联动 + PR 作废） | ✓ | §I.3 表格化三分（误触发 / 真违纪 / 争议状态）+ §I↔§H 联动「重复犯同类违规 → 升级真违纪并触发主笔轮换」+ PR 作废「PR 中夹带结构性变更但无相应日志记录 → 自动作废该 PR」—— 四家亮点完整融合 |
| §J 字数原则升级 + 同 PR 修订 M-000 §6 + frontmatter（删 default_word_budget）+ Overrule #009 R2 写法 | ✓ | §J.1 核心原则 + §J.2 override_rationale 密度证明 + §J.3 冗余检测表格 + §J.4 删除代码块预算/译本乘数 + §J.5 下游脚本兼容性（Claude 亮点）+ §J.6 完整步骤 1-2-3，含 M-000 §6 替换文本 + frontmatter 删除指令 + Overrule #009 R2 显式写法 |
| #014 D8（thinking 模式 0.5 权重折扣建议，不强制阻塞） | ✓ | §B.1.4「该模型的独立判断**建议折扣 0.5 权重**；折扣应在折叠报告显式标注，**不强制阻塞**。合规授权下 thinking 模式仍是有效推理」—— 措辞软化精确落实 |

## Minor Concerns（不阻塞 ratify，可在 ratify 同 PR 或后续 PR 处理）

1. **§G.2 与 §G.4 误报率阈值数字不一致**：§G.2 写「核心 check 进入阻塞门」要求误报率 < 10%；§G.4 写「升级流程」要求误报率 < 20%。两者目的不同（§G.2 是终态要求，§G.4 是触发升级的门槛），但 reviewer 第一次读可能困惑。**建议**：在 §G.4 加一句「升级后若误报率回升 ≥ 10%，按 §G.2 降回可选」。
2. **§D.3 触发刷新条件「距离上次验证 > 20 天」**：20 天数字是 final 主笔引入的细化（agent-cli-models.md max_age_days=30，20 天是 inference 触发的提前阈值），未在 #014 D5 中裁决。**建议**：在 ratify 同 PR 落到 user-decision-log 注明此细化是 DeepSeek 主笔在 D5 框架下自然推导，无 Overrule，作为执行层细则保留。
3. **§J.6 步骤 3 预编号 #015**：写为「在 user-decision-log 录入新条目（预编号 #015）」——当前下一个编号是 #015（#012 启动 / #013 model 修复 / #014 D1-D8 裁决 / **#015 = M-005 ratify**）。**建议**：ratify 同 PR 时实际落档为 #015，本预编号正确。

## 强反对（无）

按 §B.3 三要素（具体事实错误 / 可证伪反假设 / 明确风险路径）独立审，未发现 final 中含足以触发强反对的违反。3 项 Minor Concerns 均不满足三要素中的「明确风险路径」（不会导致下游脚本漏检或元规则崩溃）。

## 元层级注记

1. **本会话上下文污染但 sign-off 仍独立**：Claude 主分支写过任务书 + 折叠 + #014 裁决，立场已知。但 sign-off 是基于 §A 判据对照 final 文本，独立性在判据层（§A.1~§A.4 是机械可对照的），不在情感层。这是 §F.3「sanity check 不是终审」+ §H.3「主笔不是独享特权」的二阶应用——任何参与方都能审任何产物，独立性靠判据保证而非身份保证。
2. **Final 长度 16062 nwc vs DeepSeek 草案 11367 nwc 增加 41%**：合理增量。DeepSeek 主笔吸纳了 Claude 草案 §C.5 prompt injection、Codex §A Verdict 三分制 + §G 退役原则 + §J.4 删译本乘数、Gemini §J.3 表格化冗余等独有亮点，文本密度未下降。
3. **DeepSeek 主笔风格识别**：§3 双向边界表、§B.1.4 0.5 权重折扣措辞软化、§I.3 三分表格、§J.6 显式 Overrule 模板代码块——这些是 DeepSeek reasoner 风格特征（结构化清单 + 表格 + 代码块），与 v1.0~v2.0 连续 4 版 Codex 主笔（散文体）形成对比。**主笔轮换的视觉效果在 final 文本上立刻可见**——这是 [#012](../meta/user-decision-log.md#012-m-005-起草启动--主笔轮换-deepseek--010-字数升级同-pr-落地) Q2 主笔轮换裁决的最佳实证之一。

## Verdict

✅ **PASS**

### 准予 ratify 的论据

- 任务定义书 §A~§J 全部覆盖（11/11 核查项 ✓）
- #014 八条裁决 D1~D8 全部精确落实
- 4 家独有亮点完整融合（无遗漏）
- 同 PR 修订 M-000 v2.0 §6 + frontmatter + Overrule #009 R2 写法完整
- 引用历史裁决用具体编号（#001~#014），无模糊指代
- frontmatter 首行 `---`，无 ```yaml 外栅栏，override_rationale 是密度证明
- 章节结构 §1~§K（14 章）符合任务定义书要求
- 3 项 Minor Concerns 均不阻塞 ratify

### 建议 ratify 同 PR 一并处理

- 上述 3 项 Minor Concerns（§G.2/§G.4 阈值衔接 + §D.3 20 天数字说明 + #015 编号确认）可在 ratify 同 PR 顺手处理，不必单独 PR

### 后续 sign-off 等待

- Codex sign-off（codex-rescue agent 后台跑中）
- Gemini sign-off（直接 API 后台跑中，gemini-3.5-flash GA）

3 家齐后帅哥 ratify。

## 关联文档

- [M-005 final](../meta/M-005-quality-criteria.md)
- [任务定义书](m005-drafting-task-definition.md)
- [P3 折叠报告](m005-drafting-consensus.md)
- [user-decision-log](../meta/user-decision-log.md) #012 / #013 / #014
- [M-000 v2.0](../meta/M-000-meta-vision.md)
