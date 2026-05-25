---
last_verified: 2026-05-25
layer: pattern
derived_from: [M-003]
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
| `twostraws` Swift skills | `swift-concurrency-pro`, `swiftdata-pro`, `swiftui-pro` | `skills-lock.json` records GitHub source, skill path, computed hash, local entry blob, and local support-file blobs; upstream repositories include `https://github.com/twostraws/swiftui-agent-skill` | Upstream-managed; local copy tracked by lockfile |
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

## Current Managed Swift Skill Snapshot

`skills-lock.json` also records `kind: managed` entries for the three `twostraws` Swift skills. Their `computedHash` is preserved as installer/upstream metadata, but the current audit does not infer or reimplement that upstream hash algorithm. Instead, `docaudit skill-provenance` enforces repository-local git blob hashes for each managed `SKILL.md` and every listed support file. This prevents silent local edits while keeping upstream refresh semantics separate from local drift detection.

## Vendored Refresh Workflow

Refreshing a community-maintained skill is an upstream sync, not a SnapDrill rewrite. Do not edit vendored skill bodies for local preferences during refresh.

Required sequence:

1. Fetch or extract the upstream repository snapshot to a temporary directory. For git checkouts, checkout the exact `upstreamCommit` recorded in `skills-lock.json`; `skill_refresh_report.py` reports `wrong-commit` when a git checkout HEAD does not match the lockfile.
2. Run `skill_refresh_report.py` against that snapshot:

   ```bash
   python3 Scripts/audit/skill_refresh_report.py \
     --upstream-root /private/tmp/rshankras-a4eb2f27 \
     --strict
   ```

3. If the report is clean and `local_vs_upstream` is unchanged from the intended patch status, no refresh is needed.
4. If upstream rows are `changed`, decide per skill whether to keep the existing pinned copy or update to the newer upstream content.
5. If updating, copy upstream content exactly first. Apply only the portable `.agents` frontmatter adapter when needed; do not make SnapDrill-specific body edits.
   - The adapter may remove Claude-specific frontmatter such as `allowed-tools`, `context`, `disable-model-invocation`, or `user-invocable`.
   - The adapter may preserve portable fields such as `name` and `description`.
   - The adapter must not change the Markdown body below the closing frontmatter marker.
   - Keep LF line endings; unexpected CRLF conversion changes git blob hashes and must be treated as drift until explained.
6. Recompute `skills-lock.json` `upstreamCommit`, `upstreamBlob`, `localBlob`, and `supportFiles` blobs for every changed file.
7. Set `patchStatus` deliberately:
   - `exact-upstream`: local blob equals upstream blob.
   - `frontmatter-adapter-only`: body is upstream content and only portable frontmatter differs.
   - `documented-local-patch`: local skill or support-file content intentionally differs from upstream and must include `patchRationale`.

   `patchRationale` must point to `docs/standards/skill-patches/<skill>.md`. That file must include `Reason:`, `Upstream status:`, and `Removal condition:` fields so the local patch has a named owner and an exit path. If local patches accumulate or become product-specific, stop treating the skill as community-maintained and review whether it has become a project-owned fork.
8. Run:

   ```bash
   python3 Scripts/audit/skill_refresh_report.py --upstream-root <upstream-root> --strict
   python3 Scripts/audit/docaudit.py skill-links --strict
   python3 Scripts/audit/docaudit.py skill-provenance --strict
   python3 Scripts/audit/docaudit.py all --strict --baseline
   ```

Do not promote a Claude-only community skill into `.agents/skills/` during a refresh unless that promotion is reviewed as its own migration.

The refresh report only covers `kind: vendored` shared skills in `skills-lock.json`. Claude-only community skills are governed by the ledger rows in the next section and by `docaudit skill-provenance`.

## Current Claude-Only `rshankras` Skills

These skills remain only in `.claude/skills/` and are not shared through `.agents/skills/`. They still count as community-maintained source unless a separate review classifies them as project-owned. `docaudit skill-provenance` enforces the `Current local blob` column and reports untracked Claude-only non-project skills, so tracked Claude-only community skills cannot be silently rewritten or added without provenance.

| Skill | Current Claude path | Current local blob | Upstream path at `a4eb2f27477783e04ea06b353d41c14136adc259` | Upstream blob | Status |
|---|---|---|---|---|---|
| `tdd-feature` | `.claude/skills/tdd-feature/SKILL.md` | `07118d1ce2b492efb3a6a416434007085d08ad32` | `skills/testing/tdd-feature/SKILL.md` | `241c424b082aaecae0b6b9018d73f22faf5c9b6b` | 路径 C [#018](../meta/user-decision-log.md#018-skill-审计-final-ratified--路径-c-stage-44-完成) 吸纳 tdd-bug-fix / tdd-refactor-guard / integration-test-scaffold / snapshot-testing / snapshot-diff-review / characterization-test-generator 内容（旧 blob 241c424b...） |

注：路径 C [#018](../meta/user-decision-log.md#018-skill-审计-final-ratified--路径-c-stage-44-完成) ratify 后，其他 20 个 Claude-only `rshankras` skill 已处理（参见下方 Retired 段）。

`privacy-manifests` is not listed here because it is already a shared vendored copy at `.agents/skills/privacy-manifests/SKILL.md`.

## Retired Claude-Only Skills

| Skill | Retired Date | Reason | Restore Path |
|---|---|---|---|
| `biometric-auth` | 2026-05-19 | Empty trigger stub (description "Biometric Authentication"); SnapDrill 零注册 product model 当前无 biometric auth 场景 | Re-vendor from `rshankras/claude-code-apple-skills` `skills/security/biometric-auth.md` (upstream blob `610c24e999f20761e3dbee7344467969a14dcb21`) if iCloud sync (#485) requires biometric gate |
| `network-security` | 2026-05-19 | Empty trigger stub; SnapDrill 仅 Firebase Analytics 网络调用且已 gated by user consent | Re-vendor from `rshankras` upstream `skills/security/network-security.md` (upstream blob `d850346d92fa76d0b1654ff123b1e1feff56b6b3`) if network attack surface 扩大 |
| `secure-storage` | 2026-05-19 | Empty trigger stub; SnapDrill 纯本地 SwiftData + Profile 隔离，无 keychain/secrets 需求 | Re-vendor from `rshankras` upstream `skills/security/secure-storage.md` (upstream blob `2d7a25055282f4aaf7b554e0fcf3827bd3256e13`) if 引入 secrets/keychain

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
