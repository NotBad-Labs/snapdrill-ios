# Definition of Ready

> Lightweight start gate for SnapDrill tasks. This is not a Scrum ceremony.
> It exists to stop agents from starting work when the target, authority, or
> verification path is still ambiguous.

Use this gate before implementation work starts. If a task fails any required
check, shape the task further or ask PO instead of silently choosing.

## Current Admission

Every task entering the bet, active write, or frozen merge queue needs one
self-contained **current admission brief**. This is an execution gate, not a
fourth product SSOT: it must point to effective authority rather than restating
or replacing Product Constitution, Release Product Contract, or feature specs.

An issue, PR, audit, report, chat handoff, label, historical PO comment or
authorization, and an old CI result are evidence by default. Age, number,
open / closed state, Draft / Ready state, label, author, prior authorization,
or historical CI success cannot by themselves grant current execution
authority. A previously known defect or accepted idea may proceed only after
its assumptions are rebuilt against live facts.

The current admission brief records:

1. **Exact live base**: target branch and full commit SHA used for admission.
2. **Effective SSOT anchors**: product and owning technical / operations
   authority that bounds the task.
3. **Current evidence**: live path:line, reproducible command, fixture, test,
   device evidence, or other presently verified fact.
4. **Inherited assumptions**: historical assumptions explicitly accepted and
   rejected after current verification.
5. **Ownership and scope**: owner, owned files / boundaries, outcome, in-scope
   work, and exclusions / red lines.
6. **Completion contract**: acceptance criteria, T0-T4 validation level, and
   planned evidence.
7. **Execution routing**: delegation class, dependencies, merge order, and
   unresolved PO / legal / fact gates.

An existing current task remains admissible only when its present brief already
contains equivalent fields and the latest T0 confirms they still hold against
the live target. There is no bulk grandfathering based on an issue or PR already
being open, accepted, labeled, green, Draft, or Ready. The exact admission base
remains recorded; if the target advances, T0 records the newer target head and
whether the existing head, assumptions, merge order, and validation remain
sufficient. A changed authority, root cause, scope, or inherited assumption must
be reflected before queue entry or continued execution.

## Ready Checklist

1. **Current admission**: the task has a self-contained current admission brief
   with exact live base, effective anchors, current evidence, inherited
   assumptions, ownership, dependencies, and merge order.
2. **Outcome**: the task states the user-visible or repo-visible outcome, not
   only a file list.
3. **Scope**: in-scope and out-of-scope work are explicit. Adjacent cleanup is
   not implied.
4. **Authority**: product intent links through the three-layer SSOT: Product
   Constitution (`vision.md`) -> current Release Product Contract -> owning
   feature spec. Product policy or a typed decision may refine its assigned
   question but cannot bypass those layers.
5. **Decision state**: every upstream product decision is identified as
   exploration, shaped candidate, ratified, effective, or superseded. Only an
   effective authority on `develop` may replace the current cross-lane baseline.
6. **Contract first**: cross-feature, data/wire, public, business, or platform
   changes name the upstream product or release contract required before merge.
7. **Acceptance criteria**: the task names observable pass/fail checks. At
   least one check must be a command, fixture, test, screenshot/evidence path,
   or direct PO-verifiable behavior.
8. **Validation level**: the task declares a T0-T4 level from
   `parallel-lanes.md` and lists the commands or manual evidence required.
9. **Red lines**: files, product meanings, legal/fact-gated content, release
   resources, or user data that must not be changed are named.
10. **Decision gates**: unresolved PO, legal, fact, App Store, or irreversible
   data decisions are called out before coding.
11. **Delegation class**: the task is classified Green, Yellow, or Red using
    the P-A matrix below. Uncertain classification fails closed to Yellow.

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

## P-A Standing Delegation

PO 于 2026-07-20 批准 P-A：现有 Release Product Contract 承担该次发布的唯一 PRD，不新增
平行 `PRD.md`；Gate P 期间暂停新的 non-blocker feature 投入；当前已接受 bet 内的 Green 任务
可由 owning agent 自主推进至 Draft PR。该委托减少重复操作授权，不转移产品、合并或发布
决策权。

常设委托只决定“已经选中的工作如何继续”，不允许 agent 自行改变当前 bet、产品优先级或
Release scope。

| Class | 判定 | Agent 权限 | 必须停下 |
|---|---|---|---|
| **Green** | 已通过 Current Admission；effective SSOT、当前 bet、outcome、唯一语义、scope、red lines、acceptance 和 T0-T4 均明确；改动可由 Git 回滚；无 Yellow / Red gate | 自主审计、shaping、独立 worktree / branch、实现、验证、commit、push、创建或更新 Draft PR、观察 / rerun CI | 不得转 Ready、merge、删未合并分支、上传或发布 |
| **Yellow** | 存在两个以上会改变用户结果的合理方案；规范、术语、验收或 owner 含糊；需要新的公开事实、外部 reviewer 或跨 lane 契约 | 只读核实、形成选项 / 推荐 / 影响和 bounded candidate；可以在任务明确允许时做隔离原型 | 产品语义、用户结果、Release scope 或外部 reviewer 只能请 PO 裁决；只有不改变产品结果的纯技术、事实或操作契约歧义可交 owning authority；不能静默选择或降级成 Green |
| **Red** | 产品定位、Release 纳入 / 排除、默认行为、商业化、法律 / 公开承诺、不可逆数据 / wire、账号签名、外部可用人群、go / no-go、上传或发布 | 收集事实、提出可逆方案和风险；不得代替 owner 决策 | 必须由 PO；法律充分性或平台事实还需对应专业 / 一手来源 |

用户可见改动不自动等于 Yellow：若 owning effective spec 已精确固定行为或字符串，且实现不存在
第二种产品语义，它可以是 Green；布局、状态或措辞存在合理取舍时仍为 Yellow。

安全 / 数据 blocker 也不自动放宽边界。Green 修复必须保持现有产品和 wire 语义；若修复需要
改变不可逆契约，则升级为 Red。

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

P-A 只授权 Green 执行至 Draft PR。产品裁决仍走五态生命周期；merge 仍是使候选进入
`develop` 的独立 PO 动作。

## Minimal Task Brief

```text
Current admission brief / URL:
Exact live base:
Effective SSOT anchors:
Current live / reproducible evidence:
Inherited assumptions accepted:
Inherited assumptions rejected:
Outcome:
Owner / delegation class:
Scope / owned files:
Out of scope / red lines:
Authority:
Decision state and required upstream contract:
Acceptance criteria:
Validation level and commands:
Dependencies / merge order:
PO/legal/fact gates:
```
