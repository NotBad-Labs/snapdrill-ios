---
last_verified: 2026-04-22
layer: pattern
---
# docs/archive/ — 归档区

> 存放已 `status: archived` 或 `layer: archive` 的历史文档。

## 归档规则

1. **归档条件**：
   - 文件 frontmatter 声明 `status: archived` 或 `layer: archive`
   - 内容已被新文档 subsume，或承载的研究已完成固化到 principles/decisions
   - 外部引用仍存在（完全不再引用的直接删除，不归档）

2. **归档路径**：
   - 研究类：`docs/archive/research/<topic>-<date>.md`
   - 审计报告类：`docs/archive/audit-*-<date>.md`
   - 其他历史文档：`docs/archive/<topic>.md`

3. **归档后的引用规则**：
   - 活跃文档可以**叙述性引用**归档路径（如"根据 2026-04-18 的 Harness 研究，归档在 docs/archive/research/harness-engineering-study-20260418.md"）
   - 不应再有**执行性依赖**（hook 加载 / skill 引用作为工作流输入）
   - `Scripts/audit/policy.yaml` `archived-refs` check 扫描**旧路径硬编码**（如 `docs/research/xxx.md`），禁止新代码写入旧路径

## 当前归档清单

| 文件 | 归档日期 | 原位置 | 归档理由 |
|---|---|---|---|
| `research/harness-engineering-study-20260418.md` | 2026-04-22（PR-α2） | `docs/research/` | Harness Engineering 三方研究，结论已固化到 workflow / skills |
| `research/hermes-agent-study-20260418.md` | 2026-04-22（PR-α2） | `docs/research/` | Hermes agent 研究，结论已固化到 memory-routing / phase-closeout |
| `audit-report-20260409.md` | 2026-04-17 | - | 历史审计报告（元信息见文件内注记） |
| `timeline.md` | 2026-04-17 | - | 历史时间线（Phase 7.I 改 layer: snapshot → archive） |
| `phase-e-pr-e4-reflow-20260422.md` | 2026-04-22 | - | Phase E PR-E4 首次反哺实战记录 |
| `reference_codex_plugin_v104_upgrade.md` | 2026-05-19（Phase 2.5） | `docs/tech/reference/` | Codex plugin v1.0.4 升级记录，三方共识 STALE |
| `CODEX_HANDOFF-20260518.md` | 2026-05-19（Phase 5 finding G） | 根级 `CODEX_HANDOFF.md` | 5/18 Codex 接手任务 P1-1~P1-6 全部已闭环 |
| `ZERO_TRUST_AUDIT_20260513.md` | 2026-05-19（Phase 5 finding J） | `reports/` | 5/13 零信任代码审计完整报告，Step 1-8 已完成 |
| `_claude__skills__phase-closeout__SKILL_md__*.md` | 2026-05-19（Phase 5 finding I） | `.agent-harness/proposals/` | Phase E PR-E2 自动生成的反哺 proposal 草稿，TODO 占位 27 天未推进 |
| `research/M-000-meta-vision-roundtrip-20260521/` | 2026-05-21 | `docs/meta/` | M-000 Meta-Vision v1.0 起草过程材料（4 份 round 1 草案 + 4 份 round 2 草案 + 2 份 cross-analysis），结论已固化到 `docs/meta/M-000-meta-vision.md` |

## 与 `~/.claude/plans/` 的区别

- **`docs/archive/`**：团队共享（入 git），三方智能体都能读
- **`~/.claude/plans/`**：Claude 私有工作目录，其他智能体（Codex/Gemini）读不到
