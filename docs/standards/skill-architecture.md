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

`.claude/skills/` is not private when it is tracked by git, but it is vendor-specific. Portable skills should move toward `.agents/skills/`; Claude-only skills stay in `.claude/skills/`.

## Current Inventory

Counting rule: only first-level `*/SKILL.md` files are counted as triggerable skills. Nested plugin payloads such as `.agents/skills/*/skills/*/SKILL.md` are package contents, not additional first-level project skills.

| Category | Count | Source |
|---|---:|---|
| Claude discovery entries | 54 | `.claude/skills/*/SKILL.md` plus symlink skill dirs |
| Shared first-level skill sources | 6 | `.agents/skills/*/SKILL.md` |
| Claude adapter entries | 6 | 3 thin adapters + 3 managed symlink entries point to shared sources |
| Distinct first-level skill names | 54 | 54 Claude discovery entries + 6 shared sources - 6 duplicate shared entries |
| Plugin payload skills | 2 | `.agents/skills/*/skills/*/SKILL.md` |

Shared skills:

| Skill | Path | Notes |
|---|---|---|
| `swift-concurrency-pro` | `.agents/skills/swift-concurrency-pro/SKILL.md` | Tracked by `skills-lock.json`; existing Claude discovery entry is a symlink |
| `swiftdata-pro` | `.agents/skills/swiftdata-pro/SKILL.md` | Tracked by `skills-lock.json`; existing Claude discovery entry is a symlink |
| `swiftui-pro` | `.agents/skills/swiftui-pro/SKILL.md` | Tracked by `skills-lock.json`; existing Claude discovery entry is a symlink |
| `attributed-string` | `.agents/skills/attributed-string/SKILL.md` | Project pilot migration; Claude adapter remains at `.claude/skills/attributed-string/SKILL.md` |
| `navigation-patterns` | `.agents/skills/navigation-patterns/SKILL.md` | Project pilot migration; Claude adapter remains at `.claude/skills/navigation-patterns/SKILL.md` |
| `privacy-manifests` | `.agents/skills/privacy-manifests/SKILL.md` | Project pilot migration; Claude adapter remains at `.claude/skills/privacy-manifests/SKILL.md` |

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

`accessibility-generator`, `animation-patterns`, `app-description-writer`, `app-icon-generator`, `app-store-assets`, `app-store-rejection`, `background-processing`, `biometric-auth`, `characterization-test-generator`, `ci-cd-setup`, `coding-best-practices`, `data-export`, `deep-linking`, `error-monitoring`, `integration-test-scaffold`, `keyword-optimizer`, `liquid-glass`, `localization-setup`, `migration-patterns`, `network-security`, `onboarding-generator`, `push-notifications`, `review-response-writer`, `screenshot-planner`, `secure-storage`, `settings-screen`, `snapshot-testing`, `swiftui-debugging`, `tdd-bug-fix`, `tdd-feature`, `tdd-refactor-guard`, `test-contract`, `tipkit-generator`, `ui-review`.

These are migration candidates only after frontmatter and references are reviewed for Claude-only features.

## Migration Rules

1. Do not bulk-move skills.
2. Do not use new symlinked `.claude/skills` entries as the default migration path. Existing managed symlink entries may remain if `docaudit skill-inventory` confirms they point at the matching `.agents/skills/<name>` source.
3. Move only one harmless skill at a time.
4. A skill may move to `.agents/skills/` only if:
   - Its `SKILL.md` uses portable Agent Skills frontmatter.
   - It does not rely on Claude-only hooks, `context: fork`, private Claude paths, or Claude-specific `allowed-tools` semantics.
   - It has no destructive script behavior.
   - Claude Code discovery is preserved by either a physical adapter copy or an explicit verified fallback.
5. `skills-lock.json` tracks managed `.agents/skills/` dependencies only. It is not an inventory for `.claude/skills/`.

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

- Review the `attributed-string`, `navigation-patterns`, and `privacy-manifests` adapter pattern after live use before moving a fourth domain skill.
- Verify whether the current Claude Code build discovers symlinked skill directories before using symlinks anywhere.
- Decide whether a physical mirror script is needed only after a pilot proves manual duplication is painful.
