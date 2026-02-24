# SnapDrill GitHub Copilot 指令

## 项目概况

**SnapDrill** 是一款 iOS 间隔重复学习应用（错题本），基于 SM-2 算法帮助用户高效复习。  
**Bundle ID**: `com.snapdrill.app` | **最低版本**: iOS 18.0

---

## 技术栈

- **语言**: Swift 6.x（严格并发模式 `swiftLanguageMode(.v6)`）
- **UI 框架**: SwiftUI（iOS 18+）
- **持久化**: SwiftData
- **架构**: 模块化 SPM + 单向依赖

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
- **禁止** `@unchecked Sendable`

### 架构规范
- View 不含业务逻辑，逻辑应在 ViewModel 中
- Repository Pattern 封装 SwiftData 细节，View/ViewModel 不直接操作 `ModelContext`
- Services 通过协议注入，禁止 View 直接调用 singleton

### 代码质量
- **禁止** `print()`，使用 `SnapDrillLogger`（基于 `OSLog`）
- **禁止** 强制解包 `!`（SwiftLint: `force_unwrapping: error`）
- **禁止** `any` 类型
- 公开 API 必须提供 `///` DocC 文档注释

---

## 禁止事项

1. 禁止使用旧项目名 `NotBad` / `com.notbadhq.*` 相关命名
2. 禁止 macOS 平台代码（纯 iOS 项目）
3. 禁止在 `NSSetUncaughtExceptionHandler` 中使用 `async/await`
4. 禁止在 `defer` 块中创建 unstructured `Task {}`
