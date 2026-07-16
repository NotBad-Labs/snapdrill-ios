# Definition of Ready

> Lightweight start gate for SnapDrill tasks. This is not a Scrum ceremony.
> It exists to stop agents from starting work when the target, authority, or
> verification path is still ambiguous.

Use this gate before implementation work starts. If a task fails any required
check, shape the task further or ask PO instead of silently choosing.

## Ready Checklist

1. **Outcome**: the task states the user-visible or repo-visible outcome, not
   only a file list.
2. **Scope**: in-scope and out-of-scope work are explicit. Adjacent cleanup is
   not implied.
3. **Authority**: product intent links through the three-layer SSOT: Product
   Constitution (`vision.md`) -> current Release Product Contract -> owning
   feature spec. Product policy or a typed decision may refine its assigned
   question but cannot bypass those layers.
4. **Decision state**: every upstream product decision is identified as
   exploration, shaped candidate, ratified, effective, or superseded. Only an
   effective authority on `develop` may replace the current cross-lane baseline.
5. **Contract first**: cross-feature, data/wire, public, business, or platform
   changes name the upstream product or release contract required before merge.
6. **Acceptance criteria**: the task names observable pass/fail checks. At
   least one check must be a command, fixture, test, screenshot/evidence path,
   or direct PO-verifiable behavior.
7. **Validation level**: the task declares a T0-T4 level from
   `parallel-lanes.md` and lists the commands or manual evidence required.
8. **Red lines**: files, product meanings, legal/fact-gated content, release
   resources, or user data that must not be changed are named.
9. **Decision gates**: unresolved PO, legal, fact, App Store, or irreversible
   data decisions are called out before coding.

## Stop And Ask

Stop before implementation when any of these remain unresolved. A precise
current PO task or owning effective authority satisfies the gate; do not ask
again merely because the implementation is user-visible.

- The change would alter product positioning, default behavior, pricing,
  public copy, legal posture, or release authorization.
- More than one reasonable UX or data-model choice would change information
  architecture, the default path, feature semantics, or a user-perceptible
  outcome. Visual tokens already bounded by the owning spec/design system are
  an owning UI-lane implementation choice.
- The task needs a destructive migration, data deletion, signing/account change,
  or App Store Connect action.
- The task depends on an external review finding without path/line evidence or
  a reproducible command.
- The task would transmit private repository content, user data, secrets,
  signing material, or other non-public evidence to an external model/service
  without explicit PO approval for the vendor and minimal payload.
- A PO ruling is ratified but its owning authority has not yet been merged, and
  the task would treat that ruling as the new cross-lane baseline.

## PO Ruling Routing

PO rulings live in their authority document, not in this file. Examples:

- durable product / data / commercial / platform rulings -> Product
  Constitution at `docs/explanations/vision.md` and its direct policy owner
- current-release scope / non-goal / acceptance rulings -> the current dated
  Release Product Contract
- positioning rulings -> `docs/explanations/positioning-and-audience.md`
- architecture rulings -> typed `docs/decisions/ADR-*.md`
- feature behavior rulings -> the owning `docs/features/*/feat-*.md`

The generated `docs/reference/intent-traceability.md` is the index for existing
intent links. If a new PO ruling has no clear authority document, record the
temporary routing in the task brief. If a second unrouted ruling of the same
kind appears, create a dedicated tracked decision file instead of accumulating
hidden chat memory.

Decision states follow:

```text
exploration -> shaped candidate -> ratified -> effective -> superseded
```

PO ratification approves product meaning and scope; it does not authorize a
merge. A ruling becomes effective only when its owning authority is merged into
`develop`. Existing tracked norms remain effective until explicitly
superseded. Draft implementation may precede a contract for comparison, but a
cross-feature, data/wire, public, business, or platform change may not merge
before its upstream product or release contract.

## Minimal Task Brief

```text
Outcome:
Scope:
Out of scope / red lines:
Authority:
Decision state and required upstream contract:
Acceptance criteria:
Validation level and commands:
PO/legal/fact gates:
```
