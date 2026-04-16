<!-- last_verified: 2026-04-16 -->
<!-- layer: pattern -->
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
- 后台执行：`Task.detached`（当前实践）；`@concurrent` 可作为替代
- 纯计算 struct/enum 跨 actor 使用：标记 `nonisolated`（如 ImageStorage、DTO、L10n）
- Task 句柄：`@ObservationIgnored private var xxxTask: Task<Void, Never>?` + `cancelTasks()` 在 `.onDisappear`
- **Task 闭包中禁止直接访问 MainActor 属性**：`Task {}` / `Task.detached {}` 内不得引用 `@Environment`、`@State`、computed property 等 MainActor 隔离属性。必须在进入 Task 前用 `let localVar = mainActorProp` 捕获到局部变量（要求类型为 `Sendable`）。原因：clean build 可能不报警告，但 Xcode 增量编译会捕获 actor isolation 违规
- NotificationCenter：用 `for await` 替代 `addObserver`

### Upcoming Features（已全包启用）

- **InferIsolatedConformances**：当 MainActor 隔离类型遵循协议时，编译器自动推断遵循也是 MainActor 隔离的，减少显式 @MainActor 标注
- **NonisolatedNonsendingByDefault**：函数和闭包默认为 nonisolated + nonsending（不继承调用方的 actor 隔离），需要隔离时显式标注

### nonisolated(unsafe)

仅用于第三方 SDK 类型未标注 Sendable 但实际线程安全的场景（当前 4 处）。每处必须附注释说明安全理由。

| 允许 | 禁止 |
|---|---|
| Apple SDK 类型尚未审计 Sendable（AVCaptureSession、PDFPage） | 可变共享状态 |
| 属性在 MainActor 上设置、在 nonisolated 回调中只读 | 自定义类型（应直接遵循 Sendable 或用 actor） |

### @preconcurrency

用于桥接未完成 Sendable 审计的 Apple 框架，两种用法：
- `@preconcurrency import AVFoundation` — 抑制整个模块的并发警告
- `@preconcurrency Animatable` — 协议遵循标注，抑制特定协议的并发警告

随 SDK 更新逐步移除。

## 接口变更

- 修改 struct/class/protocol 的 init 或方法签名后，必须 `grep -rn "TypeName(" Packages/*/Tests/` 检查测试文件同步
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
