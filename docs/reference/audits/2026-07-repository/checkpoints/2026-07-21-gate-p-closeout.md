# 2026-07-21 Gate P Closeout

## Claim Boundary

This checkpoint records the Gate P control-plane candidate reconstructed from the effective
three-layer SSOT and live repository state. It does not claim that Release 1 conforms to M1-M10,
that any optional capability is included, that the Capability Manifest is frozen, or that merge,
upload, TestFlight, go/no-go, or release is authorized.

The Release 1 Product Contract remains the sole PRD for Release 1. This slice adds no `PRD.md` and
no fourth SSOT layer.

## T0 And Current Admission

- base: `origin/develop@ad6534dab06a4d4dad1aca702be47816692a672d`
- base CI: GitHub Actions run `29794397918`, including the develop-only UI job, passed
- worktree: `/private/tmp/snapdrill-gate-p-closeout`
- branch: `codex/gate-p-closeout`
- main checkout: detached with only its pre-existing untracked `agent-reports/`; untouched
- open PRs at admission: none
- Current Admission: issue #956 comment `5029782729`
- write WIP: Gate P is the control-plane lane and Capture draft S0 is a separate implementation
  lane. Their completed candidates overlap only in `feat-capture.md`: Gate P owns the
  `release_outcomes` frontmatter, while S0 updates the implementation-status paragraph. A merge-tree
  preflight is clean, but S0 must rebase after Gate P becomes effective and rerun its T4 evidence.

The admission explicitly rejected direct merge or cherry-pick of the older completeness candidate
based on `4fb6eecc`. Historical issues, PRs, reports, labels, and CI are evidence only; every claim
below was reopened against the exact live base and effective owning documents.

## Effective Inputs

1. Product Constitution: `docs/product/vision.md`
2. Release 1 Product Contract: `docs/product/release-1-prd.md`
3. Active feature specs under `docs/features/active/`
4. Release proof-plan owner: `docs/how-to/release-and-ci.md`

The live Contract was sufficient as the Release 1 PRD. The mechanical gaps were downstream:

- the ten Must outcomes had list positions but no stable M1-M10 identities in their owning Contract;
- active feature specs did not declare which Must outcomes they own or directly contribute to;
- the operational M1-M10 oracle / DRI table existed but was not machine checked;
- release-operations consumers were fabricated by a generator constant instead of being declared by
  the owning operations document.

These are traceability and validation gaps, not unresolved product semantics.

## Closure

- Label the existing ten Contract outcomes M1-M10 without changing their wording or order.
- Add `release_outcomes` to every active feature spec. An empty list is valid for an implemented but
  Release 1-optional feature; every M1-M10 identity must still have at least one active owner.
- Declare release-operations decision consumers in `release-and-ci.md` frontmatter.
- Validate exact M1-M10 identities, complete active ownership, exact oracle / DRI rows, and declared
  operations references in `generate_intent_traceability.py`.
- Generate forward/reverse decision edges and an M1-M10 Feature / proof-plan table while preserving
  an explicit warning that declarations are not executed conformance evidence.
- Update the feature template and operator documentation so future edits use the same fields.

The generator has focused negative tests for missing Must identity, invalid or non-active ownership,
unowned outcomes, missing or empty oracle / DRI rows, malformed or out-of-section oracle rows,
invalid operations consumers, decision-table drift, ratified / pending overlap, and a missing exact
§7 boundary.

## Independent Challenge

Claude Fable 5 reviewed only the live Contract, active feature specs, release operations document,
generator, and generator tests. It was not shown historical audit conclusions or implementation
branches. Its findings matched the local reconstruction: no duplicate PRD was needed, the missing
work was stable outcome identity, ownership, proof-plan validation, and removal of fabricated
operations edges. Its final challenge found no P0 / P1 and five P2 control-plane gaps; this candidate
closes them by rejecting non-active ownership, cross-checking ratified frontmatter against the body
table, adding the missing negative tests, freezing the superseded 2026-07-16 scheduling checkpoint,
and correcting the ratification cutoff. The external review is challenge evidence only; local source
and tests remain the acceptance authority.

A follow-up Fable 5 challenge compared the completed Gate P and S0 refs. It found that the original
file-disjoint admission assumption no longer described the live candidates and that oracle rows were
harvested document-wide with permissive column parsing. This revision records the one-file overlap,
requires post-Gate-P S0 rebase/revalidation, scopes oracle parsing to the exact owning section, and
rejects malformed column counts. The S0 spec closure statement remains candidate evidence only until
that rebased implementation passes its own T4 gates.

## Validation

- `swiftlint --strict`: 260 Swift files, 0 violations
- `python3 Scripts/generate_feature_status.py --check`: passed
- `python3 Scripts/generate_intent_traceability.py --check`: passed
- `python3 Scripts/test_doc_generators.py`: 35 tests passed
- `python3 Scripts/validate_document_control.py --check`: passed
- `python3 Scripts/validate_docs.py --check`: passed with the existing legal / fact owner warnings
- `python3 Scripts/validate_capture_contract.py --check`: passed
- `python3 Scripts/validate_release_configuration.py --check`: passed
- `python3 -m unittest discover -s Scripts/tests`: 116 tests passed
- `git diff --check`: passed

These checks prove the source-side control plane is internally complete and fail-closed at this
candidate. They do not execute M1-M10 product oracles. Candidate freeze, runtime evidence, signing,
distribution, and PO release decisions remain downstream gates.

## Next Current Slice

After this candidate becomes effective, the next admitted implementation is the Capture draft S0
conformance repair reconstructed against the same live base. Its old issue number is only a routing
handle; scope and acceptance come from P1-A, M6, the active Capture spec, the Local Library Data
Contract, and a fresh Current Admission. It must rebase after Gate P, preserve both sides of the
single `feat-capture.md` overlap, and produce its own T4 evidence and Draft PR.
