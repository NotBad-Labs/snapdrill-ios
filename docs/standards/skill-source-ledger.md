---
last_verified: 2026-05-18
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
| `rshankras` App Store skills | `app-store-rejection`, `privacy-manifests`, `snapshot-testing`, `ui-review` | Commit `89901e7f` message: "安装 4 个 rshankras 社区 skill"; current identified upstream is `https://github.com/rshankras/claude-code-apple-skills` | Community source; not currently tracked by lockfile |
| `rshankras` bulk Apple skills | `accessibility-generator`, `animation-patterns`, `app-description-writer`, `app-icon-generator`, `app-store-assets`, `attributed-string`, `background-processing`, `biometric-auth`, `characterization-test-generator`, `ci-cd-setup`, `coding-best-practices`, `data-export`, `deep-linking`, `error-monitoring`, `integration-test-scaffold`, `keyword-optimizer`, `liquid-glass`, `localization-setup`, `migration-patterns`, `navigation-patterns`, `network-security`, `onboarding-generator`, `push-notifications`, `review-response-writer`, `screenshot-planner`, `secure-storage`, `settings-screen`, `swiftui-debugging`, `tdd-bug-fix`, `tdd-feature`, `tdd-refactor-guard`, `test-contract`, `tipkit-generator` | Commit `14a263ee` message: "批量安装 28+8 个 rshankras 社区 skill"; current identified upstream is `https://github.com/rshankras/claude-code-apple-skills` | Community source; not currently tracked by lockfile |

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
| `accessibility-generator` | `.agents/skills/accessibility-generator/SKILL.md` | Vendored community copy from `rshankras`; local blob differs from current upstream | Convert to lockfile-managed vendored dependency or move back behind Claude-only discovery |
| `app-description-writer` | `.agents/skills/app-description-writer/SKILL.md` | Vendored community copy from `rshankras`; local blob differs from current upstream | Convert to lockfile-managed vendored dependency or move back behind Claude-only discovery |
| `attributed-string` | `.agents/skills/attributed-string/SKILL.md` | Vendored community copy from `rshankras`; local blob differs from current upstream | Convert to lockfile-managed vendored dependency or move back behind Claude-only discovery |
| `characterization-test-generator` | `.agents/skills/characterization-test-generator/SKILL.md` | Vendored community copy from `rshankras`; local blob differs from current upstream | Convert to lockfile-managed vendored dependency or move back behind Claude-only discovery |
| `deep-linking` | `.agents/skills/deep-linking/SKILL.md` | Vendored community copy from `rshankras`; local blob differs from current upstream | Convert to lockfile-managed vendored dependency or move back behind Claude-only discovery |
| `integration-test-scaffold` | `.agents/skills/integration-test-scaffold/SKILL.md` | Vendored community copy from `rshankras`; local blob differs from current upstream | Convert to lockfile-managed vendored dependency or move back behind Claude-only discovery |
| `liquid-glass` | `.agents/skills/liquid-glass/SKILL.md` | Vendored community copy from `rshankras`; local blob differs from current upstream | Convert to lockfile-managed vendored dependency or move back behind Claude-only discovery |
| `navigation-patterns` | `.agents/skills/navigation-patterns/SKILL.md` | Vendored community copy from `rshankras`; local blob differs from current upstream | Convert to lockfile-managed vendored dependency or move back behind Claude-only discovery |
| `privacy-manifests` | `.agents/skills/privacy-manifests/SKILL.md` | Vendored community copy from `rshankras`; local blob differs from current upstream | Convert to lockfile-managed vendored dependency or move back behind Claude-only discovery |
| `push-notifications` | `.agents/skills/push-notifications/SKILL.md` | Vendored community copy from `rshankras`; local blob differs from current upstream | Convert to lockfile-managed vendored dependency or move back behind Claude-only discovery |
| `review-response-writer` | `.agents/skills/review-response-writer/SKILL.md` | Vendored community copy from `rshankras`; local blob differs from current upstream | Convert to lockfile-managed vendored dependency or move back behind Claude-only discovery |
| `screenshot-planner` | `.agents/skills/screenshot-planner/SKILL.md` | Vendored community copy from `rshankras`; local blob differs from current upstream | Convert to lockfile-managed vendored dependency or move back behind Claude-only discovery |
| `test-contract` | `.agents/skills/test-contract/SKILL.md` | Vendored community copy from `rshankras`; local blob differs from current upstream | Convert to lockfile-managed vendored dependency or move back behind Claude-only discovery |

## Current Shared `rshankras` Snapshot

| Skill | Upstream path at `a4eb2f27477783e04ea06b353d41c14136adc259` | Upstream blob | Local shared blob |
|---|---|---|---|
| `accessibility-generator` | `skills/generators/accessibility-generator/SKILL.md` | `42f68967c488e0ff8f58901d785ed1d9950bff61` | `4a441c92b4ac444352b1ef9ddcb15466d9a2b2b2` |
| `app-description-writer` | `skills/app-store/app-description-writer/SKILL.md` | `9aef09490e42d85e3bc14ba5d05cccaa74be02ff` | `53152deaa8b89313ab9bf5451049b4cb1191268d` |
| `attributed-string` | `skills/foundation/attributed-string/SKILL.md` | `6c1aad0fabc61a20b995a4d3e0fc7a50c2c064fb` | `ddaacc15c021b7697cf508a62ac6e8e4d08a17df` |
| `characterization-test-generator` | `skills/testing/characterization-test-generator/SKILL.md` | `7768db1c762287ec70f7b5d6cd5b4d0cfe20dc8c` | `0aa6c32833036d4814a7639404b1448cfa36f140` |
| `deep-linking` | `skills/generators/deep-linking/SKILL.md` | `09bdea74d50c8ebf593764ca7aa01edd302342d1` | `791df20a56b7de75cf9e17e3922ac4d383830269` |
| `integration-test-scaffold` | `skills/testing/integration-test-scaffold/SKILL.md` | `58cf80f1f0ca60138ca84d8b75e084adfd3675f3` | `5bfeeabef2b3029ae692f4f819470ae1a0607024` |
| `liquid-glass` | `skills/design/liquid-glass/SKILL.md` | `3b3db356c5b1f665809967416b186ed0bb77a0d9` | `107b7d2b526a71c3b3d1b746a4ab9c6fbc681942` |
| `navigation-patterns` | `skills/ios/navigation-patterns/SKILL.md` | `8eff0583ac429c84188e5879f29a47e0da61fcfd` | `2e4776f7ce96f1b59e173381c79f460592839f8c` |
| `privacy-manifests` | `skills/security/privacy-manifests/SKILL.md` | `474de679156db10f587ab3a27d94f6c98c307f7d` | `f93776451d59fa4d85926978ae029827de6a61a6` |
| `push-notifications` | `skills/generators/push-notifications/SKILL.md` | `181d8ce2aeddbae73d048b364aa62d1392e2ec08` | `50860973049c4617d6e7cbd17acc5b09a832ff3e` |
| `review-response-writer` | `skills/app-store/review-response-writer/SKILL.md` | `16221ad1533749186d93e4cf80474fe38efc212f` | `c0b4897fd603fa56f49cd6d3e89599cc88948674` |
| `screenshot-planner` | `skills/app-store/screenshot-planner/SKILL.md` | `c02abbea692e6cece6aebe8f8812117340fecf9f` | `436d56008c0dabb03728e41e203a1c29aff15ef0` |
| `test-contract` | `skills/testing/test-contract/SKILL.md` | `10e24b84ce05bb71cb34d6e9c131d73d78fc3b49` | `3c091c96125635293c121f5225e10fa085427932` |

The differing blob hashes mean the shared copies are not current exact upstream files. Treat them as local vendored copies until the project either re-syncs them from upstream or records intentional patches.

`docaudit skill-provenance` enforces the `Local shared blob` column for every shared vendored copy. If a community skill body changes, the gate fails until the change is either reverted or explicitly recorded as a vendored patch decision.

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

- The exact local patch delta from current `rshankras` upstream has not yet been reviewed.
- The already-vendored `rshankras` copies in `.agents/skills/` need a decision: keep as explicitly vendored copies with recorded patches, convert to lockfile-managed dependencies, or move back behind `.claude/skills/` until source tracking is complete.
- `skills-lock.json` currently has no schema for `kind: vendored`, `upstreamCommit`, `upstreamBlob`, `localBlob`, or patch metadata.
