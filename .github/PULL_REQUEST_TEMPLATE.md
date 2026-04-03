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
- [ ] 改接口签名后已 `grep -rn "TypeName(" Tests/` 检查测试同步
- [ ] 变更不违反 `.claude/rules/` 中的架构约束

### 功能完整性

- [ ] 验收标准（Given-When-Then）全部通过
- [ ] 异常路径已考虑（空数据、权限拒绝、网络断开）
- [ ] 新增 UI 元素已补齐 VoiceOver 辅助标签
- [ ] UI 改动已经 Xcode Review 核实

### 文档同步

- [ ] `product-requirements.md` 已更新（如有新增功能）
- [ ] `api-reference.md` 已更新（如有新增/变更 public 接口）
- [ ] 新增第三方库已更新开源许可展示
- [ ] 合并后更新 `STATUS.md`

### Review

- [ ] Review 结论已留痕（PR comment 或 PR 描述）
