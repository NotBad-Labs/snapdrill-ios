# SnapDrill 编码规范

> **上游依赖**：`principles.md`（工程哲学、决策框架）
>
> 本文件定义「怎么写代码」——并发、命名、格式、禁止事项。
> 「怎么想」见 `principles.md`，「怎么协作」见 `workflow.md`。
>
> **注意**：UI/UX 编码约束见 `principles.md`「Apple 原生优先铁律」（常用模式速查表、核心心智模型）。
>
> Last verified: 2026-03-19（全量审计，与代码库一致）

---

## 并发规则（Swift 6 strict concurrency）

- 优先 actor isolation，不用锁
- 所有 ViewModel：`@Observable @MainActor final class`
- Prefer async/await；`Task` 必须保存句柄，禁止 fire-and-forget
- Task 句柄统一模式：`@ObservationIgnored private var xxxTask: Task<Void, Never>?`
- 添加 `public func cancelTasks()`，在 View 的 `.onDisappear` 调用
- NotificationCenter 监听：用 `for await _ in NotificationCenter.default.notifications(named:)` 替代 `addObserver`

---

## View 层约束

- View = 纯渲染，不含业务逻辑，不做网络/持久化调用
- 状态全部在 ViewModel 中
- View 从 `@Environment` 取依赖，传给 ViewModel

---

## 日志

- 使用 `SnapDrillLogger`（封装 `os.Logger`），禁止 `print()`
- 子系统选择：`.generic` / `.ui` / `.data` / `.network` / `.engine` / `.capture`

---

## 错误处理

- 关键路径（save/init）：禁止 `try?`，必须 `do/catch`
- 清理路径（delete temp file）：允许 `try?`，但必须加日志或注释 `// best-effort: [原因]`

---

## 代码组织（MARK 顺序）

1. `// MARK: - Properties`
2. `// MARK: - Initialization`
3. `// MARK: - Public API`
4. `// MARK: - View Body / Lifecycle`
5. `// MARK: - Private Helpers`
6. `// MARK: - Preview`

---

## 文件头

每个文件必须有标准 Xcode 版权头 + 一行功能描述：
```swift
//  一句话描述该文件的功能。
```

公司名：`NotBad Labs L.L.C.`（不是 SnapDrill Labs）。描述行不加 `核心职责：` 前缀。

---

## 注释

- 全部使用简体中文
- `public` API 用 DocC（`///`）+ 中文描述；参数名可保留英文
- `private`/`internal` 用 `//` 即可
- 内联注释说明「为什么」而非「做了什么」；逻辑自明的代码不加注释

---

## 孤儿功能禁止

每个 Repository 方法或 ViewModel 公开属性必须有明确的 UI 调用链。已实现但 UI 未接入的须标记 `// TODO: UI Integration Pending`。

---

## 禁止事项

- 禁止为「可测试性」添加只有一个实现的协议（测试用 in-memory `ModelContainer`）
- 禁止 `@unchecked Sendable`、force unwrap `!`、`any` existentials，以下两种场景除外，且须加注释说明理由：
  1. `EnvironmentKey.Value` 为跨模块协议类型（消除 `any` 需打破依赖方向边界，后者是更核心的规则）
  2. 无 associated type / Self 约束的协议作为集合元素类型（`[any PDFExportable]`，框架限制，非设计懒惰）
- 禁止跨 `ModelContext` 写入后立即读取（竞态）
- 禁止在 DEBUG 工具里引入生产级复杂度
- 禁止引入 Domain 层 / UseCase 层 / Repository 协议（理由及重新评估条件见 [ADR-001](decisions/ADR-001-model-as-domain-object.md)、[ADR-002](decisions/ADR-002-repository-no-protocol.md)）
- 禁止用值类型 struct 作领域对象（`@Model` 必须是 class）

---

## 合理规模感

- 功能：Capture / Library / Review / Dashboard / Settings（5 个）
- 用户：单用户，本地优先，无后端
- 包数应与产品功能边界对齐，不硬编码具体数字
- 每新增一个字段，最多改动 3 个文件
