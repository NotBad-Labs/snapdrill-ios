# Grok Build CLI 用量与限额结构深度解析（截至 2026 年 6 月初）

## TL;DR
- **Grok Build CLI 与 Codex/Claude Code 最大的不同在于：xAI 没有公布任何具体的订阅用量配额。** 它既没有 Codex 式的"5 小时滚动窗口 + 每周上限"，也没有公开的每日提示数；官方只用"更高的速率限制 / 最高用量限额"这类分级描述性语言，实际计量在后台按 token/额度动态进行。
- 你持有的 **X Premium+（$40/月，现已捆绑 SuperGrok 级访问）已完整获得 Grok Build beta 访问权**，与独立 SuperGrok（$30/月）享同等准入；没有任何官方来源显示 X Premium+ 的 Grok Build 限额低于 SuperGrok。真正的"最高限额"档位是 SuperGrok Heavy（$300/月，前 6 个月 $99 促销）。
- **若你需要可预测、不被限流的用量，应改用 grok-build-0.1 API 按量付费**（$1/百万输入 token、$2/百万输出、$0.20/百万缓存输入，256K 上下文），其速率限制是基于累计消费的 RPM/TPM 分级体系，而非订阅式时间窗口。

## Key Findings

1. **订阅式 Grok Build 没有公开的数字配额。** 遍查 xAI 官方文档（docs.x.ai/build/overview、modes-and-commands、enterprise）与 x.ai/news/grok-build-cli 发布博文，均无任何配额、速率限制、提示计数或 token 上限的表述。官方只说明准入资格——发布博文原文为"Now in early beta for all SuperGrok and X Premium Plus subscribers"。

2. **限额机制是动态的、token/额度计量的，而非固定时间窗口。** Grok Build 唯一的内置用量指标是官方文档确认的 `/context`（"View context usage"），它只跟踪上下文窗口（256K）消耗，而非订阅配额。第三方指南建议用 `/usage` 跟踪"token 和额度行为"再决定是否升级，暗示后台按 token/额度计量。

3. **2026 年 5 月 26 日 xAI 为所有账户重置了 Grok Build beta 用量限额。** 据 Basenor 报道，原文为："xAI has reset Grok Build Beta usage limits across all accounts... The team identified caching inefficiencies as the root cause and pushed improvements before restoring full quotas"。根因是 prompt caching 失效导致 token 消耗激增——这进一步佐证订阅限额是 token 驱动的。

4. **API 模型 grok-build-0.1 的限速是基于消费的分级体系。** 每个 xAI API 团队按模型设有 RPM（每分钟请求数）和 TPM（每分钟 token 数）两个维度的硬上限，随团队自 2026 年 1 月 1 日起的累计消费分级提升，超限返回 429 错误。

5. **竞品对比：** Codex CLI 与 Claude Code 都采用"5 小时滚动窗口 + 每周上限"双层结构；Gemini CLI 用每日请求数上限。Grok Build 的结构在四者中**最不透明**——它既不像 Codex/Claude 公开窗口逻辑，也不像 Gemini 公布每日数字。

## Details

### 1. 订阅式限额（SuperGrok / X Premium+ / SuperGrok Heavy）

**准入路径与定价（2026 年）：**
- SuperGrok：$30/月（或 $300/年）
- X Premium+：$40/月——X 登录注册页现明确将 Premium+ 标注为"包含 SuperGrok"，即捆绑 SuperGrok 级 Grok 访问（注意：独立订阅 X Premium+ 与单独订阅 SuperGrok 是两件事，二者价值定位不同，但 Grok 模型准入相同）
- SuperGrok Heavy：$300/月，目前有前 6 个月 $99/月的促销价（促销期后回到 $300 列表价）

**发布与准入时间线：**
- 2026 年 5 月 14 日：Grok Build 早期 beta 首发，初期仅限 SuperGrok Heavy（$300/月）订阅者
- 2026 年 5 月 25 日：扩展至所有 SuperGrok 与 X Premium+ 订阅者
- Elon Musk 在 5 月 26 日表示 Grok Build 还将在 beta 阶段停留约一个月（即约 2026 年 6 月底），并称其"对生产任务已相当有用"（quite useful for production tasks）

**限额结构的真相——分级描述而非数字表：**

xAI 对 Grok Build 订阅用量**不发布任何固定数字配额**。官方文档完全没有订阅配额章节，只在消费者订阅页用分级描述性语言。值得注意的是，SuperGrok Heavy 的权益文案在 5 月 15–16 日前后被悄悄修改——据 PiunikaWeb（2026 年 5 月 16 日更新）："Instead of the previous wording that said 'Near-unlimited usage'... it now says 'Highest usage limits'"。这显示 xAI 正在收紧并刻意避免承诺具体数字。

第三方指南明确指出，不适合采用 Grok Build 的人群之一是"在采用前要求完全明确的固定配额的买家"——即确认没有公开配额。隐含的层级是：**SuperGrok Heavy > SuperGrok / X Premium+**，"much higher rate limits"专属于 Heavy。**没有任何来源证明 X Premium+ 与 SuperGrok 在 Grok Build 上有限额差异**——这是你最关心的问题，答案是：就目前可查信息，两者在 Grok Build 上同档，差别只在 X 平台周边权益。

**关于"免费层 50 次/天"的说法：** 有个别第三方评测声称 Grok Build 免费层限 50 次请求/天，但这与多个来源（称"没有免费层"，需 SuperGrok 订阅或 API key）矛盾，应视为未经证实、很可能不准确。

### 2. Beta 相关限额

- Grok Build 于 2026 年 5 月 14 日进入早期 beta。
- 早期 beta 期间用户普遍反映"很快就撞到限额"（running into rate limits fast），这是 beta 早期的预期摩擦点。
- 2026 年 5 月 26 日，xAI 通过 @xai 账户官宣为所有账户重置 Grok Build beta 用量限额。根因是缓存效率问题：近期对 X 平台搜索与网页检索的升级扰乱了 prompt caching 机制，导致缓存失效→token 消耗增加、响应变慢→配额快速耗尽。修复后恢复全部配额。用户侧也有佐证（如 @mark_k 5 月 26 日下午发帖"Grok Build usage limits have been reset by @xai for everyone today!"）。
- **当前 beta 状态（截至 6 月初）：** 限额仍为动态、未公布数字；Musk 指出 beta 还将持续约一个月（约 6 月底退出早期访问）。
- xAI 承诺为 Grok Build 发布每日更新日志，意味着限额可能频繁变动。

### 3. API 用量（grok-build-0.1）

**定价（按量付费，官方 docs.x.ai/developers/pricing，5 月 27 日更新）：**
- 输入：$1.00/百万 token
- 缓存输入：$0.20/百万 token（自动缓存，约可省 85% 输入成本）
- 输出：$2.00/百万 token
- 上下文窗口：256K token
- 速度：100+ token/秒（官方 x.ai/news/grok-build-0-1 原文："served at a blazing-fast 100+ tokens/second and is priced at $1/m tokens in and $2/m tokens out"）
- 工具调用单独计费（web_search / x_search / code_execution 约 $5/千次）

**速率限制（官方 docs.x.ai/developers/rate-limits，5 月 11 日更新）：**
- 按模型设 RPM 与 TPM 双维度硬上限
- 分级基于自 2026 年 1 月 1 日起的累计 API 消费：Tier 0 = $0（默认）、Tier 1 = $50、Tier 2 = $250、Tier 3 = $1,000、Tier 4 = $5,000、Enterprise 需申请
- 一旦达到某档位即永久保留，不会降级；限额随档位指数级增长
- 超过 RPM 或 TPM 任一上限返回 429 Too Many Requests；官方建议指数退避重试
- **重要：** grok-build-0.1 具体的 RPM/TPM 数值不在公开文档中显示（文档表格显示"无模型速率限制数据"），只能在 console.x.ai 控制台查看本团队个性化限额
- 所有 token（提示、补全、推理、缓存）都计入 TPM，缓存 token 按降价计费但仍计入

**订阅 vs API 的本质区别：** 消费者订阅（grok.com、SuperGrok、X Premium）与 API 访问完全独立，订阅不提供 API 额度。订阅适合交互式人工使用，但限额不透明、动态波动；API 按 token 计费、限额可预测（但需自行处理 429）。grok-build-0.1 还可通过 OpenCode（5 月 21 日起）等环境使用，无需单独 API 计费。

**注意定价混淆：** 部分第三方站点引用 $0.20/$1.50 或将 $0.20 当作标准输入价——$0.20 实际是**缓存输入价**，标准输入价无歧义为 $1.00。$0.20 标准输入价属于更便宜的旧模型（如 grok-code-fast-1、grok-4-fast 系列）。注意 grok-code-fast-1 已于 5 月 15 日退役，请求自动路由到 grok-build-0.1。

### 4. 竞品限额结构对比

**OpenAI Codex CLI：**
- 双层叠加：5 小时滚动窗口 + 每周上限，两者同时生效（即使 5 小时额度还有余量，每周额度耗尽也会被锁）
- 2026 年 4 月 2 日改为基于 token 的额度（credits）计费；4 月 9 日起改为"推理越久消耗越多 5 小时额度"
- 5 小时窗口从首次请求开始计时；权重已不再是简单消息计数
- 多数开发者先撞 5 小时限额，但每周上限是重度用户真正的天花板
- 额度耗尽后可购买额外 credits 续用

**Anthropic Claude Code：**
- 双层：5 小时滚动窗口（从首条消息计时，300 分钟后重置）+ 每周上限（计算小时预算，每 7 天重置）
- 同一额度池在 Claude Code、Claude.ai 网页、Cowork 之间共享
- 容量随档位：据 TrueFoundry，"roughly 10–45 prompts per window on Pro, up to 900 on Max 20x"（Max 5x 约 225/窗口）
- 2026 年 5 月 6 日将 5 小时限额翻倍并取消高峰时段限流；5 月 13 日将每周上限上调 50%（至 7 月 13 日）；5 月 15 日 @ClaudeDevs 发推"Happy Friday! We've reset everyone's 5-hour and weekly rate limits"，为所有 Pro/Max/Team/Enterprise 重置两个计数器（API 不受影响）

**Google Gemini CLI：**
- 主要是每日请求数上限：据 Google 官方（blog.google）个人账户免费层为"60 model requests per minute and 1,000 requests per day at no charge"（确切数字，非约数）
- 这些每日上限跨所有模型版本聚合；一次提示可能触发多次模型请求
- 用尽后可升级 Google AI Pro/Ultra 固定价订阅或转 API 按量付费
- （注：Gemini Code Assist IDE 扩展与 Gemini CLI 将于 2026 年 6 月 18 日起停止为个人/Pro/Ultra 层服务，迁移至 Antigravity）

**Grok Build 的相对定位：** 在四者中，Grok Build 的限额结构**最不透明**。Codex 和 Claude Code 至少公开了"5 小时 + 每周"的双层逻辑和大致提示数；Gemini 公布了明确的每日数字（60 RPM / 1,000 RPD）。Grok Build 既无公开窗口逻辑，也无每日/每周数字，只有"最高用量限额"式的营销语言，且处于 token 驱动的动态计量。对于像你这样从 Codex 心智模型迁移过来的开发者，这意味着无法预先规划"还能跑多久"——只能靠 `/context`（看上下文消耗）和实测来推断。

### 5. 真实开发者反馈

- beta 早期普遍反映限额来得太快，直接促成了 5 月 26 日的缓存修复与全量重置。
- Hacker News、Reddit（r/grok、r/xAI）、X 上有活跃讨论，但多数聚焦于与 Claude Code/Codex CLI 的能力对比（部分早期评价认为 grok-build-0.1 首轮表现"并不特别亮眼"），而非硬性限额数字。
- 关于 xAI 整体限流的背景：5 月中旬大量付费 Grok 用户（SuperGrok/Heavy）反映视频、图像、语音生成被突然大幅限流——据 PiunikaWeb（5 月 13 日，5 月 15 日更新），用户"getting locked out of voice chats after just 20 to 30 minutes"，Heavy 视频日限"dropped from 500 down to 160"；xAI 5 月邮件列出标准 SuperGrok ">20 videos"/24h、Heavy ">80 per 12 hours"。这被解读为将用户推向 $300 Heavy 档。**注意：这些是媒体生成（Imagine/语音）的限额，不是 Grok Build CLI 编码限额**，但反映了 xAI 在算力紧张下激进调整限额的模式（部分因 xAI 与 Cursor 的算力合作、Grok 4.3 训练等占用 Colossus 集群资源）。
- 关于 slash 命令：官方文档（modes-and-commands，5 月 14 日）只列出 `/context`（查看上下文用量），并无 `/usage`、`/cost`、`/tokens`。第三方指南提到的 `/cost`、`/tokens` 未在官方文档证实，即便存在也是跟踪上下文窗口/会话花费，而非订阅配额。鉴于 xAI 每日更新，命令集可能在变化。

## Recommendations

1. **现在就用你的 X Premium+ 直接装 Grok Build 试跑一周真实工作负载。** 你已具备完整 beta 访问权，与 $30 SuperGrok 同档。安装：`curl -fsSL https://x.ai/cli/install.sh | bash`，首次运行浏览器登录即可。用 `/context` 监控上下文消耗，记录你大约在多少次复杂任务后撞到"usage limit reached"。这是当前唯一可靠的限额摸底方法，因为没有公开数字。

2. **不要假设 Grok Build 有 Codex 式的 5 小时窗口或每周上限。** 把它当作"动态 token 额度池"来对待：任务越重（大上下文、多子代理并行、长推理）消耗越快。善用 `/compact` 在上下文超 80% 时压缩，减少无谓 token 消耗。

3. **若撞限额频繁且影响交付，分两步走：**
   - 第一步（低成本）：评估是否升级到 SuperGrok Heavy。但注意 $99 是前 6 个月促销价，之后回到 $300/月，且 Heavy 权益文案已从"近乎无限"改为"最高用量限额"——不要假设无限。
   - 第二步（可预测）：改用 grok-build-0.1 API 按量付费，接入 CLI（`export XAI_API_KEY=...`）或自有 agent 循环。$1/$2 每百万 token 对编码代理相当便宜，且缓存输入仅 $0.20。代价是需自行实现 429 指数退避。用 `/cost`（若可用）监控 30 分钟会话花费（典型 $0.05–0.15，重度多代理 $0.50+）。

4. **触发升级/切换的阈值：** 如果你在订阅模式下每天多次撞限、或单个长任务跑不完，且这种情况每周重复——就该切到 API 按量付费（对机器化、自动化负载尤其如此）。反之，若只是偶尔交互式使用，订阅足矣。

5. **持续跟踪官方每日更新日志。** Grok Build 仍在快速迭代（每日发布说明），Musk 称约 6 月底退出 beta。退出 beta 时限额政策很可能变化（可能公布数字，也可能像媒体生成那样收紧），届时重新评估。

## Caveats

- **信息高度不稳定：** Grok Build 处于活跃 beta，限额几乎每日可能变动，且 xAI 历史上有在促销期后收紧权益的模式（如 SuperGrok Heavy 从"近乎无限"改为"最高限额"）。本报告所有"订阅限额"结论的核心是"xAI 未公布数字"，这一点本身可能随退出 beta 而改变。
- **来源冲突已标注：** 发布日期（5 月 14 日 Heavy-only 首发 vs 5 月 25 日扩展）、底层模型（canonical 为 grok-build-0.1 / 256K；早期媒体误称 grok-code-fast-1 或 2M 上下文）、Heavy 价格（$300 vs $299）、免费层是否存在（50 次/天的说法未证实）等，均存在二手来源分歧，正文已逐一说明并采信官方口径。
- **API 具体 RPM/TPM 数字无法公开获取：** 只能在 console.x.ai 控制台按你自己的消费档位查看。本报告给出的是分级体系（消费阈值）而非 grok-build-0.1 的确切每分钟数字。
- **媒体生成限额 ≠ 编码限额：** 网上大量关于 SuperGrok 限流的开发者愤怒帖多指 Grok Imagine 视频/图像/语音，不能直接套用到 Grok Build CLI 的编码用量，本报告已严格区分。
- **slash 命令集未定：** `/usage`、`/cost`、`/tokens` 仅见于第三方，官方仅确认 `/context`；可能因每日迭代而变化。