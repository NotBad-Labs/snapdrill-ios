# Phase 4 — Journey to 75% Coverage

Date: 2025-09-24 (plan)
Goal window: 3–4 days
Target: 75% overall (keep logic-only ≥ 90%)

## Strategy

- Maintain local CI-first loop; push only at milestones
- Use analyzer (`Scripts/analyze_coverage.py`) to prioritize high-LOC, low-coverage files
- Prefer tests-only or DEBUG-only hooks; avoid production logic changes
- Keep dual gates: overall ≥ 65%, logic-only ≥ 80% (current logic ~93%)

## Day-by-day Targets

### Day 1 — Infrastructure (+1.5%)

- Repository concurrency and boundary tests (timeouts, missing IDs, pagination/limits)
- Cache behavior under churn (evictions, stale reads)
- Network adapter/service stubs: error mapping and retry opt-out

### Day 2 — Services (+1.5%)

- Timeouts, retry/backoff (happy + error branches)
- Validation/normalization edge cases (invalid subject/difficulty, tag parsing)
- Statistics and derived metrics correctness under mixed data

### Day 3 — Integration (+1.5%)

- Coordinator/navigation smoke flows across tabs and detail routes
- Sheet/toolbar interactions and cancel/confirm paths
- ViewModel lifecycle: onAppear/onDisappear side-effects

### Day 4 — Polish (+0.5%)

- Fill uncovered lines in top 10 low-covered files (UI helpers, formatters)
- Delete dead code branches or guard with DEBUG
- Docs: snapshot, milestone entry, README badge refresh

## Quality Gates & Artifacts

- local_artifacts/coverage-local.json per run; snapshots to docs/coverage/ with timestamp
- Ensure Tasks/tests are idempotent and simulator-agnostic (iPhone 17)
- Use `MAX_WORKERS` to keep CI fast; prefer 2–4 locally

## Risks & Mitigations

- Simulator flakiness → prefer pure-logic tests or view hooks without system privileges
- Concurrency flakes → inject deterministic queues or leverage actors
- Test brittleness → isolate via test helpers and avoid UI text assertions

## Exit Criteria

- Overall ≥ 75.0% with green dual gates
- No production logic changes required
- Changelog + Release notes drafted for v6.1.0 or v6.0.2 (depending on scope)
