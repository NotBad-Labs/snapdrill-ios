<!-- last updated: 2026-04-13 -->
<!-- freshness: max_age_days=7, decay_trigger=[issue_change,pr_merge,priority_change], layer=snapshot -->
# Agent Memory（Repo 可追溯）

> 目的：给 Codex/Gemini/人工协作提供一个可审计、可回放、入 git 的共享上下文层。
> 边界：本目录仅记录执行状态与过程决策，不定义产品事实、技术事实或正式裁决。

## 文件结构

| 文件 | 内容 | 更新频率 |
|---|---|---|
| `handoff.md` | 当前接手状态、优先级、阻塞、下一步 | 高频（每次接手） |
| `timeline.md` | 关键事件时间线 + 证据锚点（Issue/PR/commit） | 中高频 |
| `decisions.md` | 执行策略与取舍理由（非 ADR） | 按需 |
| `backlog.md` | 接管后的可执行 backlog（按优先级） | 中频 |

## 历史归档

- 2026-04 Baseline v1 的过程性审计与批次记录已归档到 `docs/archive/2026-04-baseline-v1/memory/`，不再作为当前主线执行输入。

## 写回规则

1. 每次新 agent 接手时先读 `handoff.md`，再读 `timeline.md` 最近 7 天记录。
2. 做出关键执行选择（例如先修哪个 issue、是否重构文档体系）时，写入 `decisions.md`。
3. 合并 PR 后 24 小时内，把结果回写到 `timeline.md` 和 `handoff.md`。
4. 若与 `PRD` / `ADR` / `TDD` 冲突，以上游文档为准，并在本目录标注“待上游同步”。

## 与 Auto Memory 的关系

- Auto Memory（`~/.claude/projects/.../memory/`）属于工具私有记忆，只作本地提示，不入 git，不作为治理裁决依据。
- 本目录适合团队协作与跨工具审计，可被 code review、blame、PR 记录追溯。
- 若私有记忆与 `docs/product/*`、`docs/decisions/*`、`docs/tech/*` 或 `docs/memory/*` 冲突，按仓库第一方文档裁决。
