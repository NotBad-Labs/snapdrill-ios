---
last_verified: 2026-05-22
layer: snapshot
scope: tech
freshness:
  max_age_days: 30
  decay_trigger: [model_announcement, cli_upgrade, api_change]
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

| 项 | 值 |
|---|---|
| 安装路径 | `/opt/homebrew/bin/gemini` |
| 包管理 | Homebrew(formula: `gemini-cli`) |
| 订阅 | 20 美金 |
| **CLI 版本(2026-05-22 实测)** | **0.42.0** |
| **CLI 接受的模型 ID**(实测) | `gemini-3-flash-preview` / `gemini-3-pro-preview` |
| **GA 模型 ID**(WebSearch 验证) | `gemini-3.5-flash` / `gemini-3.5-pro` |
| **CLI 不接受 GA model ID** | ⚠️ `gemini-3.5-flash` 在 CLI 报 404 |
| 桌面端 | **Antigravity** |
| Antigravity 默认模型 | Gemini 3.5 Flash(2026-05-19 Google IO 发布后 GA) |
| CLI 用的 endpoint | OAuth Code Assist `cloudcode-pa.googleapis.com`(**滞后于直接 API GA**) |
| 直接 API endpoint | `generativelanguage.googleapis.com`(支持 GA model ID,需 GOOGLE_API_KEY) |
| 上下文污染 | 默认读项目目录;`--approval-mode plan` 只读;`GEMINI_CLI_TRUST_WORKSPACE=true` + `--skip-trust` 非交互 |

### 4. DeepSeek

| 项 | 值 |
|---|---|
| 安装路径 | `/Users/yiming/.local/bin/deepseek`(shell 脚本) |
| 包管理 | 独立安装(.local) |
| API Key | `$DEEPSEEK_API_KEY`(已配置) |
| **CLI 实质** | ⚠️ **不是干净 API**,而是 `claude -p` agent loop + DeepSeek 端点 |
| 实际跑的 model | `deepseek-v4-pro`(默认)/ `deepseek-v4-flash`(--flash 选项) |
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
| Gemini(preview) | `cd /tmp && GEMINI_CLI_TRUST_WORKSPACE=true gemini -m gemini-3-flash-preview --skip-trust -p <prompt> --approval-mode plan` |
| **Gemini 3.5 Flash GA** | ⚠️ CLI 不可达,走 **Antigravity 桌面端** 或 curl `generativelanguage.googleapis.com` |
| DeepSeek | `curl https://api.deepseek.com/v1/chat/completions`(避免走 deepseek CLI,它带 claude agent loop 污染) |

---

## 模型生态时效性签名

| 厂商 | 主力模型(2026-05-22) | 训练 cutoff(若可知) | 文档 last_verified |
|---|---|---|---|
| Anthropic | Opus 4.7 / Sonnet 4.6 / Haiku 4.5 | Claude 知识 cutoff 2026-01 | 2026-05-22 |
| OpenAI | GPT-5.5 Thinking | 未公开 | 2026-05-22 |
| Google | **Gemini 3.5 Flash / 3.5 Pro**(2026-05-19 GA) | 未公开 | 2026-05-22 |
| DeepSeek | V4-Pro / V4-Flash | 未公开 | 2026-05-22 |

⚠️ **如果距 last_verified 超过 30 天,必须 WebSearch 重新验证**。

---

## 实证案例:训练 cutoff 漏报

### 案例 #001:Gemini 3.5 Flash 漏报(2026-05-22)

**事件**:用户提到"Gemini 3.5 Flash",Claude 未 WebSearch 验证,用 CLI ping 探针得出"3.5 不存在"错误结论。

**真相**:Gemini 3.5 Flash 2026-05-19 GA(3 天前),但 gemini-cli 0.42.0 的 OAuth Code Assist endpoint 还没接入 GA model ID。用户记得没错,Claude 错。

**根因**:Claude 训练 cutoff 2026-01,对 2026-05-19 发布完全无知;同时 CLI ping 失败不能证伪模型存在(只能证伪 CLI 接入)。

**纠正措施**:本文档建立 + 加入「AI 模型版本一律 WebSearch 验证」纪律 + 落档为 [user-decision-log #002](../../meta/user-decision-log.md)。

---

## 关联文档

- [docs/meta/M-000-meta-vision.md](../../meta/M-000-meta-vision.md) §7 服务变化触发 review
- [docs/meta/user-decision-log.md](../../meta/user-decision-log.md) #002 训练 cutoff 漏报实证
- [docs/standards/worktree-audit-workflow.md](../../standards/worktree-audit-workflow.md) 多家对抗工作流
