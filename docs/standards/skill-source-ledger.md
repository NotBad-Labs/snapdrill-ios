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
| `rshankras` App Store skills | `app-store-rejection`, `privacy-manifests`, `snapshot-testing`, `ui-review` | Commit `89901e7f` message: "安装 4 个 rshankras 社区 skill"; upstream repository appears as `https://github.com/rshankras/claude-code-apple-skills` in public skill indexes | Community source; not currently tracked by lockfile |
| `rshankras` bulk Apple skills | `accessibility-generator`, `animation-patterns`, `app-description-writer`, `app-icon-generator`, `app-store-assets`, `attributed-string`, `background-processing`, `biometric-auth`, `characterization-test-generator`, `ci-cd-setup`, `coding-best-practices`, `data-export`, `deep-linking`, `error-monitoring`, `integration-test-scaffold`, `keyword-optimizer`, `liquid-glass`, `localization-setup`, `migration-patterns`, `navigation-patterns`, `network-security`, `onboarding-generator`, `push-notifications`, `review-response-writer`, `screenshot-planner`, `secure-storage`, `settings-screen`, `swiftui-debugging`, `tdd-bug-fix`, `tdd-feature`, `tdd-refactor-guard`, `test-contract`, `tipkit-generator` | Commit `14a263ee` message: "批量安装 28+8 个 rshankras 社区 skill"; public indexes show install examples for `https://github.com/rshankras/claude-code-apple-skills` | Community source; not currently tracked by lockfile |

## Current Shared Skill Ownership

| Skill | Current shared path | Ownership status | Required next action |
|---|---|---|---|
| `swift-concurrency-pro` | `.agents/skills/swift-concurrency-pro/SKILL.md` | Upstream-managed via `skills-lock.json` | Keep using lockfile |
| `swiftdata-pro` | `.agents/skills/swiftdata-pro/SKILL.md` | Upstream-managed via `skills-lock.json` | Keep using lockfile |
| `swiftui-pro` | `.agents/skills/swiftui-pro/SKILL.md` | Upstream-managed via `skills-lock.json` | Keep using lockfile |
| `accessibility-generator` | `.agents/skills/accessibility-generator/SKILL.md` | Vendored community copy from `rshankras` | Add upstream source/path/hash before further edits |
| `app-description-writer` | `.agents/skills/app-description-writer/SKILL.md` | Vendored community copy from `rshankras` | Add upstream source/path/hash before further edits |
| `attributed-string` | `.agents/skills/attributed-string/SKILL.md` | Vendored community copy from `rshankras` | Add upstream source/path/hash before further edits |
| `characterization-test-generator` | `.agents/skills/characterization-test-generator/SKILL.md` | Vendored community copy from `rshankras` | Add upstream source/path/hash before further edits |
| `deep-linking` | `.agents/skills/deep-linking/SKILL.md` | Vendored community copy from `rshankras` | Add upstream source/path/hash before further edits |
| `integration-test-scaffold` | `.agents/skills/integration-test-scaffold/SKILL.md` | Vendored community copy from `rshankras` | Add upstream source/path/hash before further edits |
| `liquid-glass` | `.agents/skills/liquid-glass/SKILL.md` | Vendored community copy from `rshankras` | Add upstream source/path/hash before further edits |
| `navigation-patterns` | `.agents/skills/navigation-patterns/SKILL.md` | Vendored community copy from `rshankras` | Add upstream source/path/hash before further edits |
| `privacy-manifests` | `.agents/skills/privacy-manifests/SKILL.md` | Vendored community copy from `rshankras` | Add upstream source/path/hash before further edits |
| `push-notifications` | `.agents/skills/push-notifications/SKILL.md` | Vendored community copy from `rshankras` | Add upstream source/path/hash before further edits |
| `review-response-writer` | `.agents/skills/review-response-writer/SKILL.md` | Vendored community copy from `rshankras` | Add upstream source/path/hash before further edits |
| `screenshot-planner` | `.agents/skills/screenshot-planner/SKILL.md` | Vendored community copy from `rshankras` | Add upstream source/path/hash before further edits |
| `test-contract` | `.agents/skills/test-contract/SKILL.md` | Vendored community copy from `rshankras` | Add upstream source/path/hash before further edits |

## Evidence Commands

```bash
cat skills-lock.json
git show -s --format=fuller 89901e7f
git show -s --format=fuller 14a263ee
git show --name-status --oneline 16b735c6 89901e7f 14a263ee
```

External reference points used for source identification:

- `https://github.com/twostraws/swiftui-agent-skill`
- `https://github.com/twostraws/swift-concurrency-agent-skill`
- `https://github.com/twostraws/swiftdata-agent-skill`
- `https://github.com/rshankras/claude-code-apple-skills`

## Open Questions

- Exact upstream paths and hashes for the `rshankras` skills have not yet been recorded.
- The already-vendored `rshankras` copies in `.agents/skills/` need a decision: keep as explicitly vendored copies, convert to lockfile-managed dependencies, or move back behind `.claude/skills/` until source tracking is complete.
