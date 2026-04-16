## Summary

<!-- 用 1-3 句话描述本次变更的目的 -->

## Changes

<!-- 列出主要变更点 -->

-

## Related Issues

<!-- 关联的 Issue，使用 Closes #N 自动关闭 -->

Closes #

## Checklist

### 代码质量

- [ ] `swiftlint --strict` 0 violations
- [ ] `xcodebuild build-for-testing` 0 errors
- [ ] 改接口签名后已 `grep -rn "TypeName(" Packages/*/Tests/` 检查测试同步
- [ ] Xcode Review 核实通过（UI 改动必须）
- [ ] 变更不违反 `docs/principles/` 中的架构约束
- [ ] 涉及数据读写时已确认 Profile 隔离（不跨 Profile 泄露数据）
- [ ] Codex 对抗性审查通过
- [ ] AI 反模式检查通过（over-generation / scope creep / pattern divergence）
- [ ] 此 PR 是否影响已文档化的约束？如是，已更新对应文件

### 功能完整性

- [ ] 验收标准（Given-When-Then）全部通过
- [ ] 异常路径已考虑（空数据、权限拒绝、网络断开）
- [ ] 新增 UI 元素已补齐 VoiceOver 辅助标签

### 文档同步

- [ ] `product-requirements.md` 已更新（如有新增功能）
- [ ] `api-reference.md` 已更新（如有新增/变更 public 接口）
- [ ] 新增第三方库已更新开源许可展示
- [ ] 合并后立即更新 `STATUS.md`

### Review

- [ ] Review 结论已留痕（PR comment 或 PR 描述）
