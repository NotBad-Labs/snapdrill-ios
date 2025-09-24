# ADR-001: CI Strategy — Self-hosted Only

Status: Accepted
Date: 2025-09-24

Context
- Hosted runners incur cost and have limited iOS capabilities
- We require stable Xcode/iOS versions and simulator availability

Decision
- Use a single self-hosted GitHub Actions workflow for all auto triggers
- Add a guard policy workflow to fail if any auto workflow uses hosted runners
- Convert non-essential workflows to manual no-ops or remove them

Consequences
- $0 hosted cost; reproducible environment
- All contributors rely on self-hosted capacity; need to monitor runner uptime
