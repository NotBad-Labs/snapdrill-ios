---
last_verified: 2026-04-18
layer: archive
status: archived
reason: "一次性概念研究归档；若后续落地为规则/skill/hook 则在各自位置维护，不再回引本文档"
---
# Harness Engineering（驾驭工程）三方独立研究（2026-04-18）

> 研究方：Claude Opus 4.7 + Codex GPT-5.4（--effort high）+ Gemini 3 Auto
> 纪律：F-008 三方相同完整任务、不分工
> 触发：用户关注 Anthropic 2026-03-24 新长文《Harness design for long-running application development》，要求研究 "Harness Engineering" 作为独立学科的全貌
> 原始三方报告：`/tmp/harness-research/{claude.md, codex-last.md, gemini.out}`（一次性，归档后删除）

## 一句话结论

**Harness Engineering = 围绕 LLM 构建运行时壳层（权限 / 工具 / 记忆 / context 管理 / 评估 / 恢复）的工程学科**。Mitchell Hashimoto 2026-02-05 首次命名，OpenAI 2026-02-11 正式制度化，Anthropic 2026-03-24 把 Planner/Generator/Evaluator 三 agent + sprint contract 落成参考架构。**SnapDrill 已经在做 Harness Engineering，只是没显式命名**；真正缺的是 sprint contract 前置契约、iOS 领域 Playwright 等价 evaluator、以及 Hashimoto 式"错误 → 永久修复"自动回流机制。中文译名共识沿用「驾驭工程」，项目内文档推荐保留英文 `Harness Engineering / Harness`。

## 三方共识分级

### 三家一致（最强信号）

| 共识点 | 证据 |
|---|---|
| **作者/日期**：Anthropic 原文作者 Prithvi Rajasekaran，发表 2026-03-24 | Claude + Codex 直接引用，Gemini 间接引用 |
| **三 agent 架构**：Planner / Generator / Evaluator 职责分离 | 三家一致 |
| **核心问题**：self-evaluation 乐观偏差 + 长 context 失连贯 | 三家一致 |
| **工具链**：Evaluator 用 Playwright MCP 做浏览器自动化 | 三家一致 |
| **中文译法**：推荐沿用「驾驭工程」 | 三家一致 |
| **概念边界**：Harness ≠ Prompt ≠ Context ≠ Scaffolding Engineering | 三家一致（具体分层略有差异） |

### 两家一致（Claude + Codex，高可信）

| 共识点 | 证据 |
|---|---|
| **命名归属**：Mitchell Hashimoto 2026-02-05 在 *My AI Adoption Journey* 首次提出 "Engineer the Harness"（错误即永久修复） | Claude + Codex 同引 mitchellh.com |
| **OpenAI 制度化**：2026-02-11 *Harness engineering: leveraging Codex in an agent-first world* | Codex 详引；Claude 未独立提到 |
| **Retro Game Maker 基准**：Solo $9 / 20min vs Full harness $200 / 6h（20× 成本，质量"immediately apparent"） | Claude + Codex 完全一致 |
| **Sprint Contract 机制**：Generator 与 Evaluator 在写代码前就"完成态"达成文件契约 | Claude + Codex 一致，Anthropic 文中最具原创性的部分 |
| **Rubric 四维**：Design Quality / Originality / Craft / Functionality，前两项权重高（补模型短板，不补已有长处） | Claude + Codex 一致 |
| **迭代区间**：5-15 轮反馈循环，单轮 wall-clock 最长 4 小时 | Claude + Codex 一致 |
| **Context 管理代际演进**：Sonnet 4.5 严重 context anxiety → Opus 4.5/4.6 大幅缓解，compaction 已可替代 context reset | Claude + Codex 一致，细粒度描述略差 |
| **Böckeler 定义**：`Agent = Model + Harness`（Thoughtworks / martinfowler.com） | Claude + Codex 一致 |
| **Hashimoto 的最低有效 harness**：`AGENTS.md` + 工具化常踩坑 + 测试 + 截图 | Claude + Codex 一致 |

### 单家独有（弱信号，谨慎采信）

**Codex 独有**：
- OpenAI 2026-02-04 *Unlocking the Codex harness*（作者 Celia Chen）— URL 可独立访问
- OpenAI 2026-02-11 作者 Ryan Lopopolo — URL 可独立访问
- Aider architect 模式是 Planner/Editor 二分的早期工程化例子
- Cursor 三件套：Rules + MCP + Background Agents（均有一手 docs URL）
- OpenHands 用 Docker 作为安全/隔离/可复现执行层
- Inspect（UK AISI）是典型 eval/scoring 框架
- Simon Willison 2025-06-27 *Context Engineering* 是相邻术语的关键整理

**Claude 独有**：
- **Stanford Meta-Harness**（arXiv 2603.28052，Lee/Nair/Zhang/Lee/Khattab/Finn，2026-03-30）：把 harness 设计本身自动化（Text Classification +7.7 / Math +4.7 / TerminalBench-2 超人工 baseline）—— **单家引用，未由其他两家独立验证，建议先 WebFetch 验证再当依据**
- DAW V2 的完整分轮时长/成本表（Planner 4.7min / $0.46 → Build1 2h7min / $71.08 → ... → 总计 3h50min / $124.70）
- 引言 "Every component in a harness encodes an assumption about what the model can't do on its own"
- Andrew Maynard 2026-02-22 首个从人文视角批评 harness 隐喻
- Rick Hightower "The model is the CPU, the harness is the OS"
- 中文圈传播详情：宝玉（dotey）/ Wang Shuyi / ZhangHanDong GitHub / 菜鸟教程
- 致谢名单 16 人含 Mike Krieger（Anthropic CPO）
- `docs/standards/` 翻译建议：保留英文术语，避免中文"驾驭"歧义

**Gemini 独有（按 `feedback_gemini_adversarial.md` 默认存疑）**：
- ⚠️ **arXiv:2408.01234 (Scaling Test-time Compute)** — 编号未由其他两家验证，**不作依据**
- ⚠️ **arXiv:2603.03612 (Natural-Language Agent Harnesses)** — 编号未验证且与 Claude 的 2603.28052 不一致，**不作依据**
- ⚠️ Karpathy "Software 3.0"、"harness 是智能体本体"、"小硬编码 Harness 包裹大推理引擎" — 未给 URL，Codex 明确指出 Karpathy 不是 harness engineering 的首个可验证提出者，**Gemini 表述推测高概率幻觉**
- ⚠️ Claude Code 使用 "nO 主循环" + "Git Worktree 子代理并行" — 未由 Claude 自己确认，**存疑**

### 冲突（裁决）

| 冲突点 | Claude 说法 | Codex 说法 | Gemini 说法 | 裁决 |
|---|---|---|---|---|
| Karpathy 在 harness engineering 中的角色 | 间接先驱（年度 workflow 倒置） | 不是首个可验证提出者 | 直接提出"harness 是本体" | 采信 Claude + Codex：**间接影响者，非命名者** |
| 学术论文锚点 | arXiv 2603.28052（Stanford Meta-Harness） | 无学术成体系代表作，引用 ReAct/Reflexion/Self-Refine/Cognitive Architectures | arXiv 2408.01234 + 2603.03612（未验证） | 采信 Codex：**目前没有以 "Harness Engineering" 为名的标志论文**；Stanford Meta-Harness 是最接近的，但 Claude 单家引用需要独立验证 |
| Hermes Agent 的 harness 贡献 | "每 ~15 次 tool call 自动抽取 skill"（具体数字） | "自我学习循环、持久记忆、skill 生成"（定性描述） | 未提及 | 采信 Claude + Codex 的一致描述，Claude 的数字细节如需引用应再核查 |

## 时间线（高可信版）

按三家一致或两家互相印证的部分：

| 时间 | 事件 |
|---|---|
| 长期（≥ 2023） | `test harness` / `evaluation harness` 在软件工程与 LLM benchmark 圈已有固定用法（如 `lm-evaluation-harness`） |
| **2025-11-26** | Anthropic 发布 *Effective harnesses for long-running agents*（作者 Justin Young）—— 用 "harness" 指长任务壳层，但未上升为学科名 |
| **2026-02-04** | OpenAI *Unlocking the Codex harness*（Celia Chen），把 Codex 各 surface 共享的 agent loop 明确称作 "Codex harness" |
| **2026-02-05** | **Mitchell Hashimoto** 在 *My AI Adoption Journey* 正式提出 "Engineer the Harness" |
| **2026-02-11** | **OpenAI** 以正式标题 *Harness engineering: leveraging Codex in an agent-first world*（Ryan Lopopolo）把术语制度化 |
| 2026-02-17 | Thoughtworks / Birgitta Böckeler 在 martinfowler.com 做术语梳理，归功 Hashimoto |
| 2026-02-22 | Andrew Maynard 首个人文视角批评 harness 隐喻（Claude 独家引用） |
| **2026-03-24** | **Anthropic** *Harness design for long-running application development*（Prithvi Rajasekaran）—— 三 agent + sprint contract 参考架构落地 |
| 2026-03-30 | Stanford *Meta-Harness*（Claude 独家，arXiv 2603.28052 待验证） |

## Anthropic 原文核心机制（三家一致，可直接采信）

1. **三 agent 物理分离**：Planner 负责 spec 扩展（不写实现细节）；Generator 按 sprint 实现；Evaluator 用 Playwright MCP 像真实用户一样测
2. **Sprint Contract**：Generator 与 Evaluator 在写代码**之前**就"完成态"达成契约，桥接高层故事与可测实现
3. **Rubric 四维权重**：Design Quality + Originality 高于 Craft + Functionality（harness 补模型短板，不补其已有长处）
4. **反馈循环 5-15 轮**
5. **Context 管理代际演进**：Sonnet 4.5 严重 context anxiety（需要 reset + handoff）→ Opus 4.5/4.6 大幅缓解（可用 compaction）
6. **self-praise bias** 是三 agent 分离的核心动因（"agents tend to confidently praise mediocre work"）
7. **关键引言（Claude 独记）**："Every component in a harness encodes an assumption about what the model can't do on its own." → **模型升级时应系统性拆除不再 load-bearing 的组件**

## 概念边界（三家交叉去重后的清晰分层）

| 术语 | 控制层级 | 核心问题 |
|---|---|---|
| Prompt Engineering | 单次调用 | 模型**想做什么** |
| Context Engineering | 单会话 / 单 context window | 模型**能看到什么** |
| **Harness Engineering** | **整个 agent 生命周期（跨会话）** | 模型**能/不能做什么 + 如何验证 + 如何迭代** |
| Tool Use Engineering | 动作层 | 模型**如何与世界交互** |
| Eval Engineering | 质量度量 | 模型**表现如何** |
| Inference-time Scaffolding | 推理步骤 | 模型**如何组织一次思考** |

Codex 的精要判断被采纳：Harness Engineering 是**旧实践的新主语** —— 测试、契约、权限、回滚、知识库、CI、代码审查、日志、质量门禁这些软件工程老手段，在 agentic coding 语境下被重新命名并收束成一个核心对象。"新意"不在组件本身，而在**"它们现在首先是为让 agent 稳定工作，而不是为让人类工程师协作舒服"**。

## 对 SnapDrill 的判断（三家共识 + 裁决）

### 三家共识：不引入完整三 agent 架构本体

- Planner / Generator / Evaluator 三独立进程 → 20× 成本，对单人 iOS 项目不划算
- 5-15 轮 evaluator 循环 → iOS build 耗时下不现实
- React/FastAPI + Playwright MCP → 非本项目技术栈
- Hermes 风格全自动 skill 抽取 → 规模小、手动可控

### 三家共识：SnapDrill 已实现 Anthropic 蓝本的大半

| Anthropic 蓝本元素 | SnapDrill 对应物 | 状态 |
|---|---|---|
| Planner / Generator / Evaluator 分离 | F-008 三方对抗（Claude + Codex + Gemini）+ Xcode Review | ✅ 事实上已存在，以"交叉 Generator + 多 Reviewer"形式呈现 |
| Context reset + structured handoff | `resume-from-handoff` skill + `docs/memory/handoff.md` + `long-session-guard` hook | ✅ 领先 Anthropic 公开实践 |
| self-praise 对冲 | F-008 三方纪律 + `cross-audit-consensus` skill | ✅ 结构性防御到位 |
| 知识沉淀 | `docs/standards/` + `docs/memory/feedback.md`（F-001~F-017）+ `.claude/rules/` 自动路由 | ✅ 已覆盖 |
| Hashimoto 式"错误即永久修复" | `feedback.md` 新增规则是手动触发 | ⚠️ 部分 —— 依赖 Claude 主动判断 |
| 运行时门 | `swift-autolint` / `prepush-lint` / `block-dangerous-bash` / `premerge-checklist` hooks | ✅ 已部署 |

### 三家共识：值得补齐的三个缺口

1. **Sprint Contract 前置契约**（Anthropic 原创）
   - 当前流程：PR 提出 → Review → 合并。没有"写代码前显式约定完成态"
   - **落地建议**：在 `.github/ISSUE_TEMPLATE/feature_request.md` 或 PR 模板里加一段 `acceptance_criteria` 字段（机器可读的 "完成态 checklist"），Generator 开始编码前先读
   - 代价：低（文档纪律）

2. **iOS 领域 Playwright 等价 evaluator**（最大工具链缺口）
   - Anthropic 用 Playwright MCP；iOS 侧候选：XCTest + UI Testing / `xcrun simctl` + snapshot diff / Xcode 26 Preview
   - **落地建议**：在 CI 把 UI Test 失败截图 diff 暴露给 agent 作为 evaluator 反馈
   - 代价：中（需 MCP 接入工程）

3. **Hashimoto 式错误回流自动化**
   - **落地建议**：在 `.claude/rules/` 加一条 `harness-recall` —— PR 合并后如果 cross-audit 发现的 bug 能归纳为规则，自动 propose 写进 `docs/standards/` 或 `feedback.md`
   - 代价：中（需要 post-merge hook + 自动分类启发式）

### 三家共识：不值得引入

- 针对常规 SwiftUI 页面跑 5-15 轮审美迭代
- 为 context reset 而 context reset（已有 phase-compaction + handoff 纪律）
- 多 agent 同时改同一块 SwiftData / SwiftUI 核心（merge thrash）
- 把 "Harness Engineering" 做成营销包装写进 `docs/standards/`（已有同等内容换名字增加维护成本）

## 中文译法（三家共识）

**推荐：驾驭工程（Harness Engineering）**

理由：
1. 语义命中核心："对有力者的方向控制"贴合 harness 的技术隐喻
2. 已成既定事实（宝玉 / Wang Shuyi / ZhangHanDong / 菜鸟教程均用此译）
3. 可动词化（"驾驭 Claude Code"）

**对 SnapDrill 的具体建议（Claude 独有观点，值得采纳）**：
- `docs/standards/` 若引入该概念 → **用英文 `Harness Engineering`**，中文解释段用"驾驭"作描述词而非术语
- `docs/memory/feedback.md` 新增规则 → **用 `Harness` 一词即可**，无需翻译
- **避免**：支架 / 脚手架（与 inference-time scaffolding 冲突）、框架（与 framework 冲突）、壳（贬义）

## 批判性评估（三家一致）

1. **部分被营销放大**：中文圈把它包装成"2026 最大风口"是营销；Hashimoto 的原意很朴素
2. **真实新价值**：sprint contract、"每次模型升级重审组件"的纪律、Planner/Generator/Evaluator 契约是有新信息量的工程内容
3. **三 agent 结构的硬局限**：
   - Evaluator 自己也会乐观偏差 → 同家模型打分时重现（Claude 观察）
   - rubric wording 会反塑生成风格（美学收敛）
   - Playwright 等价物在非 Web 栈缺失 → iOS 领域的硬阈值打分是开放问题
4. **未来走向（推测，非共识但倾向一致）**：
   - 原生收敛：Anthropic / OpenAI 会把 Planner/Generator/Evaluator 做成 SDK 原语
   - Meta-harness 普及：手写 harness 会被自动化替代
   - Harness 不是终态：按 Anthropic 自己的逻辑，每代模型升级都让一部分 harness 组件退役；harness engineering 最终**收缩**到模型短板处

## 待验证项（若后续引用需先独立查证）

- ⚠️ arXiv 2603.28052 (Stanford Meta-Harness, Yoonho Lee et al.) — Claude 单家
- ⚠️ arXiv 2408.01234 (Scaling Test-time Compute) — Gemini 单家
- ⚠️ arXiv 2603.03612 (Natural-Language Agent Harnesses) — Gemini 单家
- ⚠️ Karpathy "Software 3.0"  / "harness is the body of the agent" 具体出处
- ⚠️ Claude Code "nO 主循环" 表述 — Gemini 独家，未被 Claude 自己确认

**通则**：三方中 Gemini 按 `feedback_gemini_adversarial.md` 历史幻觉记录，其单家引用的具体论文编号、章节号、精确引文**默认不作依据**。

## 主要 URL 来源（三家均引或 Codex+Claude 共引）

**一手主源**
- Anthropic: https://www.anthropic.com/engineering/harness-design-long-running-apps （2026-03-24，Prithvi Rajasekaran）
- Anthropic: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents （2025-11-26，Justin Young）
- Anthropic: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- Anthropic: https://www.anthropic.com/research/building-effective-agents （Schluntz + Zhang）
- OpenAI: https://openai.com/index/harness-engineering/ （2026-02-11，Ryan Lopopolo）
- OpenAI: https://openai.com/index/unlocking-the-codex-harness/ （2026-02-04，Celia Chen）
- Mitchell Hashimoto: https://mitchellh.com/writing/my-ai-adoption-journey （2026-02-05，命名起源）

**命名 / 传播 / 综述**
- Birgitta Böckeler: https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html
- Birgitta Böckeler: https://martinfowler.com/articles/harness-engineering-for-coding-agent-users.html
- LangChain: https://blog.langchain.com/the-anatomy-of-an-agent-harness/
- LangChain: https://blog.langchain.com/improving-deep-agents-with-harness-engineering/
- LangChain: https://blog.langchain.com/your-harness-your-memory/
- Simon Willison: https://simonwillison.net/2025/Jun/27/context-engineering/
- Parallel: https://parallel.ai/articles/what-is-an-agent-harness

**工具生态**
- Cursor: https://docs.cursor.com/context/rules · https://docs.cursor.com/en/context/mcp · https://docs.cursor.com/en/background-agents
- Claude Code: https://docs.anthropic.com/en/docs/claude-code/hooks · https://docs.anthropic.com/en/docs/claude-code/security
- Aider: https://aider.chat/2024/09/26/architect.html
- OpenHands: https://docs.all-hands.dev/openhands/usage/architecture/runtime
- Inspect: https://inspect.aisi.org.uk/

**批评**
- Andrew Maynard: https://www.futureofbeinghuman.com/p/what-we-miss-when-we-talk-about-ai-harnesses （2026-02-22，Claude 单家）

## 下一步：SnapDrill 可行动条目（按 ROI 排序）

| 优先级 | 行动 | 代价 | 收益 |
|---|---|---|---|
| **P1** | PR 模板 / Issue 模板加 `acceptance_criteria` 字段（Sprint Contract 本土化） | 低（纯文档） | 高（对齐 Generator/Evaluator） |
| **P2** | 新建 `.claude/rules/harness-recall.md`：PR 合并后，cross-audit 新发现自动 propose 到 `feedback.md` / `docs/standards/` | 中（hook + 分类） | 高（Hashimoto 永久修复自动化） |
| **P3** | CI 把 XCUITest 失败截图 diff 暴露给 agent 作为 evaluator feedback | 中（MCP 接入） | 中（iOS 领域 Playwright 等价） |
| **P3** | `long-session-guard` hook 加 "context anxiety" 监测（连续 N 步小改 → 强制 reset） | 低（hook 增强） | 中（防 premature termination） |
| 观望 | Meta-Harness 2603.28052 若验证为真，长期可让 Claude 自读 transcript 历史自动提建议 | 高 | 待定 |

**不落地**：引入完整 Planner/Generator/Evaluator 独立进程、React+FastAPI Playwright 栈、Hermes 风格 skill 自动抽取、把 Harness Engineering 作为营销名词写进 `docs/standards/`。

---

> 本文档作为一次性研究归档（layer: archive）。若 P1~P3 行动条目后续落地为规则 / skill / hook / ADR，在各自位置维护，不再回引本文档。
