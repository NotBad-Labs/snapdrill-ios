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
3. **Authority**: product intent links to its current authority document:
   `vision.md`, `positioning-and-audience.md`, an ADR, a feature spec, or a
   PO-specified scope document.
4. **Acceptance criteria**: the task names observable pass/fail checks. At
   least one check must be a command, fixture, test, screenshot/evidence path,
   or direct PO-verifiable behavior.
5. **Validation level**: the task declares a T0-T4 level from
   `parallel-lanes.md` and lists the commands or manual evidence required.
6. **Red lines**: files, product meanings, legal/fact-gated content, release
   resources, or user data that must not be changed are named.
7. **Decision gates**: unresolved PO, legal, fact, App Store, or irreversible
   data decisions are called out before coding.

## Stop And Ask

Stop before implementation when any of these are true:

- The change would alter product positioning, default behavior, pricing,
  public copy, legal posture, or release authorization.
- More than one reasonable UX or data-model choice would produce a different
  product experience.
- The task needs a destructive migration, data deletion, signing/account change,
  or App Store Connect action.
- The task depends on an external review finding without path/line evidence or
  a reproducible command.

## PO Ruling Routing

PO rulings live in their authority document, not in this file. Examples:

- positioning rulings -> `docs/explanations/positioning-and-audience.md`
- product vision rulings -> `docs/explanations/vision.md`
- architecture / release-region rulings -> `docs/decisions/ADR-*.md`
- feature behavior rulings -> the owning `docs/features/*/feat-*.md`

The generated `docs/reference/intent-traceability.md` is the index for existing
intent links. If a new PO ruling has no clear authority document, record the
temporary routing in the task brief. If a second unrouted ruling of the same
kind appears, create a dedicated tracked decision file instead of accumulating
hidden chat memory.

## Minimal Task Brief

```text
Outcome:
Scope:
Out of scope / red lines:
Authority:
Acceptance criteria:
Validation level and commands:
PO/legal/fact gates:
```
