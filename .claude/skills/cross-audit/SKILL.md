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
2. **F-011 审计期间只读**：三方启动后不得修改被审文件，等汇总后统一修复
3. **F-012 不偷懒**：禁止抽查后声称"基本准确"，必须全量

## 启动前 checklist

- [ ] 已读取 `docs/principles/codex-delegation.md`（默认 effort high for 审计/Review）
- [ ] 已读取 `docs/principles/gemini-delegation.md`（不加 sandbox，防 7 分钟卡死）
- [ ] 已读取 `docs/principles/shared-constraints.md`（必须内联到 prompt）
- [ ] 已读取 `docs/memory/feedback.md` F-008 / F-011 / F-012
- [ ] 审计目标和文件清单已明确（写下来，不要口头默认）

## 三方启动模板

### 给 Claude（主线程）
```
你审 [审计目标]，范围 [完整文件清单]，五维度（DRY/YAGNI/Skill 化/一致性/时效性）。
不分工，独立完成全部。
```

### 给 Codex（Agent 委派或 codex exec）
```
模型：gpt-5.4，effort: high
范围：与 Claude 完全一致 [审计目标 + 完整文件清单]
五维度：DRY / YAGNI / Skill 化 / 一致性 / 时效性
内联约束：[shared-constraints.md 全文]
输出格式：结构化报告，分级 Critical / Warning / Info，每项含证据
不参考 Claude 的中间结论
```

调用方式优先级：
1. `codex exec --model gpt-5.4 --full-auto "<prompt>"`（最稳定，可写文件）
2. `Agent(subagent_type=codex:codex-rescue, prompt=...)`（fallback，注意 plan mode 误判风险）

### 给 Gemini（Bash）
```bash
gemini -p "你审 [审计目标]
范围：与 Claude/Codex 完全一致 [完整文件清单]
五维度
内联约束：[shared-constraints.md 全文]
输出：结构化中文报告，分级 Critical / Warning / Info
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
- ❌ 审计期间提前修改被审文件 — 违反 F-011
- ❌ 抽查 10 处说"全部一致" — 违反 F-012

## 完成标准

1. 三家独立报告全部到位（写到 `~/.claude/plans/doc-audit-{claude,codex,gemini}.md`）
2. 汇总表格按共识度排序
3. 每个 Critical 经实证验证（Read + Grep）
4. 综合报告归档（建议路径 `docs/archive/{topic}-audit-{YYYYMMDD}.md`，需用户确认）

## 上游引用

- `docs/principles/codex-delegation.md` — Codex 委派详细规范
- `docs/principles/gemini-delegation.md` — Gemini 委派详细规范
- `docs/principles/collaboration.md` — 三方协作总体架构 + 汇总表格模板
- `docs/principles/shared-constraints.md` — 委派 prompt 共享约束
- `docs/memory/feedback.md` — F-008 / F-011 / F-012 详细规则
