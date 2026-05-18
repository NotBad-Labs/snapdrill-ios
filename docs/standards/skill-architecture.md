---
last_verified: 2026-05-18
layer: pattern
---
# Agent Skill Architecture

> Skill directory ownership, inventory, and migration rules.

## Decision

SnapDrill uses a two-layer skill model:

| Layer | Path | Role | Ownership |
|---|---|---|---|
| Shared agent skills | `.agents/skills/` | Cross-agent SSOT for portable Agent Skills | Project |
| Claude adapter skills | `.claude/skills/` | Claude Code discovery path and Claude-only governance skills | Project, Claude adapter |
| Claude local state | `~/.claude/`, `.claude/*.local`, `.claude/session-log.txt` | Personal preferences, local runtime state, transcripts | Private, not git |

`.claude/skills/` is not private when it is tracked by git, but it is vendor-specific. Portable project-owned skills may move toward `.agents/skills/`; Claude-only skills stay in `.claude/skills/`. Community-maintained skills must follow `skill-source-ledger.md` before their bodies are copied, edited, or treated as project-owned.

## Current Inventory

Counting rule: only first-level `*/SKILL.md` files are counted as triggerable skills. Nested plugin payloads such as `.agents/skills/*/skills/*/SKILL.md` are package contents, not additional first-level project skills.

| Category | Count | Source |
|---|---:|---|
| Claude discovery entries | 54 | `.claude/skills/*/SKILL.md` plus symlink skill dirs |
| Shared first-level skill sources | 16 | `.agents/skills/*/SKILL.md` |
| Claude adapter entries | 16 | 13 thin adapters + 3 managed symlink entries point to shared sources |
| Distinct first-level skill names | 54 | 54 Claude discovery entries + 16 shared sources - 16 duplicate shared entries |
| Plugin payload skills | 2 | `.agents/skills/*/skills/*/SKILL.md` |

Shared skills:

| Skill | Path | Notes |
|---|---|---|
| `swift-concurrency-pro` | `.agents/skills/swift-concurrency-pro/SKILL.md` | Tracked by `skills-lock.json`; existing Claude discovery entry is a symlink |
| `swiftdata-pro` | `.agents/skills/swiftdata-pro/SKILL.md` | Tracked by `skills-lock.json`; existing Claude discovery entry is a symlink |
| `swiftui-pro` | `.agents/skills/swiftui-pro/SKILL.md` | Tracked by `skills-lock.json`; existing Claude discovery entry is a symlink |
| `accessibility-generator` | `.agents/skills/accessibility-generator/SKILL.md` | Vendored community copy; Claude adapter remains at `.claude/skills/accessibility-generator/SKILL.md`; see `skill-source-ledger.md` |
| `app-description-writer` | `.agents/skills/app-description-writer/SKILL.md` | Vendored community copy; Claude adapter remains at `.claude/skills/app-description-writer/SKILL.md`; see `skill-source-ledger.md` |
| `attributed-string` | `.agents/skills/attributed-string/SKILL.md` | Vendored community copy; Claude adapter remains at `.claude/skills/attributed-string/SKILL.md`; see `skill-source-ledger.md` |
| `characterization-test-generator` | `.agents/skills/characterization-test-generator/SKILL.md` | Vendored community copy; Claude adapter remains at `.claude/skills/characterization-test-generator/SKILL.md`; see `skill-source-ledger.md` |
| `deep-linking` | `.agents/skills/deep-linking/SKILL.md` | Vendored community copy; Claude adapter remains at `.claude/skills/deep-linking/SKILL.md`; see `skill-source-ledger.md` |
| `integration-test-scaffold` | `.agents/skills/integration-test-scaffold/SKILL.md` | Vendored community copy; Claude adapter remains at `.claude/skills/integration-test-scaffold/SKILL.md`; see `skill-source-ledger.md` |
| `liquid-glass` | `.agents/skills/liquid-glass/SKILL.md` | Vendored community copy; Claude adapter remains at `.claude/skills/liquid-glass/SKILL.md`; see `skill-source-ledger.md` |
| `navigation-patterns` | `.agents/skills/navigation-patterns/SKILL.md` | Vendored community copy; Claude adapter remains at `.claude/skills/navigation-patterns/SKILL.md`; see `skill-source-ledger.md` |
| `privacy-manifests` | `.agents/skills/privacy-manifests/SKILL.md` | Vendored community copy; Claude adapter remains at `.claude/skills/privacy-manifests/SKILL.md`; see `skill-source-ledger.md` |
| `push-notifications` | `.agents/skills/push-notifications/SKILL.md` | Vendored community copy; Claude adapter remains at `.claude/skills/push-notifications/SKILL.md`; see `skill-source-ledger.md` |
| `review-response-writer` | `.agents/skills/review-response-writer/SKILL.md` | Vendored community copy; Claude adapter remains at `.claude/skills/review-response-writer/SKILL.md`; see `skill-source-ledger.md` |
| `screenshot-planner` | `.agents/skills/screenshot-planner/SKILL.md` | Vendored community copy; Claude adapter remains at `.claude/skills/screenshot-planner/SKILL.md`; see `skill-source-ledger.md` |
| `test-contract` | `.agents/skills/test-contract/SKILL.md` | Vendored community copy; Claude adapter remains at `.claude/skills/test-contract/SKILL.md`; see `skill-source-ledger.md` |

Claude governance skills:

| Skill | Why Claude-only for now |
|---|---|
| `api-research` | F-rule executor, Claude tool permissions |
| `cross-audit` | Claude/Codex/Gemini orchestration, Agent delegation |
| `cross-audit-consensus` | Multi-agent result folding |
| `decision-closeout` | Product decision workflow |
| `dependency-propagation` | Docs propagation workflow |
| `dod-checklist` | Claude DoD workflow |
| `harness-recall` | Claude phase/self-evolution workflow |
| `knowledge-health` | Reads Claude-private planning/memory locations |
| `phase-closeout` | Updates handoff and phase state |
| `post-merge` | Merge closeout workflow |
| `resume-from-handoff` | Claude session bootstrap |
| `sprint-contract` | Issue contract workflow |
| `verify-audit-report` | Adversarial source verification workflow |
| `xcode-review` | Xcode review prompt workflow |

Claude local domain skills:

`animation-patterns`, `app-icon-generator`, `app-store-assets`, `app-store-rejection`, `background-processing`, `biometric-auth`, `ci-cd-setup`, `coding-best-practices`, `data-export`, `error-monitoring`, `keyword-optimizer`, `localization-setup`, `migration-patterns`, `network-security`, `onboarding-generator`, `secure-storage`, `settings-screen`, `snapshot-testing`, `swiftui-debugging`, `tdd-bug-fix`, `tdd-feature`, `tdd-refactor-guard`, `tipkit-generator`, `ui-review`.

These are migration candidates only after frontmatter and references are reviewed for Claude-only features.

## Migration Rules

1. Do not bulk-move skills.
2. Do not use new symlinked `.claude/skills` entries as the default migration path. Existing managed symlink entries may remain if `docaudit skill-inventory` confirms they point at the matching `.agents/skills/<name>` source.
3. Move only one harmless skill at a time.
4. A project-owned skill may move to `.agents/skills/` only if:
   - Its `SKILL.md` uses portable Agent Skills frontmatter.
   - It does not rely on Claude-only hooks, `context: fork`, private Claude paths, or Claude-specific `allowed-tools` semantics.
   - It has no destructive script behavior.
   - Claude Code discovery is preserved by either a physical adapter copy or an explicit verified fallback.
5. A community-maintained skill may move to `.agents/skills/` only after `skill-source-ledger.md` records upstream source, source type, skill path, and hash or commit. Do not edit community skill bodies directly for project preferences.
6. `skills-lock.json` tracks managed `.agents/skills/` dependencies only. It is not an inventory for `.claude/skills/`.

## Verification

Inventory:

```bash
python3 -c 'from pathlib import Path; print(sum(1 for p in Path(".claude/skills").iterdir() if p.is_dir() and (p / "SKILL.md").is_file()))'
find .agents/skills -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l
find .agents/skills -mindepth 4 -maxdepth 4 -path '*/skills/*/SKILL.md' | wc -l
```

Frontmatter scan:

```bash
rg -n '^(name|description|allowed-tools|disable-model-invocation|context|model|effort|agent|agents):' .claude/skills .agents/skills -g 'SKILL.md'
```

Docs gate:

```bash
python3 Scripts/audit/docaudit.py all --strict --baseline
```

## Deferred Work

- Review the already-vendored `rshankras` shared copies in `skill-source-ledger.md` before moving another community skill.
- Decide whether existing vendored community copies should stay in `.agents/skills/` with recorded local patches, become lockfile-managed exact upstream dependencies, or move back behind `.claude/skills/`.
- Verify whether the current Claude Code build discovers symlinked skill directories before using symlinks anywhere.
- Decide whether a physical mirror script is needed only after a pilot proves manual duplication is painful.
