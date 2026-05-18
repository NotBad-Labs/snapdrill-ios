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
- **状态**：零内部阻塞 · 文档治理 + skill 体系重构完工 · 53 skills

## 下一会话方向

- A. Apple 账号缴费 → 解锁 #163 链
- B. #626 真机验证（QuestionSplittingService）
- C. #699 backlog Could Have 项

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
