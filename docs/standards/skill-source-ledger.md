---
last_verified: 2026-05-19
layer: pattern
---
# Skill Source Ledger

> Upstream ownership and maintenance policy for Agent Skills.

## Policy

Community-maintained skills are upstream assets, not SnapDrill-owned documentation. SnapDrill may use them, pin them, adapt discovery paths, and carry local patch notes, but must not silently rewrite their source content as if the project owns maintenance.

Rules:

1. Do not migrate or copy community skill bodies into `.agents/skills/` unless the skill has an upstream ledger entry with source, source type, install path, and hash or commit.
2. Do not edit community skill bodies directly for project preferences. Add project-specific adapter notes or a documented patch file instead.
3. If a community skill is vendored into this repository, record it as vendored and assign update responsibility before further modification.
4. Thin adapters may point to a shared source, but the shared source must still preserve upstream ownership metadata.
5. Project-owned governance skills may be maintained locally, but they must not be confused with community skills.

## Known Upstreams

| Skill group | Skills | Upstream evidence | Current maintenance status |
|---|---|---|---|
| `twostraws` Swift skills | `swift-concurrency-pro`, `swiftdata-pro`, `swiftui-pro` | `skills-lock.json` records GitHub source, skill path, and computed hash; upstream repositories include `https://github.com/twostraws/swiftui-agent-skill` | Upstream-managed; tracked by lockfile |
| `rshankras` shared Apple skills | `accessibility-generator`, `app-description-writer`, `attributed-string`, `characterization-test-generator`, `deep-linking`, `integration-test-scaffold`, `liquid-glass`, `navigation-patterns`, `privacy-manifests`, `push-notifications`, `review-response-writer`, `screenshot-planner`, `test-contract` | `skills-lock.json` records `kind: vendored`, upstream commit/path/blob, local path/blob, and patch status | Vendored community copies; lockfile-managed |
| `rshankras` Claude-only skills | `app-store-rejection`, `animation-patterns`, `app-icon-generator`, `app-store-assets`, `background-processing`, `biometric-auth`, `ci-cd-setup`, `coding-best-practices`, `data-export`, `error-monitoring`, `keyword-optimizer`, `localization-setup`, `migration-patterns`, `network-security`, `onboarding-generator`, `secure-storage`, `settings-screen`, `snapshot-testing`, `swiftui-debugging`, `tdd-bug-fix`, `tdd-feature`, `tdd-refactor-guard`, `tipkit-generator`, `ui-review` | Commits `89901e7f` and `14a263ee`; current identified upstream is `https://github.com/rshankras/claude-code-apple-skills` | Community source; Claude-only until reviewed for portable shared use |

Current upstream snapshot for `rshankras/claude-code-apple-skills`:

- Repository: `https://github.com/rshankras/claude-code-apple-skills`
- Commit: `a4eb2f27477783e04ea06b353d41c14136adc259`
- License: MIT
- Upstream installation model: copy `skills/` into project `.claude/skills/` or a user-level Claude skills directory
- Upstream warning: content was generated with Claude Code assistance and may contain inaccuracies; contributions and corrections are welcome

## Current Shared Skill Ownership

| Skill | Current shared path | Ownership status | Required next action |
|---|---|---|---|
| `swift-concurrency-pro` | `.agents/skills/swift-concurrency-pro/SKILL.md` | Upstream-managed via `skills-lock.json` | Keep using lockfile |
| `swiftdata-pro` | `.agents/skills/swiftdata-pro/SKILL.md` | Upstream-managed via `skills-lock.json` | Keep using lockfile |
| `swiftui-pro` | `.agents/skills/swiftui-pro/SKILL.md` | Upstream-managed via `skills-lock.json` | Keep using lockfile |
| `accessibility-generator` | `.agents/skills/accessibility-generator/SKILL.md` | Vendored community copy from `rshankras`; lockfile-managed | Keep using lockfile |
| `app-description-writer` | `.agents/skills/app-description-writer/SKILL.md` | Vendored community copy from `rshankras`; lockfile-managed | Keep using lockfile |
| `attributed-string` | `.agents/skills/attributed-string/SKILL.md` | Vendored community copy from `rshankras`; lockfile-managed | Keep using lockfile |
| `characterization-test-generator` | `.agents/skills/characterization-test-generator/SKILL.md` | Vendored community copy from `rshankras`; lockfile-managed | Keep using lockfile |
| `deep-linking` | `.agents/skills/deep-linking/SKILL.md` | Vendored community copy from `rshankras`; lockfile-managed | Keep using lockfile |
| `integration-test-scaffold` | `.agents/skills/integration-test-scaffold/SKILL.md` | Vendored community copy from `rshankras`; lockfile-managed | Keep using lockfile |
| `liquid-glass` | `.agents/skills/liquid-glass/SKILL.md` | Vendored community copy from `rshankras`; lockfile-managed | Keep using lockfile |
| `navigation-patterns` | `.agents/skills/navigation-patterns/SKILL.md` | Vendored community copy from `rshankras`; lockfile-managed, including support files | Keep using lockfile |
| `privacy-manifests` | `.agents/skills/privacy-manifests/SKILL.md` | Vendored community copy from `rshankras`; lockfile-managed | Keep using lockfile |
| `push-notifications` | `.agents/skills/push-notifications/SKILL.md` | Vendored community copy from `rshankras`; lockfile-managed | Keep using lockfile |
| `review-response-writer` | `.agents/skills/review-response-writer/SKILL.md` | Vendored community copy from `rshankras`; lockfile-managed | Keep using lockfile |
| `screenshot-planner` | `.agents/skills/screenshot-planner/SKILL.md` | Vendored community copy from `rshankras`; lockfile-managed | Keep using lockfile |
| `test-contract` | `.agents/skills/test-contract/SKILL.md` | Vendored community copy from `rshankras`; lockfile-managed | Keep using lockfile |

## Current Shared Vendored Snapshot

`skills-lock.json` is the machine-readable source of truth for current shared vendored skills. For each `kind: vendored` entry it records:

- upstream repository/source type
- upstream commit, upstream path, and upstream blob
- local shared path and local blob
- patch status
- support file upstream/local blobs when a skill references additional Markdown files

As of the 2026-05-19 review, all 13 shared `rshankras` skill bodies match the fixed upstream commit after applying the `.agents` portable frontmatter adapter. The adapter removes Claude-specific `allowed-tools`; it does not rewrite the skill body for SnapDrill preferences.

`navigation-patterns` also carries upstream support files so its relative references remain resolvable without editing the community skill body. Those support file paths and blobs are tracked under its `supportFiles` lockfile entry.

`docaudit skill-provenance` enforces the lockfile local blob for every shared vendored copy. If a community skill body or support file changes, the gate fails until the change is reverted or explicitly recorded as a vendored patch decision.

## Current Claude-Only `rshankras` Skills

These skills remain only in `.claude/skills/` and are not shared through `.agents/skills/`. They still count as community-maintained source unless a separate review classifies them as project-owned.

| Skill | Current Claude path | Current local blob | Upstream status |
|---|---|---|---|
| `app-store-rejection` | `.claude/skills/app-store-rejection/SKILL.md` | `543b8da5ad42cb3a074b0199660689c78bdc5bd7` | Current upstream exact match at `skills/app-store/rejection-handler/SKILL.md` |
| `snapshot-testing` | `.claude/skills/snapshot-testing/SKILL.md` | `56876db9e872638025f412e7323f2e299ecc7278` | Local name/content does not exact-match current upstream `skills/testing/snapshot-test-setup/SKILL.md`; requires review before migration |
| `ui-review` | `.claude/skills/ui-review/SKILL.md` | `82b30a700bbf02e4a89104e420f6e00c8f367dea` | Current upstream exact match at `skills/ios/ui-review/SKILL.md` |

`privacy-manifests` is not listed here because it is already a shared vendored copy at `.agents/skills/privacy-manifests/SKILL.md`.

## Evidence Commands

```bash
cat skills-lock.json
git show -s --format=fuller 89901e7f
git show -s --format=fuller 14a263ee
git show --name-status --oneline 16b735c6 89901e7f 14a263ee
gh api repos/rshankras/claude-code-apple-skills/commits/main --jq '.sha'
gh api 'repos/rshankras/claude-code-apple-skills/git/trees/main?recursive=1' --jq '.tree[] | select(.path|test("/SKILL.md$")) | [.path,.sha,.size] | @tsv'
for f in .agents/skills/*/SKILL.md; do printf '%s\t' "$f"; git hash-object "$f"; done
```

External reference points used for source identification:

- `https://github.com/twostraws/swiftui-agent-skill`
- `https://github.com/twostraws/swift-concurrency-agent-skill`
- `https://github.com/twostraws/swiftdata-agent-skill`
- `https://github.com/rshankras/claude-code-apple-skills`

## Open Questions

- Decide whether any Claude-only `rshankras` skill should be promoted to `.agents/skills/`; do this one skill at a time after upstream path/blob and references are reviewed.
- Define a refresh workflow for checking whether `rshankras/claude-code-apple-skills` has a newer useful upstream commit before intentionally updating vendored blobs.
