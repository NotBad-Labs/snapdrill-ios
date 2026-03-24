# 编码规范（SwiftLint 管不到的规则）

## View 层

- View = 纯渲染，ViewModel 持有状态，View 通过 @Environment → ViewModel 注入依赖
- DI 链路：协议在 Core → 实现在下游 → DependencyContainer 构造 → @Environment 注入 → View 传给 ViewModel

## 日志

- SnapDrillLogger 子系统：`.generic` / `.ui` / `.data` / `.network` / `.engine` / `.capture`

## 并发

- 所有 ViewModel：`@Observable @MainActor final class`
- Task 句柄：`@ObservationIgnored private var xxxTask: Task<Void, Never>?` + `cancelTasks()` 在 `.onDisappear`
- NotificationCenter：用 `for await` 替代 `addObserver`

## 错误处理

- 关键路径（save/init）：禁止 `try?`，必须 `do/catch`
- 清理路径：允许 `try?` + `// best-effort: [原因]`

## 注释

- 简体中文，`public` API 用 DocC（`///`），内联注释说"为什么"
- 公司名：`NotBad Labs L.L.C.`

## 禁止

- `@unchecked Sendable`、`force unwrap !`、`print()`
- `any` existentials（两个例外：EnvironmentKey.Value 跨模块协议、无 associated type 协议集合）
- Domain 层 / UseCase 层 / Repository 协议 / struct 领域对象
- 跨 ModelContext 写后立即读
