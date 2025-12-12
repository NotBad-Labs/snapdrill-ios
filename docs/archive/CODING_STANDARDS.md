> **Archived**: not part of public documentation; may be outdated.

# 编码规范（NotBad）

> 精简版占位文档，确保链接可用；后续可根据团队规范补充细节。

## Swift 风格
- 使用 Swift 6 并开启严格并发检查。
- 优先使用 `let`，仅在需要变更时使用 `var`。
- 避免强制解包；使用 `guard` 早退出。
- 命名遵循小驼峰（变量/函数）、大驼峰（类型）。

## SwiftUI
- 数据流：`@Query` 读取模型，`@State`/`@Bindable` 管理局部状态。
- 视图尽量保持无副作用；复杂逻辑下沉到 Service。
- 可复用的样式提取到 `Presentation/Common`。

## SwiftData 模型
- `@Model` 作为充血模型，包含核心业务属性与方法。
- 大对象（图片等）仅存路径，文件写入使用 `ImageStorageService`。
- Migration 变更同步更新 `ReviewItemMigrationPlan`。

## 错误与日志
- 领域/服务错误集中在 `Infrastructure/Errors`（如有新增）。
- 对用户可见的错误，统一映射为可读提示，避免直接抛内部错误。

## 测试
- 单元测试聚焦纯函数和 Service；UI/集成测试覆盖关键用户路径。
- Mock 使用轻量协议替身，避免全局单例耦合。

## 文档
- 新增/调整架构决策时更新 ADR。
- 重要公共 API 添加文档注释，便于 DocC 生成。
