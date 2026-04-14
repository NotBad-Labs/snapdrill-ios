<!-- last_verified: 2026-04-14 -->
<!-- layer: pattern -->
# 项目记忆（Agent-Agnostic）

> 给所有智能体和人类提供可审计、可回放、入 git 的共享上下文层。
> 本目录仅记录执行状态与过程决策，不定义产品事实、技术事实或正式裁决。

## 文件结构

| 文件 | 内容 | 更新频率 |
|---|---|---|
| `feedback.md` | 项目纪律与反馈规则（12 条，所有智能体共遵） | 低频（新教训时） |
| `decisions.md` | 工程决策记录（非 ADR） | 按需 |
| `handoff.md` | 当前接手状态、优先级、阻塞、下一步 | 高频（每次接手） |

## 历史归档

- `docs/archive/timeline.md` — 事件时间线（2026-04-09 ~ 2026-04-13）
- `docs/archive/audit-report-20260409.md` — 三方审计报告

## 写回规则

1. 每次新 agent 接手时先读 `handoff.md`，再读 `feedback.md`。
2. 做出关键执行选择时，写入 `decisions.md`。
3. 合并 PR 后 24 小时内，更新 `handoff.md`。
4. 若与 `PRD` / `ADR` / `TDD` 冲突，以上游文档为准。

## 与智能体私有记忆的关系

- 智能体私有记忆（如 `~/.claude/projects/.../memory/`）只作本地提示，不入 git。
- 本目录适合团队协作与跨工具审计。
- 若私有记忆与仓库文档冲突，按仓库第一方文档裁决。
