# Phase 02d Results: Product Constitution and Release Contract

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/explanations/vision.md` 与 `docs/reference/release-1-contract.md`。

## Outcome

SnapDrill 已有可用的规范骨架，但尚未形成一个足以让新团队脱离聊天记录实施的稳定产品契约。`vision.md` 已保存使命、定位、价值链和原则；feature frontmatter、生成状态与 intent index 也能表达功能现状和显式引用。缺口集中在四个结构问题：PO 对话何时从探索变成规范没有生效规则；当前发布没有有界产品契约；下游 roadmap / feature / ADR 仍可创造跨功能产品不变量；当前 bet 与长期产品状态没有彻底分开。

因此，本阶段不重写 PRD，也不修改任何产品裁决。先把规范所有权、变更状态机和待 PO 决策固定下来。Draft PR #868 继续作为单资料库候选实现与验证证据，不在本阶段请求合并。

## T0 And Coverage

- reference baseline: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- product base: `origin/develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- read-only checkout: `/Users/yiming/Developer/snapdrill-audit-fixed-56e9d27e`
- audit worktree: `/private/tmp/snapdrill-repository-audit-phase04`
- audit branch start: `codex/repository-audit-phase04@955078ea`
- main checkout remained at `d62fead8` with its pre-existing untracked `agent-reports/`; untouched
- open write WIP: Draft PR #867 (audit) + Draft PR #868 (single library), exactly 2
- #867 / #868 Build & Test: pass; UI Tests job skipped by PR workflow as configured

Primary coverage was the normative chain in `AGENTS.md`, `docs/explanations`, `scope-and-roadmap.md`, generated feature/intent indexes, PO decision log, ADRs and all feature frontmatter. Issue #490 and the current open issue/PR set were checked only to reject the possibility that a live GitHub bet already supplied the missing current-release contract.

## Proposed Authority Matrix

One physical mega-document is not the goal. The target is one authority graph in which each question has one owner.

| Normative question | Single owner | Ratifier / maintenance boundary |
|---|---|---|
| mission, primary user problem, value promise, durable non-goals and principle order | `docs/explanations/vision.md` | PO ratifies; agents may clarify without changing meaning |
| audience, positioning and UI/marketing guardrails | `docs/explanations/positioning-and-audience.md` | PO ratifies; legal facts require qualified review |
| cross-feature design rules | `docs/explanations/design-principles.md` | design DRI maintains; workflow/product changes return to PO |
| free/Pro boundary, monetization posture and pricing policy | `docs/explanations/business-model.md` | PO ratifies; candidate prices and hypotheses stay explicitly non-normative |
| current release Must outcomes, non-goals and outcome acceptance | a thin dated Release Product Contract | PO ratifies; release/QA DRIs attach evidence |
| representative end-to-end journeys | `docs/explanations/user-journeys.md` | product/design DRI maintains within Vision and release contract |
| one feature's observable behavior | owning feature spec | feature DRI decides reversible detail; cross-feature/default changes return upstream |
| implementation state | feature frontmatter -> generated `feature-status.md` | empirical owner only; never defines release scope or product intent |
| hypotheses and invalidation signals | `assumptions.md` / business H4-H8 | product/research DRI maintains; hypotheses are not promises |
| technical choices and their consequences | typed decision record / `architecture.md` | engineering DRI; PO only when product, risk, cost or external commitments change |
| historical decision index | `po-decision-log.md` | index and temporary fallback only; substantive authority remains at the owning document |

External law, Apple platform behavior and live technical facts are constraints, not preferences. Agents must establish them with primary evidence; PO chooses the product response but cannot redefine the external fact.

## Verified Findings

### RA-02-013 — P2 — PO intent has no activation lifecycle

- `AGENTS.md:33-36`, `docs/README.md:6` and `vision.md:8,81-96` make the latest explicit PO intent immediately superior to all tracked norms.
- `definition-of-ready.md:42-55` explains where a ruling should be routed, and `po-decision-log.md:3-5` describes drafting and confirmation, but neither distinguishes exploration, shaped candidate, ratified decision, effective baseline and superseded history.
- Impact: two agents can legitimately follow different chat statements; an exploratory thought can start high-blast downstream work before impact analysis; a fresh clone cannot reconstruct which untracked statement is binding.
- Smallest corrective action: add one activation clause to the root arbitration rule and DoR, then make the decision log record state/effective authority rather than serve as hidden product substance.

### RA-02-014 — P2 — the current release has no bounded product contract

- `scope-and-roadmap.md:14-79` defines product-wide MoSCoW and a broad `v2.0` panorama, not one next release.
- `feature-status.md:1-22` is an implementation inventory. It does not state release inclusion.
- `business-model.md:43-46,97-103` says the current TestFlight/first-release baseline is pure free; `release-and-ci.md:215-346` is a long operational regression checklist; `po-decision-log.md:13,28-41` records changing work order and quality gates.
- Live issue #490 owns App Store submission materials and still requests iPad screenshots; it does not define the product Must/non-goal/outcome set. The other open issues are deferred Pro work; the only open PRs are #867/#868.
- Impact: Review, Dashboard, SmartPaper, Profile/single-library, Pro placeholders and public listing can each be inferred in or out from a different source. “Is Release 1 complete?” has no single falsifiable answer.
- Smallest corrective action: after PO decisions, add one thin Release 1 Product Contract with target artifact, Must outcomes, explicit non-goals and outcome-level acceptance. Link feature specs and release checks; do not duplicate their implementation detail.

### RA-02-015 — P2 — downstream documents can create product-level invariants

- Vision's durable value chain is capture -> manage -> export/print (`vision.md:29-40`) and does not name Multi-Profile.
- The downstream roadmap upgrades Multi-Profile to Must / “缺失 = 产品不可用” (`scope-and-roadmap.md:16-29`); business model, design success signals and feature specs then treat it as foundational (`business-model.md:35-43,53-69`; `design-principles.md:52-65`; `feat-profile.md:23-38`).
- The 2026-07-11 replacement Draft correctly removes that complexity, but its candidate diff touches 126 files (1,695 insertions / 4,417 deletions) while the durable Vision remains unchanged. It moves the opposite rule, single library, into a feature spec and roadmap.
- Impact: either profile choice can become a cross-layer architectural law without first being classified as a durable product invariant or a release-specific simplification.
- Smallest corrective action: any rule that changes multiple features, data/wire boundaries, public commitments or more than one lane must first be ratified in Vision/product policy or the current Release Contract. A feature spec may refine but not originate that rule.

### RA-02-016 — P3 — decision records do not distinguish product and architecture authority

- `AGENTS.md:33` and `vision.md:83-90` place ADRs beside product policy and business model in the normative chain.
- ADR-001 is a pricing/tiering product decision; ADR-002 is a privacy/UX decision; ADR-003 mixes product region, distribution, build and historical legal framing; ADR-005 mixes privacy policy and technical analytics architecture.
- Feature `intent_refs` can consequently cite an ADR as product authority even when its subject is weakly related; `intent-traceability.md:1-5` explicitly cannot verify semantic correctness.
- Impact: architecture rationale can silently acquire product authority, while product choices can be mistaken for engineering-owned reversible detail.
- Smallest corrective action: add a typed field such as `decision_scope: product|architecture|operations` plus `current_authority` / status. No bulk rename or decision-history rewrite is required.

### RA-02-017 — P2 — current bet guidance conflicts on SmartPaper

- `shape-up.md:55-60` names Review/SM-2 enhancement, SmartPaper and advanced analytics as parked/frozen and incorrectly points all three at H9.
- `po-decision-log.md:13-16` records active SmartPaper free-tier decisions, while `feature-status.md:18` and `feat-smartpaper.md` mark the mixed free/Pro feature in progress; SmartPaper's commercial hypothesis is H8, not H9.
- Impact: a lane may correctly refuse SmartPaper work as parked while another correctly follows the approved free path; release and investment scope diverge even when generated status is fresh.
- Smallest corrective action: the Release Contract/current accepted bet owns investment scope. Remove named parked examples once the PO has classified Review, Dashboard and SmartPaper for Release 1.

Existing RA-02-002 (iPhone/iPad scope), RA-02-005 (orphaned success signals/free-tier constraint), RA-02-009 (off-repo decision evidence) and RA-02-006 (stale lane DRI) remain active and are inputs to the same stabilization pass; they are not duplicated here.

## Proposed Decision Lifecycle

```text
exploration -> shaped candidate -> ratified -> effective -> superseded
```

1. **Exploration**: chat, analogy, preference or question. It has no downstream normative force.
2. **Shaped candidate**: an agent writes alternatives, impact, affected authorities, reversibility and verification. A Draft branch/PR may be authorized as an experiment, but it is not the product baseline.
3. **Ratified**: PO explicitly approves the shaped decision and its scope. Legal/fact gates must already be identified.
4. **Effective**: the owning authority document is merged into `develop`, either in a small contract PR first or atomically with the bounded implementation. Only this state may supersede the tracked baseline for other lanes.
5. **Superseded**: old decisions remain as history with a pointer to the current authority; they cannot drive new work.

Recommended default: pre-2026-07-10 tracked norms remain effective until explicitly superseded. “Everything may be challenged” means no old decision is sacred; it must not create a normative vacuum in which every agent invents a replacement.

For urgent security/data-safety fixes, PO may authorize immediate bounded implementation, but merge still requires the relevant product/data contract and the existing separate merge authorization.

## Gate A PO Ruling — 2026-07-11

The PO ratified all three Gate A governance rules as one package:

1. product intent follows `exploration -> shaped candidate -> ratified -> effective -> superseded`;
2. current tracked norms remain effective until explicitly superseded;
3. cross-feature, data-wire, public, business or platform changes require an
   upstream product/release contract before merge, although a Draft experiment
   may precede that contract.

This ruling is **ratified, not yet effective**. The activation clause still has
to land in its owning root/DoR authority on `develop`. The ruling does not
authorize merging #867, #868 or a future contract PR. The earlier PO instruction
to retire Multi-Profile with no migration/old-backup compatibility is likewise a
ratified product/data candidate; it becomes effective only when the owning
Product Constitution or Release Contract is merged under Gate A.

## Decision Rights

| Decision class | PO required | Agent authority within ratified constraints |
|---|---|---|
| primary user/problem, value promise, non-goals, feature inclusion, business model, platform/region, privacy posture, destructive compatibility and release go/no-go | yes | research alternatives, expose consequences, challenge with evidence |
| cross-feature workflow, default behavior, terminology, migration policy and visible Pro/free boundary | PO ratifies | product/design/engineering DRI shapes and implements |
| architecture, package/API shape, algorithms, tests, CI, scripts, refactoring and performance | only if product/risk/cost/external contract changes | engineering DRI decides and verifies |
| reversible layout, spacing, component choice and microcopy within approved voice/AX rules | only when workflow/brand meaning changes | UI DRI decides; PO may accept/reject the delivered experience |
| law, Apple rules, market facts and live implementation behavior | not decidable by preference | agent gathers primary evidence; qualified expert decides where required |

## P0 Decision Packet

### Gate A — governance before further high-blast work

**PO status (2026-07-11): all three items ratified; authority integration pending.**

1. Ratified: the five-state decision lifecycle above.
2. Ratified: current tracked norms remain effective until explicitly superseded.
3. Ratified: cross-feature/data-wire/public/business/platform changes require a
   contract before merge; Draft exploration may precede it.

### Gate B — Product Constitution v1

1. Name the primary first user and first job-to-be-done; “general audience” may remain the public/legal posture but is not by itself a product wedge.
2. Confirm or revise the durable promise and capture -> manage -> export/print value chain.
3. Confirm durable non-goals: content platform, solving/search-answer service, social/gamification, account requirement and backend content collection.
4. Classify one local library as a durable product boundary or only a Release 1 simplification.
5. Classify local-first/no-account, future CloudKit and free/Pro strategy as invariant, roadmap or hypothesis.
6. Confirm current platform/region policy: iPhone-only US-company global build; iPad and China are explicit re-entry decisions.

### Gate C — Release 1 Product Contract

1. Define the target artifact: internal TestFlight, public App Store release, or no-ship rebaseline milestone.
2. Select Must outcomes for capture, manage, export/print, backup/recovery and accessibility; avoid equating every implemented input or setting with Must.
3. Classify Dashboard, Review and SmartPaper as ship Must, optional shipped capability, hidden/parked, or removed from Release 1.
4. Decide whether unavailable Pro/StoreKit/CloudKit/Word surfaces are hidden or shown as future placeholders.
5. Restore, relocate or retire the orphaned success signals and free-tier non-degradation rule (RA-02-005).
6. State launch language/market boundary and the outcome evidence required for go/no-go.

Gate A is now ratified. Its authority clause must become effective before a later
product choice supersedes `develop`. Gates B/C remain the product workshop;
agents provide options and impact, not answers on behalf of the PO.

## Agent Cross-Check

- Grok 4.5 independently converged on the activation and release-contract gaps, plus downstream invariant leakage. Its P0 severity was downgraded to P2 because these are governance defects, not a live user/runtime emergency.
- Antigravity Gemini 3.5 Flash (High) converged on activation and release bounding. Its claims that future subscription cancellation details currently block Settings/Backup and that current journeys require iPad/Pencil were rejected: StoreKit is not shipping and the cited journey evidence does not establish that requirement.
- Claude Fable 5 converged on activation, release bounding, orphaned Vision constraints and off-repo decision evidence. Its first broad search incidentally returned two old audit lines, so that run was discarded for blind-independence purposes. A fresh whitelist-only rerun read 12 named primary files, confirmed all three structural checks and touched no audit result or repository file.
- C1 reopened every retained citation on the fixed checkout and independently checked current GitHub issues/PRs. External prose did not enter the ledger verbatim.

## Rejected Claims

- A single giant PRD would stabilize the product: rejected. It would duplicate feature specs and become another stale truth source.
- Every pre-2026-07-10 decision should become non-binding immediately: rejected as the default because it creates a normative vacuum. Explicit supersession is safer and remains fully reversible.
- General-audience positioning itself is inconsistent with specialist exam/document workflows: not proven. Public audience posture and an initial product wedge can coexist; the missing item is PO choice of the wedge.
- Candidate Pro pricing, cancellation and iCloud behavior block the current pure-free release: rejected. They block only their future lane unless Release 1 exposes a misleading promise.
- iPad aspiration versus iPhone-only shipping is automatically a contradiction: rejected. It is a durable aspiration/current-release distinction, but the current owner and re-entry gate still need PO confirmation under RA-02-002.
- Draft PR #868 should be discarded because the upstream contract is incomplete: rejected. It is valuable implementation and safety evidence; keeping it Draft preserves comparison and rollback while governance is ratified.

## Recovery

- neutral brief: `phases/02d-product-constitution-brief.md`
- results: this file
- ledger: `../findings.md`
- current checkpoint: `../checkpoints/phase-04-in-progress.md`
- next: obtain separate PO merge authorization for #867, then land Gate A in a
  small authority/contract branch before any #868 merge decision
