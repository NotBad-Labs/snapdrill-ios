---
last_verified: 2026-05-22
layer: snapshot
scope: meta
freshness:
  max_age_days: 365
  decay_trigger: [meta_vision_consensus, user_decision_log_update]
---
# M-000 字数计量单位多家裁决汇总（2026-05-22）

> 触发：v1.1 Codex 主笔时撞 2000 字"上限"，用户质疑"字"的定义。
> 流程：Claude 主笔起草中立 prompt，独立 zero-context 调用四家智能体裁决。
> 输出：三家选 B（non-whitespace 2500），一家选 C（语义字符 2000），最终倾向 B 但需用户裁决。

## 调用环境与渠道

| 家 | 模型 | 渠道 | 渠道严谨性 |
|---|---|---|---|
| DeepSeek | V4-Pro | 直接 curl `api.deepseek.com /v1/chat/completions` | ✅ zero-context API |
| Codex | GPT-5.5 Thinking | `codex exec -s read-only`,cwd=/tmp | ✅ 沙箱非交互 |
| Gemini | **3.5 Flash GA**（2026-05-19 发布） | 直接 curl `generativelanguage.googleapis.com /v1beta/models/gemini-3.5-flash:generateContent` | ✅ zero-context API（需 GOOGLE_API_KEY） |

⚠️ Gemini CLI（`gemini-cli 0.42.0`）走 OAuth Code Assist endpoint，不接受 `gemini-3.5-flash` GA model ID（404），只接受 `gemini-3-flash-preview`。要用真 GA 必须直接 curl `generativelanguage.googleapis.com`。详见 [agent-cli-models.md](../tech/reference/agent-cli-models.md)。

## 投入材料（共同 prompt）

四家拿到的 prompt 完全相同，纯净化版本，未告诉对方的立场。原文见 `/tmp/deepseek-字数定义-prompt.md`（一次性临时材料，未归档；议题等同于 §6 主笔建议中描述的 A/B/C 三方案）。

议题摘要：
- 方案 A：CJK 中文字 2000
- 方案 B：non-whitespace chars 2500
- 自提 C/D 允许

## 裁决结果矩阵

| 家 | 选择 | 关键论证 |
|---|---|---|
| DeepSeek V4-Pro | **C 自提**（语义字符 = CJK + ASCII 字母数字，2000） | 标点是"结构性脚手架"不该消耗预算；防膨胀只锁定"信息承载单元" |
| Codex GPT-5.5 Thinking | **B**（non-whitespace 2500，建议代码块单独预算） | 防膨胀约束的是"读者必须处理的信息表面积"；A 的"动机审判"反规避条款会让 review 变成主观判断 |
| Gemini 3.5 Flash GA | **B**（non-whitespace 2500） | **古德哈特定律**："当指标变目标，它就不再是好指标"。A 会引导"中改英"或"符号化"规避；B 让所有可见字符等价计费 |
| **结论** | **3:1 B** | non-whitespace 2500 |

## 异源/同源分析

- **B 阵营**：Codex（OpenAI）+ Gemini（Google）= 两家**真正异源**模型共识
- **C 阵营**：DeepSeek 独家
- DeepSeek round 3 review 时出现身份误识别（自称 Claude），说明它对 Claude 训练数据有 leakage——但本次 C 立场与 Codex/Gemini 都不同，**反而证明它的独立性**（如果它只是 Claude 镜像，应该跟我之前主笔的 倾向重叠）

## 三家共同 callout（必须复核）

不分阵营，三家都提到的真盲点：

1. **A 方案的"反规避副规定"会变成动机审判**（Codex / Gemini 共识）
2. **代码示例应另设极小预算或彻底禁止**（Codex 独家提出，DeepSeek 提到代码块按字符全计入）
3. **古德哈特定律 / 行为规避**（Gemini 独家命名，但 Codex 论证实质相同）

## 各家独家洞察

| 家 | 独家贡献 |
|---|---|
| DeepSeek | 「标点是结构性脚手架，不携带规则含义」精确论证 |
| Codex | 代码块独立预算建议 + 「字符数只能约束体积，不能约束规则复杂度」盲点（建议另设条目数/MUST 密度限制） |
| Gemini 3.5 Flash | **古德哈特定律**命名；**翻译膨胀风险**盲点（若英文译本应有独立乘数 ~4000） |

## 主笔（Claude CLI）观察

我之前给的"主笔倾向方案 C"基于直觉，没引用古德哈特定律。Gemini 3.5 Flash 的论证让我看到 C 方案的真隐患：**"中改英"或"符号化"规避会破坏中文写作自然节奏**。Codex 的"动机审判"批评其实是同一现象的不同表述——A 和 C 都依赖"不得有意识规避"的副规定，而 B 让规避在物理上无意义。

但 DeepSeek 的核心论证"标点不该消耗预算"仍然有道理：宪法层标点是表达节奏，不应被作为膨胀源。

**折中：B 实施 + 翻译膨胀盲点纳入实施细则**：
- 主上限：2500 non-whitespace chars（中文主文本）
- 代码块：单独预算（建议 ≤400 non-whitespace chars）
- 英文译本（如未来）：独立乘数 ~4000

## 给用户的最终选择

| 选项 | 含义 |
|---|---|
| **B+**（推荐） | non-whitespace 2500 + 代码块独立 ≤400 + 译本独立乘数 4000 |
| B（精简） | non-whitespace 2500，其他细则下沉 M-001 |
| C | 语义字符 2000（DeepSeek 提案）|
| A | CJK 2000（你最初考虑） |

请用户裁决，主笔不替你拍板。

## 关联资产

- [docs/meta/M-000-v1.1-prompt.md](M-000-v1.1-prompt.md) v1.1 起草任务包（含字数定义条款待替换）
- [docs/meta/user-decision-log.md](user-decision-log.md) #001（1500→2000 Overrule）+ #002（WebSearch 验证纪律）
- [docs/tech/reference/agent-cli-models.md](../tech/reference/agent-cli-models.md) 工具调用方式 + 模型快照
- [docs/meta/M-000-meta-vision.md](M-000-meta-vision.md) 当前 v1.1（待 v1.2 修订）
