# Verified Finding Ledger

> 本表只收录 C1 在固定 base 上复核后的结论。外部 agent 原始报告和未验证 hypothesis 不进入本表。本表不是 feature status 或 roadmap。

| ID | Severity | Category | Status | Base | Evidence | Decision / next check |
|---|---|---|---|---|---|---|
| RA-00B-001 | P2 | tooling | verified | `d62fead8` | `Scripts/setup.sh:11-18`; `Scripts/pre-commit:20-27`; `Scripts/generate_feature_status.py:18`; `Scripts/generate_intent_traceability.py:16` | clean venv reproduces `ModuleNotFoundError: yaml`; route fix to a bounded tooling slice |
| RA-00B-002 | P3 | ci/docs | verified | `d62fead8` | `docs/how-to/release-and-ci.md:47-74`; `.github/workflows/ci.yml:53-60,105-122,179-217` | refresh the descriptive step list and `last_verified`; no CI behavior change |
| RA-00B-003 | P3 | docs/tooling | verified | `d62fead8` | `.gitignore:48-49`; `Scripts/hooks/pre-push:18` | replace or remove two dead pointers only after PO accepts a fix slice |

允许状态：`verified` / `rejected` / `pending-po` / `deferred` / `fixed`。`candidate` 只存在于 phase 工作报告，不进入本表。
