---
id: ADR-004
status: Accepted
date: 2026-03-13
---

# ADR-004: DependencyContainer 唯一单例（DI 模式）

## 背景

项目中有多个服务需要在 View 层和 ViewModel 层之间共享（Repository、Analytics、OCR、PDF 导出等）。需要一个统一的依赖注入机制，且要与 SwiftUI 的 `@Environment` 体系兼容。

## 决策

**采用组合根模式：DependencyContainer 是唯一被接受的单例（@MainActor），通过 @Environment 注入到 View 层，View 传递给 ViewModel。**

```
1. 协议定义在上游包（Core）
2. 具体实现在下游包（Infrastructure；未来 Services 包亦同）
3. DependencyContainer 构造所有实例（唯一单例，组合根）
4. 通过 @Environment 注入到 View 层
5. View 传递给 ViewModel — ViewModel 只知道协议
```

## 被否决的方案

### 方案 A：各服务各自 `.shared` 单例

- **为什么否决**：绕过 DI，产生隐式全局状态。ViewModel 直接调用 `SomeService.shared` 时，依赖关系不可见，测试时无法替换。多个 AI 协作者在不同会话中可能各自创建新的 `.shared` 单例，导致单例泛滥
- **现状**：6 个历史遗留 `.shared` 单例（CaptureDraftService、PDFExportService、PerformanceMonitor、NetworkMonitor、AppConfiguration、OnboardingManager）列为技术债，待 Core → Core + Services 拆包时统一清理

### 方案 B：ViewModel 构造函数默认参数 `= ConcreteType()`

- **为什么否决**：隐式耦合具体实现。View 层不经过 @Environment 就能创建 ViewModel，绕过了整个 DI 链路。测试时虽然可以传入替代实现，但生产代码中的默认值掩盖了真实依赖

### 方案 C：第三方 DI 框架（Swinject、Factory 等）

- **为什么否决**：违反 Swift/SwiftData 原生优先原则。SwiftUI 的 @Environment 已经是一个完整的 DI 机制，引入第三方框架是多余的抽象层
- **何时重新评估**：当 @Environment 无法满足需求时（目前未遇到）

### 方案 D：@Environment 直接注入具体类型

- **为什么否决**：`@Environment(ConcreteType.self)` 绕过协议抽象，下游包直接依赖上游具体实现，破坏依赖方向原则

## 后果

**正面**：
- 所有依赖关系在 DependencyContainer 中一目了然
- ViewModel 只知道协议，测试时可注入替代实现
- 与 SwiftUI @Environment 原生集成，无第三方依赖

**负面**：
- DependencyContainer 本身是单例（但它是组合根，这是 DI 模式中唯一被接受的单例位置）
- View 需要从 @Environment 取依赖再传给 ViewModel，代码略显冗余

**技术债**：
- 6 个 `.shared` 单例待迁移到 DI 注入（见 `principles.md` 技术债标记）
