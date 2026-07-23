## Summary

<!-- 1-3 句话描述本次变更目的 -->

## Current Admission / T0

- Base / current evidence：`origin/develop@<full-sha>`
- Authority / outcome：
- Owner / scope / red lines：
- Acceptance / validation：
- Routing / dependencies / unresolved gates：

<!-- Yellow / Red、T4、历史恢复或跨 lane 时，按 DoR 追加适用的 expanded admission。 -->

## Candidate Binding

- PR head：
- 主 checkout dirty files：
- 独立 worktree / branch：
- WIP state：active write / frozen merge queue（冻结时说明满足条件）

<!-- 历史 issue / PR / 审计、旧授权和旧 CI 只作证据；Draft / Ready 本身不构成准入或合并授权。 -->

## Scope

<!-- 列出主要变更点 -->

-

## Out of Scope / Red Lines

-

## Related Issues

Closes #

## Validation

- Level：T0 / T1 / T2 / T3 / T4
- Commands actually run：
- Targeted test / UI / AX / device / release evidence：
- Not run / remaining risk：

## Checklist

- [ ] `git diff --check`
- [ ] 受影响 owner validator / generator `--check`
- [ ] T2+ 在 clean committed checkout 运行 `bash Scripts/ci-local.sh`，或明确说明未运行原因
- [ ] 验收标准（Given-When-Then）通过
- [ ] T3 用户界面已补 UI / AX / Dynamic Type 与截图证据
- [ ] T4 数据 / 隐私 / wire / release 改动已有对应 contract 与 fault-path evidence
- [ ] 影响规范或当前操作时已更新 owning docs；历史材料未被当成当前授权
- [ ] 未修改无关标识符、wire key、schema、签名或发布资源

Draft / Ready 状态不构成合并授权；每次 merge 仍需 PO 对已展示候选单独明确授权。PO 无需抄写
SHA，但执行工具必须通过 `expected_head_sha` 绑定该候选的精确 head；head 移动后原授权失效。
