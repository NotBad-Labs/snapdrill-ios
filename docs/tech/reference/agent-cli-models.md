---
last_verified: 2026-05-25
layer: snapshot
scope: tech
freshness:
  max_age_days: 30
  decay_trigger: [model_announcement, cli_upgrade, api_change, vendor_sunset]
---
# 智能体 CLI 工具与可用模型快照

> ⚠️ **强时效性文档**。AI 模型生态变化极快(2026-05-19 Google IO 一天就让本目录的多处过期)。
> 任何使用本表前必须 WebSearch 验证当前 SOTA 模型。
> `max_age_days: 30` 触发强制 review,模型快照 30 天必须刷新。

## 元规则:为什么需要这份文档

**血泪教训**:Claude 训练数据 cutoff 是 2026-01。当用户 2026-05-22 提到 "Gemini 3.5 Flash" 时,Claude 没有 WebSearch 验证就用 CLI ping 探针,
而 gemini-cli 0.42.0 走的 OAuth Code Assist endpoint 滞后于 Gemini API GA,导致 Claude 误判 "3.5 不存在"。

**根本盲点**:把 "训练记忆" 当成 "当前事实",尤其在 AI 模型/工具版本这种**强时效性**领域。

**纪律**:任何关于「当前哪个模型可用 / 哪个 model ID 正确 / 哪个 API 端点活着」的判断,**默认不信任训练记忆,必须 WebSearch 实时验证**。

---

## 当前可用智能体工具清单

### 1. Claude(Anthropic)

| 项 | 值 |
|---|---|
| 安装路径 | `/Users/yiming/.local/bin/claude` → `~/.local/share/claude/versions/2.1.146` |
| 包管理 | **独立安装**(Anthropic 官方独立包,非 Homebrew) |
| 订阅 | MAX |
| 默认模型 | Opus 4.7(claude-opus-4-7) |
| Sonnet | Sonnet 4.6(claude-sonnet-4-6) |
| Haiku | Haiku 4.5(claude-haiku-4-5-20251001) |
| 桌面端 | Claude Desktop(chat / cowork / **Code** 三个界面) |
| 调用方式 | `claude` 交互 / `claude -p` 非交互 / `claude --bare` 干净启动 |
| 上下文污染 | **默认读 CLAUDE.md / AGENTS.md / MEMORY.md** —— 启动即被项目污染 |
| Zero-context 路径 | `claude --bare` 或 `cd /tmp` + Desktop chat 界面 |

### 2. Codex(OpenAI)

| 项 | 值 |
|---|---|
| 安装路径 | `/opt/homebrew/bin/codex` |
| 包管理 | Homebrew(formula: `codex`) |
| 订阅 | 20 美金 |
| 默认模型 | **GPT-5.5 Thinking**(2026-05 当前 OpenAI 主力 reasoning 模型) |
| 桌面端 | Codex Desktop(macOS) |
| 调用方式 | `codex` 交互 / `codex exec <prompt>` 非交互 / `codex exec -s read-only` 沙箱 |
| 上下文污染 | 默认读项目目录;cd 到 /tmp + `-s read-only` 可获干净环境 |
| 非交互沙箱选项 | `--sandbox <read-only \| workspace-write \| danger-full-access>` |

### 3. Gemini(Google)

⚠️ **2026-06-18 重大变更**:Gemini CLI 和 Gemini Code Assist IDE 扩展将**停止为 Google AI Pro/Ultra 个人用户提供服务**(I/O 2026 5月19日官宣)。替代品为 **Antigravity CLI (`agy`)**,从 I/O 当天开始对所有人开放;Antigravity CLI 与 Antigravity 2.0 桌面端共用同一 agent runtime。本仓库使用直接 API endpoint(`generativelanguage.googleapis.com`)的代码路径(`Scripts/gemini_utils.py`)不受 sunset 影响,只有 `gemini` CLI 命令本身停摆。

| 项 | 值 |
|---|---|
| **当前 CLI(将于 2026-06-18 停服)** | |
| 安装路径 | `/opt/homebrew/bin/gemini` |
| 包管理 | Homebrew(formula: `gemini-cli`) |
| 订阅 | 20 美金(Pro / Ultra)|
| **CLI 版本(2026-05-22 实测)** | **0.42.0** |
| **CLI 接受的模型 ID**(实测) | `gemini-3-flash-preview` / `gemini-3-pro-preview` / `gemini-2.5-flash`(后者底层不是 3.5 GA,见 [user-decision-log #013](../../meta/user-decision-log.md#013-gemini-主笔候选-model-误用事故--直接-api-修复--scriptsgemini_utilspy-ssot-同步) 实证) |
| **CLI 不接受 GA model ID** | ⚠️ `gemini-3.5-flash` 在 CLI 报 404 / ModelNotFoundError |
| CLI 用的 endpoint | OAuth Code Assist `cloudcode-pa.googleapis.com`(**滞后于直接 API GA**) |
| 上下文污染 | 默认读项目目录;`--approval-mode plan` 只读;`GEMINI_CLI_TRUST_WORKSPACE=true` + `--skip-trust` 非交互 |
| **2026-06-18 后状态** | ⚠️ **停服**(Pro/Ultra/免费个人);企业 Standard/Enterprise license 不受影响 |
| **替代品:Antigravity CLI (`agy`)** | |
| 包管理 | Homebrew(`brew install antigravity-cli`,2026-05-25 已上架)/ 桌面端 Antigravity 2.0 内置 |
| 调用方式 | `agy` 命令(本机当前未安装) |
| 实现语言 | Go(比 TypeScript 实现的 gemini-cli 快) |
| 默认模型 | **Gemini 3.5 Flash GA**(2026-05-19 GA) |
| 保留特性 | Agent Skills / Hooks / Subagents / Extensions(改名 Antigravity plugins) |
| 配额变化 | ⚠️ **从 daily 改为 weekly**(降级,~2000 行代码可能耗尽) |
| Antigravity 2.0 桌面端 | `~/.gemini/antigravity/` 已存在(默认模型 Gemini 3.5 Flash) |
| **本仓库推荐路径(不依赖 CLI)** | |
| 直接 API endpoint | `generativelanguage.googleapis.com/v1beta`(支持 GA model ID `gemini-3.5-flash`) |
| Python 包装 | `Scripts/gemini_utils.py`(MODELS_DEEP/MODELS_FAST 首选 `gemini-3.5-flash`,2026-05-25 同步) |
| 认证 | `GEMINI_API_KEY` 环境变量(直接 API)/ OAuth(CLI) |
| Zero-context 路径 | 直接 API 调用(无项目挂载、无 Claude.md 污染) |

### 4. DeepSeek

| 项 | 值 |
|---|---|
| 安装路径 | `/Users/yiming/.local/bin/deepseek`(shell 脚本) |
| 包管理 | 独立安装(.local) |
| API Key | `$DEEPSEEK_API_KEY`(已配置) |
| **CLI 实质** | ⚠️ **不是干净 API**,而是 `claude -p` agent loop + DeepSeek 端点 |
| 实际跑的 model | **`deepseek-v4-pro` 固定**(项目策略：永不使用 `--flash` / `deepseek-v4-flash`) |
| **模型策略** | 帅哥 2026-05-25 裁决：本机所有 DeepSeek 调用统一 V4 Pro，**禁止 Flash**。理由：路径 C 期间用量审计发现主笔级元规则起草跑在 Flash 上，存在质量不一致污染产出风险。详见 `~/.claude/projects/-Users-yiming-Developer-snapdrill-ios/memory/feedback_deepseek_pro_only.md` |
| 上下文污染 | **CLI 路径自动读 CLAUDE.md/AGENTS.md**(因为底层是 claude -p)|
| **Zero-context 路径** | 直接 curl OpenAI 兼容端点 `https://api.deepseek.com/v1/chat/completions` |
| API 兼容模型名 | `deepseek-chat` / `deepseek-reasoner` / `deepseek-v4-pro`(实测全部可用) |

### 5. 未来加入

| 工具 | 状态 |
|---|---|
| Grok CLI | 用户提及但暂未安装 |

---

## 调用矩阵(zero-context 任务)

需要 zero-context 独立调用某家时的优选路径:

| 智能体 | Zero-context 最佳路径 |
|---|---|
| Claude | Claude Desktop **Code** 界面新会话(无项目挂载) / `claude --bare` |
| Codex | `cd /tmp && codex exec -s read-only <prompt>` |
| Gemini(preview,2026-06-18 前可用) | `cd /tmp && GEMINI_CLI_TRUST_WORKSPACE=true gemini -m gemini-3-flash-preview --skip-trust -p <prompt> --approval-mode plan` |
| **Gemini 3.5 Flash GA(推荐)** | **Python 调 `Scripts/gemini_utils.py`** 或 curl `generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent`(需 `GEMINI_API_KEY`,本仓库 [M-005 P2/P3.d 实战路径](../../meta/M-005-quality-criteria.md)) |
| **Gemini Antigravity CLI**(2026-06-18 起替代 gemini CLI) | `brew install antigravity-cli && agy <subcommand>`(本机当前未安装,推荐先继续直接 API 路径,agy 上线稳定后再切) |
| DeepSeek | `curl https://api.deepseek.com/v1/chat/completions` 且 `"model": "deepseek-v4-pro"`(避免走 deepseek CLI,它带 claude agent loop 污染;**禁止用 `deepseek-chat` / `deepseek-v4-flash`**);Python 同;走 CLI 时 `deepseek "<prompt>"` 不带 `--flash`(本仓库 M-005 主笔实战路径) |

---

## 模型生态时效性签名

| 厂商 | 主力模型(2026-05-25) | 训练 cutoff(若可知) | 文档 last_verified |
|---|---|---|---|
| Anthropic | Opus 4.7 / Sonnet 4.6 / Haiku 4.5 | Claude 知识 cutoff 2026-01 | 2026-05-25 |
| OpenAI | GPT-5.5 Thinking | 未公开 | 2026-05-25 |
| Google | **Gemini 3.5 Flash / 3.5 Pro**(2026-05-19 GA);Gemini CLI 2026-06-18 sunset(替代:Antigravity CLI `agy`) | 未公开 | 2026-05-25 |
| DeepSeek | **V4-Pro 唯一允许**(V4-Flash 项目内禁用) | 未公开 | 2026-05-25 |

⚠️ **如果距 last_verified 超过 30 天,必须 WebSearch 重新验证**。
⚠️ **Gemini CLI 2026-06-18 sunset 倒计时**:Pro/Ultra/免费个人用户。本仓库已使用直接 API 路径(`Scripts/gemini_utils.py`),不受 sunset 影响;但 `gemini` 命令本身停摆,后续如需 CLI 形态需切换到 `agy`。企业 Standard/Enterprise license 不受影响。

---

## 实证案例:训练 cutoff 漏报

### 案例 #001:Gemini 3.5 Flash 漏报(2026-05-22)

**事件**:用户提到"Gemini 3.5 Flash",Claude 未 WebSearch 验证,用 CLI ping 探针得出"3.5 不存在"错误结论。

**真相**:Gemini 3.5 Flash 2026-05-19 GA(3 天前),但 gemini-cli 0.42.0 的 OAuth Code Assist endpoint 还没接入 GA model ID。用户记得没错,Claude 错。

**根因**:Claude 训练 cutoff 2026-01,对 2026-05-19 发布完全无知;同时 CLI ping 失败不能证伪模型存在(只能证伪 CLI 接入)。

**纠正措施**:本文档建立 + 加入「AI 模型版本一律 WebSearch 验证」纪律 + 落档为 [user-decision-log #002](../../meta/user-decision-log.md)。

### 案例 #002:Gemini 主笔 model 误用三层错 + Gemini CLI sunset 同步刷新(2026-05-25)

**事件**:M-005 P2 阶段 Gemini 草案启动时,调度方未把本 SSOT 强制注入 prompt,Gemini subagent 报告自己用了 `gemini-2.5-flash`(完全错的模型,不是任务定义书要求的 3.5 Flash GA),Claude 主分支没 grep SSOT 验证就向上回报。帅哥本人指出错误后才追溯。详见 [user-decision-log #013](../../meta/user-decision-log.md#013-gemini-主笔候选-model-误用事故--直接-api-修复--scriptsgemini_utilspy-ssot-同步)。

**纠正措施**:
1. 旧 gemini-2.5-flash 草案归档作 §C 静默退化实证(`docs/archive/audits/m005-static-degradation-evidence/`)
2. 重做用 `Scripts/gemini_utils.py` 直接 API + `gemini-3.5-flash` GA
3. `Scripts/gemini_utils.py` MODELS 列表 SSOT 同步:首选 `gemini-3.5-flash` GA
4. M-005 §D 明文:"subagent 返回的 model ID/工具版本/API endpoint 必须 grep SSOT 验证后才能向上回报"

**触发本文档刷新**:同日帅哥通报 I/O 2026 (5月19日)官宣的 Gemini CLI 2026-06-18 sunset + Antigravity CLI (`agy`) 替代,WebSearch 验证属实。本次 last_verified 从 2026-05-22 刷到 2026-05-25,Gemini 章节大改加 sunset 倒计时 + agy 调用路径 + 现有直接 API 路径不受影响声明。这是 M-005 §D.3「`agent-cli-models.md` 刷新机制 - 感知到发版事件 / 厂商 blog 发布新模型」的活体应用——M-005 还未 ratify 已经触发自己定义的刷新条件。

---

## 关联文档

- [docs/meta/M-000-meta-vision.md](../../meta/M-000-meta-vision.md) §7 服务变化触发 review
- [docs/meta/user-decision-log.md](../../meta/user-decision-log.md) #002 训练 cutoff 漏报实证
- [docs/standards/worktree-audit-workflow.md](../../standards/worktree-audit-workflow.md) 多家对抗工作流
