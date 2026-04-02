---
paths:
  - "**/*.swift"
---

<!-- last verified: 2026-03-30 -->
# 编码规范（SwiftLint 管不到的规则）

## View 层

- View = 纯渲染，ViewModel 持有状态，View 通过 @Environment → ViewModel 注入依赖
- DI 链路：协议在 Core → 实现在下游 → DependencyContainer 构造 → @Environment 注入 → View 传给 ViewModel

## 日志

- SnapDrillLogger 子系统：`.generic` / `.ui` / `.data` / `.network` / `.engine` / `.capture`

## 并发

- 启用 `defaultIsolation(MainActor.self)`：所有代码默认 MainActor 隔离
- **禁止手写 `@MainActor`**（冗余），唯一例外：`Sendable` 协议 + 可变状态的类需显式标注
- ViewModel 声明：`@Observable final class`（不需要 `@MainActor`）
- 后台执行：`Task.detached` 或 `@concurrent`
- 纯计算 struct/enum 跨 actor 使用：标记 `nonisolated`（如 ImageStorage、DTO、L10n）
- Task 句柄：`@ObservationIgnored private var xxxTask: Task<Void, Never>?` + `cancelTasks()` 在 `.onDisappear`
- NotificationCenter：用 `for await` 替代 `addObserver`

## 接口变更

- 修改 struct/class/protocol 的 init 或方法签名后，必须 `grep -rn "TypeName(" Tests/` 检查测试文件同步
- 用 `xcodebuild build-for-testing` 验证（`build` 不编译测试 target）

## 错误处理

- 关键路径（save/init）：禁止 `try?`，必须 `do/catch`
- 清理路径：允许 `try?` + `// best-effort: [原因]`
- **Typed throws（SE-0413，Swift 6.0+）**：
  - **业务验证方法**（查重、权限判断、格式校验）：使用 `throws(SpecificError)`，如 `throws(DataError)`、`throws(OCRError)`
  - **纯 CRUD 代理方法**（直接包装 SwiftData `save`/`fetch`、`FileManager`、`URLSession`）：保持原生 `throws`，不做无意义包装
  - **禁止**：在强类型错误枚举中定义 `case underlying(Error)` 逃生舱——这破坏 exhaustive 检查的意义

## 注释

- 简体中文，`public` API 用 DocC（`///`），内联注释说"为什么"
- 公司名：`NotBad Labs L.L.C.`

## 禁止

- `@unchecked Sendable`、`force unwrap !`、`print()`
- `any` existentials（三个例外：EnvironmentKey.Value 跨模块协议、无 associated type 协议集合如 `[any PDFExportable]`、Protocol 作为函数参数类型）
- Domain 层 / UseCase 层 / Repository 协议 / struct 领域对象
- 跨 ModelContext 写后立即读
