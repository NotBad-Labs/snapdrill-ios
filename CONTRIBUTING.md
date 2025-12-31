# 贡献指南 (Contributing Guide)

感谢您有兴趣为 **NotBad** 做出贡献！为了确保协作顺畅及代码质量，请遵循以下流程和规范。

## 开发流程

1.  **Issue**: 在开始任何工作之前，请确保有一个相关的 GitHub Issue，并在评论区告知您正在处理。
2.  **Branch**: 从 `main` 分支检出新分支。
    - 分支命名规范: `feature/your-feature-name` 或 `fix/issue-id-description`。
3.  **Commit**: 提交信息应清晰简洁。
    - 推荐格式: `[Feature] Add specific functionality` 或 `[Fix] Resolve crash in settings`。
4.  **Pull Request**: 提交 PR 到 `main` 分支。
    - 确保所有 CI 检查通过。
    - 请求至少一名维护者进行 Code Review。

## 环境设置

- **Xcode**: 请使用最新稳定版 Xcode (目前推荐 Xcode 16.0+)。
- **SwiftLint**: 项目强制使用 SwiftLint 进行代码风格检查。请确保本地已安装 (`brew install swiftlint`)。

## 代码规范

-遵循项目根目录下的 `.swiftlint.yml`配置。
- 保持模块化原则，不要在 App Target 中编写具体业务逻辑。
- 新增功能建议包含单元测试。

## 测试

在提交 PR 之前，请运行所有测试以确保没有回归问题：
- 使用 `Cmd+U` 在 Xcode 中运行测试。
- 或在终端运行: `xcodebuild test -scheme NotBad -destination 'platform=iOS Simulator,name=iPhone 16'`

如有疑问，请联系项目维护者。
