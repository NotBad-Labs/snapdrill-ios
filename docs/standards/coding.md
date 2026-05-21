---
last_verified: 2026-05-19
layer: pattern
---
# 编码规范（SwiftLint 管不到的规则）

## View 层

- View = 纯渲染，ViewModel 持有状态，View 通过 @Environment → ViewModel 注入依赖
- DI 链路：协议在 Core → 实现在下游 → DependencyContainer 构造 → @Environment 注入 → View 传给 ViewModel

## 日志

- SnapDrillLogger 子系统：`.generic` / `.ui` / `.data` / `.network` / `.engine` / `.capture`

## 并发

- 启用 `defaultIsolation(MainActor.self)`：所有代码默认 MainActor 隔离
- **禁止手写 `@MainActor`**（冗余），唯一例外：`Sendable` 协议 + 可变状态的类需显式标注
- ViewModel 声明：`@Observable final class`（因 `defaultIsolation` 已隐式 MainActor 隔离，**不应手写 `@MainActor`**）
- **现状偏差**：仓库中部分 ViewModel / Router 仍写有 `@MainActor`（如 `DashboardViewModel` / `DashboardRouter` / `DashboardAnalyticsViewModel` / `LibraryRouter` / `SettingsRouter`），属于 `defaultIsolation` 启用前的历史代码遗留。新代码不得手写；旧代码逐步在改动其所在文件时一并清理（不开独立工单批量清理，避免 churn）
- 后台执行：`Task.detached`（文件 IO、图片压缩等确需脱离当前 actor 的场景）
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

## 文件组织

- **单文件单主类型**：每个 .swift 文件有且只有一个主要类型（struct/class/enum/actor）
- **允许的附属类型**：与主类型强耦合、不超过 50 行、仅被主类型使用：
  - Service + Error 枚举（如 BackupService + BackupError）
  - Router + Destination 枚举（如 CaptureRouter + CaptureDestination）
  - View + 小 helper view（UIViewControllerRepresentable + Coordinator）
  - ViewModel + 小 supporting type（如 ReviewPhase 枚举 <20 行）
- **禁止**：独立业务组件（>50 行或被其他文件引用）塞在别人文件里
- **SwiftLint 守护**：`file_length` error 600，超限即需拆分

## 值类型优先

- DTO、配置、快照、纯值模型 → 默认 `struct` 或 `enum`
- 需要 identity、生命周期、`@Observable`、SwiftData 持久化 → `class`
- 守门问题：这个类型需要 identity 吗？不需要就用 struct。

## 禁止

### 并发安全
- `@unchecked Sendable`（测试 Mock 除外，须注释说明）
- `force unwrap !`（`swiftlint force_unwrapping: error`）

### 调试
- `print()` — 用 `SnapDrillLogger` 对应子系统

### 类型系统
- `any` existentials（**例外清单**：`EnvironmentKey.Value` 跨模块协议、无 associated type 协议集合如 `[any PDFExportable]`、Protocol 作为函数参数 / 存储属性类型用于 DI 注入。后者实际场景包括 `any ProEntitlementProvider` 在 ViewModel/View 持有用于运行时切换、`any UserNotificationScheduling` 在 LiveNotificationService 注入用于测试。判断标准：**编译期类型未知但需要协议契约**就允许 `any`，**编译期已知具体类型**用泛型或具体类型）

### 架构
- Domain 层 / UseCase 层 / Repository 协议（ViewModel 直调 Repository）
- struct 领域对象（SwiftData @Model 须为 class）
- 跨 ModelContext 写后立即读（须先 saveContext）
