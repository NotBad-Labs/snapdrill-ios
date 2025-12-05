# Dependency Injection

NotBad 的依赖注入实现。

## Overview

NotBad 使用 DI Factory 模式结合 SwiftUI Environment 实现依赖注入，无需第三方框架。

## DI Factory 模式

### 协议定义

```swift
protocol DependencyFactory: Sendable {
    // Repositories
    var reviewItemRepository: ReviewItemRepository { get }
    var subjectRepository: SubjectRepository { get }
    
    // Use Cases
    func makeCreateReviewItemUseCase() -> CreateReviewItemUseCase
    func makeFetchReviewItemsUseCase() -> FetchReviewItemsUseCase
}
```

### 生产环境实现

```swift
final class ProductionDependencyFactory: DependencyFactory {
    private let modelContainer: ModelContainer
    
    var reviewItemRepository: ReviewItemRepository {
        SwiftDataReviewItemRepository(modelContainer: modelContainer)
    }
    
    func makeCreateReviewItemUseCase() -> CreateReviewItemUseCase {
        CreateReviewItemUseCase(repository: reviewItemRepository)
    }
}
```

### 测试环境实现

```swift
final class TestDependencyFactory: DependencyFactory {
    var mockReviewItemRepository = MockReviewItemRepository()
    
    var reviewItemRepository: ReviewItemRepository {
        mockReviewItemRepository
    }
    
    func makeCreateReviewItemUseCase() -> CreateReviewItemUseCase {
        CreateReviewItemUseCase(repository: mockReviewItemRepository)
    }
}
```

## SwiftUI 集成

### Environment Key

```swift
struct DependencyFactoryKey: EnvironmentKey {
    static var defaultValue: DependencyFactory = 
        ProductionDependencyFactory(...)
}

extension EnvironmentValues {
    var dependencyFactory: DependencyFactory {
        get { self[DependencyFactoryKey.self] }
        set { self[DependencyFactoryKey.self] = newValue }
    }
}
```

### 在 View 中使用

```swift
struct ReviewListView: View {
    @Environment(\.dependencyFactory) private var factory
    
    var body: some View {
        // 使用 factory 创建依赖
    }
}
```

### 在测试中替换

```swift
func testView() {
    let testFactory = TestDependencyFactory()
    
    ReviewListView()
        .environment(\.dependencyFactory, testFactory)
}
```

## 生命周期管理

### 单例 vs 工厂方法

```swift
final class ProductionDependencyFactory: DependencyFactory {
    // 单例：共享实例
    private lazy var _repository = SwiftDataReviewItemRepository(...)
    
    var reviewItemRepository: ReviewItemRepository {
        _repository  // 返回同一实例
    }
    
    // 工厂方法：每次创建新实例
    func makeCreateReviewItemUseCase() -> CreateReviewItemUseCase {
        CreateReviewItemUseCase(repository: reviewItemRepository)
    }
}
```

## 优势

1. **编译时安全**: 依赖缺失在编译时发现
2. **显式依赖**: 依赖关系清晰可见
3. **测试友好**: 轻松替换 mock 实现
4. **无第三方依赖**: 纯 Swift 实现

## See Also

- <doc:Architecture>
- <doc:CleanArchitecture>
