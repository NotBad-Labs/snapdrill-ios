## Summary

<!-- 1-3 句话描述本次变更目的 -->

## T0 / Authority

- Base / head：
- 主 checkout dirty files：
- 独立 worktree / branch：
- Owning authority / current operations doc：
- Decision lifecycle：effective / candidate / not applicable

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

Draft / Ready 状态不构成合并授权；每次 merge 仍需 PO 对精确 head 单独明确授权。
