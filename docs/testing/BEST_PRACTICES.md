# Testing Best Practices

This project follows a layered architecture (Application, Domain, Infrastructure, Presentation). Our test strategy mirrors those layers and enforces dual coverage gates:

- Logic-only coverage: >= 80% (excludes SwiftUI view files)
- Overall coverage: ratcheting baseline (currently 64%)

## Principles

- Test behavior, not implementation details. Favor public API and observable effects.
- Keep tests deterministic: control time, randomness, and concurrency.
- Prefer fast unit tests; UI and snapshot tests are smoke-level unless they catch real regressions.
- Cover both happy paths and key negative paths (validation, errors, edge input).

## Project Patterns

- In-memory repositories (`InMemoryReviewItemRepository`) for fast, hermetic tests.
- Use cases (e.g., `CaptureReviewItemUseCase`) coordinate domain services; test end-to-end across service + repository when logic is thin.
- Coordinators and ViewModels are tested via simple state assertions and routing delegates.
- SwiftUI views are rendered in lightweight smoke tests to ensure basic stability, not pixel-perfect assertions.

## Writing Good Tests

1) Name tests clearly: `test<Subject>_<Action>_<Expected>()`.
2) Arrange-Act-Assert structure; avoid hidden work in `setUp` that varies per test.
3) Keep one assertion group per scenario, but multiple related assertions are fine.
4) Prefer `XCTAssertThrowsError` or pattern-matching `do/catch` for error paths.
5) For async tests, use `async` functions and avoid arbitrary sleeps. If needed, keep <= 0.3s and document why.

## Examples

- Domain aggregate validation: empty/whitespace-only fields throw `ReviewItemError`.
- Repository filters: `ReviewItemQueryCriteria` for proficiency, date ranges, tags, text search.
- Use case negative paths: `CaptureError.missingRequiredFields` for incomplete input.
- Coordinator routing: assert `routes` updates or delegate calls.
- ViewModel interactions: toggle flags, apply/clear filters, handle deletion errors via `AppErrorHandler`.

## Coverage Guidance

- Prioritize low-covered files from `Scripts/analyze_coverage.py` (exclude Views/Tests). Aim to raise weak files to >= 85% quickly via targeted unit tests.
- Maintain logic-only >= 80% at all times. Overall coverage should trend upward; raise the baseline when consistently above threshold.

## Lint and Structure

- Follow `docs/STYLE_GUIDE.md`. Keep test helpers small, colocated or under `NotBad/Testing`.
- Use per-directory SwiftLint configs to avoid noise in tests while keeping production code strict.

## Running

- Local: `Scripts/check-quality.sh` (runs tests with coverage and enforces gates; snapshots JSON to `docs/coverage/`).
- Analyze weakest files: `python3 Scripts/analyze_coverage.py docs/coverage/<snapshot>.json --exclude-path-regex 'NotBad/NotBad/Presentation/.*/Views/.*\\.swift|.*Tests/.*' --min-executable-lines 20 --limit 10`.

---

When in doubt, add a small, fast test that covers an important branch. Small wins add up to steady coverage gains.
