# Phase 01 Checkpoint

## T0

- base：`origin/develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- 主 checkout：同一 SHA；只存在原有未跟踪 `agent-reports/`，未触碰
- worktree：`/private/tmp/snapdrill-repository-audit`
- branch：`codex/repository-audit-program`
- audit write WIP：1

## Coverage

- GitHub：347 issues、517 PRs、1,881 Actions runs、10 workflow records
- Git：当前 `develop` 可达的 1,285 commits，8,600 numeric numstat rows
- slices：`01a` lifecycle、`01b` CI taxonomy、`01c` churn hotspots、`01d` history discontinuity、`01e` governance ROI、`01f` churn accounting

## Agent Status

- Claude Fable：6 个独立 slice 均完成；CI、history 和 accounting 因 tool turns 用尽，续接同一 session 只做 final synthesis，没有重新取样。
- Antigravity：显式 `Gemini 3.5 Flash (High)`；独立 churn 报告对 code-level 风险过度推断，只保留其反例，不入 finding。
- Grok：terminal tool schema 与当前 CLI 冲突；移除 Bash 后完成 inference challenge，指出 rename / docs migration / vendored skills 等 confounder。
- Codex C1：复算 lifecycle、rename-folded churn 和 CI branch/SHA join；抽取 19 个 job endpoint 与多个月份 failed logs。
- 外部 agent 临时 brain / session 已在取证后删除；没有原始报告入仓。

## Verified Results

- findings：3（2×P2，1×P3）
- RA-01-001：历史 CI 非有效 merge gate；97 个 2026 merged PR 无同 SHA success，70 个在 failure 已完成后才合并
- RA-01-002：agent governance rebuild/archive/purge；`a2356087` 删除 80,680 行，且 72-file archive 约 37 小时后被清空
- RA-01-003：2025 PR 与当前 develop 图谱断层；21/21 ancestry loss，内容损失边界 4–11 PR
- routed candidates：Phase 02 ×1、Phase 03 ×1、Phase 06 ×1、Phase 07/08 ×1、Phase 09 ×1

## Corrections To Agent Output

- PR median 是 16.4 分钟，不是 18 分钟。
- 2025 不能只按 10 个 unmerged PR 判断；11 个 GitHub-merged PR 也不在当前 ancestry，但至少 10 个 head 由 tags 保留。
- `run_attempt > 1` 不是 flake 上界。
- deleted-path churn 与 merge rate 均不是价值指标。
- 71.5% deleted-canonical 与 53.7% process/docs 数字可复现；它们的语义标签不能从数字自动推出。

## Validation

- docs validators：feature status / intent traceability / docs health / Capture contract 全部 exit 0；8 generator tests passed
- script regression tests：25 passed
- `swiftlint --strict`：245 files，0 violations
- `AllTests build-for-testing`：`TEST BUILD SUCCEEDED`
- `git diff --check`：clean

## Recovery

- result：`phases/01-results.md`
- ledger：`findings.md`
- raw snapshots：`/private/tmp/snapdrill-repository-audit-phase01/`，checkpoint commit 后可删除
- next command：为 Phase 02a 生成规范链 / 实证链 SSOT inventory，不读取本轮 agent raw reports
