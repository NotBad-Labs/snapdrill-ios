---
last_verified: 2026-05-13
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [phase_change]
---
# Phase Checkpoint 2026-04-17 Phase 4 P2 Sprint

## Goal

执行 `~/.claude/plans/doc-audit-summary.md` P2 优先级条目：文档体系三方审计发现的 6 项中优先级治理（时效性修正、SSOT 去重、KNOWLEDGE_MAP 校准、失效 skill 引用清理、Issue 模板去重、archive 元信息）。

## Done

| PR | 主题 | 关键改动 |
|---|---|---|
| #650 | PR-D F-008 去重 | `docs/workflow.md:142-146` 改纯指针，指向 `collaboration.md` + `feedback.md` F-008 |
| #651 | PR-G archive 元信息 | `docs/archive/audit-report-20260409.md` 加"已归档·不可信"注记；`docs/memory/README.md` 同步 |
| #652 | PR-F 时效性修正 + T-01 追补 | `collaboration.md` Opus 4.6→4.7；`product-requirements.md` 端上 AI 毕业（MoSCoW Could Have → Done） |
| #653 | PR-H ux-design 失效 skill | 删除 `docs/principles/ux-design.md:5` 指向已废弃的 `ux-designer` / `user-advocate` skill 的死引用 |
| #654 | PR-K Issue 模板去重 | `docs/workflow.md:17-48` 改 SSOT 指针；`.github/ISSUE_TEMPLATE/feature_request.md` 合并 bug_report 独有字段 |
| #655 | PR-E KNOWLEDGE_MAP 校准 | 12→17 条，覆盖文件 ~25→~40；`docs/memory/README.md` 同步 |

## Open

- 无（6 PR 全部合并）
- 下一阶段 P3（#656~#663）在另一个 checkpoint

## Decisions

- F-008 三处陈述 → 保留 `collaboration.md`（完整说明）+ `feedback.md`（纪律版），`workflow.md` 降为指针（Codex 精化建议采纳）
- archive 旧审计不直接删除，改为元信息标注 "已归档 / 不可信 / 仅历史溯源"（用户判定）
- 产品文档 MoSCoW 表：端上 AI 标签/题目分割从 Could Have 移到 Done，不再保留为"未来待办"
- Issue 模板：feature_request.md 作为模板 SSOT，bug_report 独有字段合入

## Risks

- Mac mini runner 事件（2026-04-17 晚）：CoreSimulator 1051.49→1051.50 过时导致 #651/#652/#653 首轮 CI FAILURE；用户系统更新 + 重启 Mac mini（macOS 26.4.1 / Xcode 26.4.1）后恢复
- KNOWLEDGE_MAP 现 ~40 文件，接近"可手工维护"上限；后续如超过 50 文件需考虑自动生成

## Next

- Phase 4 P3 sprint（高优先级）：YAML frontmatter 5-layer schema + 40 文件迁移 + CI 校验门 + 备份/隐私拆分 + Claude Code hooks + QuestionSplittingService PoC
- 见 `checkpoints/2026-04-17-phase4-p3-sprint.md`
