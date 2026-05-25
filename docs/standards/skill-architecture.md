---
last_verified: 2026-05-19
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

`.claude/skills/` is not private when it is tracked by git, but it is vendor-specific. Portable project-owned skills may move toward `.agents/skills/`; Claude-only skills stay in `.claude/skills/`. Community-maintained skills must be recorded in `skill-source-ledger.md` and machine-pinned in `skills-lock.json` before their bodies are copied, edited, or treated as shared dependencies.

## Current Inventory

Counting rule: only first-level `*/SKILL.md` files are counted as triggerable skills. Nested plugin payloads such as `.agents/skills/*/skills/*/SKILL.md` are package contents, not additional first-level project skills.

| Category | Count | Source |
|---|---:|---|
| Claude discovery entries | 11 | `.claude/skills/*/SKILL.md` plus symlink skill dirs |
| Shared first-level skill sources | 16 | `.agents/skills/*/SKILL.md` |
| Claude adapter entries | 5 | adapters pointing to shared sources（路径 C #018 大规模清理后） |
| Distinct first-level skill names | 22 | 11 Claude discovery + 16 shared - 5 duplicate adapters |
| Plugin payload skills | 2 | `.agents/skills/*/skills/*/SKILL.md` |

> 2026-05-19：3 个 stub skill 退役（`biometric-auth` / `network-security` / `secure-storage`）—— 详见 `skill-source-ledger.md` Retired Claude-Only Skills 段。54 → 51。
> 2026-05-20：从 `snapshot-testing/SKILL.md` 拆出嵌入的第二个 frontmatter `snapshot-diff-review` 为独立 skill（Phase 9 finding Y）。51 → 52。
> 2026-05-25：路径 C 第一性原理审计（[user-decision-log #016~#018](../meta/user-decision-log.md#016-路径-c-启动--skill-生态第一性原理审计彻底解决自举循环)）完成，52 → 11 active skill（净减 79%）。归档 41 个：7 DELETE + 24 MERGE 到目标容器 / standards / templates + 5 PROMOTE_TO_STANDARDS + 7 DOWNGRADE_TO_TEMPLATE。详见 [skill-audit-final.md](../audits/skill-audit-final.md)。

Shared skills:

| Skill | Path | Notes |
|---|---|---|
| `swift-concurrency-pro` | `.agents/skills/swift-concurrency-pro/SKILL.md` | Tracked by `skills-lock.json`; existing Claude discovery entry is a symlink |
| `swiftdata-pro` | `.agents/skills/swiftdata-pro/SKILL.md` | Tracked by `skills-lock.json`; existing Claude discovery entry is a symlink |
| `swiftui-pro` | `.agents/skills/swiftui-pro/SKILL.md` | Tracked by `skills-lock.json`; existing Claude discovery entry is a symlink |
| `accessibility-generator` | `.agents/skills/accessibility-generator/SKILL.md` | Vendored community copy tracked by `skills-lock.json`; Claude adapter remains at `.claude/skills/accessibility-generator/SKILL.md` |
| `app-description-writer` | `.agents/skills/app-description-writer/SKILL.md` | Vendored community copy tracked by `skills-lock.json`; Claude adapter remains at `.claude/skills/app-description-writer/SKILL.md` |
| `attributed-string` | `.agents/skills/attributed-string/SKILL.md` | Vendored community copy tracked by `skills-lock.json`; Claude adapter remains at `.claude/skills/attributed-string/SKILL.md` |
| `characterization-test-generator` | `.agents/skills/characterization-test-generator/SKILL.md` | Vendored community copy tracked by `skills-lock.json`; Claude adapter remains at `.claude/skills/characterization-test-generator/SKILL.md` |
| `deep-linking` | `.agents/skills/deep-linking/SKILL.md` | Vendored community copy tracked by `skills-lock.json`; Claude adapter remains at `.claude/skills/deep-linking/SKILL.md` |
| `integration-test-scaffold` | `.agents/skills/integration-test-scaffold/SKILL.md` | Vendored community copy tracked by `skills-lock.json`; Claude adapter remains at `.claude/skills/integration-test-scaffold/SKILL.md` |
| `liquid-glass` | `.agents/skills/liquid-glass/SKILL.md` | Vendored community copy tracked by `skills-lock.json`; Claude adapter remains at `.claude/skills/liquid-glass/SKILL.md` |
| `navigation-patterns` | `.agents/skills/navigation-patterns/SKILL.md` | Vendored community copy tracked by `skills-lock.json`, including support files; Claude adapter remains at `.claude/skills/navigation-patterns/SKILL.md` |
| `privacy-manifests` | `.agents/skills/privacy-manifests/SKILL.md` | Vendored community copy tracked by `skills-lock.json`; Claude adapter remains at `.claude/skills/privacy-manifests/SKILL.md` |
| `push-notifications` | `.agents/skills/push-notifications/SKILL.md` | Vendored community copy tracked by `skills-lock.json`; Claude adapter remains at `.claude/skills/push-notifications/SKILL.md` |
| `review-response-writer` | `.agents/skills/review-response-writer/SKILL.md` | Vendored community copy tracked by `skills-lock.json`; Claude adapter remains at `.claude/skills/review-response-writer/SKILL.md` |
| `screenshot-planner` | `.agents/skills/screenshot-planner/SKILL.md` | Vendored community copy tracked by `skills-lock.json`; Claude adapter remains at `.claude/skills/screenshot-planner/SKILL.md` |
| `test-contract` | `.agents/skills/test-contract/SKILL.md` | Vendored community copy tracked by `skills-lock.json`; Claude adapter remains at `.claude/skills/test-contract/SKILL.md` |

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
| `snapshot-diff-review` | Snapshot baseline 二进制 diff 人工审查工作流 |
| `sprint-contract` | Issue contract workflow |
| `verify-audit-report` | Adversarial source verification workflow |
| `xcode-review` | Xcode review prompt workflow |

Claude local domain skills:

`animation-patterns`, `app-icon-generator`, `app-store-assets`, `app-store-rejection`, `background-processing`, `ci-cd-setup`, `coding-best-practices`, `data-export`, `error-monitoring`, `keyword-optimizer`, `localization-setup`, `migration-patterns`, `onboarding-generator`, `settings-screen`, `snapshot-testing`, `swiftui-debugging`, `tdd-bug-fix`, `tdd-feature`, `tdd-refactor-guard`, `tipkit-generator`, `ui-review`.

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
5. A community-maintained skill may move to `.agents/skills/` only after `skill-source-ledger.md` records ownership policy and `skills-lock.json` records upstream source plus a locally verifiable integrity boundary. Vendored skills must record upstream commit/path/blob, local path/blob, and patch status. Managed skills must record local entry/support-file blobs in addition to their installer metadata. Do not edit community skill bodies directly for project preferences.
6. `skills-lock.json` tracks managed and vendored `.agents/skills/` dependencies only. It is not an inventory for `.claude/skills/`.

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

Adapter shape:

```bash
find .claude/skills -maxdepth 1 -type l -print
for f in .claude/skills/*/SKILL.md; do if rg -q 'Shared skill source:' "$f"; then printf '%s\n' "$f"; fi; done
```

Docs gate:

```bash
python3 Scripts/audit/docaudit.py all --strict --baseline
python3 Scripts/audit/docaudit.py skill-provenance --strict
```

## Deferred Work

- Review Claude-only `rshankras` skills one at a time before moving another community skill into `.agents/skills/`.
- Use the `skill-source-ledger.md` vendored refresh workflow before updating any lockfile-managed community skill.
- Verify whether the current Claude Code build discovers symlinked skill directories before using symlinks anywhere.
- Decide whether a physical mirror script is needed only after a pilot proves manual duplication is painful.

## Skill `description` 字段语义边界（澄清）

`description` 是 **routing / trigger 索引**，不是 SLA 承诺：

- Claude（或其他 agent）通过 description 决定**是否触发 skill** + 进入 body 后再读详细行为契约
- description 经常使用「Generates / Reviews / Checks / Verifies / Provides」等动作动词作为触发关键字（与 body 实际行为可能有「承诺动词」与「实际工作流」的字面差异）
- 不应将 description 字面与 body 完全对齐作为漂移判据——只要 body 实际行为与 description 表达的**意图**一致即可
- 但凡 description 描述的**意图**与 body 实现的**功能**不匹配（如 description 承诺 X 类输入但 body 完全不处理 X），仍属真漂移，需修正

实际漂移判定的优先级：
1. 触发关键字偏差但意图一致 → 容忍（不算漂移）
2. body 引用的支持文件不存在 → 真漂移（修 body 或补文件）
3. description 承诺的输出格式与 body 输出不匹配 → 真漂移（对齐 description 或 body）
4. description 涵盖范围远小于 body 实际能力 → 真漂移（扩 description）
5. description 涵盖范围远大于 body 实际能力 → 真漂移（收 description）
