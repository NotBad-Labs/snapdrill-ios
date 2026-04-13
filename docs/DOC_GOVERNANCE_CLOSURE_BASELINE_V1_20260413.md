# 文档治理里程碑收口报告（Codex Baseline v1）

> 日期：2026-04-13  
> 里程碑：`Codex Baseline v1（文档治理）`  
> 主 issue：`#583`

## 结论

`#583` 定义的文档治理目标已满足，产品文档体系进入“稳定 SoT + 增量维护”阶段。

## #583 范围项对照

| #583 范围项 | 状态 | 证据 |
|---|---|---|
| 根级执行入口迁移（`CODEX.md`） | ✅ 完成 | `CODEX.md`、`docs/agent/CODEX_BASELINE_20260413.md` |
| 规则文档迁移到 `docs/agent/rules/*` | ✅ 完成 | `docs/agent/rules/*.md`、`docs/workflow.md` |
| 清理 `.claude/skills/**/*.md`（保留 `.claude/worktrees/**` 排除） | ✅ 完成 | `docs/DOC_GOVERNANCE_CLOSURE_20260411.md`、`docs/workflow.md` |
| 全量文档冲突红名单与裁决回写 | ✅ 完成 | `docs/DOC_MISLEADING_AUDIT_20260413.md`、`docs/DOC_MISLEADING_AUDIT_BATCH2_20260413.md` |
| 关键文档权威链路复核（product -> tech -> memory） | ✅ 完成 | `docs/workflow.md`（裁决顺序）、`docs/DOC_DEPENDENCY_MAP.md`（传播关系）、`docs/memory/*`（执行留痕） |
| 里程碑收口总结（含风险与未决项） | ✅ 完成 | 本文档 + `#583` 评论留痕 |

## 验收标准对照

1. 主链路文档不再依赖 `CLAUDE.md` 与 `.claude/rules/*`：✅  
说明：主链路入口已切换为 `CODEX.md` 与 `docs/agent/rules/*`；对 `CLAUDE.md/.claude/rules` 的引用仅保留为历史迁移说明。

2. `docs/agent/*` 成为可追溯执行基线：✅  
说明：协作、委派、共享约束、记忆隔离规则均已纳入 `docs/agent/rules/*`，并在 `docs/workflow.md` 对齐。

3. 文档冲突项有明确裁决与回写证据：✅  
说明：Batch 1/Batch 2 已形成冲突清单、裁决结论和回写结果，且 Batch 2 当前无挂起裁决项。

## 当前风险与未决项（非文档基线阻断）

- `#579` Share Extension 手工体感回归待完成（代码已改，自动化证据分层完成）。
- `#580` Profile 切换阻断语义手工体感回归待完成（自动化测试已补齐）。
- StoreKit 相关能力接线（`#479/#485/#486`）仍为产品能力阻塞项，但不影响文档基线稳定性结论。

## 后续维护策略

- 文档冲突继续按 `docs/workflow.md` 裁决顺序处理。
- 外部模型委派按“记忆隔离”硬规则执行（Claude `--bare --no-session-persistence`；Gemini 禁 `--resume`）。
- 新增冲突项采用“先建 issue、再回写 SoT”的增量治理模式。
