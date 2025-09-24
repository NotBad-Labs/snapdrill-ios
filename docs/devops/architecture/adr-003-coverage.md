# ADR-003: Coverage Reporting

Status: Proposed
Date: 2025-09-24

Context
- Coverage snapshots are needed for gating and trending

Decision
- Keep SSoT JSON at `local_artifacts/coverage-local.json`
- Export snapshot copies under `docs/coverage/coverage-<timestamp>.json`

Consequences
- Enables dashboard/report scripts; keeps docs snapshots for history
