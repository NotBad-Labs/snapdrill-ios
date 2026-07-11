# Phase 04 In-Progress Checkpoint

## T0

- rebaseline reference: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- product base: `origin/develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- main checkout: remains at `d62fead8`; only pre-existing untracked `agent-reports/`, untouched
- worktree: `/private/tmp/snapdrill-repository-audit-phase04`
- branch: `codex/repository-audit-phase04`
- phase start HEAD: `56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- open write work: audit branch plus pre-existing Draft PR #864; write WIP = 2

## Frozen Slices

- `04a`: SwiftData models, relationships, repository save/delete and migration baseline
- `04b`: Profile/Vault lifecycle, isolation, preferences and legacy migration
- `04c`: backup V2 wire, ZIP validation, restore staging, rollback and round-trip
- `04d`: image paths, Profile filesystem ownership, EXIF privacy and orphan cleanup

Each slice uses the same product base and an independent neutral brief. Claude, Antigravity and Grok remain read-only reviewers; Codex C1 reproduces every candidate before ledger entry.

## Early PO Decisions

- Draft PR #864 bundles App Store/legal copy with SmartPaper-domain terminology that conflicts with the retained domain vocabulary. Recommendation: close and later respin bounded copy slices.
- If Phase 04 verifies a P0/P1, C1 requests authority to open a second bounded fix worktree and Draft PR while preserving the no-merge rule.

## Recovery

- `04a` complete: `phases/04a-results.md`; 2×P2 and 2×P3, no P0/P1
- next action: run independent `04b` reviews from `phases/04b-profile-brief.md`
- stop conditions: base drift, write WIP above 2, verified destructive P0/P1 without fix authority, or a required dynamic probe that cannot run
