---
last_verified: 2026-04-22
layer: contract
---
# .agent-harness/ — agent-harness consumer 契约

本目录声明 snapdrill-ios 与 [agent-harness](https://github.com/NotBad-Labs/agent-harness) 的消费关系。

## 当前状态（Phase D PR-D5，2026-04-22）

snapdrill-ios 作为 agent-harness **第一个 consumer + 孵化器（dual-role）**。

**PR-D5 只声明契约，不改变 snapdrill-ios 实际机制**：
- `.claude/hooks/` 继续用 snapdrill-ios 本地版本（**未** symlink 到 agent-harness/adapter-claude/hooks/）
- `.claude/skills/` 继续用 snapdrill-ios 本地版本
- `Scripts/audit/docaudit.py` 继续用 snapdrill-ios 本地版本
- `docs/principles/*` / `docs/memory/*` 等都继续用本地

这是 Codex 主锚推荐的"**非破坏性消费试点**"策略（Phase D consensus §5.4 C5）：先声明契约，后续再做实际接线。

## 文件

- `project.yaml` — 项目 metadata + upstream 契约 + overlay 路径声明
- `lock.json` — 锁定 upstream（agent-harness）的 commit SHA
- `README.md` — 本文件

## 后续可能的动作（不在 PR-D5 scope）

**Phase E PR-E4（首次反哺实战）候选动作**：

1. 选某个 snapdrill-ios 本地已被 agent-harness 迁走的 hook/skill，做对照验证：
   - `diff .claude/hooks/block-dangerous-bash.sh <agent-harness-path>/adapter-claude/hooks/block-dangerous-bash.sh`
   - 确认行为一致后，本地 symlink 到 agent-harness 版本
2. 在 CI 加一个 `agent-harness doctor` 并行 job（不替换现有 docaudit CI job）
3. 跑 `agent-harness extract-candidate` 看 snapdrill-ios 本地是否有值得反哺的新模式

**Phase F 候选**：
- snapdrill-ios 完整切换为 symlink 消费（删除本地重复副本）
- 或引入 agent-harness 作为 git submodule

## 与 agent-harness 的关系

```text
                                 ┌─────────────────────────────┐
                                 │      agent-harness          │
                                 │  (NotBad-Labs/agent-harness)│
                                 │                             │
                                 │  core/                      │
                                 │  adapter-claude/            │
                                 │  preset-ios/ (空)           │
                                 └──────────┬──────────────────┘
                                            │ upstream
                             ┌──────────────┴──────────────┐
                             │                             │
                             ▼                             ▼
                   ┌──────────────────┐          ┌───────────────────┐
                   │  snapdrill-ios   │          │  (future) other   │
                   │  (孵化器+消费者) │          │       consumer    │
                   │                  │          │                   │
                   │ .agent-harness/  │          │  .agent-harness/  │
                   │ .claude/         │          │  .claude/         │
                   │ Scripts/audit/   │          │                   │
                   │ docs/            │          │                   │
                   └──────────────────┘          └───────────────────┘
                             │                             │
                             └─────── 反哺 upstream ─────── ┘
                                  （Phase E+ 启用）
```

## 文档引用

- [agent-harness PHILOSOPHY](https://github.com/NotBad-Labs/agent-harness/blob/main/PHILOSOPHY.md)
- [agent-harness BOOTSTRAP](https://github.com/NotBad-Labs/agent-harness/blob/main/BOOTSTRAP.md)
- [agent-harness CONTRIBUTING（反哺协议）](https://github.com/NotBad-Labs/agent-harness/blob/main/CONTRIBUTING.md)
- [agent-harness core/tools/docaudit](https://github.com/NotBad-Labs/agent-harness/tree/main/core/tools/docaudit)
- [agent-harness adapter-claude](https://github.com/NotBad-Labs/agent-harness/tree/main/adapter-claude)
- snapdrill-ios 本地：[docs/memory/decisions.md](../docs/memory/decisions.md) agent-harness 抽仓决策
- Phase D/E consensus 归档：`~/.claude/plans/phase-de-consensus-20260422.md`（私有）
