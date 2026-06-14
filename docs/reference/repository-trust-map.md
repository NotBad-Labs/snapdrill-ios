# Repository Trust Map

> This map classifies repository material by how safely an agent or maintainer may
> rely on it. It is not a product roadmap and does not replace live evidence.

## Rule

Unreviewed repository material is a lead, not a fact.

Trust is earned by current evidence: PO decision, live code, tests, builds,
GitHub state, release evidence, and tracked SSOT documents. Authorship does not
matter; a Claude-authored, Codex-authored, or human-authored file must pass the
same checks before it can guide implementation.

## Authority Classes

| Class | Use | Examples | Required check before relying on it |
|---|---|---|---|
| A. Current authority | May guide product or engineering decisions | `AGENTS.md`, root `README.md`, `docs/explanations/vision.md`, `docs/explanations/positioning-and-audience.md` | Confirm it does not conflict with the latest explicit PO decision or live code evidence |
| B. Generated SSOT | May guide status lookup, not strategy | `docs/reference/feature-status.md` | Regenerate or run `Scripts/generate_feature_status.py --check`; inspect source feature spec when changing status |
| C. Current specs and ADRs | May guide implementation after traceability check | `docs/features/active/feat-*.md`, active ADRs | Check `intent_refs`, upstream docs, and live code/test coverage for the specific claim |
| D. Operational tools | May be used only after probe or test | `Scripts/*.py`, hooks, local CLIs, CI workflow files | Verify command path, version, failure mode, and whether hook/CI actually invokes it |
| E. Historical evidence | May explain provenance; must not drive current behavior | historical ADRs, closed PRs, old audit reports, completed migrations | Confirm frontmatter/status marks it as historical or archived, and find the current authority |
| F. Private memory | Routing cache only | Codex/Claude/Gemini/Grok memory files | Treat as stale until confirmed by tracked docs or live evidence; delete obsolete entries instead of preserving noisy summaries |

## Mandatory Checks

Before using any non-trivial repository claim, identify which chain it belongs to:

- Normative chain: latest PO intent -> Vision -> product policy / ADR -> feature spec -> acceptance criteria.
- Evidence chain: live code -> tests / build / device / release evidence -> generated implementation status.

If the two chains disagree, record a deviation or ask for PO judgment. Do not let
the current codebase silently rewrite product intent, and do not let an aspirational
document pretend that implementation already exists.

Before trusting a script or tool as a gate:

1. Locate the executable actually used by the command or hook.
2. Check the version where applicable.
3. Run a small positive/negative probe when feasible.
4. Confirm failure is fail-closed for the relevant workflow.
5. Confirm CI or local hooks really call the same path/configuration.

## Current High-Risk Drift Patterns

The following phrases or concepts are recurring red flags and require fresh
verification before reuse:

- Firebase as a future overseas/default analytics path.
- Domestic-first release as the active production path.
- M-000 / M-003 / M-005 lanes as active planning.
- Agent private memory as product source of truth.
- Old closed issues, old planning files, or deleted docs as current blockers.
- "Already verified" claims without a current build, test, GitHub, App Store
  Connect, or live code reference.

## Cleanup Policy

Prefer deletion over archiving when a private memory entry or repository note is
obsolete and does not provide durable provenance. Preserve history through Git and
GitHub. Keep tracked current docs small enough that agents can read the right file
instead of inheriting stale summaries.

Historical repository documents may remain when they explain why a decision
changed, but they must point to the current authority and must not be listed as
active work.
