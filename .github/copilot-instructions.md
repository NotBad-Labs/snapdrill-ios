# SnapDrill GitHub Copilot 指令

## 项目概况

**SnapDrill** 是一款 iOS 间隔重复学习应用（错题本），基于 SM-2 算法帮助用户高效复习。  
**Bundle ID**: `com.snapdrill.app` | **最低版本**: iOS 17.0

---

## 技术栈

- **语言**: Swift 6.x（严格并发模式 `swiftLanguageMode(.v6)`）
- **UI 框架**: SwiftUI（iOS 17.0+）
- **持久化**: SwiftData
- **架构**: 模块化 SPM + 单向依赖
- **质量核心**: **零技术债 (Zero Tech Debt)** - 绝不为了发布而牺牲代码质量，P0/P1/P2 风险必须发布前归零。

---

## 包结构（SPM 模块）

| 包名 | 职责 | 依赖 |
|:---|:---|:---|
| **SnapDrillCore** | 领域模型、Service、Engine、Utils | 0 依赖 |
| **SnapDrillData** | SwiftData 持久化、Repository | SnapDrillCore |
| **SnapDrillUI** | 设计系统、通用组件 | SnapDrillCore |
| **SnapDrillFeatures** | 所有功能页面（Capture / Library / Review / Dashboard / Settings） | SnapDrillCore, SnapDrillData, SnapDrillUI |

**依赖方向**：Features → Data/UI → Core（严禁逆向引用）

---

## 核心开发约定

### Swift 6 并发
- 所有包开启 `.swiftLanguageMode(.v6)`
- UI 状态：`@Observable @MainActor class ViewModel`
- 跨隔离边界传递数据必须符合 `Sendable`
- 耗时 I/O（图像处理、OCR）封装在 `actor` 中
- **不可退坡**：绝对不为了图省事而写出需要妥协编译警告的代码。如果遇到并发告警，宁死不用 `@unchecked Sendable`。
- **纯粹性**：UI 层与业务核心保持彻底隔离，任何业务计算和持久化（SwiftData）都决不应当污染视图界面的清晰度。
- **零债务承诺**：本项目信奉「零技术债」交付。所有关于数据一致性、生命周期管理的瑕疵（P0/P1/P2）必须在 Beta 前清零。
- **数据生命线**：Repository 层必须保证数据完整性，包括但不限于级联更新、删除检查、强错误处理。
- **并发稳定**: 异步任务（Task）必须具备明确的句柄管理和取消逻辑（Cancellation Check），严禁非结构化的识别结果覆盖（Race Condition）。

### 架构规范
- View 不含业务逻辑，逻辑应在 ViewModel 中
- Repository Pattern 封装 SwiftData 细节，View/ViewModel 不直接操作 `ModelContext`
- Services 通过协议注入，禁止 View 直接调用 singleton
- **数据安全 (Data Integrity)**: 
    - 严禁静默失败：移除关键保存/初始化路径的 `try?`。
    - 显式保存：所有 Mutation 操作（增删改）必须显式调用 `save()`。
    - 级联一致性：重命名分类必须级联更新关联记录，删除前必须进行引用检查（Delete Intercept）。

### 代码质量
- **禁止** `print()`，使用 `SnapDrillLogger`（基于 `OSLog`）
- **禁止** 强制解包 `!`（SwiftLint: `force_unwrapping: error`）
- **禁止** `any` 类型
- 公开 API 必须提供 `///` DocC 文档注释
- **重构注意事项**：
    - **结构完整性**：在迁移 `@Query` 时，务必检查 View body 的大括号嵌套，确保 `.onAppear` / `.toolbar` / `.sheet` 依然挂载在正确的容器上。
    - **显式导入**：重构产生的模块拆分需重新确认 `SwiftUI` 和 `Observation` 的导入，防止编译链断裂。
    - **#Predicate 限制**：SwiftData 的 `#Predicate` 闭包仅支持**单表达式**。复杂逻辑需拆解为链式逻辑，且注意可选值解包的 SwiftLint 冲突（使用 `force_unwrapping` 禁用注释或更优雅的表达式）。
    - **onDelete 挂载点**：`.onDelete` 必须挂载在 `ForEach` 循环上，严禁直接挂载在 Cell 视图或 Button 上。

---

## 禁止事项

1. 禁止使用旧项目名 `NotBad` / `com.notbadhq.*` 相关命名
2. 禁止 macOS 平台代码（纯 iOS 项目）
3. 禁止在 `NSSetUncaughtExceptionHandler` 中使用 `async/await`
4. 禁止在 `defer` 块中创建 unstructured `Task {}`
