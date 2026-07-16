# Phase 00b Brief: Control-Plane Blind Review

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/explanations/vision.md` 与 `docs/reference/release-1-contract.md`。

## Metadata

- `base_sha`: `d62fead87fb103708652ac5378eda8e2c03f8257`
- outcome: determine whether repository process claims are enforced by the live control-plane files
- validation: T1 read-only audit
- time/file budget: 30 minutes, 9 primary files

## Scope

Read only these primary files and files they directly reference:

- `AGENTS.md`
- `.gitignore`
- `.github/workflows/ci.yml`
- `Scripts/pre-commit`
- `Scripts/setup.sh`
- `docs/README.md`
- `docs/how-to/definition-of-ready.md`
- `docs/how-to/parallel-lanes.md`
- `docs/how-to/release-and-ci.md`

Questions:

1. Which claims about hooks, CI, generated docs, worktrees or agent roles are not enforced by the live files?
2. Which referenced files or commands are missing, stale or misleading?
3. Could any verified drift create duplicate work, false-green validation or a second truth source?

## Exclusions

- Do not inspect or change product code.
- Do not read another agent's report, private memory, old report or chat history.
- Do not use web search or external product facts.
- Do not propose broad rewrites. The task is evidence collection, not repair.
- Existing warning-only output is not a finding unless it contradicts an explicit enforced claim.

## Allowed Commands

Use read-only `git`, `rg`, `sed`, `find`, `ls` and existing `python3 ... --check` commands. Do not create, edit, delete, stage or commit files. Do not run network commands.

## Output

Emit the report only; the orchestrator captures stdout outside the repository. Use these sections:

1. Metadata: exact agent/model/CLI, base SHA, outcome and commands run.
2. Coverage: files actually read and any excluded content.
3. Findings: stable candidate ID, P0-P3, falsifiable claim, expected, actual, `path:line`, exact reproduction, impact, confidence and smallest next check.
4. Hypotheses: suspicions without direct evidence and what evidence is missing.
5. Rejected During Review: candidates disproved by a guard, test or scope rule.
6. Handoff: only the next verification command or blocker.

`No findings` is valid. Do not state that the whole repository was audited.
