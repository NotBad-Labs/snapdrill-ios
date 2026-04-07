# Compact Reminder

> 压缩后恢复上下文用。CLAUDE.md 和 .claude/rules/ 由系统自动重新加载，此文件只补充它们覆盖不到的会话状态。

## 恢复步骤

1. 读 `STATUS.md` 确认当前任务和优先级
2. 按 `docs/workflow.md` 的 S0-S3 / WIP / 价值链给出决策导航建议（建议优先做 X，原因：Y，备选：Z）
3. 读 `docs/workflow.md` 对齐最新 DoD、Review 留痕和协作纪律
4. 若存在 `.claude/session-log.txt`，读取它确认本次会话改动文件
5. 运行 `git status` 和 `git log --oneline -5` 确认当前分支和最近提交
6. 继续工作

## 执行命令（容易记错参数）

```bash
swiftlint --strict
xcodebuild build-for-testing \
  -scheme SnapDrill \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

- `swift test` 不可用（SPM 仅声明 iOS 平台）
- `xcodebuild build` 不编译测试 target，必须用 `build-for-testing`

## 关键约束速查

- 架构决策未经用户批准不可推翻
- 修改代码前必须先读产品文档
- 改接口签名后 `grep -rn "TypeName(" Packages/*/Tests/` 检查同步
- PR 未合并前禁止推进下一任务
- Review 结论必须留痕
- PR 合并后立即更新 `STATUS.md`（允许直推 develop）
- 价值链：采集 > 管理 > 导出/打印（复习是独立附加值）
