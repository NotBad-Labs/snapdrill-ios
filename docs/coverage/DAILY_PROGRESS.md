# Daily Coverage Progress

This log tracks daily coverage metrics (logic-only and overall), notable changes, and snapshot references.

## 2025-09-23

- Run: 14:51:35
- Snapshot: `docs/coverage/coverage-20250923-145135.json`
- Logic-only coverage (Views excluded): 91.43% (6069/6638)
- Overall coverage: 63.08% (6595/10455)
- Gates: PASS (logic ≥ 80%, overall ≥ 62%)
- Delta vs previous run (14:47:30):
  - Logic-only: +0.07pp (91.36% → 91.43%)
  - Overall: +0.16pp (62.92% → 63.08%)
- Changes today:
  - Added `FeatureFlagsAndMockDataTests` covering:
    - `FeatureFlag.isEnabled` DEBUG path via `UserDefaults` toggling
    - `MockDataProvider.loadReviewSessions()` decoding and difficulty mapping
  - Earlier quick wins already merged: AppLogger.Timer edge tests; CaptureViewModel supplemental tests.
- Notes:
  - Now above 63% overall. Per policy, we’ll wait to consistently achieve ≥63.5% before ratcheting the overall gate to 63%.

---

- Run: 15:11:58
- Snapshot: `docs/coverage/coverage-20250923-151158.json`
- Logic-only coverage (Views excluded): 91.79% (6268/6829)
- Overall coverage: 63.82% (6794/10646)
- Gates: PASS (logic ≥ 80%, overall ≥ 63%)
- Delta vs previous run (15:07:45):
  - Logic-only: +0.16pp (91.63% → 91.79%)
  - Overall: +0.45pp (63.37% → 63.82%)
- Changes:
  - Added `CoordinatorBaseTests` covering BaseCoordinator defaults (start, goBack, delegate, coordinate).
  - Added `MockDataProviderMoreTests` covering `loadDecodable` success and missing-file error paths.
  - Ratcheted overall coverage gate from 62% to 63% in `Scripts/check-quality.sh` and updated docs.
    - Later run stabilized at ~65.1% overall; ratcheted overall coverage gate from 64% to 65% in `Scripts/check-quality.sh` and updated docs.
- Notes:
  - Both logic-only and overall gates remain comfortably green with buffer; continue targeting safe edges to build cushion toward ~65%.


How to reproduce locally:

- Run: `zsh Scripts/check-quality.sh`
- Latest metrics and JSON snapshot will be written under `docs/coverage/`.
