# Phase 02f Review Brief: Product Intent Impact Map

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/product/vision.md` 与 `docs/product/release-1-prd.md`。

## Inputs

- candidate impact map is included verbatim in the prompt
- primary checkout: `/Users/yiming/Developer/snapdrill-audit-fixed-56e9d27e`
- base: `56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`

Read only primary files needed to test a candidate claim. Do not read prior audit
results, findings, checkpoints, another reviewer, private memory, network content
or Draft PR diffs. Do not write files.

## Question

If the PO later chooses any Gate B/C option, does this map identify the real
upstream owner, direct downstream consumers, required serialization and evidence
without forcing unrelated churn? Could a new team follow it without missing a
wire/data/public contract or treating a broad grep match as mandatory work?

## Checks

1. Find missing normative, feature, runtime, test, localization, privacy, signing,
   public or operational consumers for D1-D8.
2. Reject consumers included only because a keyword matched but whose behavior
   is unaffected by the decision.
3. Check the contract -> spec -> implementation -> evidence order and identify
   any circular dependency.
4. Check the proposed WIP/merge sequence against write WIP <= 2, audit/fix
   separation and separate PO merge authority.
5. Challenge S/M/L/XL classification only with a concrete omitted/extra surface;
   do not estimate calendar time.
6. Verify each validation level can prove the claimed outcome; build success or
   a checklist is not enough.
7. Identify shared files that make proposed parallel lanes unsafe.
8. Do not decide Gate A/B/C or recommend merging/closing a PR.

## Output

Return at most eight corrections labeled:

- `MISSING_CONSUMER`
- `FALSE_DEPENDENCY`
- `WRONG_ORDER`
- `WRONG_BUDGET`
- `WIP_VIOLATION`
- `VALIDATION_GAP`

Each correction needs `path:line` primary evidence where factual, concrete impact
and the smallest map edit. Include rejected concerns and unverified areas. `No
corrections` is valid.
