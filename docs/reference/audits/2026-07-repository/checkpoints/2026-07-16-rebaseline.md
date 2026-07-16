# 2026-07-16 Repository Audit Rebaseline

## T0

- base: `origin/develop@41a389583a5edeb4304d751e8894cf9843238d83`
- source merge: #937, exact head `c7c6cb635ae34b3f871e0e6e0b1886b351131624`
- worktree: `/private/tmp/snapdrill-audit-checkpoint-rebaseline`
- branch: `codex/audit-checkpoint-rebaseline`
- main checkout: detached at `82c9aab9` with only the pre-existing untracked
  `agent-reports/`; untouched
- open PRs at T0: none
- write WIP at T0: this docs-only checkpoint only
- external reviewers: none required for the factual rebaseline; historical external output remains
  non-authoritative

This checkpoint supersedes the recovery instructions in `phase-04-in-progress.md` and
`phase-05-in-progress.md`. It does not rewrite those fixed-base reports.

## Document Control Closure Addendum

This branch also closes the repository-wide Markdown control gap identified after the Agent control
plane review. The addendum stayed on Draft PR #938 because #938 and the independent data-safety
Draft PR #939 already occupy the `write WIP <= 2` allowance; no third write branch was opened.

At validation time, the registry covers 126 repository Markdown paths exactly once: 2 aliases point
to an existing body, while the remaining 124 bodies are classified as authority, operations,
evidence, generated output or template, each with an explicit lifecycle. The high-risk inactive
sets are visible and machine enforced:

- 43 fixed-base audit documents are `evidence/frozen`;
- 6 former UI contracts are `evidence/superseded`;
- ADR-001 and ADR-004 are `authority/superseded`;
- ADR-003 is `authority/suspended`.

[`document-control.md`](../../../document-control.md) explains the model and
[`document-control.json`](../../../document-control.json) is the machine registry. The validator
fails when a Markdown file is unclassified, matches multiple rules, uses an invalid role/lifecycle,
omits a required historical marker, contains an unsupported wiki link, or points to a missing local
file / heading. `validate_docs.py` now excludes frozen, superseded and suspended material from
current semantic scans without deleting its historical evidence.

The same slice aligns the release-readiness skill, GitHub templates, root/package/DocC navigation
and generated feature indexes. `implemented` now means only that a live code path exists; it no
longer claims Release 1 conformance, public reachability or release readiness.

## Effective Authority

The normative chain is now effective in `develop`:

1. Product Constitution v1 through #871;
2. Release 1 Product Contract through #878;
3. D1-B through D5-A, #932-A, #891 copy and the Local Library Data Contract through #934;
4. the role-based Agent control plane through #937.

Draft PR #868 is closed and conflicting. It remains historical implementation evidence only; no
future branch may rebase, reopen or merge it as the single-library implementation. Production
convergence starts from the current contracts and latest `develop`.

## Merged Lineage Since The Phase 05 Checkpoint

| PR | Exact implementation head | Merge commit | Current audit meaning |
|---|---|---|---|
| #872 | `6bcb4fbb` | `bff9d84a` | RA-05-001/002 fixed |
| #873 | `8354a38e` | `f6274a1d` | RA-05-003 fixed |
| #875 | `3f201957` | `b39a3277` | Library photo edit race fixed; Phase 06 input |
| #876 | `17de8fdf` | `06dd77be` | RA-05-005 fixed |
| #878 | `eac38a45` | `82c9aab9` | Release 1 Gate C effective |
| #879 | `4ac24724` | `466e68bd` | RA-04-005/009 fixed |
| #874 | `900744c2` | `1f597a99` | RA-05-004 fixed after refresh |
| #934 | `5b19be6d` | `bc5c0221` | follow-up decisions and Local Library Data Contract effective |
| #935 | `ca9895be` | `a5a10643` | canonical local source gate fixed |
| #936 | `7e4fc564` | `64f54b81` | exact GitHub checkout/tool/simulator binding fixed |
| #937 | `c7c6cb63` | `41a38958` | Agent control plane fixed |

The PR bodies and merge commits are the lineage evidence. Historical phase reports retain the state
that existed before these merges and are not current scheduling instructions.

## Current Risk Order

### 1. #919: immediate no-prune stop-loss

The latest live code still calls `pruneCorruptedStoreArchives` after every damaged-store isolation
and deletes all but three directories. The existing test still requires deletion of the oldest
archive. This violates effective DATA-1-R and is a deterministic irreversible-loss path.

- scope: `DataExecutor.swift` plus `ModelExecutorTests.swift`
- decision state: effective contract; no further PO product decision required
- next: open one independent T4 implementation slice, remove count pruning, and prove four-plus
  incident directories and sentinel bytes remain unchanged
- boundary: this closes only automatic deletion; restart persistence and incident management remain
  in #889

### 2. #880: restore zero-mutation safety

The live coordinator still treats failure of the complete pre-restore auto-backup as best effort and
can continue into database/image restore. #879, D3-B and the Local Library Data Contract are now
effective, so the issue's former DoR blockers are satisfied. Reproduce the current failure on the
new base before editing, then make recovery-snapshot failure abort before active mutation.

### 3. #889: persistent incident lifecycle

After #919 removes the P0 deletion path, the remaining parent is still a release-blocking S1:
recovery decisions are process-local, relaunch can expose a rebuilt empty library, and retained
incidents lack visible export/delete management. Implement against the Local Library Data Contract;
do not preserve temporary Profile runtimes as target architecture.

### 4. Backup v3 exact wire

D1-B selected the SQLite container family, but `backup-wire-format.md` intentionally does not yet
freeze `application_id`, `user_version`, exact DDL/object allowlist, hostile-file opening sequence,
incremental BLOB contract, limits, compatibility rules or golden/adversarial fixtures. Shape these as
one separately PO-approved irreversible wire contract before writer/reader implementation.

## Remaining Audit Inputs

- Phase 05: run the six candidate oracles in `phases/05-p1-triage-results.md`; the original five P1
  rows are fixed and must not be re-opened without a failing post-merge oracle.
- Phase 09: #935 and #936 close the canonical source/destination truthfulness slice; #922 still owns
  durable failed-attempt evidence and bounded retention, while #933 owns validation cadence and test
  stratification.
- Phase 06-08 and 10-12 remain pending. Existing conformance issues are implementation/shaping inputs,
  not proof that every severity label is current; each code slice must reopen live path:line and run
  the named oracle.
- GitHub decision/source issues may remain open after their decision becomes effective. Their issue
  state does not override the merged owning contract.

## Recovery Command

Start from live state, not this hash:

```bash
git fetch origin develop
git worktree add -b codex/<slice> /private/tmp/snapdrill-<slice> origin/develop
```

Then run T0, verify open PR/write WIP and reopen every cited path. The next write slice is #919;
merges remain serial and require PO authorization for the exact head.
