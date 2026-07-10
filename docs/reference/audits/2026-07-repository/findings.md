# Verified Finding Ledger

> 本表只收录 C1 在固定 base 上复核后的结论。外部 agent 原始报告和未验证 hypothesis 不进入本表。本表不是 feature status 或 roadmap。

| ID | Severity | Category | Status | Base | Evidence | Decision / next check |
|---|---|---|---|---|---|---|
| RA-00B-001 | P2 | tooling | verified | `d62fead8` | `Scripts/setup.sh:11-18`; `Scripts/pre-commit:20-27`; `Scripts/generate_feature_status.py:18`; `Scripts/generate_intent_traceability.py:16` | clean venv reproduces `ModuleNotFoundError: yaml`; route fix to a bounded tooling slice |
| RA-00B-002 | P3 | ci/docs | verified | `d62fead8` | `docs/how-to/release-and-ci.md:47-74`; `.github/workflows/ci.yml:53-60,105-122,179-217` | refresh the descriptive step list and `last_verified`; no CI behavior change |
| RA-00B-003 | P3 | docs/tooling | verified | `d62fead8` | `.gitignore:48-49`; `Scripts/hooks/pre-push:18` | replace or remove two dead pointers only after PO accepts a fix slice |
| RA-01-001 | P2 | ci/process | verified | `d62fead8` | `phases/01-results.md`; PR #219/#232/#571; Actions runs `22884208182`/`22889699283`/`24177924284` | Phase 09 verify current required-check enforcement and merge race; historical red merges are not assumed current |
| RA-01-002 | P2 | governance/docs | verified | `d62fead8` | commits `7d300507`, `967f038d`, `91137a12`, `a2356087`, `8fe45255`, `05879c47` | freeze new meta-system construction during audit; Phase 02 verify current lean control plane and evidence retention |
| RA-01-003 | P3 | history/recovery | verified | `d62fead8` | root `f213fd7e`; `v6.0-*` tags; `phases/01-results.md` | preserve existing tags; do not rewrite history; use 4–11 PR content-loss bound in later cost synthesis |

允许状态：`verified` / `rejected` / `pending-po` / `deferred` / `fixed`。`candidate` 只存在于 phase 工作报告，不进入本表。
