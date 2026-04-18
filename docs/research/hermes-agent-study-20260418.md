---
last_verified: 2026-04-18
layer: archive
status: archived
reason: "一次性研究产物，结论已落地为规则/skills/hooks（PR 后续）"
---
# Hermes Agent 三方对抗研究（2026-04-18）

> 研究方：Claude Opus 4.7 + Codex GPT-5.4 + Gemini 3 Auto（F-008 三方相同完整任务）
> 触发：用户问 "Hermes agent" 概念是否值得借鉴
> 原始三方报告：`/tmp/hermes-research/{claude,codex,gemini}.out`（一次性，已删）

## 一句话结论

**Hermes Agent** = Nous Research 开源的 `NousResearch/hermes-agent`（v0.10.0，~96.2k stars）。本质是 "ReAct + 三层记忆 + skill 自抽取 + 多渠道 gateway" 的产品化组合。**SnapDrill 不引入本体，借鉴其 memory taxonomy 和 context compaction discipline**。

## 三方共识

### 1. 定义与起源
- 项目：`NousResearch/hermes-agent`（MIT，2026-02 内部起步，2026-03-12 v0.2.0 首次 tagged 公开）
- 不是论文/学术概念，是 "battery-included autonomous agent runtime"
- 与 Nous Hermes LLM 系列（Hermes 2/3/4 微调权重）区分；后者是模型，前者是框架

### 2. 核心机制（三层记忆 + 上下文纪律）

**(a) 三层记忆**
- Working memory：当前会话上下文
- Episodic memory：SQLite + FTS5 全文索引；召回时不塞回原文，而是 query-focused summary 注入
- Procedural memory (skills)：Markdown + YAML frontmatter 5 段结构。任务 ≥ 5 次 tool call 后自动抽取

**(b) 上下文 compression 纪律**
- 双层：Gateway 85% 保险丝 + Agent 50% 主压缩
- 保护头尾压中间（`protect_first_n` + `protect_last_n`）
- **System prompt 冻结** 保 prefix cache（工程细节，省钱）

**(c) Skills progressive disclosure**
- `skills_list()` 只给 name/description
- 需要时才 `skill_view(name)` 读全文
- 再需要时才读 skill 内 reference file

**(d) Context file priority**
- `.hermes.md` > `AGENTS.md` > `CLAUDE.md` > `.cursorrules`
- 同时 `SOUL.md` 独立加载

### 3. 与其他框架对比

| 框架 | 定位 | 与 Hermes 关键差异 |
|---|---|---|
| ReAct | prompt pattern | Hermes 本质是 ReAct + memory/skill 外壳 |
| LangGraph | low-level orchestration | LangGraph 给 primitives 让你自造；Hermes 给成品 |
| Claude Agent SDK | Anthropic 原生 harness | SDK 锁 Claude 模型；Hermes 模型无关、自托管 |
| AutoGen / CrewAI | 多 agent 协作 | Hermes 单 agent + sub-agent 长期驻留 |
| Cognition Devin | 闭源 SaaS 专注 SWE | Hermes 开源通用 |
| Windsurf Cascade | IDE 内置 | Hermes 后端常驻 |

**核心差异**：Hermes 的创新不在编排模型，在**整合方式 + 默认纪律**。

### 4. 实现与生态

- 成熟度：Beta 向 production 过渡（v0.10.0 仅 6 周从 v0.1）
- Skills 标准：agentskills.io 开放，Claude Code / Codex / Cursor / Gemini CLI 等 12 家兼容
- 商业采用：小团队 + 独立开发者；无大企业公开案例
- 已知问题：
  - Issue #7826 默认 ALLOW-ALL，4 Critical / 9 High 安全发现
  - 本地模型转发性能下降（1-2 tok/s vs 45 tok/s 直连）
  - Claude Opus 托管推理可达 $131/day

## 对 SnapDrill 的判断

### 不引入 Hermes 本体的理由
- SnapDrill 上下文瓶颈在工具链协同（三方对抗），不在 agent 长期驻留
- Hermes 默认 ALLOW-ALL + skill 注入风险 → 对签 Apple 证书仓库不可接受
- Swift/Xcode 工具链 Hermes 不理解
- Honcho user modeling 对单人项目过度

### 借鉴 Hermes 思想的落地（用户已批准 "全做"）

**规则**（2 条）
- `memory-routing`：明确 docs/product/ vs docs/tech/ vs docs/memory/ vs 私有 auto-memory 的内容路由
- `phase-compaction`：每 3-5 PR 合并后强制产出结构化摘要（Goal / Done / Open / Decisions / Risks / Next）

**Skills**（3 个新增到 .claude/skills/）
- `cross-audit-consensus`：三方完整审计折成共识/冲突/裁决表
- `phase-closeout`：长任务（如 Phase 4 收官 19 PR）checkpoint summary 生成
- `resume-from-handoff`：接手时只读 STATUS + handoff + 最近 checkpoint，不强吃长 transcript

**Hooks + Scripts**
- `post-merge-checkpoint` hook：PR 合并后自动写 `docs/memory/checkpoints/`（Goal/CI/风险）
- `Scripts/recall-index.sh`：ripgrep 包装做 docs/ + STATUS + memory 快速召回（Codex 建议 SQLite FTS5，Claude 评估 SnapDrill 规模 ripgrep 即够）
- `long-session-guard` hook 或 skill：会话过长提示先 compact 再继续

## 批判性评估

### 真有东西
- Skill 自抽取 + 冻结 system prompt 保 prefix cache + FTS5/LLM 分级记忆，**工程组合拳**
- 6 周 96k stars 反映普遍痛点（"2026 所有 agent 都记不住昨天"）

### 被炒作
- "Self-improving" 远没宣传那么强 — 本质是 system prompt 工程自动化
- "Grows with you" 边际收益递减，第 50 个 skill 可能互相矛盾
- 性能/成本数据不透明

### 不值得采纳的场景
- 任务很短，几轮就结束
- 团队要确定性 workflow，不是 agent 自增长
- 合规要求不允许 agent 自写 memory/skills
- 项目已有良好 CLAUDE.md + rules + docs + auto-memory 体系（如 SnapDrill）
- 需要 framework 嵌入产品，不是现成 runtime

## 三方对抗细节

### Claude Opus 4.7 独立研究
- 18 次工具调用，涵盖 WebSearch + WebFetch
- 主要发现 Issue #7826 安全风险 + 成本透明度问题
- 完整报告：3800 字

### Codex GPT-5.4 (effort high) 独立研究
- 长时间 web search 链路（80KB raw output，一些 search 失败）
- 主要细节贡献：v0.2.0 timeline / 双层 compression 50%+85% / progressive disclosure / context file priority
- 完整报告：4200 字

### Gemini 3 Auto 独立研究
- **失败**：1.3KB 仅停在"搜索计划阶段"，无实质内容
- 符合 `feedback_gemini_adversarial.md` 已记录的 Gemini 某些场景偏短行为
- 不影响共识结论（Claude + Codex 2/2 一致）

## 信息来源（关键 URL）

- github.com/NousResearch/hermes-agent
- hermes-agent.nousresearch.com/docs/
- hermes-agent.nousresearch.com/docs/developer-guide/context-compression-and-caching/
- hermes-agent.nousresearch.com/docs/user-guide/features/memory/
- hermes-agent.nousresearch.com/docs/user-guide/features/skills/
- deepwiki.com/NousResearch/hermes-agent
- github.com/agentskills/agentskills
- github.com/plastic-labs/honcho
- code.claude.com/docs/en/memory
- code.claude.com/docs/en/agent-sdk/overview
- arxiv.org/html/2508.10146v1（Agentic AI Frameworks 综述）

---

> 本文档作为研究归档（layer: archive）。后续落地的规则 / skills / hooks 在各自位置维护，不再回引本文档。
