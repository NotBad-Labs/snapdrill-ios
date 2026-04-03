# Compact Reminder

> 压缩后恢复上下文用。CLAUDE.md 和 .claude/rules/ 由系统自动重新加载，此文件只补充它们覆盖不到的会话状态。

## 恢复步骤

1. 读 `STATUS.md` 确认当前任务和优先级
2. 读 `.claude/session-log.txt` 确认本次会话修改过的文件
3. 运行 `git status` 和 `git log --oneline -5` 确认当前分支和最近提交
4. 继续工作

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
- 改接口签名后 `grep -rn "TypeName(" Tests/` 检查同步
- PR 未合并前禁止推进下一任务
- Review 结论必须留痕
- 价值链：采集 > 管理 > 导出/打印 > 复习
