---
name: cross-audit-consensus
description: 把 Claude/Codex/Gemini 三方独立审计/研究输出，折成"共识 / 单家独有 / 冲突"裁决表。当用户要求汇总三方对抗结果，或 cross-audit skill 已产出三方报告需要比对时触发。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /cross-audit-consensus — 三方对抗结果汇总

## 触发场景

- 用户说："汇总三方 / 比对三方 / 出共识表"
- `cross-audit` skill 已产出三方独立报告，需要 Claude 充当 reviewer 折叠
- Hermes 研究、文档审计等三方完成后

## 输出格式（强制）

### 1. 三方完成度速览

```markdown
| 方 | 状态 | 字数 | 关键发现数 |
|---|---|---|---|
| Claude | ✅ 完整 | ~4000 | 8 |
| Codex | ✅ 完整 | ~4500 | 11 |
| Gemini | ❌ 失败/偏短 | 1.3KB | 0 实质 |
```

如有方失败，必须**显式标注**（参考 `feedback_gemini_adversarial.md`：Gemini 在某些场景偏短/幻觉，不得静默忽略）。

### 2. 共识表

```markdown
| 发现/方案 | Claude | Codex | Gemini | 共识 | 证据 |
|---|---|---|---|---|---|
| [简短描述] | Critical | Critical | — | 2/3 ✅ | 文件:行号 / URL |
```

**裁决原则**：
- 2/3 共识默认采纳
- 1/3 独有发现进 `docs/memory/decisions.md` 备忘（不采纳但不丢）
- 0 共识 / 严重冲突 → 用户裁决（不缝合方案）

### 2.5 量化评分（强制）

每次 consensus 必须给出三方各自在以下 4 维的打分（0-10），最后汇总为综合分。**这是评估不是裁决**——共识/冲突的采纳仍按 §2 原则，但分数决定"是否该 retry 一轮"。

```markdown
| 维度 | 含义 | Claude | Codex | Gemini |
|---|---|---|---|---|
| **Scope Fidelity** | 与 Issue Sprint Contract（Touches / No-Touch / Interface Delta）吻合度 | | | |
| **Code Quality** | swiftlint 违规、圈复杂度、架构一致（独立于 CI 的人工审查） | | | |
| **Test Coverage** | 新增/修改逻辑是否有对应测试，异常路径是否覆盖 | | | |
| **Architecture Fit** | 是否遵循 `docs/principles/engineering.md`（奥卡姆剃刀 / YAGNI / SSOT / 可逆性）与现有模式 | | | |
| **综合** | 上 4 项平均 | | | |
```

**Retry 阈值**：
- 任一方综合分 **< 7.0** → consensus 必须给出"建议按该方反馈 retry 一轮"的显式建议
- 任一方综合分 **< 5.0** → **硬性要求 retry**（继续合并视为违反 F-016 质疑方批准）
- 三方综合分均 **>= 8.5** → consensus 可直接给出"立即合并"建议
- 三方综合分方差 **> 2.5** → 必须在 §4 冲突表列出原因（为什么一方严重低分）

**评分原则**：
- 每维度 10 分制，整数打分；不打半分
- 打分依据必须引用具体证据（与 §2 共识表共用证据列）
- Sprint Contract 未填写的 Issue → Scope Fidelity 默认扣 2 分（F-018 违反）

**评分方权重**（防 Claude 自审 bias）：

当 Claude 同时是实施方（写了被审代码）和评分方时，**Claude 自审分作参考列出，不作裁决锚点**。裁决锚点按证据严格度顺序：

1. **Codex 严格评分**（对照 plan 明文逐条打分）— 主锚点
2. **Gemini 评分**（需满足 Gemini 委派纪律：逐条对照 plan，见 `docs/principles/gemini-delegation.md` 评分段；否则降权作参考）
3. **Claude 自审**（实施方自审时作参考；非实施方时与 Codex 平权）

**Why**：Harness Stage A+B 实战暴露 Claude 自审均分 9.3 vs Codex 7.5，方差 > 2.5 触发硬 retry（见 `docs/memory/checkpoints/2026-04-19-harness-stage-a-b.md` Risks）。根因是 Claude 既是实施方又是评分方，倾向看"完成度"而非 plan"吻合度"。把 Claude 自审作参考而非锚点，把裁决权交给独立视角（Codex）是对 F-016 质疑方批准的配套强化。

**何时降权 vs 何时平权**：
- Claude 在主对话内审查自己刚实施的 PR → **降权作参考**（当前场景）
- Claude 在主对话内审查他人或历史 PR → **与 Codex 平权**（独立视角）
- Claude 通过独立 Agent 委派审自己的 PR → **接近平权**（Agent fork context 减弱 bias），但建议仍以 Codex 为主锚点

**来源**：Anthropic Harness Design 2026-03-24 的 rubric 范式（Design Quality / Originality / Craft / Functionality），本项目根据 iOS 代码审查特点替换为 Scope Fidelity / Code Quality / Test Coverage / Architecture Fit 四维。详见 `docs/research/harness-engineering-study-20260418.md`。

### 3. 单家独有发现归档

| 来源 | 发现 | 处置 |
|---|---|---|
| Claude 独有 | ... | 进 decisions / 推迟 / 拒绝 |
| Codex 独有 | ... | 同上 |
| Gemini 独有 | ... | 同上 |

### 4. 冲突点（如有）

```markdown
| 维度 | Claude 主张 | Codex 主张 | Gemini 主张 | 我推荐 | 证据 |
|---|---|---|---|---|---|
```

按 `docs/principles/collaboration.md` 冲突裁决证据等级：编译/测试/日志结果 > 官方文档引用 > 代码分析推断 > 经验性判断。

### 5. 给用户的行动清单

- [ ] 高 ROI 共识项（建议立即采纳）
- [ ] 中等价值（用户裁决）
- [ ] 低价值/不采纳（理由）
- [ ] 冲突需用户拍板的具体问题

## 必须遵守的纪律

1. **F-008 同源**：汇总前确认三方输入是同一任务，不是分工的子集
2. **Gemini 验证**：Gemini 涉及具体文件 diff 的输出必须代码验证（feedback_gemini_adversarial.md）
3. **不缝合方案**：冲突时选一方完整方案，不混合（避免逻辑断裂）
4. **保留原始**：原始三方输出不删（落到 `~/.claude/plans/` 或 `docs/research/` 归档）

## 输出位置

- 临时汇总：贴回 chat
- 决策类汇总：`~/.claude/plans/<topic>-summary.md` 或 `docs/research/<topic>-<date>.md`
- 影响 ADR 的 → 同步到 `docs/decisions/ADR-NNN.md` "三方研究摘要" 段

## 反模式

- ❌ 三方都没看就汇总（必须 Read 所有三方原始输出）
- ❌ Gemini 失败时假装它有效（要标失败）
- ❌ "三方都同意" 但没列证据（必须给文件路径/URL）
- ❌ 缝合三方方案制造逻辑断裂的混合体（选一方完整方案）

## 历史案例

- Phase 4 文档审计：`~/.claude/plans/doc-audit-summary.md`
- Phase 4 P3 对抗起草：`~/.claude/plans/phase4-p1-adversarial-summary.md`
- Hermes agent 研究：`docs/research/hermes-agent-study-20260418.md`
