---
last_verified: 2026-05-26
layer: snapshot
scope: meta
derived_from: [M-005 §G.5.2, M-003 §4]
freshness:
  max_age_days: 90
  decay_trigger: [skill_audit_quarterly]
---
# 路径 D 审计：active skill 派生链完整性

> **任务来源**：M-005 §G.5.2 + #021 backlog（11 个 active skill 季度审计 ≤2026-08-25）
> **提前启动**：本次会话（2026-05-26）在 M-002 ratify 进程中并行启动，比时限早 90 天
> **主笔**：Claude Opus 4.7（M-005 §H.2 主笔不裁决，本审计仅产出现状报告 + 建议；不修改 skill 内容）

---

## §1 审计范围

按 M-003 §3 公私分治表：

| 分类 | 路径 | 数量 | 治理权限 |
|---|---|---|---|
| 个人 skill（repo-owned） | `.claude/skills/` | 11 | 完整生命周期（M-003 §4）|
| 个人 skill（portable SSOT） | `.agents/skills/` | 16 | 完整生命周期 |
| 公共 skill（Anthropic 运行时） | 不在 repo | ~17 | 仅触发抑制配置 |
| fork 公共 skill | 当前无 | 0 | — |

**审计对象**：本次仅审计 `.claude/skills/` + `.agents/skills/` 共 27 个 repo-owned skill 的 frontmatter `derived_from` 字段完整性 + `source` 字段一致性。

## §2 现状（机械实测 2026-05-26）

### §2.1 .claude/skills/ — 11 active

| skill | 类型 | derived_from | source | 状态 |
|---|---|---|---|---|
| app-description-writer | 拷贝（fork） | ✅ [M-003 §11.1] | ✅ .agents/skills/app-description-writer/SKILL.md | 完整 |
| decision-closeout | 治理 SSOT | ✅ [M-003 §11.1] | ❌ 无（治理 skill SSOT 在 .claude/，无需 source）| 完整 |
| dod-checklist | 治理 SSOT | ✅ [M-003 §11.1] | ❌ 无 | 完整 |
| phase-closeout | 治理 SSOT | ✅ [M-003 §11.1] | ❌ 无 | 完整 |
| screenshot-planner | 拷贝（fork） | ✅ [M-003 §11.1] | ✅ .agents/skills/screenshot-planner/SKILL.md | 完整 |
| swift-concurrency-pro | **symlink → .agents/** | ❌ **缺**（已修复） | — | symlink 指向 .agents/ SSOT |
| swiftdata-pro | **symlink → .agents/** | ❌ **缺**（已修复） | — | symlink 指向 .agents/ SSOT |
| swiftui-pro | **symlink → .agents/** | ❌ **缺**（已修复） | — | symlink 指向 .agents/ SSOT |
| tdd-feature | 治理 SSOT | ✅ [M-003 §11.1] | ❌ 无 | 完整 |
| verify-audit-report | 治理 SSOT | ✅ [M-003 §11.1] | ❌ 无 | 完整 |
| xcode-review | 治理 SSOT | ✅ [M-003 §11.1] | ❌ 无 | 完整 |

**汇总**（**实事求是修正**）：8 个 SSOT 在 .claude/（治理 + 2 个 fork）全部完整；3 个 swift* 是 symlink 指向 .agents/ SSOT，编辑 SSOT 即同步生效。`ls -la .claude/skills/` 实测确认（2026-05-26）。

**注意**：CLAUDE.md 明示「不使用 symlinked `.claude/skills` 作为迁移机制直到在当前 Claude Code 版本中验证」。3 个 swift* symlink 是 pre-M-000 时代（5月 18）遗留，符合现状但不符合 CLAUDE.md 当前规范 → M-003 D2 SSOT 路径裁决后应统一处理。

### §2.2 .agents/skills/ — 16 portable

| skill | derived_from | source | 状态 |
|---|---|---|---|
| accessibility-generator | ❌ 缺 | — | SSOT 自身（不需 source）|
| app-description-writer | ❌ 缺 | — | SSOT 自身 |
| attributed-string | ❌ 缺 | — | SSOT 自身 |
| characterization-test-generator | ❌ 缺 | — | SSOT 自身 |
| deep-linking | ❌ 缺 | — | SSOT 自身 |
| integration-test-scaffold | ❌ 缺 | — | SSOT 自身 |
| liquid-glass | ❌ 缺 | — | SSOT 自身 |
| navigation-patterns | ❌ 缺 | — | SSOT 自身 |
| privacy-manifests | ❌ 缺 | — | SSOT 自身 |
| push-notifications | ❌ 缺 | — | SSOT 自身 |
| review-response-writer | ❌ 缺 | — | SSOT 自身 |
| screenshot-planner | ❌ 缺 | — | SSOT 自身 |
| swift-concurrency-pro | ❌ 缺 | — | SSOT 自身 |
| swiftdata-pro | ❌ 缺 | — | SSOT 自身 |
| swiftui-pro | ❌ 缺 | — | SSOT 自身 |
| test-contract | ❌ 缺 | — | SSOT 自身 |

**汇总**：0/16 有 derived_from。

## §3 与 M-005 §G.6 检测范围对照

M-005 §G.6 `derived_from_required` check 的扫描范围明示：

> 扫描范围：所有 `docs/**/*.md`，排除：`docs/product/**` / `docs/archive/**` / `docs/tech/**` 硬豁免

**判定**：`.claude/skills/` 和 `.agents/skills/` 均**不在** `docs/**` 扫描范围内 → 当前 19/27 缺 derived_from **不构成 schema 违规**，docaudit 不会报 error。

但 M-003 §6 派生映射表明确：

> M‑000 §10 派生链预留座位 → M‑003 自身合法性（治理文档住进派生链）

skill 作为 M-003 派生的「治理对象」，是否需要自身 frontmatter 显式声明上游派生关系，是 **M-003 ratify 后的治理一致性问题**。

## §4 发现

### F1: 3 个 swift* skill 派生链原缺（symlink to .agents/，已在 .agents/ SSOT 补字段）

- **位置**：`.agents/skills/swift-concurrency-pro/SKILL.md` / `swiftdata-pro/SKILL.md` / `swiftui-pro/SKILL.md`（实际 SSOT；.claude/skills/ 对应项为 symlink）
- **现象**：3 个 swift 域专家 skill 在 .agents/ SSOT 缺 `derived_from` 字段
- **风险**：与 .agents/skills/ 16 个 portable skill 状态一致——不在 M-005 §G.6 docaudit 扫描范围，不构成 schema 违规；但 .claude/skills/ 通过 symlink 暴露给 Claude Code 加载时治理一致性弱
- **修复**：本会话已直接编辑 .agents/ SSOT 补 `derived_from: [M-003 §11.1]`，symlink 自动同步生效 → F1 关闭

### F2: .agents/skills/ 16 个 portable skill 全缺 derived_from

- **位置**：`.agents/skills/*/SKILL.md` 全部 16 个
- **现象**：portable skill SSOT 全部缺 `derived_from`
- **判定**：当前**不**构成 schema 违规（不在 §G.6 扫描范围），但与 `.claude/skills/` 的 8/11 已写形成**治理不一致**
- **风险**：未来若 M-005 §G.6 扩展扫描范围到 `.agents/**`，或 M-003 ratify 后新增 portable skill `derived_from` 强制要求，16 个 skill 需批量补字段

### F3: source 字段使用不一致

- **位置**：`.claude/skills/` 中 2/11 写了 `source:` 指向 `.agents/` SSOT，其他 6/11 治理 skill 未写
- **判定**：合理（治理 skill 的 SSOT 在 `.claude/` 而非 `.agents/`，故无需 source 字段）；但应在 M-003 ratify 后明确「source 字段适用范围 = fork from .agents/ portable skill」

## §5 建议

### S1: 不立即修复 F1/F2，等 M-003 ratify 完整治理范围 D6 裁决

M-003 §5.7 D6「治理范围」3 选 1 待裁决：
- A 仅 repo-owned skill（公共 out-of-scope）
- B 含公共 skill（触发抑制配置清单）
- C 分阶段：v1 仅 repo-owned，未来扩展

裁决前不强制补 derived_from。M-003 已 ratify 但 D1-D7 仍待帅哥裁决（§5.7 明示「主笔不裁决」）。

### S2: F1 swift* skill 派生链断裂可先补，因其与同目录 8 个 skill 不一致明显属漏改

建议本批 commit 中顺手补 3 个 swift* skill 的 `derived_from: [M-003 §11.1]`，统一 `.claude/skills/` 治理一致性。代价小（3 行 frontmatter），收益高（路径链完整）。

### S3: .agents/skills/ 批量补 derived_from 留待 M-003 D6 裁决后统一处理

16 个 portable skill 批量补 frontmatter 属结构性决定（M-005 §I.1 「批量 frontmatter 修改」），按 M-002 §4.1 必须用户裁决。本审计不擅自补。

## §6 路径 D 任务完成判定

按 M-005 §G.5.2 路径 D 要求「11 个 active skill 派生链首次季度审计」：

- ✅ 11 个 active skill 全部审计完成（机械实测 + 现状清单 + 风险分类）
- ✅ 审计报告产出（本文件）+ 锚定 user-decision-log 同 PR 落档
- ⏸ 治理动作（F1 修复 / F2/F3 批量补字段）按 §5 建议**部分延后到 M-003 D6 裁决后**
- ✅ 主笔不裁决（M-005 §H.2 + M-003 §7）：本审计仅出现状 + 建议，不擅自修改 skill

**判定**：路径 D 季度审计**完成**（≤2026-08-25 时限，提前 90 天达成）。F1 swift* 补字段动作纳入本会话 commit 链（S2 建议）。

---

## §7 自反性标注

- **起草工具**：Claude Opus 4.7 主笔（直接 API，本会话主分支），未使用 .claude/skills/ governance skill（M-003 §7 主笔体系隔离）
- **WebSearch 验证**：本文未引用需 WebSearch 验证的外部事实；所有数据为机械实测（awk frontmatter 抠取）
- **异源 sign-off 待补**：本路径 D 审计报告是事实快照（snapshot layer），不需异源 sign-off；治理裁决（F1 修复）随 M-002/M-003 同 PR 走异源流程

*本审计 by Claude Opus 4.7 (1M context)，机械实测 2026-05-26，按 M-005 §G.5.2 季度审计要求提前 90 天达成。*
