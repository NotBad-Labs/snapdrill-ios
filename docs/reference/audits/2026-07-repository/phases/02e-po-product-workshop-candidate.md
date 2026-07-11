# Phase 02e Candidate: PO Product Constitution and Release 1 Workshop

> **NON-NORMATIVE SHAPING INPUT** — 本文件只列证据、选项、推荐与影响。
> 它不是 Product Constitution、Release Contract、roadmap 或 PO 决策。
> 任何选项只有经过 02d Gate A 生命周期、PO 明确批准并合入权威文档后才生效。
> **Recommended 不等于默认选中**；工作坊开始时所有产品选项均为空，推荐只表示当前判断及其置信度。

## Purpose

把“产品应该是什么”从散落的聊天、功能现状和历史 ADR 中抽离出来，让 PO 用有限选择稳定 Product Constitution v1 与 Release 1。目标不是保留现有实现，也不是为了整洁删除功能；每个推荐都必须同时说明用户价值、当前证据、可逆性和下游成本。

## Current Evidence Matrix

| Question | Current normative claim | Current empirical state | What remains undecided |
|---|---|---|---|
| public posture | general-audience adult productivity tool; exam/question/training workflows may remain sharp | UI/L10n 已大体转向“资料 / 资料库”，旧 ASO/部分 docs 仍 education-first | public posture can remain broad, but the first product wedge is unnamed |
| core value | capture -> manage -> export/print; Review is optional | app has five equal tabs: Dashboard, Library, Capture, Review, Settings | whether optional Review/Dashboard deserve primary navigation and Release 1 scope |
| capture | lowest friction; image is truth, OCR is assistive | camera, Photos, document scan, PDF, manual, clipboard/share paths exist | which outcomes are Must versus merely implemented channels |
| management | searchable/editable personal library | search, filtering, taxonomy, edit, batch actions and undo exist | whether dynamic taxonomy complexity is core or optional |
| output | export/print is a first-class endpoint | PDF/print/share, JSON/CSV and backup are present | which formats are user-value Must versus data-portability support |
| data | local-first, no account, user owns data | SwiftData/files local; no CloudKit/Firebase; backup/restore exists | local-first forever versus optional future Apple-private sync |
| library identity | `develop@56e9d27e` 仍把 Multi-Profile 视为 Must；PO 已明确裁决退休，该裁决为 ratified candidate，尚未按 Gate A 成为 effective baseline | Draft PR #868 replaces it across 126 files; not merged (count reproduced in `02d-product-constitution-results.md`) | route the ratified ruling into its owning authority, then separate durable product behavior from implementation strategy |
| business | free core; future Pro may add sync/intelligence/output | StoreKit/CloudKit/Word unavailable; SmartPaper free quota still promotes future Pro | hide unavailable Pro, show placeholders, or finish monetization before ship |
| platform/region | US-company global production; current target iPhone-only | `com.snapdrill.global`, iPhone family, English + Simplified Chinese resources | Release 1 languages; iPad/China re-entry policy |
| quality/success | no crash/data loss, privacy/AX, low capture friction | strong local gates; no external users and no backend event stream | outcome acceptance and post-TestFlight learning signals |

## Gate A — Governance

**PO status (2026-07-11): items 1-3 below are ratified as a package but remain
non-effective until their owning authority is merged. Item 0 is a separately
ratified product/data candidate and must land through the same lifecycle. No
merge authorization is implied.**

Ratified package (not effective until the owning authority is merged):

0. Separately ratified product/data candidate: retire Multi-Profile with no data migration/old-backup compatibility. It remains non-effective despite #868 implementation evidence.
1. `exploration -> shaped candidate -> ratified -> effective -> superseded`.
2. Current tracked norms remain effective until explicitly superseded.
3. Cross-feature, data-wire, public, business or platform changes require an upstream contract before merge; Draft exploration may happen earlier.

Alternative: chat becomes binding immediately. Rejected by the audit because a fresh clone cannot reconstruct it and parallel lanes can diverge without violating any tracked rule.

## Gate B — Product Constitution Options

### B1. First workflow wedge and job-to-be-done

| Option | Definition | Consequence |
|---|---|---|
| **B1-A (recommended shaping hypothesis, medium confidence)** | Adults handling structured paper/PDF material that needs capture, organization, later retrieval and print; exam, certification, training and adult-managed family material are examples | Gives the workflow a sharp shape without claiming one unproven demographic; current structured capture/print strengths remain relevant |
| B1-B | Adults preparing for exams, certifications or structured training | Sharpest historical fit, but no external demand evidence yet; may overfit existing answer/SM-2 code |
| B1-C | Any adult organizing any personal paper or document | Broad addressable use, but competes directly with Notes/Files/scanner apps and gives weak defaults/ASO direction |
| B1-D | Adults organizing family study material | Valid adult-owned workflow, but should not revive multi-child accounts/Profile architecture or child-directed marketing |

Recommendation rationale: “general audience” is an audience/compliance posture, not a useful first workflow. B1-A is a TestFlight learning hypothesis, not a proven market segment or permanent constitutional demographic. External acquisition and willingness-to-pay evidence: none yet. It is cheap to revise at the metadata/onboarding/example layer if the durable value promise remains content-neutral.

### B2. Durable value promise

| Option | Promise |
|---|---|
| **B2-A (recommended)** | Turn paper, photos and PDFs into a searchable, organized and printable personal material library with minimal friction |
| B2-B | Scan, archive and organize any question or document | Current wording; durable but broad and less outcome-oriented |
| B2-C | Build a personal question bank and review system | Strongly education-first and makes Review core, contradicting current positioning |

### B3. Core value chain

| Option | Chain | Treatment of Review / SmartPaper |
|---|---|---|
| **B3-A (recommended)** | capture -> organize/retrieve -> export/print | optional reuse tools; they must not occupy or complicate the main path |
| B3-B | capture -> organize -> review -> improve | Review becomes core and needs equal acceptance/investment |
| B3-C | scan -> file/archive | simpler scanner product; discards differentiated print/structured workflow |

### B4. Data and identity posture

| Option | Definition | Consequence |
|---|---|---|
| **B4-A (recommended)** | local-first, no SnapDrill account, one library; manual portable backup is permanent; optional future Apple-private sync remains a separate hypothesis | Preserves privacy/differentiation without promising CloudKit or Pro architecture now |
| B4-B | strictly local-only forever | Simplest privacy posture; permanently gives up multi-device value |
| B4-C | sync-first with account/cloud as eventual core | Changes privacy, business, architecture and release positioning; requires new product evidence |

### B5. Single-library product behavior

| Option | Definition | Consequence |
|---|---|---|
| **B5-A (recommended shaping hypothesis, medium confidence)** | users see one library; no workspace/Profile model is planned until external evidence earns a new product decision | Removes unvalidated user-facing complexity; does not claim multiple workspaces can never return |
| B5-B | users see one library in Release 1, but a future workspace/Profile model remains an explicit roadmap item | Preserves a product promise with no demand evidence and keeps downstream architecture uncertain |
| B5-C | retain visible Multi-Profile now | Retains current `develop` behavior but conflicts with the ratified, non-effective PO ruling and adds cross-cutting UI/data burden |
| B5-D | ship one visible library while hiding/disabling the existing Multi-Profile code path | Maximizes short-term technical reversibility but retains speculative state, backup and failure complexity |

The PO should decide product behavior, not whether a particular `ProfileManager` abstraction survives. After B5 is ratified, engineering owns the simplest implementation consistent with the chosen reversibility and data contract. #868's existing work is impact evidence, not product justification. Any future evidence-backed PDR may supersede B5 through Gate A.

### B6. Commercial posture

| Option | Definition | Consequence |
|---|---|---|
| **B6-A (recommended)** | Release 1 is free, no ads/IAP; future Pro/CloudKit/Word/pricing remain hypotheses; unavailable purchase surfaces are hidden | Product makes no promise it cannot fulfill and gathers core-value evidence first |
| B6-B | Release 1 free but visibly advertises coming Pro capabilities | Tests interest weakly but adds unfinished-product signals and public commitments |
| B6-C | finish StoreKit/CloudKit before Release 1 | Delays core validation and expands privacy/release scope without users |

Current Pro-surface inventory that B6 must classify: SmartPaper quota and Pro toast; Dashboard “more insights later” placeholder; App Store metadata price/IAP claim; settings/library future-feature copy; Pro-tier backlog rows. Hiding Pro is a bounded product policy but not a one-string edit.

### B7. Platform and region

| Option | Definition | Consequence |
|---|---|---|
| **B7-A (recommended)** | Release 1: iPhone-only, NotBad Labs US global build; English and Simplified Chinese product UI; iPad and China-specific release require explicit re-entry decisions | Matches live production facts and existing localization investment |
| B7-B | add iPad before Release 1 | Requires UI dogfood, screenshots, NFR and release work before core validation |
| B7-C | revive China-specific build before Release 1 | Reopens account, metadata, privacy, signing and regional maintenance scope |

## Gate C — Release 1 Options

### C1. Target artifact

| Option | Definition | Recommendation |
|---|---|---|
| **C1-A** | Internal TestFlight build for PO dogfood, followed by a separate public go/no-go | **Recommended**: creates a real release artifact without prematurely claiming market readiness |
| C1-B | Public App Store release immediately after rebaseline | Requires metadata/legal/screenshots/support and full external-user compatibility now |
| C1-C | No ship; repository rebaseline only | Produces cleaner internals but no product evidence; should be time-bounded |

### C2. Must outcomes, not implementation inventory

Recommended Release 1 Must outcomes:

1. A new user starts without registration or identity setup.
2. The user captures/imports a real item, retains the original image truth and can save even when OCR fails or is inaccurate.
3. The user can find, inspect, edit and delete/undo saved material in one library.
4. The user can turn selected material into a usable PDF and print/share/save it.
5. Cancelled capture/import/export does not create partial data; an interrupted unsaved capture can be recovered or explicitly discarded.
6. Permission denial offers a usable alternate input path instead of a dead end.
7. The user can create and restore a complete portable backup without silent overwrite/loss or traversal/extraction risk; failure leaves the prior library recoverable and visible.
8. The product clearly explains local-storage/uninstall loss and does not upload user content unexpectedly.
9. A returning user whose local store cannot open reaches an understandable recovery choice and can restore a backup or continue with an explicitly empty library without a blank/dead-end screen.
10. All Must journeys remain usable with VoiceOver and supported Dynamic Type; public privacy claims match the build.

Channels such as clipboard, Share Extension, JSON/CSV, every taxonomy field and every setting may ship, but are not automatically Must merely because they are implemented.

### C3. Dashboard

| Option | Treatment | Impact |
|---|---|---|
| C3-A (lowest-churn experiment) | keep as current home, but judge it only by navigation/orientation value; do not make statistics a core promise | Lets dogfood test whether it helps or delays capture, but risks accidental primary-product commitment |
| C3-B | Library becomes home; Dashboard is removed/demoted | Sharper core path, but requires navigation/UI rework before evidence |
| C3-C | Dashboard/analytics become core | Requires measurable insight value and ongoing investment |
| C3-D | keep Dashboard module, but default launch to Capture or Library during dogfood | Preserves evidence gathering while testing whether users intentionally seek Dashboard |

C3-A/D are valid only with the internal C1-A artifact. After the first structured TestFlight feedback packet, PO re-decides Dashboard using activation/core-utility evidence; a public C1-B release would turn the chosen home/navigation into a soft external commitment.

### C4. Review

| Option | Treatment | Impact |
|---|---|---|
| C4-A (lowest-churn experiment) | ship existing Review as an optional capability but park new investment; explicitly test whether an equal top-level tab overstates its importance | Preserves working value while collecting evidence, but equal chrome risks accidental core-product commitment |
| C4-B | demote Review from primary navigation before Release 1 | Stronger alignment with the core chain; user-flow and screenshot change |
| C4-C | remove Review from Release 1 | Maximum simplification, but deletes a substantial working feature without usage evidence |
| C4-D | keep Review module for dogfood behind a secondary Library/Dashboard entry | Separates optional-value testing from an equal primary-tab promise |

An equal primary tab in an internal dogfood build is an experiment, not a Product Constitution commitment. After the first structured feedback packet, PO re-decides Review using optional-value evidence. Keeping that IA for public Release 1 requires intentional-use evidence.

### C5. SmartPaper and unavailable Pro

| Option | Treatment | Impact |
|---|---|---|
| C5-A | keep the existing basic generator as an unlimited free secondary tool for Release 1; remove quota/Pro upsell until a purchasable tier exists | No artificial dead end, but creates a strong free-use precedent and requires ADR-001 to be explicitly suspended or superseded |
| **C5-B (recommended shaping hypothesis, medium confidence)** | hide SmartPaper for Release 1 and park it | Simplest coherent release and strongest future pricing optionality; loses dogfood evidence for differentiated print |
| C5-C | keep 3/month quota and “Pro coming soon” | Preserves pre-07-10 decision but blocks users without offering an upgrade; not recommended |
| C5-D | implement StoreKit/Pro now | Converts a release-scope question into a major commercial/privacy program |
| C5-E | expose unlimited basic SmartPaper only in the internal dogfood build, with no Pro copy; decide public treatment from evidence | Preserves dogfood learning without silently making a public free-tier promise; still requires ADR-001 status to be explicit |

Any unlimited-free option must say whether ADR-001 Hybrid is suspended or superseded. SmartPaper domain language (`题 / 试卷 / 组卷`) may remain only if the PO confirms that specialized workflow language still fits the Release 1 public posture.

For C5-A/E, PO must also choose which already-implemented selector is exposed: basic random selection only, or the SM-2 urgency-based precise selector currently parked behind the Pro entitlement. This is separate from quota and cannot be inferred from “free SmartPaper.” C5-A/E supersede or suspend the tracked 07-01 quota, deduct-on-export and non-Pro-gated-entry decisions through Gate A.

### C6. Release 1 acceptance

Recommended outcome evidence:

- one clean-install and one returning-user physical-device dogfood pass;
- deterministic automated coverage for save (including storage failure), delete/undo, export and backup/restore failure paths;
- explicit dogfood for denied permissions, failed OCR, cancelled flows, draft recovery and failed restore without prior-data loss;
- zero unresolved P0/P1 and explicit PO acceptance for remaining P2;
- zero Accessibility Audit issues on all reachable Release 1 screens;
- no truncated/blocking UI at supported Dynamic Type and the shipping iPhone viewport set;
- release archive/install/launch plus TestFlight upload/install evidence for the exact candidate, including the main app -> App Group -> Share Extension round trip;
- public copy, Privacy Manifest, entitlements and observed network/data flow agree.
- the chosen tester audience has a working privacy-policy, support and feedback path;
- unavailable Pro/coming-soon surfaces are either zero or individually accepted by PO as explicit Release 1 debt;
- the first external-user build declares the compatibility boundary after which backup wire/data changes require explicit migration or incompatibility decisions.

Build success and a feature-status row are supporting evidence, not outcome acceptance.

## Success Signals After First TestFlight

No backend event stream is required. Apple aggregate signals cannot prove task-level activation, retrieval or optional-feature intent. The product/research DRI must collect those through a scripted moderated dogfood session, TestFlight feedback form and short follow-up interview; participants must know what feedback they are providing.

1. **Activation**: can an unfamiliar adult complete first capture/save without help, and where do they stop?
2. **Core utility**: can the user later retrieve the saved item and produce a usable PDF/print?
3. **Repeat value**: does the user return to capture/manage another real item within a week?
4. **Trust**: does backup/restore work and do users understand local-data ownership/uninstall risk?
5. **Optional value**: do users intentionally use Review or SmartPaper after completing the core chain?
6. **Quality**: crash/hang/launch and accessibility evidence remain within the Release Contract threshold.

These signals test H1/H2/H3/H9. They do not promote a hypothesis to a product promise without a later PO decision. Before external dogfood, PO must accept the evidence-collection method and owner under the no-telemetry posture.

## Downstream Impact Map

| Decision | First authorities to update | Main downstream surfaces |
|---|---|---|
| B1/B2/B3 | Vision + positioning | onboarding, user journeys, metadata, navigation emphasis, feature intent refs |
| B4/B5 | Vision/product policy + `feat-profile` / local-library PDR | #868, backup wire, settings, CloudKit backlog, architecture/NFR |
| B6/C5 | business model + ADR-001 + Release Contract | SmartPaper quota/strings/tests, Settings Pro surfaces, metadata |
| B7 | production/platform policy + Release Contract | NFR, orientations/device family, release guide, screenshots, localization |
| C2-C5 | Release Contract + affected feature specs | top-level navigation, UI tests, AX route matrix, dogfood scripts, screenshots |
| C6/success | Release Contract + assumptions/success-signal owner | test plan, audit gates, TestFlight feedback packet, go/no-go |

## Recommended Decision Order

1. Gate A governance.
2. B1/B2/B3 user, promise and value chain.
3. B4/B5 data posture and single-library durability.
4. B6/B7 commercial/platform posture.
5. C1/C2 target and Must outcomes.
6. C3/C4/C5 optional feature treatment.
7. C6 acceptance and success signals.

This order prevents a feature-level decision from defining the product upstream.
