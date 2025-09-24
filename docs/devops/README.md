# DevOps Runbook (NotBad)

Purpose
- Provide a single, durable place for CI/CD, release, and operations workflows.
- Make decisions traceable (ADR), progress measurable (metrics), and actions repeatable (checklists/SOP).

Scope
- CI: self-hosted-only pipeline, dual coverage gates, artifacts, caching (TBD)
- CD: release/tag flow driven by Git Flow and Test Plans
- Ops: cost governance (self-hosted), runner health, artifact retention

Structure
- runbooks/: step-by-step operations
- architecture/: ADRs for DevOps decisions
- metrics/: time-series and snapshots to trend quality and cost
- checklists/: PR/Release/Daily checklists
- sop/: routine workflows for the team

SSoT links
- VERSION (versioning)
- local_artifacts/coverage-local.json (coverage snapshot)
- docs/releases/ (release notes)

How to contribute
- Prefer small, atomic PRs that update docs with code (Docs-as-Code)
- Co-locate scripts in Scripts/ and reference here
