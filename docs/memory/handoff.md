<!-- last updated: 2026-04-14 -->
<!-- freshness: max_age_days=3, decay_trigger=[issue_change,branch_change,priority_change], layer=snapshot -->
# Handoff

## 当前接手状态

- 主力智能体：Claude Code
- 主分支：`develop`
- 当前工作分支：无（develop 上）

## 待合并 PR（3 个，按依赖顺序）

1. **PR #589** `docs/audit-fix-588` — 第一方文档审计修复（断链引用 + 依赖图重建）
2. **PR #591** `fix/compliance-590` — 移除 Firebase Remote Config + 隐私文案修正（八方合规审计）
3. **PR #593** `chore/doc-metadata-standardize` — 文档元数据标准化（32 文件）

注意：#591 和 #593 都基于 develop，可能与 #589 有文档冲突，合并时需按顺序处理。

## 关键事实（当前快照）

- Firebase Remote Config 已在 #591 分支移除（代码 + 依赖 + UI overlay）
- 隐私文案已从"不收集任何"修正为"默认不收集"（文档 + Localizable.strings）
- compliance.md 记录了八方合规审计结论（RC 移除 / DeviceID 不声明 / 文案修正 / age gate 待观察）
- 文档元数据标准化在 #593 分支完成（32 文件，覆盖率 48% → 100%）
- COPPA compliance date: 2026-04-22（距今 8 天）
- 测试基线：130 tests（SnapDrillFeaturesTests）
- iOS 26 已发布，项目基于 iOS 26.0+ / Xcode 26.4 / Swift 6.3
