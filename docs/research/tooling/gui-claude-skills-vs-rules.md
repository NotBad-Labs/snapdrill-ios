# Claude Skills vs. 传统 Rules 文件：一场关于"按需加载能力"的范式迁移

## TL;DR

- **Skills 不取代 CLAUDE.md / .cursorrules，而是把 rules 文件里被"职责过载"的一类内容——程序化的、多步骤的、任务触发的工作流——剥离出来，重组成可按需加载、可携带脚本与资源的能力包。** Anthropic 自己的官方指引就是这个意思（verbatim, code.claude.com）："Put it in CLAUDE.md if Claude should always know it… Put it in a skill if it's reference material Claude needs sometimes or a workflow you trigger with `/<name>`"，并明确建议 "Keep CLAUDE.md under 200 lines"。
- **行业在 90 天内完成了一次极罕见的"标准化收敛"**：2025 年 10 月 16 日 Anthropic 推出 Agent Skills，12 月 18 日开源为 agentskills.io 规范，48 小时内 Microsoft（VS Code / Copilot）、OpenAI（Codex CLI、ChatGPT）、Cursor（2.4 版本，2026 年 1 月）、Windsurf、Goose、Amp、OpenCode 等全部支持同一份 SKILL.md。`anthropics/skills` 仓库到 2026 年 5 月已达约 117k stars / 13.4k forks。Skills 与 MCP 不是替代关系而是分层关系——Anthropic 官方说法："MCP connects Claude to data; Skills teach Claude what to do with that data。"
- **对独立 iOS / Swift 开发者用 Claude Code 的实际建议**：把 CLAUDE.md 当作"项目元数据"（技术栈、命令、不可逾越的红线），Skills 当作"工具箱"（SwiftUI 重构、XCTest 生成、App Store 文案、Liquid Glass 模式等），MCP 当作"接口"（XcodeBuildMCP、Linear、TestFlight）。已存在多个开源的 iOS skill 集合（rshankras/claude-code-apple-skills 跨 100+ skill、patrickserrano/ios-swift-skills、hmohamed01/swift-development），可以直接 fork 而不是从零写。但要警惕第三方 skill 的供应链风险——Snyk 在 2026 年 2 月 5 日发布的 ToxicSkills 报告对来自 ClawHub 与 skills.sh 的 3,984 个公共 skill 的审计发现 13.4%（534 个）含严重安全问题，36.82%（1,467 个）含至少一个安全问题，76 个为确认恶意 payload。

---

## Key Findings

### 1. 概念差异是"加载时机 + 内容形态"两个维度

| 维度 | CLAUDE.md / .cursorrules / Windsurf rules | Agent Skills (SKILL.md) |
|---|---|---|
| **加载时机** | 会话开始时 100% 注入 system prompt | 启动时只注入 frontmatter（name + description，约 50–100 tokens/skill）；body 在模型判定相关时才读入 |
| **内容形态** | 纯 Markdown 静态指令 | 目录：SKILL.md + 可选 `scripts/`、`references/`、`assets/`（可执行代码、模板、数据） |
| **触发模型** | 永久常驻、被动 | model-invoked：模型根据 description 自主决定调用；也可显式 `/skill-name` |
| **跨工具可移植性** | 工具专属（Cursor 的 .cursorrules 在 Claude Code 不工作） | 同一份 SKILL.md 在 32+ 工具运行（Claude Code、Codex、Cursor 2.4+、VS Code、Gemini CLI、Junie、Kiro、Goose、Amp 等） |
| **多实例** | 一个项目一份（Cursor 支持 globs 分片） | 一个项目可装数百个 skill，因为不进 context |
| **作用范围** | "Claude 应永远知道这件事" | "Claude 在做某类任务时该用这套流程" |

Anthropic 在 `code.claude.com/docs/en/features-overview` 给出了一张总览表（verbatim）：

| Feature | When it loads | What loads | Context cost |
|---|---|---|---|
| CLAUDE.md | Session start | Full content | Every request |
| Skills | Session start + when used | Descriptions at start, full content when used | Low (descriptions every request) |
| MCP servers | Session start | Tool names; full schemas on demand | Low until a tool is used |
| Subagents | When spawned | Fresh context with specified skills | Isolated from main session |
| Hooks | On trigger | Nothing (runs externally) | Zero |

这张表清晰回答了"是否取代 CLAUDE.md"的疑问：不是。它们解决不同问题的不同层次。

### 2. progressive disclosure 是核心机制创新，也是和 MCP 最大的设计差异

Anthropic 工程博客（verbatim）："At startup, the agent pre-loads the name and description of every installed skill into its system prompt. This metadata is the first level of progressive disclosure: it provides just enough information for Claude to know when each skill should be used without loading all of it into context."

三级渐进式加载（anthropics/skills 文档）：

1. **Level 1 — Frontmatter only**：name + description，~50–100 tokens/skill，启动时全部加载
2. **Level 2 — SKILL.md body**：模型判定相关时读入（建议 < 500 lines / < 5,000 words）
3. **Level 3 — Bundled files**：scripts/、references/、assets/ 仅在 body 显式引用时按需加载

Dotzlaw 给出了一个量化对比：8 个 skill 的项目启动时只占 ~500 tokens（而非传统全转储 CLAUDE.md 的 70,000 tokens），即 ~140× 的效率差异。这就是为什么 Simon Willison 在 2025 年 10 月 16 日（发布当天）写下 "Claude Skills are awesome, maybe a bigger deal than MCP"——传统 MCP 把所有 tool schema 全部塞进 context，一个有 30+ tool 的 MCP server 就能吃掉几千 token。MCP 在 2026 年 1 月加入了类似的"progressive discovery"机制，某种程度上承认了 Skills 的设计胜出。

### 3. 行业反响与标准化速度史无前例

时间线（主要来自 paperclipped.de、Simon Willison、VentureBeat 采访 Anthropic PM Mahesh Murag）：

- **2025-09-22**：`anthropics/skills` 仓库创建。Simon Willison 在 2025 年 10 月 10 日（官方发布前 6 天）已经"逆向工程"出该机制——他在 10 月 16 日的发布文里写道（verbatim）："I inadvertently preempted their announcement of this feature when I reverse engineered and wrote about it last Friday!"
- **2025-10-16**：Anthropic 正式发布 Agent Skills，作为 Claude.ai / Claude Code / API 三端能力
- **2025-12-09**：Linux Foundation 成立 Agentic AI Foundation（AAIF）。据 LF 官方新闻稿，AAIF 的 platinum 创始成员有 8 家（AWS、Anthropic、Block、Bloomberg、Cloudflare、Google、Microsoft、OpenAI），其中 Anthropic、OpenAI、Block 分别贡献了 MCP、AGENTS.md、goose 作为创始项目
- **2025-12-12**：Simon Willison 发现 OpenAI Codex CLI 已悄悄合并 "feat: experimental support for skills.md" PR；Elias Judin 发现 ChatGPT 代码解释器中存在 `/home/oai/skills` 目录
- **2025-12-18**：Anthropic 在 agentskills.io 发布开放标准 + 参考 SDK + 企业管理功能；同时上线 10 个合作伙伴目录（Atlassian、Canva、Cloudflare、Figma、Notion、Ramp、Sentry、Stripe、Zapier、Box）
- **2025-12-18 + 48h**：Microsoft 将 Agent Skills 整合进 VS Code / Copilot；OpenAI 在 ChatGPT 和 Codex CLI 添加支持；`anthropics/skills` 突破 20k stars
- **2025-12-19**：Simon Willison 写下对开放标准的评价（verbatim, simonwillison.net/2025/Dec/19/agent-skills/）："It is a deliciously tiny specification - you can read the entire thing in just a few minutes. It's also quite heavily under-specified."
- **2026-01**：Cursor 2.4 发布 Skills 支持。官方 changelog（verbatim）："Compared to always-on, declarative rules, skills are better for dynamic context discovery and procedural 'how-to' instructions"
- **2026-01-20**：Vercel 上线 skills.sh 市场——据 termdock.com 与 JP Caparas 的报道，首日发布的 `vercel-react-best-practices` skill 在六小时内即冲到约 20,900 次安装
- **2026-02-05**：Snyk 发布 ToxicSkills 审计，扫描 3,984 个 skill，13.4% 含严重问题
- **2026-02-11**：Anthropic 把 Skills 加入 Claude Free Plan
- **2026-03**：agentskills.io 列出 32 个适配工具，包括 Google Gemini CLI、JetBrains Junie、AWS Kiro、Block Goose、Sourcegraph Amp、Snowflake、Databricks、ByteDance TRAE、Mistral AI、Spring AI
- **2026-05-18（当前）**：`anthropics/skills` 约 117k stars / 13.4k forks / 196 open issues / 493 PRs；`anthropics/knowledge-work-plugins` 约 12.3k stars

90 天 32 工具的采纳速度，在开发者工具历史上罕见。对比：gRPC、OpenTelemetry、LSP 都用了 1–3 年才达到这个跨厂商支持范围。

### 4. 背后逻辑：Rules 文件被"职责过载"，Skills 解决三件事

**职责过载**：开发者社区把 CLAUDE.md / .cursorrules 塞了三类东西——(a) 项目元数据 ("we use Tailwind")，(b) 风格约束 ("never use any")，(c) 流程性知识 ("how to write a PR review")。前两类适合常驻，(c) 不适合——它每次会话都消耗 context 即使不被用，且没法绑定脚本。

**Skills 解决三件事**：

1. **Context 经济**：Dotzlaw 测算 8 skill 项目从 70k → 500 tokens 启动开销，140× 效率提升
2. **可组合性**：多 skill 可以并行加载、协同；Anthropic 文档："Claude can load multiple skills simultaneously"
3. **可携带的可执行性**：skill 可以 bundle Python/Bash 脚本；Claude 用 bash 执行而不读源码进 context（一个 200 行的 Python 风险计算脚本，直接执行只产生 3 行输出 token，而读源码要 ~2,000 token）

Anthropic 官方判定准则（verbatim, code.claude.com）："Create a skill when you keep pasting the same instructions, checklist, or multi-step procedure into chat, or when **a section of CLAUDE.md has grown into a procedure rather than a fact**."

### 5. Skills 与 MCP：不是竞争，是分层

LlamaIndex 的总结很精炼：MCP tool 是一次 "API call, clear input/output"；Skill 是 "自然语言指令, LLM 解释执行"。换言之：

- **MCP = the verbs / actions**（能做什么，确定性 API 调用，有 auth）
- **Skills = the recipes / playbooks**（该怎么做，何时做，组合什么）

Anthropic 官方表述（claude.com/blog/skills-explained, verbatim）："**MCP connects Claude to data; Skills teach Claude what to do with that data.** Use both together: MCP for connectivity, Skills for procedural knowledge."

Speakeasy 工程团队基于一年 MCP 部署经验补充：在企业场景下两者不可互相替代——"Credentials have to live somewhere. In the sandbox model, the agent needs raw API keys… An MCP server handles auth server-side. The agent never sees the credentials." Skills 在认证、审计、版本化上仍然弱于 MCP。Maxim Blog 的判断："Skills didn't eliminate MCP. They pushed it down the stack" ——MCP 不再充当所有外部访问的边界，而是退守到需要持久化、auth、企业 SLA 的场景。

Hacker News 上有一条对立观点值得记录（comment id 45607117）："I highly doubt we'll be talking about MCP next year. It is a pretty bad spec but we had to start somewhere." 这是少数派——主流共识是互补。

### 6. 安全：Skills 是"代码，不是文本"

Snyk 2026-02-05 发布的 ToxicSkills 审计是迄今最系统的研究：

- 扫描范围：ClawHub 和 skills.sh 上 **3,984 个公共 skill**
- **13.4%（534 个）** 含严重安全问题（恶意软件、prompt injection、暴露 secrets）
- **36.82%（1,467 个）** 含至少一个安全问题
- 确认 **76 个恶意 payload**（凭证窃取、后门、数据外泄）
- 8 个恶意 skill 在 Snyk 披露时仍在 ClawHub 在线
- **91% 的恶意 skill 同时使用 prompt injection + 传统 malware**，绕过 AI 安全机制和传统扫描器

Mobb.ai 后续做了更大规模扫描（22,511 个 skill 覆盖 skills.sh、ClawHub、GitHub、Tessl），发现 140,963 个安全发现。最具体的案例是 `flyingtimes/podcast-using-skill` 仓库——一个 `.claude/settings.json` 把 Anthropic API 端点重定向到 BigModel.cn，把用户所有上下文静默送到第三方服务器。

OWASP 2026 年发布了 Agentic Skills Top 10 项目，Check Point Research 披露了 Claude Code 的两个 CVE（CVE-2025-59536 CVSS 8.7、CVE-2026-21852 CVSS 5.3），都是"打开未受信任仓库即可触发 RCE"的级别。Vercel skills.sh 集成了 Gen / Socket / Snyk 三方扫描；Tessl 是唯一在客户端阻塞高危安装的注册表；ClawHub 只标记不阻止。

**结论：Skills 是 npm 早期阶段的供应链问题。** 任何 production 使用必须用 Snyk Agent Scan 等工具扫描，并把 skill 当 dependency 管理（owner、版本、review schedule）。

### 7. Claude Code 自带 skills 已是核心交互方式

截至 2026 年 5 月，Claude Code bundled skills（官方文档 code.claude.com/docs/en/skills 与 /commands）：

- `/simplify [focus]` — 并行 3 个 review 子代理，审视最近改动文件并修复（verbatim: "Review your recently changed files for code reuse, quality, and efficiency issues, then fix them. Spawns three review agents in parallel"）
- `/batch <instruction>` — 将大型变更拆成 5–30 个独立单元，每个起一个 git worktree 后台 subagent（verbatim: "orchestrate large-scale changes across a codebase in parallel… spawns one background subagent per unit in an isolated git worktree"）
- `/debug [description]` — 启用调试日志并分析问题
- `/loop [interval] [prompt]` — 周期性运行 prompt
- `/claude-api [migrate|managed-agents-onboard]` — 加载 Anthropic API 文档与代码迁移
- `/fewer-permission-prompts` — 扫描 transcript 自动构建权限白名单

值得注意的产品决策：Anthropic 把 `.claude/commands/` 和 `.claude/skills/` 合并（verbatim, code.claude.com）："Custom commands have been merged into skills. A file at `.claude/commands/deploy.md` and a skill at `.claude/skills/deploy/SKILL.md` both create `/deploy` and work the same way." 这是产品层面把"命令"和"能力"统一为同一抽象的信号——slash commands 不再是独立的扩展机制。

### 8. 生态指标（2026 年 5 月 18 日）

- **anthropics/skills**：~117k stars / ~13.4k forks / 196 open issues / 493 PRs（自 2025 年 10 月发布 7 个月内）
- **anthropics/skills 官方示例 skills**：algorithmic-art、brand-guidelines、canvas-design、claude-api、doc-coauthoring、docx、frontend-design、internal-comms、mcp-builder、pdf、pptx、skill-creator、slack-gif-creator、theme-factory、web-artifacts-builder、webapp-testing、xlsx
- **anthropics/knowledge-work-plugins**：~12.3k stars
- **第三方聚合站**：SkillsMP 声称 1.2M+ skill（含全网抓取，真实独立 skill 数远少）；Vercel 的 skills.sh 是最规范的一个，启动当天 `vercel-react-best-practices` 即达约 20,900 安装；agensi.io、claudeskills.info、kissmyskills.com、ClawHub 等多个市场
- **第三方 awesome 仓库**：travisvn/awesome-claude-skills、alirezarezvani/claude-skills（~5,200 stars / 248 skills）
- **iOS / Swift 子生态**：hmohamed01/swift-development、keskinonur/claude-code-ios-dev-guide、patrickserrano/ios-swift-skills、rshankras/claude-code-apple-skills（后者含 100+ skill，跨 iOS/macOS/watchOS/visionOS、SwiftUI、Apple Intelligence、Liquid Glass、App Store 优化）

### 9. 对独立 iOS 开发者的实际工作流影响

如果你在用 Claude Code 做中小型 Swift 项目，基于 Anthropic 官方指引和实际生态：

**应该放进 CLAUDE.md（≤ 200 行）**：
- 项目元数据："iOS 17+，SwiftUI，The Composable Architecture，deploy via Fastlane"
- 不可逾越规则："never use force-unwrap in production code"，"always use @MainActor for ViewModels"
- 构建命令：`xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15'`
- 项目结构地图："Features/ 下每个目录是独立 module"

**应该是 Skill**：
- `swift-concurrency-expert`：async / await / actor 重构（patrickserrano 仓库已有）
- `swiftui-view-refactor`：长 View 拆分成 sub-views
- `xctest-generator`：给已写完的 ViewModel 生成 XCTest / Swift Testing
- `appstore-rejection-handler`：拿 App Review 拒绝信生成回复 + 修复 plan（rshankras 仓库）
- `liquid-glass-migration`：iOS 26 Liquid Glass UI 适配
- `release-app-store-changelog`：从 git log 生成 ASO 文案
- `swiftlint-fix`：跑 swiftlint + 自动修复（Allowed-tools: Bash(swiftlint *), Bash(swift-format *)）

**应该是 MCP 而非 Skill**：
- XcodeBuildMCP（实时 simulator 控制、log 抓取）
- App Store Connect API（需要 auth + 实时数据）
- TestFlight 分发
- Linear / GitHub Issues

**应该用 subagent**：
- 当你要 Claude 读 50+ 文件做 codebase audit，你只想要结论时

**操作步骤建议**：

1. 把现有 CLAUDE.md 用 "In this project…" / "When [task]…" 做分类，前者留下，后者搬出
2. `git clone https://github.com/rshankras/claude-code-apple-skills && cp -r skills/* ~/.claude/skills/` 作为基础集
3. 在装新 skill 前跑 `uvx snyk-agent-scan@latest <skill-path>` 或至少手动 review SKILL.md
4. 用 `skill-creator` skill 把你重复 3 次以上的 prompt 沉淀成自己的 skill，提交到 `.claude/skills/` 让团队 / 未来项目复用

---

## Details

### 关于 progressive disclosure 的一个 bug 与现实

GitHub Issue anthropics/claude-code#14882 报告：在某些插件场景下，skill 的完整 body 会在启动时被加载而非仅 frontmatter，导致 5+ 个插件可以吃掉 50k+ token。这说明 progressive disclosure 是设计目标而非每个 host 实现都严格遵守。Codex CLI 官方文档明确给了一个保护机制（verbatim）："this list is capped at roughly 2% of the model's context window, or 8,000 characters when the context window is unknown. If many skills are installed, Codex shortens skill descriptions first. For very large skill sets, some skills may be omitted from the initial list."

### 关于 Anthropic 的标准化策略

Anthropic 把 Agent Skills 开源、捐赠到 Linux Foundation 旗下的 Agentic AI Foundation（AAIF），复制了 MCP 的剧本。VentureBeat 引述产品经理 Mahesh Murag（verbatim）："We're launching Agent Skills as an independent open standard with a specification and reference SDK available at https://agentskills.io. Microsoft has already adopted Agent Skills within VS Code and GitHub; so have popular coding agents like Cursor, Goose, Amp, OpenCode, and more." 关于商业模式他说："Partners who build skills for the directory do so to enhance how Claude works with their platforms. It's a mutually beneficial ecosystem relationship similar to MCP connector partnerships. There are no revenue-sharing arrangements at this time."

这是教科书级的"开放标准换生态主导权"策略——Anthropic 在 MCP 上已经证明过一次，Skills 是第二次。

### 三大产品面对 Skills 的不同呈现

- **Claude.ai（web / desktop apps）**：用户在设置面板里开关，Pro / Max / Team / Enterprise 可用，内置 skill-creator 引导式创建，无需写文件；企业管理员可中央 provisioning
- **Claude Code**：filesystem-native，`.claude/skills/<name>/SKILL.md` 项目级或 `~/.claude/skills/` 用户级；支持 `allowed-tools`、`disable-model-invocation`、`context: fork` 等扩展字段
- **API（`/v1/skills` endpoint）**：程序化上传 / 调用，需要 beta header `code-execution-2025-08-25`；内置 pptx / xlsx / docx / pdf 文档生成 skill，这些 skill 实际上就是 9 月发布的 Claude 文档创建能力的实现（Simon Willison 在反向工程过程中证实）

### Cursor / Windsurf / 其它 IDE 的对比

- **Cursor 2.4（2026-01）**：同时保留 `.cursor/rules/` 和 `.cursor/skills/<name>/SKILL.md`，官方明确 "Rules guide. Skills do. Commands trigger"。Skills 自动注册到 `/` 菜单。Cursor 自家文档建议 rules 用于 "static context that applies to every conversation"，skills 用于 "dynamic context discovery and procedural how-to instructions"
- **Windsurf**：`.windsurf/skills/<name>/SKILL.md`，Cascade 自动 progressive disclosure；同时保留 Rules、Memories、Workflows 三种机制（Skills 由 Workflow 调用，Workflow 由 Rules 约束）
- **Codex CLI**：`~/.codex/skills/`，`--enable skills` 启用，2% context budget 上限
- **GitHub Copilot**：VS Code 集成，无原生自动发现（需要在 instructions 文件里手动建 catalog table）——这是采纳速度最慢、最不完整的一家
- **Cline / Continue.dev**：未见原生 SKILL.md 支持公告（截至 2026-05），但因为是开源，社区改造门槛低

### Anthropic 自己怎么定位 Skills vs CLAUDE.md（再次）

Anthropic 官方功能总览页（verbatim）给出了一个判断流程表：

| Trigger | Add |
|---|---|
| Claude gets a convention or command wrong twice | CLAUDE.md |
| You keep typing the same prompt to start a task | user-invocable skill |
| You paste the same playbook for the third time | skill |
| You keep copying data from a browser tab Claude can't see | MCP server |
| A side task floods your conversation with output | subagent |
| You want something to happen every time without asking | hook |
| A second repository needs the same setup | plugin |

这套准则比社区任何一篇博客都更清晰——它就是 Anthropic 期望开发者建立的心智模型。

---

## Recommendations（针对独立 iOS 开发者）

### 立即执行（第 1 周）

1. **审计现有 CLAUDE.md**：用 "In this project…" 与 "When doing X…" 两个测试句把内容分类。前者留下，后者迁移到 skill。目标：CLAUDE.md 控制在 200 行以内
2. **装一个基础 Swift skill 集**：推荐 `git clone https://github.com/rshankras/claude-code-apple-skills` 或 `keskinonur/claude-code-ios-dev-guide`，但在装之前用 `uvx snyk-agent-scan@latest <path>` 扫一遍
3. **启用 bundled skills 习惯**：每次大改动后跑 `/simplify`，大重构用 `/batch`，记不住的 API 用 `/claude-api`

### 中期（1–4 周）

4. **沉淀个人 skill 库**：用内置 `skill-creator` 把你重复 3+ 次的 prompt（App Store 拒绝回复、ViewModel test scaffold、SwiftLint 规则解释等）沉淀。放在 `~/.claude/skills/` 跨项目复用
5. **MCP 互补**：装 XcodeBuildMCP（build / test / simulator）、GitHub MCP（issue / PR）、可选 Linear MCP；skill 调用这些 MCP 完成工作流
6. **建立 skill 维护节奏**：每个 skill 加 owner、version、review-by-date 三段 frontmatter（即使 spec 不强制）。把 skills 当 dependency 而非 prompt

### 触发条件（Threshold Triggers）

- **当 CLAUDE.md > 200 行**：触发重构成 skill
- **当 SKILL.md > 500 行**：拆 references/ 子目录
- **当装超过 20 个 skill**：考虑 `skillListingBudgetFraction` 设置（Claude Code v2.1.129+），或干脆 archive 不用的
- **当一个 skill 跑 3 次都不准确**：不是描述问题就是没该用 skill 而该用 MCP / subagent
- **当 skill 来自非 anthropics/* 仓库**：必须 snyk-agent-scan 扫；如果 skill 修改 `.claude/settings.json` 或重定向 API 端点，直接拒绝

### 不要做的事

- **不要把整本 Swift API Reference 塞进 CLAUDE.md** — 用 skill 的 references/，只在需要时加载
- **不要给同一件事既写 rule 又写 skill** — Cursor 实测如果两者冲突 rules 胜出（实际上是非确定的浪费 token）
- **不要在 SKILL.md 里硬编码 API key** — Snyk 数据里大量 leak 来自这一个错误
- **不要直接 install 来自 1 周龄 GitHub 账号的 skill** — ToxicSkills 报告里大多数恶意 skill 都是这种特征

---

## Caveats

- **生态数据有水分**：SkillsMP 声称 1.2M+ skill 是把 GitHub 全网抓 SKILL.md 的结果，真实有意义的独立 skill 估计在数千量级。Vercel skills.sh、anthropics/skills 是更可靠的基线
- **progressive disclosure 不是每个 host 都完美实现**：anthropics/claude-code#14882 issue 显示某些插件场景会全量加载；实际效果可能介于"几乎零成本"和"占满 context"之间
- **Cursor 早期采用者反馈不一**：论坛上"什么时候用 rule 什么时候用 skill"是高频疑问，Cursor 官方答复是 "Compared to always-on, declarative rules, skills are better for dynamic context discovery and procedural 'how-to' instructions"；一位用 20+ rules 的开发者经测试结论是 "I'm sticking with rules… but if I were starting fresh today, I'd probably try skills first"
- **MCP 阵营的反弹**：部分企业用户认为 Skills 把 secrets / auth 推回到 sandbox 是退步（Speakeasy 一年 MCP 部署后的判断："At org scale, the difference between 'every agent has access to raw secrets' and 'no agent ever touches a credential' is the difference between a security model and a security incident"）。这是 Skills 当前最大的架构争议
- **安全态势仍在恶化**：ToxicSkills（Feb 2026）、Mobb.ai 22,511 个 skill 审计（Feb–Mar 2026）、CVE-2025-59536 / CVE-2026-21852（Claude Code RCE）、OWASP Agentic Skills Top 10 项目启动——这是一个 npm 早期阶段的供应链生态。任何严肃使用必须扫描
- **Anthropic 官方没有"取代 CLAUDE.md"的措辞**：反复确认下，所有官方文档都用 "complement"、"different problem"、"build over time" 的措辞。任何说 "Skills 会让 CLAUDE.md 过时" 的第三方文章都是误读
- **本报告中部分数据来自第三方综述**（如 paperclipped.de 列出 32 个适配工具）：截至撰稿日（2026-05-18），agentskills.io 上的适配列表是更准确的真相来源，但具体数字会持续变化
- **Hacker News 上对 Skills 的怀疑论点值得认真对待**（verbatim）："I'm kind of in stitches over this. Claude's 'skills' are dependent upon developer documentation skills and a coherent file system structure — for those few who do write competent documentation… you'd likely be better off farming that grunt work to a Junior as a learning exercise." 即：Skills 的价值上限取决于你能写多好的过程文档——而这恰恰是大多数开发者不擅长的