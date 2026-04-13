<!-- last updated: 2026-04-13 -->
<!-- freshness: max_age_days=3, decay_trigger=[issue_change,branch_change,priority_change], layer=snapshot -->
# Handoff

## 当前接手状态

- 主力智能体：Claude Code（用户决策，2026-04-13）
- 主分支：`develop`
- 当前工作分支：`chore/project-sovereignty`（项目主权重组）

## 当前优先级

1. **项目主权重组**（当前进行中）：建立 `docs/principles/` 作为 agent-agnostic 规则源
2. `#582` PR review + 合并（Share Extension 后台读图 + AppActivityTracker 全链路接线）
3. `#584` PR review + 合并（CI Swift Testing 计数识别）
4. `#585` PR 需要 re-scope（受项目主权重组影响，docs/agent/ 将被清理）
5. 账号依赖型事项（`#479/#485/#486/#490`）继续阻塞，等待 Apple 开发者账号

## 关键事实（当前快照）

- 项目架构重组中：`docs/principles/` 取代 `.claude/rules/` 和 `docs/agent/rules/` 作为规则唯一源
- `.claude/rules/` 保留为 Claude Code 的薄指针（自动路由到 `docs/principles/`）
- 委派文件（codex-delegation.md、gemini-delegation.md）仍在 `.claude/rules/`（Claude 专有）
- 项目级反馈已合并到 `docs/memory/feedback.md`（12 条规则）
- CLAUDE.md 和 CODEX.md 均为对称的纯指针文件
- 测试基线：130 tests（SnapDrillFeaturesTests）

## 下一步建议

1. 完成项目主权重组 PR，合并到 develop
2. Review 并合并 #582（源代码修复）
3. Review 并合并 #584（CI 改进）
4. Re-scope #585（适配新的 docs/principles/ 结构）
