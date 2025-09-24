# ADR-002: Testing Strategy — Dual Coverage Gates

Status: Accepted
Date: 2025-09-24

Context
- Overall coverage should trend upward without being blocked by UI details

Decision
- Enforce two gates via `Scripts/check-quality.sh`:
  - logic-only coverage ≥ 80% (Views excluded)
  - overall coverage ≥ baseline (≥65% currently)

Consequences
- Encourages testing core logic; UI can be covered progressively
