# UI Redesign Log

> Purpose: record durable UI design decisions, PO decisions, cross-layer findings, changed files, validation status, and unresolved questions. Private agent memory is not a design source of truth.

## 2026-06-14 - Design tool routing and Claude Design

### Scope

- `docs/how-to/parallel-lanes.md`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Design Decisions

- Codex + PO remain the UI design decision owner for SnapDrill.
- Claude Design may be used as a comparison and rapid prototyping tool during UI work.
- Claude Design outputs are candidates only. A candidate enters the project only after it is translated into repo evidence: design log, SwiftUI code, snapshot/XCUITest, or device/simulator validation.
- Recommended workflow: wireframe first, then high fidelity, then SwiftUI implementation and device validation.
- Useful things to inspect from external prototypes: layout hierarchy, information density, component structure, color tokens, spacing, and motion intent.
- Do not treat HTML/CSS/React output, screenshots, or social-media workflow advice as direct SwiftUI architecture decisions.

### Files Changed

- `docs/how-to/parallel-lanes.md`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Cross-Layer Findings

- None. This entry only records UI design workflow governance.

### DoD Status

- Passed:
  - `python3 Scripts/generate_feature_status.py --check`
  - `python3 Scripts/validate_docs.py --check`
  - `git diff --check`

### Open Questions

- None for this milestone.
