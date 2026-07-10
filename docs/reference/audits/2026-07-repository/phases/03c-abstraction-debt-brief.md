# Phase 03c Brief: Abstraction Debt and Historical Simplification

## Fixed Base

- Product base: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- Audit worktree: `/private/tmp/snapdrill-repository-audit`
- Mode: read-only review; do not edit, stage, commit, create files or use network tools

Do not read prior audit findings, phase results, checkpoints, private memory, agent reports or another reviewer's output.

## Question

Did past architecture simplification remove only pass-through layers, or did it also erase business-rule tests or leave half-migrated protocols, coordinators, static facades and dead abstractions that now raise change risk?

## Primary Scope

- Current `Packages/**/Sources/**/*.swift` and focused tests
- Git commits `240887cb`, `37cb827e`, `aa5e1de8` and their parents
- Current protocol implementations and callers
- `docs/explanations/architecture.md`
- `AGENTS.md` simplicity/decoupling rules

Do not treat deleted lines, old age, single implementation or lack of a static caller as sufficient proof of waste/deletion. Do not revive the removed Domain/UseCase package without a concrete lost rule and current change-cost proof.

## Checks

1. Compare removed UseCase/Domain behavior and tests with current Repository/ViewModel/Core coverage; identify any business oracle that disappeared without replacement.
2. Inventory current protocols and distinguish real alternate implementations/test doubles from pass-through interfaces.
3. Check coordinators/facades/managers for actual orchestration value, duplicate ownership or half-completed migration.
4. Find dead source only when build, runtime, tests, docs and dynamic references all support the claim; otherwise route as a hypothesis.
5. Prefer keep/repair/retire classifications over a broad rewrite; quantify the smallest behavior-preserving next check.

## Output

Use the repository report schema. Return at most eight falsifiable findings with `path:line`, impact and smallest next check; include rejected cleanup temptations. `No findings` is valid. Separate historical cost from current release risk.
