<!-- last updated: 2026-04-13 -->
<!-- freshness: max_age_days=3, decay_trigger=[issue_change,branch_change,priority_change], layer=snapshot -->
# Handoff

## 当前接手状态

- 主力智能体：Claude Code
- 主分支：`develop`
- 当前工作分支：无（develop 上无活跃开发）

## 当前状态

项目主权重组已完成并合并（PR #587）。文档精简到 68 文件，工程哲学 7 条原则，skills 6 个。
所有 PR 已关闭（0 open）。功能开发被 Apple 开发者账号（#163）阻塞。

## 关键事实（当前快照）

- `docs/principles/` 是 agent-agnostic 规则唯一源
- `.claude/rules/` 是 Claude Code 的薄指针（自动路由到 `docs/principles/`）
- 委派文件（codex-delegation.md、gemini-delegation.md）在 `.claude/rules/`（Claude 专有）
- 项目级反馈：`docs/memory/feedback.md`（12 条规则）
- 测试基线：130 tests（SnapDrillFeaturesTests）
- 113 个历史分支待清理
- iOS 26 已发布，项目基于 iOS 26.0+ / Xcode 26.4 / Swift 6.3
