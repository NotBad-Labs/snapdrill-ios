# Phase 02d Brief: Product Constitution and Release Contract

## Fixed Base

- Product base: `origin/develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- Read-only checkout: `/Users/yiming/Developer/snapdrill-audit-fixed-56e9d27e`
- Mode: read-only review; do not edit, stage, commit, create files, invoke network
  tools or read another reviewer's output

Do not read prior audit findings, phase results, checkpoints, private memory,
agent reports, Draft PR #867/#868 diffs or another reviewer's output. The PO's
2026-07-11 concern below is the only post-base input allowed in this slice.

## PO Concern

The PO questions whether product vision and requirements are stable enough to
drive downstream design and implementation. The PO retains final authority but
does not want every exploratory chat statement to silently invalidate the whole
repository. Everything predating the 2026-07-10 rebaseline, including ADRs, may
be challenged. The desired outcome is a durable product definition that another
competent team could implement without relying on agent memory or chat history.

This concern does not itself decide any feature, business model, audience,
platform, migration or release-scope question.

## Question

Does the tracked normative system define one sufficiently stable and complete
product contract, with clear decision rights and change activation rules, or can
PO conversation, vision, policy, roadmap, feature specs and ADRs independently
send downstream work in incompatible directions?

## Primary Scope

- `AGENTS.md` §§意图与事实的裁决规则, 文档体系
- `docs/README.md`
- `docs/explanations/vision.md`
- `docs/explanations/positioning-and-audience.md`
- `docs/explanations/design-principles.md`
- `docs/explanations/business-model.md`
- `docs/explanations/assumptions.md`
- `docs/explanations/user-journeys.md`
- `docs/reference/scope-and-roadmap.md`
- `docs/reference/feature-status.md`
- `docs/reference/intent-traceability.md`
- `docs/decisions/po-decision-log.md`
- `docs/decisions/ADR-*.md`
- `docs/features/active/feat-*.md`
- `docs/features/backlog/feat-*.md`

Live code and tests may be read only to reject a false claim about current
behavior. This slice audits product normativity, not implementation quality.

## Checks

1. Inventory which file owns mission, audience, user problem, value promise,
   non-goals, release scope, business model, platform/region, privacy/data
   posture, major user journeys, feature behavior and technical choices.
2. Distinguish durable product invariants, release-specific requirements,
   hypotheses, current implementation facts and historical decisions.
3. Verify that each normative question has one owner and that downstream files
   cannot create or override upstream product intent implicitly.
4. Test whether a new PO statement has a defined lifecycle from exploration to
   impact analysis, ratification, effective baseline and supersession.
5. Identify unresolved product decisions that would materially change more than
   one feature, architecture boundary, business commitment or release artifact.
6. Check whether the current release has a bounded contract with explicit Must,
   non-goals and outcome-level acceptance criteria; do not treat a feature-status
   table or implementation inventory as a release contract.
7. Separate decisions that require PO ratification from reversible decisions an
   engineering/design DRI can make within approved constraints.
8. Treat older dates, imperfect prose and implementation drift as evidence only
   when they can change a downstream decision. Do not propose a giant PRD or a
   full document rewrite merely for neatness.

## Output

Use the repository report schema. Include:

- an authority matrix with one proposed owner per normative question;
- at most eight falsifiable findings with `path:line`, concrete downstream
  impact and smallest corrective action;
- a minimal list of P0-only decisions needed before downstream implementation
  can safely resume;
- rejected candidates and missing evidence.

`No findings` is valid. Do not decide the product on the PO's behalf, change
feature status, preserve or remove Multi-Profile, or recommend merging a Draft
PR in this slice.
