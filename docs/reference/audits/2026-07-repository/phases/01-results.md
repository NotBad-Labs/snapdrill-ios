# Phase 01 Results: History, CI and Rework

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/explanations/vision.md` 与 `docs/reference/release-1-contract.md`。

## Outcome

Phase 01 在固定 `develop@d62fead8` 上冻结 GitHub 与 Git 历史，分别审查 issue / PR 生命周期、Actions 失败和文件 churn。Claude Fable 执行 6 个独立 evidence slice；Antigravity 与 Grok 作异构挑战；Codex C1 重新计算关键数字并抽查 GitHub job / failed log。

结论不是“几个月全部白做”。2026 年产品工作大多进入当前 `develop`，但历史上存在三个可证实的成本问题：2025 年图谱断层、2026 年 3–4 月红 CI 仍合入，以及 4–5 月 agent 治理体系的高成本构建后清空。

## Frozen Evidence

| Snapshot | Records | SHA-256 |
|---|---:|---|
| `issues.json` | 347 | `d27ac52f6599da1b86b23f439b3dca036e6ec506ca9fc726b80b23c9deda8615` |
| `pulls.json` | 517 | `b47d49cd626791b206f54419c96c8b8f278ca7f273a6f41573bb86614c225194` |
| `runs.json` | 1,881 | `77592057257f00f4f9b9b6d1506ff0d44e06e5fdc100a84d60e56a36629d5381` |
| `workflows.json` | 10 | `1f6ab5546763a26c4ec0aa84ab3ad105cd399a18645935b46c381139b89e1982` |
| `git-numstat.txt` | 1,285 commits | `f31d9b77a6749334d39a355e6e467a166324938cec4e452edbf9eb4351408053` |

Snapshots 只在阶段执行期间保存在 `/private/tmp/snapdrill-repository-audit-phase01/`；原始模型 transcript 不入仓。

## Verified Findings

### RA-01-001 — P2 — Historical CI was not an effective merge gate

- 2026 年有 495 个分支产生主 workflow (`workflow_id=175662287`) 的 PR run；其中 104 个分支最后一次 PR run 为 failure，98 个对应 PR 最终仍 merged。
- 排除同一 workflow + head SHA 存在其他 success 的 1 个分支后，仍有 **97 个 merged PR 没有同 SHA success**。
- 其中 **70 个在 failure 的 `updated_at` 之后才合并**，另 27 个在失败 run 完成前已合并；全部发生在 2026-03 至 2026-04。
- 样本：PR #219、#232、#571；run `22884208182`、`22889699283`、`24177924284`。
- 影响：CI 在这一时段提供了信号，但没有阻止已知红分支进入 base，后续 PR 因共享红底产生重复失败与诊断噪声。
- 边界：这是历史结论，不声称当前 GitHub branch protection 状态；当前规则仍在 Phase 09 复核。

### RA-01-002 — P2 — Agent governance was built, archived and purged at avoidable scale

- 2026-04-21 开始构建 `Scripts/audit/docaudit.py`、policy、hooks、skills、meta rules、多模型报告与 checkpoints。
- 2026-05-25 `967f038d` 将 72 个 audit 文件系统性归档；`91137a12` 又为 27 个归档文件补 frontmatter。
- 约 37 小时后，2026-05-27 `a2356087` 一次删除 **80,680 行 / 418 files**；其中 `docs/` 58,925、vendored `.agents/skills` 11,060、`Scripts/` 6,465、`.claude/` 3,437。
- 同一 purge 删除 `docs/archive` 44,552 行、`Scripts/audit` 5,686 行、`docs/audits` 4,306 行、`docs/standards` 4,105 行、`docs/meta` 3,596 行。
- 产品 SSOT 并未随 purge 全删；`docs/product` 基本保留，并于 `05879c47` 迁移到当前 Diátaxis / feature-spec 体系。当前窄 validator + generator + pre-commit/CI 是有效的耐久替代。
- 影响：主要浪费来自治理内容的生成规模、重复多模型 artifact 和“归档后立即删除”，不是治理本身，也不是所有 docs churn。

### RA-01-003 — P3 — Current develop is graph-disconnected from all 2025 PRs

- 当前 `develop` 根是 2025-12-29 的 orphan commit `f213fd7e`；2025 年 21 个 PR 没有一个进入当前 ancestry。
- 10 个 PR closed-unmerged；11 个标记 merged 的 merge SHA 中，4 个本地存在但不是 ancestor，7 个本地对象缺失。
- 进一步检查 head SHA 后，至少 10 个 PR 内容仍由 `v6.0-*` tags 保留；closed-unmerged 的 #8、#9 也实际落入旧 incarnation，说明 GitHub merge state 不能单独代表内容是否保存。
- 以 PR work item 计，C1 接受的可证实内容损失下界为 4 个 PR（#1、#17、同一 release head 的 #18/#20），证据不足时的上界为 11 个；**21/21 是 ancestry loss，不是 21/21 content loss**。
- 影响：2025 的投入解释和回归溯源存在盲区；不能用当前 Git history 直接评价旧实现质量。

## C1 Reproduction Notes

### Lifecycle

- Issues：343 closed / 4 open；322 completed / 21 not planned。
- PRs：479 merged / 37 closed-unmerged / 1 open。
- 2026 PR merge SHA：468/468 是当前 `develop` ancestor。
- PR open-to-merge median：**16.4 分钟**；190/479 小于 10 分钟，336/479 小于 1 小时。外部报告中的“18 分钟”未通过 C1 重算。

2025 merge ancestry 可用以下模式复现：

```bash
jq -r '.[] | select(.created_at < "2026-01-01" and .merged_at) | .merge_commit_sha' pulls.json |
while read -r sha; do git merge-base --is-ancestor "$sha" develop || echo "$sha"; done
```

### CI

Actions failure 按月为：2025-09 `152`；2025-12 `1`；2026-01 `3`；2026-03 `190`；2026-04 `69`；2026-05 `83`；2026-06 `7`；2026-07 `1`。

- 2025-09 的 152 次主要是 CI / simulator / self-hosted workflow 搭建；旧 logs 已被 GitHub 以 HTTP 410 清除。
- 2026-05-21 至 05-29 有 53 次连续 `develop` 主 workflow failure。首、中、尾 job logs 均显示 `UNUserNotificationCenter.currentNotificationCenter` 在 test process 初始化时崩溃；PR #771 后 05-31 首次转绿。58 次 window failures 中 5 次 PR failure 可能含独立原因，因此只把 53 次 develop streak 归为一个已抽样确认的共享根因 cluster。
- 2026-06 样本同时出现 dependency clone EOF、真实 snapshot mismatch；2026-07 唯一失败是 checkout 到 GitHub 超时。run attempt 大于 1 的 failure 只有 9 个，但这**不能**作为 flake 上界。
- 17 个 workflow + SHA group 同时被 push 与 PR 触发，产生 34 个 failure run；这是可量化的重复执行，不等于 34 个独立缺陷。

RA-01-001 的 C1 join 规则：按 `(workflow_id, head_branch)` 排序所有 2026 PR runs，取每个分支最后一次 run；关联 `pulls.head_ref`，再排除相同 `(workflow_id, head_sha)` 存在 success 的分支，并比较 `merged_at` 与 failed run `updated_at`。

### Churn

按 snapshot 从新到旧处理 rename：遇到 `old => new` 时把旧路径映射到 `new` 的当前 canonical path，并在越过 rename 后释放 `new` 以避免更早的 path reuse 污染。对 base tree 重算得到：

| Metric | Value |
|---|---:|
| numeric rows | 8,600 |
| binary rows excluded | 22,638 |
| total numeric churn | 422,176 |
| rename rows with numeric counts | 437 |
| rename-operation churn | 2,335 |
| current canonical-path churn | 120,118 |
| deleted canonical-path churn | 302,058 (71.5%) |
| Swift churn | 117,682 |
| deleted Swift canonical-path churn | 28,582 (24.3%) |

“process/docs 226,770 (53.7%)”也可精确复现，但其定义是 `docs/`、`.claude/`、`Scripts/audit/`、根 `STATUS.md` / `CLAUDE.md` / `AGENTS.md` / `README.md`；它混入当前产品 SSOT，不能直接解释为 waste。该 bucket 中 210,748 行落在 deleted canonical paths（92.9%）。

## Routed Candidates

1. **CAND-03-001**：UseCase / Domain 层在 2026-02-28 完成迁移后，于 03-03 被删除；相关提交为 `240887cb`、`37cb827e`、`aa5e1de8`。Phase 03 复核其是否只删 pass-through，还是丢失测试或业务规则。
2. **CAND-06-001**：旧 Subject / Source / Grade / Tag 体系在 03-01 仍补 parity UI，06-03 被 `a788cd0f` 删除 3,346 行并迁移到动态 taxonomy。Phase 06 判断这是必要 product pivot 还是延迟止损。
3. **CAND-07-001**：Onboarding 在 06-18 flagship polish 后 07-07 重做。单次 dogfood UI 迭代不能证明浪费；Phase 07/08 对照 PO 决策与截图判断。
4. **CAND-09-003**：当前 branch protection / required checks、PR merge race、develop push coverage 与 CI-only test configuration 必须在 Phase 09 现场复核。
5. **CAND-02-001**：检查当前 `docs/ui-redesign/evidence/` 的长期所有权与保留策略，避免重复“一次性证据长期入仓再集中清空”的模式；不得在未确认引用前删除。

## Rejected Claims

- **“几个月工作大部分都浪费了”**：作为全局结论不成立。2026 年 468 个 merged PR 的 merge SHA 全部进入当前 `develop`；价值仍需按语义判断，但不是 wholesale discard。
- **“479/517 merged 证明工作有价值”**：不成立。合并率只证明进入历史；97 个无同 SHA success 的红分支也被合并。
- **“302,058 deleted-path lines 都是浪费”**：不成立。包含 rename、生成物、vendored skill、替代实现、测试和有意简化。
- **“只有 9 个 run attempt >1，所以 flake ≤9”**：不成立。新 SHA、新 run 或 runner failure 也可 flake；`run_attempt` 只量化显式 rerun。
- **Antigravity 的 Core Data / OCR lifecycle 建议**：Phase 01 只提供 churn 信号，且报告误把 SwiftData / 现有路径作了过度推断，不进入 ledger。

## Recovery

- briefs：`01a-lifecycle-brief.md` 至 `01f-churn-accounting-brief.md`
- raw agent reports：归一化后删除，不进入仓库或私有 memory
- next：Phase 02 Truth，先审规范链与实证链的 SSOT / generated artifact / dead-pointer drift
