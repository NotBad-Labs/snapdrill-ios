# Rules、Skills、Workflow：AI 编码 Agent 生态的概念图谱与实操指南（2024–2026）

## TL;DR

- **Rules 仍然流行，但角色被显著收窄**：从 2023 年 Cursor 单文件 `.cursorrules`，到 2024–2025 年的 `.cursor/rules/*.mdc` 多文件 + glob 作用域，再到 2025 年 8 月 OpenAI 推出、12 月 9 日被捐给 Linux Foundation 旗下 AAIF 的 AGENTS.md 跨厂商标准，Rules 已经成为"不变事实层"的事实工业标准；Anthropic 官方与社区共识是 CLAUDE.md 控制在 200 行以内，"放所有东西进去"的旧打法已被淘汰。
- **Workflow 不是式微，而是分化**：旧的"命令式 workflow"（Cursor Commands、Claude Code 的 `.claude/commands/`、Windsurf Workflows）正被 Anthropic 在 2026 年 1 月 24 日明确并入 Skills；同时 LangGraph（2025 年 10 月 22 日发布 1.0）、CrewAI、Temporal、Microsoft Agent Framework 等"agentic workflow"框架在生产侧爆发增长——一头是 model-invoked 的声明式 Skills，另一头是 graph/durable 的工程化编排，中间的"固定步骤命令"被两端挤压。
- **对独立 iOS 开发者（Claude Code + Claude Max + SwiftUI/SwiftData）的实操结论**：用一个 60–150 行的 CLAUDE.md 锚定项目身份、构建命令、SwiftData 模型约束；把 SwiftUI/SwiftData/Swift Concurrency 这种"过程性知识"装进社区已有的 Skills（Paul Hudson 的 `twostraws/swiftui-agent-skill`、`twostraws/swift-agent-skills`、`rshankras/claude-code-apple-skills` 等）；只有当某个动作真的需要"固定顺序的多步流程"（如 App Store 发版、Xcode 项目模板生成）时才写自定义 skill/command；其它都让 Claude Code 自己规划。

---

## Key Findings

1. **`.cursorrules` 起源于 2023 年 Cursor 单 Markdown 文件**，2025 年 1 月底随 Cursor v0.45 升级为 `.cursor/rules/*.mdc` 多文件 + YAML frontmatter（`description` / `globs` / `alwaysApply`）+ 四种触发模式（Always / Auto Attached / Agent Requested / Manual）。Cursor 官方文档原文称："The .cursorrules file in your project root is still supported but will be deprecated."

2. **CLAUDE.md 随 Claude Code 2025 年 2 月 24 日预览版（与 Claude 3.7 Sonnet 同日）推出**，5 月随 Claude 4 GA。Anthropic 官方文档和 HumanLayer 等社区博客一致建议：**< 200 行**，HumanLayer 公开其根 CLAUDE.md "less than sixty lines"；超过 300 行就开始失效。

3. **AGENTS.md 是一次罕见的跨厂商收敛**。OpenAI 2025 年 8 月推出，到 2025 年 12 月 9 日 OpenAI 官方称已被 60,000 多个开源项目采用（涵盖 Amp、Codex、Cursor、Devin、Factory、Gemini CLI、GitHub Copilot、Jules、VS Code）；同日 OpenAI、Anthropic、Block 共同把 AGENTS.md、MCP、goose 捐给 Linux Foundation 新成立的 Agentic AI Foundation（AAIF），白金会员含 AWS、Google、Microsoft、Bloomberg、Cloudflare。

4. **Rules 的厂商对照已基本稳定**：Cursor → `.cursor/rules/*.mdc`；Claude Code → CLAUDE.md + `.claude/rules/`；Windsurf → `.windsurf/rules/*.md` + `global_rules.md`；Cline → `.clinerules/` 文件夹 + 可切换 UI；GitHub Copilot → `.github/copilot-instructions.md` + `.instructions.md`；Roo Code → `.roo/rules/`；Aider → `CONVENTIONS.md`（社区推动支持 AGENTS.md）。

5. **Anthropic 2025 年 10 月 16 日发布 Agent Skills**（"equipping-agents-for-the-real-world-with-agent-skills"），12 月 18 日开源标准化（`agentskills.io`），48 小时内被 Microsoft VS Code、OpenAI Codex、ChatGPT 跟进。Simon Willison 在 2025 年 10 月 16 日发布的博文 "Claude Skills are awesome, maybe a bigger deal than MCP" 中写道："I expect we'll see a Cambrian explosion in Skills which will make this year's MCP rush look pedestrian by comparison."核心机制是 **progressive disclosure**：启动时只加载每个 skill 的 name+description（约 20–50 tokens），匹配后才加载完整 SKILL.md，再按需读取子文件。

6. **Anthropic 2026 年 1 月 24 日把 `.claude/commands/` 并入 Skills**。Slash commands 文档被重定向到 Skills 页面，文档原文："Custom slash commands have been merged into skills. A file at `.claude/commands/review.md` and a skill at `.claude/skills/review/SKILL.md` both create `/review` and work the same way."

7. **Workflow 在两端发生分化**：
   - **AI 助手内部**：固定步骤的 "Commands/Workflows" 被 Skills 吸收（声明式、model-invoked）。
   - **生产编排侧**：LangGraph 在 **2025 年 10 月 22 日发布 1.0**（LangChain 官方 changelog："LangGraph 1.0 is the first stable major release in the durable agent framework space"），成为 LangChain 推荐的 agent 运行时；CrewAI 据 CEO João Moura 在 Insight Partners 的访谈表述 "now used by more than 60% of Fortune 500 companies"（其 2024 年 10 月 22 日的官方 A 轮新闻稿则用的是 "nearly half of the Fortune 500"，两者是不同时间点的表述）；Microsoft 把 AutoGen 与 Semantic Kernel 合并为 Agent Framework，2026 Q1 GA；Temporal、mcp-agent、Google ADK、OpenAI Agents SDK 各占生态位。
   - Anthropic 的 *Building Effective Agents*（作者 Erik Schluntz & Barry Zhang，2024 年 12 月 19 日发布）定义 workflow = predefined paths、agent = LLM 自主决定，被业界普遍引用为术语锚点。

8. **"agentic workflow"作为混合术语取代了纯 workflow 一词**。Kore.ai、G2、Gartner 多份 2026 报告都在用"agentic workflow"——形式上是工程化编排（带任务列表、检查点、人在回路），内核是 agent 自主推理。Gartner 高级总监分析师 Anushree Verma 在 2025 年 8 月的 *"The Future of Agentic AI in Enterprise Applications"* 中预测：到 2027 年 "one-third of the agentic AI implementations will use a combination of agents, with different skills for complex tasks within application and data environments."G2 *"2025 AI Agents Insights Report"*（2025 年 10 月 9 日发布，基于 1,035 名 B2B 决策者 2025 年 8 月在北美/EMEA/APAC 的调研）发现 "57% of companies have agents in production today."这不是 "workflow 死亡"，而是 workflow 被重新定义为"为 agent 而设计的可治理结构"。

---

## Details

### 一、Rules 的完整溯源

#### 1. Cursor：从 `.cursorrules` 到 Project Rules

- **2023 年**：Cursor 在项目根放一个 `.cursorrules` 单文件，纯 Markdown，每次 chat 都注入 prompt 头部，最初设计目标是替代"每次粘贴同样的栈说明、命名约定"的复读机式开发体验。
- **2025 年 1 月（Cursor v0.45）**：升级为 `.cursor/rules/*.mdc` 目录式 + YAML frontmatter（官方 changelog：`cursor.com/changelog/0-45-x`，原文 "Users can write several repository-level rules to disk in the .cursor/rules directory. The Agent will automatically choose which rule to follow"）。每个 `.mdc` 含 `description`、`globs`、`alwaysApply` 三个核心字段，分别对应四种触发：
  - **Always**：`alwaysApply: true`，每次请求都注入。
  - **Auto Attached**：当上下文中出现匹配 `globs` 的文件时自动加载。
  - **Agent Requested**：留 `description`，由 agent 自己判断是否相关，按需加载。
  - **Manual**：用 `@rule-name` 显式 @ 进来。
- **优先级**：Manual > Auto Attached > Agent Requested > Always；Team Rules（Business/Enterprise）> Project Rules > User Rules > Legacy `.cursorrules`。
- **token 成本意识**：社区一致建议 Always Apply 控制在 200 字以内；一篇基于 47K 行 TypeScript monorepo 的 30 天对比测试（rpdi.us）显示，Cursor 的 MDC 方案因 glob 作用域，比 Copilot 的全局 `copilot-instructions.md` 节省约 3.1× token（该测试仅一次单点对比，数据方向可信但倍数应谨慎引用）。

#### 2. Anthropic：CLAUDE.md + `.claude/rules/` + Skills

- **2025 年 2 月 24 日**：Claude Code 限量预览随 Claude 3.7 Sonnet 发布（Anthropic 官方："Today, we're empowering developers further by introducing Claude Code—our first agentic coding tool—in a limited research preview"），CLAUDE.md 作为根项目记忆文件即被引入；**5 月**随 Claude 4 GA。
- **官方建议 < 200 行**：HumanLayer 工程团队公开其根 CLAUDE.md "less than sixty lines"；TurboDocx 总结 "The recommended target is under 200 lines... The absolute ceiling is roughly 300 lines before Claude starts losing signal in the noise."原因：CLAUDE.md 每次会话都进 system prompt 区，过长不仅吃 token，更会让模型"忽略实际指令"——Anthropic 在最近的 Claude Code 文档中已加入指令告诉模型可以忽略明显不相关的 CLAUDE.md 段落，间接证实了"臃肿 CLAUDE.md 反而降低指令遵循度"这一观察。
- **进阶机制**：`.claude/rules/` 子目录的 markdown 文件与 CLAUDE.md 同优先级自动加载；`@path/to/file.md` 实现最深 5 级的递归引用，把"项目地图"放主文件、把"具体 SOP"按需 import。

#### 3. Windsurf

- 两层：**Global Rules**（`global_rules.md`，存于 `~/.codeium/windsurf/memories/`）与 **Workspace Rules**（`.windsurf/rules/*.md`）。
- 配合 **Memories**（Cascade agent 自动生成的会话长期记忆）和 **Workflows**（声明式自动化脚本）三件套。
- 现已新增 system-level 规则供企业 IT 强制下发；同时支持 AGENTS.md fallback。

#### 4. GitHub Copilot

- 仓库级：`.github/copilot-instructions.md`。
- 路径级（2025 年 7 月 23 日 GitHub Changelog 宣布）：`.github/instructions/*.instructions.md`，支持 YAML frontmatter 的 `applyTo` 字段。
- 2025 年 8 月 28 日起，Copilot Coding Agent 也支持 AGENTS.md、CLAUDE.md、GEMINI.md 等多源指令文件，优先级为 Personal > Repository > Organization。
- 社区资源：微软官方维护的 `github/awesome-copilot` 仓库整合 instructions、prompts、chat modes、skills 等多种自定义资源，2026 年中约 33.1k stars。

#### 5. Cline / Roo Code

- Cline 从单 `.clinerules` 文件演进到 `.clinerules/` 文件夹（v3.7.0），v3.13 加入可切换 popover UI；同时支持 AGENTS.md 作为 fallback。
- Roo Code 用 `.roo/rules/`（全局 `~/.roo/rules/`、工作区 `.roo/rules/`、按模式 `.roo/rules-{modeSlug}/`），社区也在 #5966 / #5967 推动 AGENTS.md 标准。

#### 6. Aider / Continue.dev

- Aider 用 `CONVENTIONS.md`，通过 `aider --read CONVENTIONS.md` 或 `.aider.conf.yml` 的 `read:` 字段加载，强调 read-only + prompt caching。社区已在 GitHub issue #4363 推动 AGENTS.md 作为推荐名。
- Continue.dev 用 `.continuerules`（同概念）。

#### 7. AGENTS.md 与 AAIF：跨厂商收敛

- OpenAI **2025 年 8 月**推出 AGENTS.md，"一个 Markdown 文件给 AI agent 提供项目级指令"。
- 至 **2025 年 12 月 9 日**，OpenAI 官方称已有 60,000+ 开源项目采用。
- 同日，OpenAI、Anthropic、Block 在 Linux Foundation 下成立 **Agentic AI Foundation (AAIF)**，分别捐出 AGENTS.md、MCP、goose；白金会员含 AWS、Microsoft、Google、Bloomberg、Cloudflare 等（Linux Foundation press release，2025 年 12 月 9 日）。

#### 8. 各家 Rules 机制对比表

| 工具 | 文件位置 | 触发方式 | 作用域 | 是否 model-invoked |
|---|---|---|---|---|
| Cursor (新) | `.cursor/rules/*.mdc` | Always / Glob / Agent Requested / Manual | 项目 + 子目录嵌套 | 部分（Agent Requested） |
| Claude Code | `CLAUDE.md` + `.claude/rules/` + `@imports` | 每次注入 + 递归 import | 全局/项目/子目录 | 否（恒载） |
| Windsurf | `global_rules.md` + `.windsurf/rules/*.md` | 始终或按上下文 | 全局/工作区/系统 | 部分 |
| GitHub Copilot | `.github/copilot-instructions.md` + `.instructions.md` | 全局注入 + applyTo glob | 仓库 | 否 |
| Cline | `.clinerules/` + 可切换 UI | 始终（开关控制） | 全局/工作区 | 否 |
| Roo Code | `.roo/rules/`（全局/工作区/模式） | 始终 | 多层 | 否 |
| Aider | `CONVENTIONS.md`（`--read`） | 显式加载 | 项目 | 否 |
| 跨厂商 | `AGENTS.md`（AAIF 标准） | 各家 fallback / 主源 | 项目（可嵌套） | 否 |

---

### 二、Rules 现在还流行吗？

**结论：流行，但用法收窄了。**

**仍在快速演进的证据**：
- `PatrickJS/awesome-cursorrules` 截至 2026 年中约 39.6k stars、3.4k forks。
- `github/awesome-copilot` 约 33.1k stars，由 Microsoft 官方维护。
- Cursor 仍在不断迭代 Project Rules、Team Rules、Memories 自动生成功能（其文档中 `/Generate Cursor Rules` 命令为内置）。
- Anthropic 在 Claude Code 中继续保留并优化 CLAUDE.md（包括与 Skills、subagent、plan mode 的协同）。
- AGENTS.md 通过 AAIF 完成跨厂商收敛，反而代表了 Rules 文件概念的胜利——只是从私有格式变成开放标准。

**用法收窄的证据**：
- **"放所有东西进去"已过时**：Anthropic、HumanLayer、TurboDocx、Ruben Hassid（Substack）等多个来源一致建议 CLAUDE.md **< 200 行**，根目录甚至可压到 60 行。原因是：长 CLAUDE.md 反而拉低指令遵循度，模型在长上下文里更难抓重点。
- **新打法是"只放不变事实"**：项目身份 (WHAT)、技术栈和构建/测试命令 (HOW)、不可变约束（"绝不能提交 secrets"）。所有"过程性 / 偶尔用到"的知识——SOP、模板、工作流——都迁移到 Skills 或 import 文件，用 progressive disclosure 按需加载。
- **Skills 没有取代 Rules，二者分工已经稳定**：
  - **Rules / CLAUDE.md = 恒载、静态、不变事实层**（每次会话都进 system prompt）。
  - **Skills = model-invoked、动态、过程性知识包**（只在 agent 判断相关时才加载）。
- **社区讨论趋势**：Reddit/X/Substack 2025 下半年到 2026 上半年的主流帖子都在讨论"如何精简 CLAUDE.md"、"哪些东西该迁移到 skill"、"为什么我的 rules 不生效（答案常是太长了）"——这是工具成熟的标志，不是衰退。

**Anthropic 是否在"淡化"CLAUDE.md？** 不是淡化，而是**重新定位**：CLAUDE.md 从"什么都往里塞的项目说明书"变成"启动会话时给 Claude 的 60–200 行简报"，而把"长内容、过程性知识、可执行脚本"迁移到 Skills。Anthropic 在 Claude Code 文档里明确把 Skills 作为"想要可复用 prompts/workflows 在主会话里运行"的推荐方案，把 subagents 作为"想要隔离上下文运行"的方案，而 CLAUDE.md 仍是默认的项目记忆——三者分工明确。

---

### 三、Workflow 理念是否在式微？

**结论：旧的"命令式 workflow"在式微，"agentic workflow"在崛起，整体不是消亡而是分化。**

#### 1. 命令式 workflow 被 Skills 吸收

- **2026 年 1 月 24 日**，Anthropic 把 Claude Code 的 slash commands 文档重定向到 Skills 页面，文档原文："Custom slash commands have been merged into skills. A file at `.claude/commands/review.md` and a skill at `.claude/skills/review/SKILL.md` both create `/review` and work the same way. Your existing .claude/commands/ files keep working. Skills add optional features: a directory for supporting files, frontmatter to control whether you or Claude invokes them, and the ability for Claude to load them automatically when relevant."已有的 `.claude/commands/` 仍然兼容，但官方建议新流程都写成 skill。
- Cursor 的旧 Commands、Windsurf 的 Workflows 也呈现同样轨迹：从"固定步骤"向"声明式 + model-invoked"靠拢。

#### 2. Anthropic 的 agents vs workflows 区分定义了术语

Anthropic **2024 年 12 月 19 日**发布 *Building Effective Agents*（作者 Erik Schluntz、Barry Zhang），核心区分被业界普遍接受：

- **Workflows** = "systems where LLMs and tools are orchestrated through predefined code paths"，predictable、可重复；
- **Agents** = "systems where LLMs dynamically direct their own processes and tool usage"，灵活、自主。

文章给出五种 workflow 模式（Prompt Chaining、Routing、Parallelization、Orchestrator-Workers、Evaluator-Optimizer）+ 一种 Agent 模式，并明确建议："finding the simplest solution possible, and only increasing complexity when needed"——大多数应用单 LLM call + retrieval 就够，能不上 agent 就别上。Simon Willison 评价这是 LLM 圈少见的"先给清晰定义再讨论"的文章。

#### 3. Agentic workflow 框架在生产侧爆发

- **LangGraph** 2025 年 10 月 22 日发 1.0（LangChain 官方 changelog："LangGraph 1.0 is the first stable major release in the durable agent framework space — a major milestone for production-ready AI systems"），成为 LangChain 推荐 agent 运行时，特点是 graph-based 状态机 + durable execution + human-in-the-loop。
- **CrewAI** 2024 年 10 月 22 日宣布 1800 万美元 A 轮（Globe Newswire / Insight Partners 表述为 "nearly half of the Fortune 500"），其 CEO João Moura 在 Insight Partners 的稍后访谈中表述为 "CrewAI is now used by more than 60% of Fortune 500 companies"。主打 role-based 多智能体协作。
- **Microsoft** 在 2025 年 10 月宣布把 AutoGen 与 Semantic Kernel 合并为 Microsoft Agent Framework，2026 Q1 GA。
- **Temporal** 提供 durable execution 后端，给长 running 工作流做容错。
- **OpenAI Agents SDK**（2025 年 3 月）、**Google ADK**（2025 年 4 月，含原生 A2A 协议）等也加入战局。

第三方对比测试（skywork.ai LangChain vs CrewAI guide 等 2025–2026 资料）显示：CrewAI 上手最快但 token 成本约为 LangGraph/LangChain 的 2–3×（在等价任务上）；LangGraph boilerplate 重但可控；Temporal/Pydantic AI/mcp-agent 在 durability 上最强。**这恰恰说明 workflow 没有死——它在生产侧从"prompt 链"演化成"带审计、回滚、容错的工程化编排"。**

#### 4. "Agentic workflow" 作为混合术语的兴起

Kore.ai 2026 年的分析把这个趋势讲得最直白：**"全自主 agent"在企业试点中暴露出不可预测、不可治理的问题；行业转向"agentic workflows"——结构化、有边界、可治理的多智能体协作系统**。Gartner 高级总监分析师 Anushree Verma 在 *"The Future of Agentic AI in Enterprise Applications"*（2025 年 8 月）中预测：到 2027 年 "one-third of the agentic AI implementations will use a combination of agents, with different skills for complex tasks within application and data environments."G2 *"2025 AI Agents Insights Report"*（2025 年 10 月 9 日发布，基于 1,035 名 B2B 决策者 2025 年 8 月的调研）发现 "57% of companies have agents in production today"。这些都指向同一个方向：**workflow ≠ 命令式硬编码，而是给 agent 提供的"可治理结构"**。

#### 5. Subagents、orchestrator-worker、plan-execute 算不算 workflow 的新形态？

算。它们正是 Anthropic 那五种 workflow 模式在 2025–2026 的生产化实现：

- **Subagents**：Claude Code 原生支持，每个子 agent 独立 context window，主 agent 通过 Task tool 委派——对应 orchestrator-workers 模式。
- **Agent Teams**（Claude Code 实验性，需 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`）：通过共享任务列表 + 文件锁实现 peer-to-peer 协作，更接近 kanban 而非命令链。
- **Plan-Execute**：Claude Code 的 plan mode、Cursor 的 Composer 都在内化"先规划再执行"的两阶段模式。

所以**正确的说法是：workflow 概念被一分为二**——
- **轻量端**：被 Skills 吸收，进入 agent 主上下文，model 自决何时调用。
- **重量端**：进化成 agentic orchestration framework，做 graph、durability、observability、governance。
- **中间地带（固定步骤 slash command）**：被两端挤压，正在消亡。

---

### 四、Rules / Skills / Commands / Workflow / Agent 分工总图（2026 年）

| 概念 | 何时加载 | 谁来决定 | 形式 | 典型规模 | 关键场景 |
|---|---|---|---|---|---|
| **Rules / CLAUDE.md** | 每次会话注入 | 框架自动 | 静态 markdown | < 200 行 | 不变事实：栈、命名、不可越界约束 |
| **Skills** | 启动加载元数据，匹配时加载主体 | Model（progressive disclosure） | 文件夹 + SKILL.md + 可选脚本 | 单 skill < 500 tokens 描述，主体不限 | 过程性知识：如何填表、如何渲染 PDF、SwiftUI/SwiftData 最佳实践 |
| **Commands**（旧） | 用户 `/cmd` 显式触发 | 人 | 单 markdown | 一两屏 | 已被 Skills 取代（Anthropic 已合并） |
| **Workflow**（旧/IDE 内） | 固定步骤序列 | 人 | YAML/markdown | — | 正在消亡 |
| **Agentic Workflow**（新/生产） | 框架运行时编排 | LLM + 编排器混合 | 代码 / 图 / 任务列表 | 工程级 | 多步、跨服务、需要 durability/审计 |
| **Agent** | — | LLM 自主决策路径 | 主 LLM + tools/skills/subagents | — | 开放性问题、不可预测步数 |

---

### 五、对独立 iOS 开发者（中国，Claude Code + Claude Max，SwiftUI/SwiftData 应用 SnapDrill）的实操建议

> **总原则**：把 CLAUDE.md 当"项目身份证"，把 Skills 当"专业技能包"，把 subagents 当"独立上下文工人"，**不要写自定义 workflow**——除非你已经反复执行同一个 5+ 步流程超过一周。

#### 1. 应该放进 CLAUDE.md 的（控制在 60–150 行）

```markdown
# SnapDrill

## What
独立 iOS app（SwiftUI + SwiftData，iOS 17+），中文/英文双语，主要功能是 [一句话]。
单人项目，App Store 已上架/未上架。

## Stack
- Swift 6 严格并发；SwiftUI；SwiftData（不用 Core Data）
- Xcode 16+；最低 iOS 17.0
- 测试：Swift Testing（不是 XCTest）
- CI：GitHub Actions（如果有）

## Commands
- `xcodebuild -scheme SnapDrill -destination 'platform=iOS Simulator,name=iPhone 15' build`
- `xcodebuild test -scheme SnapDrill -destination '...'`
- `swift format --in-place --recursive Sources/`

## Project map
- `App/` — @main、Scene、根 ContentView
- `Features/<FeatureName>/` — 每个功能一个文件夹，View + ViewModel + Model
- `Models/` — SwiftData @Model
- `Shared/` — 复用组件、扩展

## Hard rules
- 不要在 SwiftData @Model 里用容易触发 Xcode 16 编译器崩溃的属性形式（参见 .claude/rules/swiftdata-gotchas.md）
- 永远不提交 .xcuserdata, ~/.config, secrets
- UI 字符串走 String Catalog (.xcstrings)，不要硬编码

## When unsure
- Read .claude/rules/swiftdata-gotchas.md
- Or invoke the swiftui-pro skill
```

**禁忌**：不要把 SwiftUI 的所有最佳实践都塞进来；不要写"how to handle navigation"——那是 skill 该干的事。

#### 2. 应该装进 Skills 的（用社区已有的，不要自己造轮子）

强烈推荐安装以下社区 skill（Paul Hudson `twostraws` 维护的两个仓库是当前 SwiftUI/SwiftData 领域最权威的开源 skill，覆盖 SwiftUI、SwiftData、Swift Concurrency、Swift Testing）：

```bash
# 在项目根
npx skills add https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro

# 或手动放到 .claude/skills/
mkdir -p .claude/skills
cd .claude/skills
git clone https://github.com/twostraws/swift-agent-skills
```

- `twostraws/swiftui-agent-skill`（Paul Hudson，hackingwithswift.com）："An agent skill that helps AI coding assistants write smarter, simpler, and more modern SwiftUI… It uses the Agent Skills format, so it works smoothly with Claude Code, Codex, Gemini, Cursor, and more."
- `twostraws/swift-agent-skills`："A curated directory of open-source AI agent skills for Swift and Apple platform development"（含 SwiftData 子目录）。
- `rshankras/claude-code-apple-skills`：iOS、macOS、iPadOS 通用，含 `swiftui/` 与 `macos/SwiftData` 等子目录。
- `patrickserrano/ios-swift-skills`（claudepluginhub.com 收录）：含 iOS Swift/SwiftUI 与发版 workflow skill。
- `keskinonur/claude-code-ios-dev-guide`：PRD-driven workflow + extended thinking + plan mode，含 MVVM/MVC/VIPER/Clean Architecture、Swift Concurrency（actors、async/await、Sendable）、SwiftUI navigation、DI、SwiftData/Core Data 的 subagent 与 CLAUDE.md 示例。

**自己加一两个本项目专属 skill**（在 `.claude/skills/snapdrill-*/SKILL.md`）：
- `snapdrill-feature-scaffold`：描述"创建新功能模块时的目录约定 + 模板文件"，触发词包括 "create new feature"、"add screen"。
- `snapdrill-swiftdata-migration`：描述"修改 @Model 时如何写 schema migration plan"，仅在涉及 `@Model` 修改时触发。

#### 3. 什么时候才需要写"workflow"

**几乎不需要**。如果你发现自己每周重复同一个 5+ 步流程超过 3 次，再考虑把它写成 skill（注意：是 skill，不是 command）。最常见的两种值得写：

- **App Store 发版 skill**：bump version → 跑 tests → archive → 上传 TestFlight → 写 release notes（参考 `patrickserrano/ios-swift-skills` 的发版 workflow）。
- **新功能 scaffold skill**：一条 prompt 创建 Feature 文件夹、占位 View+ViewModel+Tests。

**不要**给"每次都让 Claude 做 X"写自定义 workflow——这种东西应该作为约束放进 CLAUDE.md，或作为 progressive-disclosure 的 skill。

#### 4. 何时召唤 subagent

当你做"跨层重构"时（例如改 SwiftData schema + ViewModel + 所有调用方），用 Claude Code 的 subagent 把"读旧代码"、"改 model"、"改 view"分别交给独立上下文的 sub-agent，避免主上下文 attention dilution。Claude Code 官方文档明确说："Subagents cannot spawn other subagents. If your workflow requires nested delegation, use Skills or chain subagents from the main conversation."

#### 5. AGENTS.md 要不要写

**建议写一个最小化 AGENTS.md**，内容与 CLAUDE.md 90% 重叠（建议用 symlink 或者一段 shell 脚本同步），这样：
- 哪天试用 Codex CLI、Cursor、Windsurf 都能直接 work；
- 跨工具的项目说明书只维护一份；
- 跟上 AAIF 的开放标准趋势，避免被单一工具锁定。

#### 6. Claude Max 使用层面的几条具体省钱建议（结合 2026 年现状）

- **CLAUDE.md 一定要短**（< 150 行）。Claude Max 的 5 小时窗口 + 周配额在 2026 年明显收紧（多个 Substack 抱怨贴提到 cache TTL 已从 1 小时降至 5 分钟），臃肿的项目记忆每次都吃 token。
- **优先用 Sonnet**，仅在架构决策、复杂重构、调 bug 调到 4 次还没解决时切 Opus。
- **善用 `/compact` 和 `/clear`**，长会话一定要主动压缩。
- **把"模型从 Anthropic 训练数据里学不到"的东西放 Skills**（你的特殊业务术语、SnapDrill 特有约定），让 progressive disclosure 帮你省 token。
- 在国内访问 Anthropic API/Claude Code 服务的网络稳定性问题不在本报告范围，但请留意 Claude Max 的"按你所在地区计费/限速"政策。

---

## Recommendations

按优先级分阶段：

**本周做（< 2 小时）**：
1. 把现有 CLAUDE.md 压到 < 150 行，只留 What / Stack / Commands / Project map / Hard rules 五段。
2. 在项目根加一个 AGENTS.md，与 CLAUDE.md 同步内容（pre-commit hook 自动复制）。
3. 安装 `twostraws/swiftui-agent-skill` 到 `.claude/skills/`。

**本月做**：
4. 把"过去一个月在 Claude Code 里反复纠正的同一类错误"列成 3–5 条，每条决定是放进 CLAUDE.md `Hard rules`（如果是不变约束）还是写成专属 skill（如果是过程性）。
5. 给 SnapDrill 写一个 `swiftdata-gotchas.md`（如果有），用 `@.claude/rules/swiftdata-gotchas.md` 在 CLAUDE.md 里 import，而不是直接写进去。
6. 试用一次 Claude Code 的 subagent / plan mode 做一次跨模块重构，记录哪些上下文应该隔离。

**阈值与变化触发条件**：
- **当 CLAUDE.md 超过 200 行**：立即拆出至少一半到 `.claude/rules/*.md` 或 `.claude/skills/`。
- **当某个 prompt 在两周内重复 3 次以上**：写成 skill。
- **当一次任务需要超过 30 步、跨多个文件**：考虑 subagent / plan mode，而不是一个长 prompt。
- **当 Claude Code 限额变化或 Anthropic 政策更新**：重新评估 Opus/Sonnet 比例和 CLAUDE.md 长度。
- **当你开始多人协作或开第二个产品线**：把 CLAUDE.md / AGENTS.md / Skills 上 git，团队共享。

---

## Caveats

1. **"workflow 式微"是一个有歧义的命题**：在"AI IDE 内的命令式 slash workflow"层面，是真在式微；在"生产侧的 agentic orchestration framework"层面，反而是历史最旺。本报告把两层都展开了，结论不能跨层套用。
2. **Skills 还在快速演化**：2025 年 10 月 16 日发布，12 月 18 日开源，2026 年 1 月 24 日吞并 commands——半年内核心定位连续调整，本报告基于截至 2026 年 5 月的官方文档与社区共识，未来半年仍可能继续重新洗牌。
3. **token 成本对比数据来自单一来源**（rpdi.us 一篇 47K 行 monorepo 对比测试），结论方向可信但具体倍数（3.1×）仅供参考；CrewAI vs LangGraph 的 "2–3×" token 成本也是综合多份资料的区间值，无单一权威 benchmark。
4. **AAIF 还很年轻**：2025 年 12 月才成立，"AGENTS.md 是事实标准"目前更多是采用数和厂商背书的产物，治理细节仍在制定中。
5. **Anthropic 在 2026 年 2–3 月收紧了 Max 配额并把 cache TTL 从 1 小时降到 5 分钟**（来自 Substack 多个抱怨贴），独立开发者需要重新评估 Pro vs Max 的性价比；这点超出本研究主问题但影响实际选型。
6. **CrewAI 的 "60% Fortune 500" 说法**来自其 CEO 在 Insight Partners 访谈中的表述；其 2024 年 10 月 22 日官方 A 轮新闻稿用的是 "nearly half of the Fortune 500"，二者是不同时间点的不同口径，应警惕单一数字被反复转写后失真。
7. **本报告对 SnapDrill 的建议基于"独立 iOS 开发者 + Claude Max + SwiftUI/SwiftData"的画像**；如果你的项目结构、团队规模、或网络环境与此不同，请相应调整 CLAUDE.md / Skills / subagent 的分工比例。
8. **某些社区博客文章（特别是 Medium / Substack / 自助站）在引用统计数字时倾向于乐观化**（如 "63% 更快上手"、"41% 减少 review"），本报告对此类数字保持距离，只引用厂商官方或多方一致的事实。