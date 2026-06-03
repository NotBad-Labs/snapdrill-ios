# Grok Build / Grok CLI 深度调研报告（截至 2026 年 6 月初）

## TL;DR
- **Grok Build 是 xAI 的终端原生 AI 编码代理（CLI）**，2026 年 5 月 14 日以早期 beta 形式首发，底层模型 grok-build-0.1（256K 上下文，$1/$2 每百万 token）于 5 月 20 日上 API、5 月 28 日进入公开 beta；它直接对标 Claude Code、Codex CLI 和 Gemini CLI，主打 Plan Mode（计划先行）、最多 8 个并行子代理（各自独立 Git worktree）、原生 MCP/ACP，以及**对 Claude Code 生态（CLAUDE.md、skills、plugins、hooks、MCP）的零配置兼容**。
- **对你这样的 Claude Code 重度用户，迁移成本极低**——可以把现有 `~/.claude/skills/`、`CLAUDE.md`、MCP server 直接拿来用；但底层模型在 SWE-bench 上落后前沿约 17 点（byteiota《Honest Review》原文："It also scores 70.8% on SWE-Bench Verified, against Claude Code's 87.6%"），且仍是 beta（有幻觉、限流、子代理协调回归等粗糙边），**目前建议作为辅助工具而非主力**。
- **访问门槛已大幅下降**：从最初仅限 SuperGrok Heavy（$300/月）开放到 SuperGrok（$30/月）和 X Premium+（$40/月），无独立免费层；API 按量计费 $1/$2 每百万 token。**性价比甜点是 $30/月的 SuperGrok**，但需注意 beta 期的限额波动与订阅绑定 X 生态。

## Key Findings

1. **它是什么 / 何时发布**：Grok Build 是 xAI 首个面向专业软件工程的终端编码代理，2026 年 5 月 14 日首发早期 beta（最初仅 SuperGrok Heavy），约 5 月 24–25 日扩展到所有 SuperGrok 与 X Premium+ 订阅者。底层 grok-build-0.1 模型 5 月 20 日上 OpenRouter、5 月 28 日在 xAI API 公开 beta。截至 6 月初仍处于 beta（Musk 称还要"大约一个月"）。

2. **安装与访问**：单命令安装——macOS/Linux/WSL：`curl -fsSL https://x.ai/cli/install.sh | bash`；Windows PowerShell：`irm https://x.ai/cli/install.ps1 | iex`。首次运行 `grok` 打开浏览器登录 SuperGrok/X 账号；无浏览器环境用 `export XAI_API_KEY="xai-..."`。

3. **核心能力**：Plan Mode（默认对复杂任务先出计划、逐步可批改，写操作被阻塞直到批准）、最多 8 个并行子代理（各自独立 Git worktree，避免互相覆盖）、256K 上下文、headless 模式（`grok -p`，支持 streaming-json）、完整 ACP（可做编排器/bot）、原生 MCP、Skills/Plugins/Hooks 市场、内联图像/视频生成（`/imagine`）。

4. **生态兼容性（对你最关键）**：官方文档明确"Grok 与 Claude Code 完全兼容、零配置"——自动读取 Claude Code 的 marketplaces、plugins、skills、MCP、agents、hooks 以及指令文件（CLAUDE.md、Claude.md、CLAUDE.local.md、.claude/rules/），与 `.grok/` 并存。AGENTS.md 也开箱即用。

5. **基准与定位**：广为流传的 70.8% SWE-bench Verified 实际是前代 grok-code-fast-1 的成绩——xAI 官方 grok-code-fast-1 公告（x.ai/news/grok-code-fast-1）原文："On the full subset of SWE-Bench-Verified, grok-code-fast-1 scored 70.8% using our own internal harness"，且第三方 vals.ai 对 grok-code-fast-1 的独立测量仅 57.6%（vals.ai 模型页，经 Hacker News item 45064606 引用，vendor 与独立测量约 13 点差距）。**xAI 至今未公布 grok-build-0.1 自己的 SWE-bench 数字**。相比之下 Claude Opus 4.7 为 87.6%、Opus 4.8（5 月 28 日发布）88.6%，GPT-5.5/Codex 在 Terminal-Bench 2.0 上 82.7%。

6. **价格对比**：Grok Build 经 SuperGrok（$30）、X Premium+（$40）、SuperGrok Heavy（$300，$99/月 6 个月促销）解锁；API $1/$2 每百万 token。Claude Code 捆绑在 Claude Pro（$20）/Max；Codex CLI 捆绑 ChatGPT Plus（$20）；Gemini CLI 有最慷慨的免费层（个人 Google 账号每天 1,000 次请求）。

7. **开发者反馈**：Plan Mode 普遍被称赞；CLAUDE.md 兼容被视为聪明的"接管生态"策略；并行子代理对大型重构/迁移有价值。负面集中在：$300 太贵、模型偶尔幻觉出不存在的 API、beta 限流（xAI 已重置过额度并修复缓存问题）、子代理协调回归、验证步骤偶尔崩溃。每日发布说明的节奏被广泛认为"快得离谱"。

## Details

### 1. 产品定位、发布时间线与当前状态

Grok Build（xAI 公告中也称 Grok Build CLI）是 xAI 进军专业软件开发工具的首个产品，把 Grok 从"聊天机器人"推向"终端里的自主编码代理"。官方定位是"a powerful new coding agent and CLI for professional software engineering and complex coding work"。Engadget 指出 Musk 此前曾承认 xAI 在编码方面落后于竞品，Grok Build 是其补课努力的一部分。

关键时间线（已交叉核对）：
- **5 月 6 日**：Connectors 第一波（GitHub、Notion、Linear、Google Workspace、Microsoft 365/SharePoint/Outlook/OneDrive + Bring-Your-Own-MCP）。
- **5 月 14 日**：Grok Build 早期 beta 首发，最初仅 SuperGrok Heavy（$300/月，$99/月 6 个月促销）。Musk 亲自在 X 上征集反馈（"Try this early Grok Build (anything) beta and let us know what to improve. Much appreciated!"）。
- **5 月 18 日**：Grok Skills 发布（跨对话持久化技能，生成 Word/PPT/Excel/PDF）。
- **5 月 20 日**：grok-build-0.1 上 OpenRouter / Vercel AI Gateway。
- **5 月 21 日**：OpenCode 集成（SuperGrok/X Premium 订阅可经 OAuth 直接在 OpenCode 内使用，无需单独 API key）。
- **5 月 22 日**：Connectors 第二波（据二手来源含 Vercel、Canva、Gamma、S&P Global —— 具体清单需以官方为准）。
- **约 5 月 24 日**：v0.1.218 发布（修复 Linux 图片粘贴、Windows 快捷键、50+ 工具调用长会话崩溃；新增子代理视图、Gmail connector、插件、内联图像生成）。xAI 宣布**每日发布说明**。
- **5 月 24–25 日**：访问扩展到所有 SuperGrok 与 X Premium+。
- **5 月 26 日**：Musk 发布官方"How to use Grok Build"视频指南（约 390 万次观看），并称仍将在 beta "大约再一个月"，但已"对生产任务相当有用"。
- **5 月 28 日**：grok-build-0.1 在 xAI API 公开 beta。

当前状态（6 月 1 日）：仍是 early beta；官方在 x.ai/build/changelog 维持近乎每日的更新节奏（X 用户称"The pace of development is honestly insane right now"）。

### 2. 底层模型 grok-build-0.1

官方文档（docs.x.ai/developers/models/grok-build-0.1）确认的规格：
- 模态：文本 + 图像输入，文本输出
- 上下文窗口：256,000（注意：早期一些报道称"2M"，已被官方 256K 推翻；2M 是 Grok 4 聊天模型而非编码模型）
- 价格：输入 $1.00/百万 token，缓存输入 $0.20/百万，输出 $2.00/百万；超过 200K 上下文的请求按更高费率
- 能力：function calling、structured outputs、reasoning（始终开启，不可配置 reasoning effort，无 non-reasoning 模式）
- 速度：100+ tokens/秒
- 速率限制：1,800 RPM，10,000,000 TPM；区域 us-east-1、eu-west-1
- **重要细节**：模型卡把 grok-code-fast-1 列为别名（aliases: grok-code-fast-1, grok-code-fast, grok-code-fast-1-0825），且 5 月 15 日起原本路由到 grok-code-fast-1 的 API 请求自动迁移到 grok-build-0.1。一些深度分析据此认为 grok-build-0.1 在很大程度上是 grok-code-fast-1 同一谱系的重新命名 + 调价：grok-code-fast-1 原价据 xAI 公告为"$0.20 / 1M input tokens, $1.50 / 1M output tokens, and $0.02 / 1M cached input tokens"，新价 $1/$2，约 5x 涨价。

也可通过 OpenRouter、Vercel AI Gateway、Requesty 等以 `xai/grok-build-0.1` 调用（OpenAI 兼容）。

### 3. 功能与能力详解

**Plan Mode（计划模式，核心差异化）**：对复杂任务默认先生成逐步执行计划，写工具被阻塞（仅允许写 session plan 文件），你可以批准、对单步评论或整体重写，批准后所有改动以干净 diff 呈现。TUI 内 `Shift+Tab` 循环切换模式，`/plan` 查看当前计划。这是相对 Claude Code 的一个真实 UX 优势——Claude Code 也展示计划但不像 Grok Build 这样强制门控。

**并行子代理**：对大型任务委派给专门子代理并行运行（research/build/review 同时进行），每个子代理有自己的上下文窗口，并可启动在各自独立的 Git worktree 中——这避免了并行编辑互相覆盖，是该品类中最独特的架构决策。子代理数量"最多 8"为多家二手来源报道，xAI 官方未硬性承诺固定数字。

**模式与命令**（官方 docs.x.ai/build/modes-and-commands）：
- 模式：Plan（计划）、Always-approve（`grok --always-approve` 跳过权限提示）；默认 `approval_mode = "ask"`，可在 `~/.grok/config.toml` 改为 always-approve
- 核心斜杠命令：`/model <name>` 切换模型、`/context` 查看上下文用量、`/compact` 压缩历史、`/plan`、`/hooks`、`/plugins`、`/mcps`、`/imagine`、`/imagine-video`、`/feedback`、`/btw`（不打断地问旁支问题）、`/share`、`/skillify`（把会话保存为可复用技能）
- 任何用户可调用的 skill 也作为斜杠命令出现（如 `/<skill-name>`）

**Headless / 脚本化**：`grok -p "Explain this codebase"`，`--output-format streaming-json` 输出结构化事件流（step_start、tool_use、step_finish 等），适合 CI/CD、GitHub Actions、自动化。`grok inspect` 查看当前目录发现的配置来源、指令、skills、plugins、hooks、MCP。`--batch-api` 走 xAI 批处理 API 降低无人值守成本。

**自定义模型路由**：可在 config.toml 中定义任意自定义模型（model id + base_url + env_key），甚至经 OpenRouter 路由到 Claude、GPT-5、Gemini 等其他模型，同时保留 Grok Build 的多代理架构与工具链。

**支持语言/框架**：与代码库、语言无关——Python、Node.js、Go、Rust 等均处理良好，开箱理解 Django、Express、FastAPI 等框架。

**IDE 集成**：Grok Build CLI 本身是 TUI/CLI 优先，非独立桌面 GUI；但通过 ACP 可作为其他应用（IDE 扩展）的后端。底层 grok-build-0.1 模型可在 Cursor、Zed、VS Code、Kilo Code、OpenCode、Hermes Agent 等第三方 harness 中作为后端使用。注意：Grok Build CLI 当前主要支持 macOS/Linux/WSL；Windows 有 PowerShell 安装脚本但部分功能（沙箱）受限。

### 4. Skills、Connectors 与生态兼容性（针对多工具工作流）

**与 Claude Code 的兼容性**是 xAI 的核心战略赌注。官方 Skills/Plugins 文档明确："Grok is fully compatible with Claude Code with zero configuration needed. Grok automatically reads Claude Code marketplaces, plugins, skills, MCPs, agents, hooks, and instruction files (CLAUDE.md, Claude.md, CLAUDE.local.md, and .claude/rules/) alongside .grok/."

实务含义（对你的多工具工作流）：
- 你可以把现有 `~/.claude/skills/` 文件夹直接放进 Grok 工作目录，无需修改即可使用
- 已配置的 MCP server 会被自动发现、注册并作为工具暴露给代理
- AGENTS.md（Codex 推广的跨工具约定）也开箱即用
- Skills 采用与 Claude Code 相同的 Markdown + YAML frontmatter 约定；唯一例外是依赖 Claude 特定模型行为（如 Opus 特别擅长的 prompt 模式）的 skill 可能表现不同

这与微软当年用 VS Code 兼容性蚕食 Atom/Sublime 是同一打法——通过"导入生态"而非"另起炉灶"来降低切换成本。

**Connectors**：第一波（5/6）GitHub、Notion、Linear、Google Workspace、Microsoft 365 + BYO-MCP；第二波（5/22）据报道加 Vercel、Canva、Gamma、S&P Global。这些是第一方集成，让 Grok 读写开发团队日常使用的应用（如经 MCP 注册 Totalum 后可从终端"在我的 Totalum 项目里搭客户引导流程"）。

### 5. 访问与价格

**订阅解锁**（截至 6 月初）：
- SuperGrok $30/月 —— 含 Grok Build 访问（性价比甜点）
- X Premium+ $40/月 —— 含 Grok Build（外加 X 平台权益）
- SuperGrok Heavy $300/月（$99/月 6 个月促销）—— 更高用量配额、更深的 agentic 功能（如 16x AI agents）
- 无独立免费层（grok.com 聊天免费层不含 Grok Build CLI 的完整使用）

**API 价格**：grok-build-0.1 $1/百万输入、$0.20/百万缓存输入、$2/百万输出。相比 Claude Sonnet（$3/$15）、Opus 4.7/4.8（$5/$25）显著便宜；但工具调用（web_search、x_search、code_execution）通常另计 ~$5/1000 次。

**与竞品价格对比**：
- **Claude Code**：捆绑 Claude Pro $20/月或 Max；底层 Opus $5/$25。注意 Anthropic 6 月 15 日的计量信用变更会影响程序化使用成本。
- **Codex CLI**：捆绑 ChatGPT Plus $20/月、Pro $200/月；2026 年 4 月起改为基于 token 的信用计费；底层 GPT-5.5 API $5/$30。
- **Gemini CLI**：最慷慨的免费层——据 Google 官方博客（blog.google《Google announces Gemini CLI》），个人 Google 账号"60 model requests per minute and 1,000 model requests per day at no charge"，并含 Gemini 2.5 Pro 与 1M 上下文；开源（Apache 2.0）。**重要变动**：据 Google for Developers 文档（developers.google.com/gemini-code-assist/resources/quotas，2026-05-27 更新），"Gemini Code Assist IDE Extensions and Gemini CLI will stop serving requests for Gemini Code Assist for individuals, Google AI Pro, and Google AI Ultra tiers starting June 18, 2026. Migrate to Antigravity and Antigravity CLI before this date."——即免费层/Google One 用户的 Gemini CLI 将于 6 月 18 日被 Antigravity CLI 取代。

### 6. 基准对比与竞品全景

**关键澄清**：grok-build-0.1 没有官方公布的 SWE-bench 成绩。常被引用的 70.8% SWE-bench Verified 属于前代 grok-code-fast-1（xAI 内部 harness，原文见上），第三方 vals.ai 对 grok-code-fast-1 的独立测量仅 57.6%（vendor 与独立测量约 13 点差距）。xAI 也未公布任何 SWE-bench Pro 或 Terminal-Bench 数字。

竞品（均为 vendor-reported，截至 5/6 月）：
- **Claude Opus 4.7**（4/16 发布）：SWE-bench Verified 87.6%、SWE-bench Pro 64.3%、Terminal-Bench 2.0 69.4%；$5/$25。
- **Claude Opus 4.8**（5/28 发布）：SWE-bench Verified 88.6%、SWE-bench Pro 69.2%、Terminal-Bench 2.1 74.6%；价格不变 $5/$25；Claude Code 新增"dynamic workflows"可把难题分发给数百个并行子代理自验证。
- **GPT-5.5 / Codex**（4/23 发布）：Terminal-Bench 2.0 82.7%（领先）、SWE-bench Pro 58.6%、SWE-bench Verified 88.7%；API $5/$30；Codex 速度优势明显（~240+ tokens/秒）。

**结论性定位**：
- Codex CLI（GPT-5.5）= 速度王 + Terminal-Bench 领先
- Claude Code（Opus 4.7/4.8）= 成熟度/可靠性王 + SWE-bench Pro 领先（复杂多文件推理最强）
- Grok Build = 架构有野心（Plan Mode 门控 + worktree 隔离的并行子代理 + 本地优先），但模型落后约 17 点，仍 beta
- Gemini CLI = 免费层之王 + 开源（但个人/Pro/Ultra 档 6/18 起转 Antigravity CLI）

差异化要点：Grok Build 的并行子代理在各自 Git worktree 中隔离（Claude Code 的子代理默认在同一 workspace、无分支隔离）；本地优先架构——DevOps.com 原文："The tool is also local-first, meaning no source code is transmitted to xAI's servers. For teams working with proprietary codebases or in regulated industries, that's a meaningful design choice."（号称 air-gap 兼容），对金融/政府/医疗等敏感代码库是真实优势。

### 7. 真实开发者反馈

**正面**：
- **Plan Mode** 是最一致的赞点。一位实测者用它重构一个长成"意大利面"的遗留认证模块，Grok Build 建议拆成四个职责清晰的文件，30 秒内执行完成，"结果比我手写还干净"。
- **每日迭代节奏**被广泛称赞——"快得离谱"，有用户称一夜更新后体验"从 6 分跳到 8 分"。Musk 称"Grok Build is improving like lightning"。
- **CLAUDE.md/生态兼容**被视为聪明的"零切换成本接管 Claude Code 用户"策略。
- **并行子代理 + worktree 隔离**对 5 万行以上代码库的迁移、测试回填价值最大。
- 一些实测注意到自验证回路有效（代理主动发现并修正自己的字体大小错误并重写 SVG）。

**负面**：
- **$300 太贵**：HN 评论"$300 a month on something my employer will never approve"。DevOps.com 称 $300 档"目标是成本能消化进 headcount 的专业工程团队"。
- **模型幻觉**：偶尔编造不存在的 API 端点或方法签名——务必先审计计划再批准。
- **beta 限流/额度**：早期用户很快撞限额，xAI 承认是缓存效率问题、已修复并重置所有账号额度。还有 GitHub issue 显示标准 SuperGrok（$30）订阅者遇到 403（权限层一度仍把推理门控在 Heavy 档）。
- **子代理协调回归**：xAI 自己承认多代理并行是最新、最易在复杂任务上出错的部分；有实测记录验证步骤崩溃。
- **简单任务反而慢**：因为它会 plan→ask→verify，不像 Codex 在创建文件后即停。
- **整体情绪**：谨慎乐观但"明显落后前沿"。共识是架构强、迭代猛，但被 ~17 点基准差距、beta 不稳与定价拖累。

**Arena Mode**（最被讨论但尚未 GA 的功能）：让多个代理对同一问题独立作答、自动评分排名后再交给开发者选择。2 月即在代码痕迹中发现，xAI 在发布公告中列为"即将推出"，截至 6 月初仍未默认开启（一些来源称在 beta 中分阶段铺开，但非 GA）。

## Recommendations

**给你（iOS/Swift，Claude Code 为主力，Codex/Gemini CLI 为辅）的分阶段建议：**

1. **第一阶段（本周，低成本试用）**：如果你已有或愿意花 $30/月开 SuperGrok，安装 Grok Build 在一个**非关键的 Swift/工具型副项目**上跑。直接复用你现有的 `CLAUDE.md` 和 `.claude/skills/`——它们零配置即可工作。重点体验 Plan Mode 的强制门控（这是相对 Claude Code 的真实增量），以及把一个大重构 fan-out 给并行子代理 + worktree 的效果。**不要**把它放进生产 CI/CD。

2. **第二阶段（评估其在 iOS 工作流中的位置）**：注意 Grok Build CLI 是终端代理，不直接驱动 Xcode/模拟器构建链——它擅长多文件编排、脚本化、文档/测试桩生成，但 Swift/SwiftUI 的编译与预览仍需 Xcode。把它定位为"编排层"，让它跑跨文件改动、迁移脚本、CI 配置优化，而把 Xcode 内的交互式编码与构建留给你现有流程。Swift 生态它能处理，但前沿模型（Opus 4.8）在复杂多文件推理上仍更可靠。

3. **第三阶段（多工具分工）**：最成熟的 2026 做法是 2–3 个工具按工作流分工——**Claude Code 当日常主力**（成熟度、commit/PR 质量、Opus 4.8 的多文件推理最强）；**Grok Build 当实验/高并发重构的副手**（Plan Mode + 并行 worktree + 便宜的 API）；**Codex CLI 处理 OpenAI 侧**（速度、Terminal-Bench 领先）；**Gemini CLI 用免费额度跑轻量/一次性任务**（但留意 6/18 起个人档转 Antigravity CLI）。由于三者都读 AGENTS.md/MCP，你可以维护一份统一的 AGENTS.md + 精简 CLAUDE.md，让它们共享项目上下文。

**触发重新评估的阈值/基准：**
- 若 xAI 公布 grok-build-0.1 的官方 SWE-bench（或 Grok 5 落地驱动 Grok Build）且独立验证接近/超过 Opus —— 可升级为主力候选。
- 若 Grok Build 正式 GA（退出 beta，预计最快 6 月底）且限流稳定、子代理协调回归消除 —— 可纳入生产路径。
- 若 Arena Mode 正式默认开启 —— 其"多方案择优"机制可在一定程度上抵消单次生成的模型弱点，值得重新测速。
- 若你不想把订阅绑死在 X 生态，或需要 SSO/审计日志/组织访问控制等企业能力 —— 继续以 Claude Code/Codex 为主。

## Caveats

- **信息快速变动**：Grok Build 处于近乎每日更新的早期 beta，版本号、功能、限额随时变。本报告确认到的最新版本为 v0.1.218（约 5/24）；按每日节奏，6 月初已有更高 build，但官方 changelog（x.ai/build/changelog）有机器人防护，具体更晚版本号未能逐一核实。请以 docs.x.ai/build 和 x.ai/build/changelog 为准。
- **来源质量参差**：大量"评测"来自 SEO 聚合站（codersera、byteiota、chatforest、jingrey 等），部分明确声明未做实测。本报告已尽量以 xAI 官方页面、官方文档、HN、GitHub issue、Engadget/DevOps.com、Musk 的 X 帖等一手/高质量来源为锚，并标注冲突处。
- **冲突数据点**：(a) 上下文窗口——官方 256K，早期误传 2M；(b) API 价格——官方 $1/$2，部分来源仍用旧的 $0.20/$1.50（grok-code-fast-1 旧价）；(c) 发布日期——多数为 5/14，部分写 5/25（扩展日）；(d) 基准——70.8% 属 grok-code-fast-1 而非 grok-build-0.1。
- **基准应视为下限而非排名**：SWE-bench Verified 已接近饱和且有记忆化争议；grok-build-0.1 无官方 SWE-bench 数字，跨厂商对比只能用前代/竞品 vendor-reported 数据，且 LLM-Stats 显示几乎所有 SWE-bench 条目均为厂商自报、无独立验证。
- **"账号封禁"传闻需澄清**：未发现 Grok Build CLI 用户被封号的可信报告；网上"Grok 账号被封"多指 2025 年 Grok 聊天机器人在 X 上的争议，与 CLI 无关。真实存在的是订阅档位权限混乱导致的 403/访问门控问题。
- **安全/合规背景**：xAI 在 2025 年末至 2026 年初有图像生成滥用争议；个人 SuperGrok/X Premium 档默认可能用对话训练模型，处理客户/专有/受监管代码应考虑 Grok Business 档（默认不训练）。