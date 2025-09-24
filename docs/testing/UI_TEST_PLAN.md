# UI Testing Plan (NotBad)

Date: 2025-09-22

## Goals

- Incrementally raise overall coverage by adding low-risk UI tests.
- Keep logic-only gate at >= 80% (currently ~91%).
- Phase overall gate from 60% -> 70% -> 80% over 1-3 months.

## Scope (Phase 1)

- Smoke navigation checks on main tabs ("首页", "题库", "拍照", "发现", "我的").
- Assert navigation titles render after tapping each tab.
- Avoid new dependencies; use XCTest UI testing only.

## Candidate Next (Phase 2)

- Add ViewInspector unit-level UI tests for key Views with mocked ViewModels.
- Introduce SnapshotTesting for layout regressions of Library/Home screens.

## Test List

- NotBadUITests/MainTabNavigationUITests.swift
  - `testSwitchingTabsShowsExpectedTitles()`

## Execution

- Local: `./Scripts/check-quality.sh`
- CI: run on iPhone 17 simulator; archive xccov JSON; snapshot to `docs/coverage/`.

## Coverage Strategy

- Maintain `COVERAGE_EXCLUDE_REGEX` to exclude SwiftUI Views in logic-only gate.
- Report both overall and logic-only metrics in CI summary.

## Risks & Mitigations

- Flaky tab navigation: add `waitForExistence(timeout:)` before assertions.
- Text-based selectors brittle with i18n: prefer accessibility identifiers in future.

## Future Work

- Add accessibility identifiers to critical controls.
- Snapshot tests for Home/Library; minimal golden images for iPhone 13/15/17.
