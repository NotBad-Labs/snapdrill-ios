---
name: cross-audit
description: 三方对抗性审查工作流（Claude + Codex + Gemini）。强制 F-008「相同完整任务、不分工」纪律。当用户要求"三方审计/对抗性审查/独立审计/cross-audit"，或 PR 合并前需对抗性 review 时触发。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Agent
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /cross-audit — 三方对抗性审查工作流

## 触发场景

- 用户说："三方审计 / 对抗性审查 / 独立审计 / cross-audit"
- PR 合并前需对抗性 review（DoD 要求 F-005）
- 大型重构 / 文档系统性变更前

## 必须遵守的纪律（F-008 + F-011 + F-012）

1. **F-008 相同完整任务**：三家审同**同一批文件**完整集合，**不分工**。冗余是刻意的——通过"你发现了我没发现的"暴露盲区
2. **F-011 被审范围只读**：三方启动后不得修改被审文件；`Write` 只允许落审计报告，等汇总后统一修复
3. **F-012 不偷懒**：禁止抽查后声称"基本准确"，必须全量

## 启动前 checklist

- [ ] 已读取 `docs/standards/codex-delegation.md`（默认 effort high for 审计/Review）
- [ ] 已读取 `docs/standards/gemini-delegation.md`（不加 sandbox，防 7 分钟卡死）
- [ ] 已读取 `docs/standards/shared-constraints.md`（必须内联到 prompt）
- [ ] 审计目标和文件清单已明确（写下来，不要口头默认）
- [ ] 审计报告落盘路径已明确；所有委派 prompt 已写明"不得修改被审文件"

## 三方启动模板

### 给 Claude（主线程）
```
你审 [审计目标]，范围 [完整文件清单]，五维度（DRY/YAGNI/Skill 化/一致性/时效性）。
不分工，独立完成全部。
PR 审查场景必须补 4 维评分：Scope Fidelity / Code Quality / Test Coverage /
Architecture Fit（0-10 分，整数），见 cross-audit-consensus §2.5。
```

### 给 Codex（Agent 委派或 codex exec）
```
模型：gpt-5.4，effort: high
范围：与 Claude 完全一致 [审计目标 + 完整文件清单]
五维度：DRY / YAGNI / Skill 化 / 一致性 / 时效性
内联约束：[shared-constraints.md 全文]
输出格式：结构化报告，分级 Critical / Warning / Info，每项含证据
只读边界：不得修改范围内文件；如需落盘，仅写审计报告到指定路径
PR 审查场景必须在报告末尾补 4 维评分表（0-10 整数分 + 综合平均），
维度：Scope Fidelity / Code Quality / Test Coverage / Architecture Fit
不参考 Claude 的中间结论
```

调用方式优先级：
1. `codex exec --model gpt-5.4 --full-auto "<prompt>"`（最稳定，write-capable 仅用于写审计报告；prompt 必须禁止修改被审文件）
2. `Agent(subagent_type=codex:codex-rescue, prompt=...)`（fallback，注意 plan mode 误判风险）

### 给 Gemini（Bash）
```bash
gemini -p "你审 [审计目标]
范围：与 Claude/Codex 完全一致 [完整文件清单]
五维度
内联约束：[shared-constraints.md 全文]
输出：结构化中文报告，分级 Critical / Warning / Info
PR 审查场景末尾补 4 维评分表（0-10 整数分 + 综合平均），
维度：Scope Fidelity / Code Quality / Test Coverage / Architecture Fit

**评分纪律（强制，来自 docs/standards/gemini-delegation.md 评分任务纪律段）**：
1. 每维度必须引用 plan / Issue Sprint Contract 明文条目作锚点；禁止感性打分
2. **默认从 8.0 起评**，每个正向证据 +1，每个负向证据 -1
3. **10.0 分硬门槛**：仅在 plan 每一条都明文命中 + 无任何 scope 外增量 + 架构严格遵守时给
4. 若某维度无 plan/contract 可对照，降权或标 N/A（不折算为 10.0）
5. **方差自检**：若你的分数与 Codex 可能差 ≥ 2 分，在报告末尾解释原因（自省锚点是否不足）
6. 裁决权重：你守纪律时作次锚点（不等于主锚点 Codex），不守时降为参考
" 2>&1
```

注意：
- 不加 `--sandbox`（性能 2x+ 损失）
- 单次 prompt 不超 5 个长文件，超出则分批
- 大型审计可能触发 429 速率限制，需 retry

## 汇总表格（collaboration.md:71 模板）

| # | 维度 | 发现 | Claude | Codex | Gemini | 共识 | 证据 |
|---|---|---|---|---|---|---|---|
| R1 | ... | ... | Critical | Critical | — | 2/3 ✅ | ... |

**共识度判定**：
- ≥2/3 → 高置信度，进入修复
- 单家 → 必须实证验证（按 F-006 深度读源码）
- 实证否定 → 归档为"误判"案例（沿袭 Gemini Critical 2 Alert 案例的处理范式）

## 反模式（本 skill 旨在拦截）

- ❌ "Gemini 擅长 X，让它审 X；Codex 擅长 Y，让它审 Y" — 违反 F-008
- ❌ "为节省时间，三家分工" — 失去对抗性，盲区无法暴露
- ❌ "Gemini 报 Critical 直接修" — 未经实证验证，可能是误判（历史多次）
- ❌ 审计期间提前修改被审文件 — 违反 F-011；允许写审计报告不等于允许改被审范围
- ❌ 抽查 10 处说"全部一致" — 违反 F-012

## 完成标准

1. 三家独立报告全部到位（写到 `~/.claude/plans/doc-audit-{claude,codex,gemini}.md`）
2. 汇总表格按共识度排序
3. 每个 Critical 经实证验证（Read + Grep）
4. 综合报告归档（建议路径 `docs/archive/{topic}-audit-{YYYYMMDD}.md`，需用户确认）

## 内嵌纪律（权威源）

本 skill 是 F-008、F-011、F-016 的权威定义源。`docs/memory/feedback.md` 仅保留索引指针。


### F-008: 三方相同完整任务

三方审计必须审同一批文件的完整集合，**不分工**。冗余是刻意的——通过"你发现了我没发现的"暴露盲区。

**Why:** 早期审计曾按擅长领域分工（"Gemini 擅长 X 让它审 X，Codex 擅长 Y 让它审 Y"），结果失去对抗性，每家只覆盖自己分到的子集，单点盲区无人交叉验证。

**How to apply:** 启动三方前明确写下"审计目标 + 完整文件清单"，三家收到的 prompt 在范围段措辞**逐字一致**。禁止以"为节省时间"为由分工。冗余成本是对抗性的对价。


### F-011: 审计期间三方只读

审计流程中三方必须同时只读审计 → 汇总比对 → 统一修复。审计期间不得提前修改被审文件。

**Why:** api-reference.md 审计中 Claude 提前修改文件（731→779 行），导致 Codex 检测到文件变更后暂停。

**How to apply:** 三方并行启动后审计结果只记录在回复中不触碰文件，等全部完成后汇总比对再统一修复。另外：抽查 ≠ 审计。


### F-016: 质疑方批准，禁止自审自批

修复审查发现的问题后，必须提交回原质疑方（Codex/Gemini/Xcode）复核。只有提出问题的 reviewer 确认修复有效，才能声称"问题已解决"。Claude 自己不允许批准合并。

**Why:** Claude 修复 Gemini Critical 发现（内存风险）后直接说"准备合并"，跳过了 Gemini 复核。自审自批违反对抗性审查的根本目的——独立视角验证。

**How to apply:** 修复后必须重新提交给原 reviewer：Gemini 提的问题回 Gemini 验收，Codex 提的问题回 Codex 验收，Xcode 提的问题回 Xcode 验收。只有 reviewer 说"通过"才能声明修复完成。


## 上游引用

- `docs/standards/codex-delegation.md` — Codex 委派详细规范
- `docs/standards/gemini-delegation.md` — Gemini 委派详细规范
- `docs/standards/collaboration.md` — 三方协作总体架构 + 汇总表格模板
- `docs/standards/shared-constraints.md` — 委派 prompt 共享约束
- `docs/memory/feedback.md` — F 规则索引
