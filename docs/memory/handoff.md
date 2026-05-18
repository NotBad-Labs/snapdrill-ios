---
last_verified: 2026-05-18
layer: snapshot
freshness:
  max_age_days: 7
  decay_trigger: [pr_merge, branch_change]
---
# Handoff

## 当前接手状态

- **当前主力**：Claude Opus 4.7（Claude Code CLI）
- **辅审**：Codex CLI + Gemini CLI + DeepSeek V4-Pro
- **主分支**：`develop`
- **状态**：52 文档三方审计 Phase 0-2 完成，P0 已修，P1 待修

## 进行中：文档系统审计

Claude + Codex + Gemini 完成 52 个第一方文档的 Phase 0-2 审计。

- Rubric: `docs/standards/audit-rubric.md`
- Ledger: `~/.claude/plans/audit-ledger.tsv`
- Codex 独立审查了修复结果，发现了更高优先级的新问题

## Codex 当前任务（P1 修复）

按 Codex 排的优先级：
1. engineering.md ↔ feedback.md SSOT 矛盾（engineering 仍写 feedback 是 SSOT）
2. KNOWLEDGE_MAP.md 旧 rules 入口模型
3. deployment.md frontmatter 与正文 last_verified 不一致
4. standards/README.md 缺 audit-rubric/execution-gates 条目
5. api-pitfalls/apple-limits/appstore-metadata freshness 刷新
6. CLAUDE.md + AGENTS.md 冗余合并

详见 `CODEX_HANDOFF.md`

## 下一会话方向

- A. 确认 Codex P1 修复完成 → 回归 docaudit
- B. Apple 账号缴费 → 解锁 #163 链
- C. #626 真机验证

## Boot 序列（新会话必读）

| 序号 | 文件 | 为什么读 |
|---|---|---|
| 1 | `STATUS.md` | 项目状态快照 |
| 2 | `docs/workflow.md` | 流程规范、DoD |
| 3 | `docs/standards/coding.md` | 编码规范 |
| 4 | `docs/standards/testing.md` | 测试规则 |
| 5 | `docs/tech/api-pitfalls.md` | 已知 API 陷阱 |
| 6 | `docs/tech/apple-limits.md` | Apple 平台能力边界 |
| 7 | `docs/standards/apple-native.md` | Apple 原生 UI 模式 |
| 8 | `docs/memory/feedback.md` | F 规则索引 |

历史 handoff 记录已由 git log 保留，不再在文件中堆积。
