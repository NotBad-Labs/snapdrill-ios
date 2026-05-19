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

These skills remain only in `.claude/skills/` and are not shared through `.agents/skills/`. They still count as community-maintained source unless a separate review classifies them as project-owned. `docaudit skill-provenance` enforces the `Current local blob` column and reports untracked Claude-only non-project skills, so tracked Claude-only community skills cannot be silently rewritten or added without provenance.

| Skill | Current Claude path | Current local blob | Upstream path at `a4eb2f27477783e04ea06b353d41c14136adc259` | Upstream blob | Status |
|---|---|---|---|---|---|
| `animation-patterns` | `.claude/skills/animation-patterns/SKILL.md` | `d1e3f068950ccbd14c3006fc2f890f4beed00103` | `skills/design/animation-patterns/SKILL.md` | `d1e3f068950ccbd14c3006fc2f890f4beed00103` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `app-icon-generator` | `.claude/skills/app-icon-generator/SKILL.md` | `e348a20596b0f8e2f0132b66dab4198e212ff87e` | `skills/generators/app-icon-generator/SKILL.md` | `e348a20596b0f8e2f0132b66dab4198e212ff87e` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `app-store-assets` | `.claude/skills/app-store-assets/SKILL.md` | `1bbd8f8ade002f61c5aaa6d7768f9ae2e4d4ae4e` | `skills/generators/app-store-assets/SKILL.md` | `1bbd8f8ade002f61c5aaa6d7768f9ae2e4d4ae4e` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `app-store-rejection` | `.claude/skills/app-store-rejection/SKILL.md` | `543b8da5ad42cb3a074b0199660689c78bdc5bd7` | `skills/app-store/rejection-handler/SKILL.md` | `543b8da5ad42cb3a074b0199660689c78bdc5bd7` | Exact upstream SKILL.md; local skill name differs from upstream directory |
| `background-processing` | `.claude/skills/background-processing/SKILL.md` | `4e2cae2ee63664e5c44363fc03c34775d1d93800` | `skills/generators/background-processing/SKILL.md` | `4e2cae2ee63664e5c44363fc03c34775d1d93800` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `biometric-auth` | `.claude/skills/biometric-auth/SKILL.md` | `86ee6c7bc85112915863130e03efef0885a9f667` | `skills/security/biometric-auth.md` | `610c24e999f20761e3dbee7344467969a14dcb21` | Local Claude trigger stub; upstream content is a Markdown reference, not SKILL.md |
| `ci-cd-setup` | `.claude/skills/ci-cd-setup/SKILL.md` | `020afa25befe8a74fcb8e8ea3bcba213fb721bda` | `skills/generators/ci-cd-setup/SKILL.md` | `020afa25befe8a74fcb8e8ea3bcba213fb721bda` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `coding-best-practices` | `.claude/skills/coding-best-practices/SKILL.md` | `1181a9c2cbbf782436554b42f823f41118b67b0b` | `skills/ios/coding-best-practices/SKILL.md` | `1181a9c2cbbf782436554b42f823f41118b67b0b` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `data-export` | `.claude/skills/data-export/SKILL.md` | `7d5c633c0f80733d5353410ac4503adbfc173c91` | `skills/generators/data-export/SKILL.md` | `7d5c633c0f80733d5353410ac4503adbfc173c91` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `error-monitoring` | `.claude/skills/error-monitoring/SKILL.md` | `5a0be90659113d7b4a9eb7acd65765968390d6ac` | `skills/generators/error-monitoring/SKILL.md` | `5a0be90659113d7b4a9eb7acd65765968390d6ac` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `keyword-optimizer` | `.claude/skills/keyword-optimizer/SKILL.md` | `6bb44e400ae12a32fcc6c5be750233b95e27223a` | `skills/app-store/keyword-optimizer/SKILL.md` | `6bb44e400ae12a32fcc6c5be750233b95e27223a` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `localization-setup` | `.claude/skills/localization-setup/SKILL.md` | `c35fc8dc0f40d459b2a22a2a5c11f1e24561b07d` | `skills/generators/localization-setup/SKILL.md` | `c35fc8dc0f40d459b2a22a2a5c11f1e24561b07d` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `migration-patterns` | `.claude/skills/migration-patterns/SKILL.md` | `6bc52abba31db7fd194611cfb6ee4a6136ee5191` | `skills/ios/migration-patterns/SKILL.md` | `6bc52abba31db7fd194611cfb6ee4a6136ee5191` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `network-security` | `.claude/skills/network-security/SKILL.md` | `08fa3ebc6558660484cfc99c12504f8fd8d14727` | `skills/security/network-security.md` | `d850346d92fa76d0b1654ff123b1e1feff56b6b3` | Local Claude trigger stub; upstream content is a Markdown reference, not SKILL.md |
| `onboarding-generator` | `.claude/skills/onboarding-generator/SKILL.md` | `c80d3a18ad06b74a3db630633e20e11dcfb3bb70` | `skills/generators/onboarding-generator/SKILL.md` | `c80d3a18ad06b74a3db630633e20e11dcfb3bb70` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `secure-storage` | `.claude/skills/secure-storage/SKILL.md` | `d8aef7aac9c56603cdbbe59b46928e4dc23ad0e4` | `skills/security/secure-storage.md` | `2d7a25055282f4aaf7b554e0fcf3827bd3256e13` | Local Claude trigger stub; upstream content is a Markdown reference, not SKILL.md |
| `settings-screen` | `.claude/skills/settings-screen/SKILL.md` | `8085eb5ba3f6be04dfd1f5f38a124c3a08f533c1` | `skills/generators/settings-screen/SKILL.md` | `8085eb5ba3f6be04dfd1f5f38a124c3a08f533c1` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `snapshot-testing` | `.claude/skills/snapshot-testing/SKILL.md` | `56876db9e872638025f412e7323f2e299ecc7278` | `skills/testing/snapshot-test-setup/SKILL.md` | `676876544ffe6b55e9d0665bf325714534d8ec8f` | Local body differs from current upstream; requires review before promotion |
| `swiftui-debugging` | `.claude/skills/swiftui-debugging/SKILL.md` | `82f6f078404b9239a5803f3980dd2e6f76336c0b` | `skills/performance/swiftui-debugging/SKILL.md` | `82f6f078404b9239a5803f3980dd2e6f76336c0b` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `tdd-bug-fix` | `.claude/skills/tdd-bug-fix/SKILL.md` | `64a06989041c77516258c981baf54217a906fff4` | `skills/testing/tdd-bug-fix/SKILL.md` | `64a06989041c77516258c981baf54217a906fff4` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `tdd-feature` | `.claude/skills/tdd-feature/SKILL.md` | `241c424b082aaecae0b6b9018d73f22faf5c9b6b` | `skills/testing/tdd-feature/SKILL.md` | `241c424b082aaecae0b6b9018d73f22faf5c9b6b` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `tdd-refactor-guard` | `.claude/skills/tdd-refactor-guard/SKILL.md` | `03a171c47f5a4533255e70157b2bca5f441b0cdf` | `skills/testing/tdd-refactor-guard/SKILL.md` | `03a171c47f5a4533255e70157b2bca5f441b0cdf` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `tipkit-generator` | `.claude/skills/tipkit-generator/SKILL.md` | `a89c5a063b6f8169e3337163cca435d44a2192a8` | `skills/generators/tipkit-generator/SKILL.md` | `a89c5a063b6f8169e3337163cca435d44a2192a8` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |
| `ui-review` | `.claude/skills/ui-review/SKILL.md` | `82b30a700bbf02e4a89104e420f6e00c8f367dea` | `skills/ios/ui-review/SKILL.md` | `82b30a700bbf02e4a89104e420f6e00c8f367dea` | Exact upstream SKILL.md; keep Claude-only until shared need is proven |

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
