# CI Pipeline Runbook (Self-hosted)

Objective

- Guarantee green builds with zero hosted cost and enforce coverage gates.

Triggers

- push: `develop`, `release/**`, `feature/**` (docs excluded)
- pull_request: `main`, `develop`, `release/**` (docs excluded)

Steps

1. Check Xcode/Simulators
2. Optional NAS mount (artifacts)
3. Run `Scripts/check-quality.sh` with:
   - `SIM_DEVICE="iPhone 17 Pro" TEST_PLAN="UnitTestPlan" MAX_WORKERS="4"`
4. Upload `TestResults.xcresult` + `local_artifacts/coverage-local.json`
5. Gate: overall ≥ 65%, logic-only ≥ 80% (Views excluded)

Troubleshooting

- Simulator not found: list with `xcrun simctl list devices`
- Coverage JSON missing: rerun script; ensure test plan has NotBadTests target
- Runner capacity: adjust `MAX_WORKERS`
