# ADR-005: DI Factory 模式

## 状态
**已废弃** — 被 [ADR-006](./ADR-006-pragmatic-architecture.md) 取代

> ⚠️ 本决策已于 2025年12月6日废弃。DI 层已删除，使用 SwiftUI `@Environment` 或简单单例替代。

## 日期
2025年12月

## 上下文

Clean Architecture 需要依赖注入 (DI) 来：
- 解耦各层依赖
- 支持测试时注入 mock
- 管理对象生命周期

iOS 常见 DI 方案：
- 手动构造器注入
- Service Locator 模式
- DI 容器（Swinject 等）
- 工厂模式

## 决策

采用 **DI Factory 模式** + SwiftUI Environment：

```swift
protocol DependencyFactory: Sendable {
    // Repositories
    var reviewItemRepository: ReviewItemRepository { get }
    var subjectRepository: SubjectRepository { get }
    
    // Use Cases
    func makeAddReviewItemUseCase() -> AddReviewItemUseCase
    func makeFetchReviewItemsUseCase() -> FetchReviewItemsUseCase
    // ...
}
```

## 实现

### 生产环境工厂
```swift
final class ProductionDependencyFactory: DependencyFactory {
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    var reviewItemRepository: ReviewItemRepository {
        SwiftDataReviewItemRepository(modelContainer: modelContainer)
    }
    
    func makeAddReviewItemUseCase() -> AddReviewItemUseCase {
        AddReviewItemUseCase(repository: reviewItemRepository)
    }
}
```

### 测试环境工厂
```swift
final class TestDependencyFactory: DependencyFactory {
    var mockReviewItemRepository = MockReviewItemRepository()
    
    var reviewItemRepository: ReviewItemRepository {
        mockReviewItemRepository
    }
    
    func makeAddReviewItemUseCase() -> AddReviewItemUseCase {
        AddReviewItemUseCase(repository: mockReviewItemRepository)
    }
}
```

### SwiftUI 集成
```swift
struct DependencyFactoryKey: EnvironmentKey {
    static var defaultValue: DependencyFactory = ProductionDependencyFactory(...)
}

extension EnvironmentValues {
    var dependencyFactory: DependencyFactory {
        get { self[DependencyFactoryKey.self] }
        set { self[DependencyFactoryKey.self] = newValue }
    }
}

// 使用
struct ReviewListView: View {
    @Environment(\.dependencyFactory) private var factory
    
    var body: some View {
        // 使用 factory 创建依赖
    }
}
```

## 选项考虑

### 选项 A: 手动构造器注入
```swift
let repo = SwiftDataRepository()
let useCase = AddUseCase(repository: repo)
let viewModel = ViewModel(useCase: useCase)
```
- ✅ 简单直接，无魔法
- ✅ 编译时安全
- ❌ 依赖链长时代码冗长
- ❌ 每个入口点需要手动组装

### 选项 B: Service Locator
```swift
Container.shared.register(Repository.self) { ... }
let repo = Container.shared.resolve(Repository.self)
```
- ✅ 灵活，按需解析
- ❌ 运行时错误风险
- ❌ 隐式依赖，难以追踪
- ❌ 测试时需要全局配置

### 选项 C: DI 容器 (Swinject)
- ✅ 功能丰富
- ✅ 自动解析依赖图
- ❌ 额外依赖
- ❌ 运行时错误风险
- ❌ 学习成本

### 选项 D: Factory 模式
- ✅ 编译时安全
- ✅ 显式依赖
- ✅ 无外部依赖
- ✅ 测试友好
- ❌ 需要手动维护工厂方法

## 后果

### 正面
1. **类型安全**：编译时检查依赖完整性
2. **测试友好**：轻松替换为测试工厂
3. **无依赖**：不需要第三方 DI 框架
4. **显式依赖**：依赖关系清晰可见

### 负面
1. **样板代码**：每个依赖需要工厂方法
2. **手动维护**：新增依赖需要更新工厂
3. **协议限制**：需要为每个服务定义协议

## 生命周期管理

```swift
final class ProductionDependencyFactory: DependencyFactory {
    // 单例：共享实例
    private lazy var _reviewItemRepository = SwiftDataReviewItemRepository(...)
    
    var reviewItemRepository: ReviewItemRepository {
        _reviewItemRepository
    }
    
    // 工厂方法：每次创建新实例
    func makeAddReviewItemUseCase() -> AddReviewItemUseCase {
        AddReviewItemUseCase(repository: reviewItemRepository)
    }
}
```

## 参考

- [Dependency Injection in Swift](https://www.swiftbysundell.com/articles/dependency-injection-in-swift/)
- [Factory Pattern](https://refactoring.guru/design-patterns/factory-method)
