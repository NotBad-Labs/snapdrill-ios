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
