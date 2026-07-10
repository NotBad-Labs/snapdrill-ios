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
| RA-02-001 | P2 | product/docs | verified | `d62fead8` | `business-model.md:54`; `feat-smartpaper.md:18,33-47,54-62`; `LibraryView.swift:127-131,218-223` | correct only the stale free-tier status sentence; keep the mixed free/Pro feature state |
| RA-02-002 | P2 | nfr/release | verified | `d62fead8` | `non-functional-requirements.md:66-70`; `project.pbxproj:1014,1038,1050,1073,1085,1274`; `release-and-ci.md:134,151` | separate current iPhone shipping requirements from future iPad scope; PO decides orientations |
| RA-02-003 | P2 | positioning/release | verified | `d62fead8` | `appstore-metadata.md:25,29,38-43,52-107`; `positioning-and-audience.md:14-24`; `README.md:26,34` | rewrite behind PO/legal/ASO gate before submission; do not use the current draft |
| RA-02-004 | P2 | terminology/docs | verified | `d62fead8` | `glossary.md:18-24`; `design-principles.md:74,86,94-104`; `feat-library.md:3,16,23,28-37`; `L10n+Foundation.swift:17-22` | bounded docs terminology slice; preserve SmartPaper terms, identifiers and wire keys |
| RA-02-005 | P2 | intent/traceability | pending-po | `d62fead8` | `design-principles.md:46,52-65`; `user-journeys.md:39`; `analytics-events.md:7`; commit `fa118bec` | PO decides whether to restore, relocate or retire success signals and free-tier non-degradation |
| RA-02-006 | P2 | process/governance | verified | `d62fead8` | PO 2026-07-10; `parallel-lanes.md:38-50,66-102,138`; `release-and-ci.md:12,110-117,175,189-202,348-351` | align steady-state C1 leadership, external-review boundary and memory-disabled state in one process slice |
| RA-02-007 | P2 | ui/docs | verified | `d62fead8` | `UI-FREEZE-QA-MATRIX.md:3-5,103,119`; `LibraryView.swift:127-131,218-223`; 138 evidence files | Phase 08 classify current/historical evidence and capture reachable SmartPaper; do not bulk-delete assets |
| RA-02-008 | P2 | ci/tooling | verified | `d62fead8` | `Scripts/ci-local.sh:12,35-52`; `AGENTS.md:53-56`; `phases/00b-results.md:36-37` | Phase 09 establish one canonical local CI command mapped to required jobs/configuration |
| RA-02-009 | P3 | governance/evidence | verified | `d62fead8` | `po-decision-log.md:30,32,40`; no tracked or GitHub mirror for named support reports | retain minimum reproducible summary or PR/commit pointer for still-operative release decisions |
| RA-02-010 | P3 | release/tooling | verified | `d62fead8` | `upload_testflight.sh:2-5,61-65,73-104`; no tracked caller | Phase 11 either make it canonical and functional or retire it after owner check |
| RA-02-011 | P3 | platform/docs | verified | `d62fead8` | `apple-platform-limits.md:2-11,34,41`; `README.md:33-36` | refresh from Apple primary sources and device evidence; correct current blocker causes |
| RA-02-012 | P3 | build/tooling | verified | `d62fead8` | `project.pbxproj:60-61,189-190,1091,1158`; unreferenced `Configs/Debug.xcconfig`, `Configs/Release.xcconfig` | Phase 11 verify effective settings, then keep one configuration pair |

允许状态：`verified` / `rejected` / `pending-po` / `deferred` / `fixed`。`candidate` 只存在于 phase 工作报告，不进入本表。
