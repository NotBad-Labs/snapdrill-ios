---
last_verified: 2026-05-25
layer: pattern
scope: template
name: resume-from-handoff
description: 新 Claude 会话接手项目时，按最小上下文加载顺序读取，避免强吃长 transcript。当会话开始或用户说"接手 / 续上次工作 / resume / handoff"时触发。
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
context: fork
disable-model-invocation: false
user-invocable: true
---

# /resume-from-handoff — 接手时最小上下文加载

## 触发场景

- 新会话第一次工作于 SnapDrill 项目
- 用户说："接手 / 续上次工作 / resume / 你看看现状 / 我们到哪了"
- 长会话 compact 后需要重建上下文

## 加载顺序（严格按序，少即是多）

按 Hermes "less context, more retrieval" 思想（参考 `docs/archive/research/hermes-agent-study-20260418.md`）。

### Tier 1：必读（5 文件，约 800 行）
1. `CLAUDE.md` —— 项目入口（已自动加载）
2. `STATUS.md` —— 当前快照
3. `docs/memory/handoff.md` —— 接手状态、待合并 PR、阻塞
4. `docs/memory/feedback.md` —— 项目纪律（F-001~F-N）
5. `docs/standards/collaboration.md` —— 三方协作架构（如即将做对抗审查）

### Tier 2：按需（用户描述任务后再读）
6. 任务相关的 `docs/standards/<rule>.md`（如改代码 → coding.md）
8. 任务相关的 `docs/product/<file>.md`（如改产品文档 → 对应文件）
9. 当前 git 状态：`git status` + `git log --oneline -10` + `gh pr list --state open --author '@me'`

### Tier 3：避免（除非明确需要）
- ❌ 全部 `docs/memory/decisions.md`（除非要写新 ADR）
- ❌ 全部 `~/.claude/plans/*`（旧三方对抗汇总，仅相关任务时按需）
- ❌ 全部 STATUS.md 历史段（看头部"当前状态"段即可）

## 不加载长 transcript

- 不强吃"上次会话的全部对话"
- 不读完整 ADR 历史
- 不展开所有 docs/product/ 内容

如果 Tier 1+2 不足以回答用户问题：
- 用 Grep 检索相关关键词
- 不要"先读所有文件再说"

## 启动报告模板

接手完成后给用户一句话简报：

```markdown
**接手完成**
- 当前焦点：[STATUS.md 当前状态段]
- 待合并 PR：#NNN ([标题简短])
- 阻塞：[handoff.md 阻塞链]
- 最近阶段：[handoff.md 当前接手状态]
- 我准备 [下一步动作]，你确认或修正？
```

## 反模式

- ❌ 一上来读 20+ 文件再开始（违反 Tier 原则）
- ❌ 跳过 STATUS / handoff 直接写代码（必失上下文）
- ❌ 读完 Tier 1 不简报就开干（用户不知 Claude 抓了什么）
- ❌ 把 docs/memory/decisions.md 整篇贴 chat（应 grep 关键词）

## 与 Hermes 对应

Hermes 用 SQLite + FTS5 做 episodic memory recall。SnapDrill 当前用 ripgrep + 人工 routing（见 `docs/standards/memory-routing.md`）+ checkpoints 实现等价效果。无需引入 Hermes runtime。

## 与 post-merge / phase-closeout 的分工

- `post-merge` Step 2：合并 PR 后更新 STATUS.md（写入）
- `phase-closeout`：phase 结束写 checkpoint（写入）
- `resume-from-handoff`：接手时**只读**最小上下文，不写入

三 skill 一组形成完整的 "context lifecycle"。
