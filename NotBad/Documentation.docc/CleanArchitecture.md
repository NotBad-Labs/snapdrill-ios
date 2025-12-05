# Clean Architecture

理解 NotBad 的 Clean Architecture 实现。

## Overview

Clean Architecture 由 Robert C. Martin (Uncle Bob) 提出，核心思想是通过分层和依赖反转实现关注点分离。

## 为什么选择 Clean Architecture

### 可测试性

```swift
// Use Case 可以独立测试，无需 UI 或数据库
func testCreateReviewItem() async throws {
    let mockRepo = MockReviewItemRepository()
    let useCase = CreateReviewItemUseCase(repository: mockRepo)
    
    let item = try await useCase.execute(input)
    
    XCTAssertEqual(item.question, "测试问题")
}
```

### 可维护性

- 每层职责单一
- 修改一层不影响其他层
- 易于定位问题

### 技术栈独立

- 可以替换 SwiftData 为其他存储方案
- 可以替换 SwiftUI 为 UIKit
- 业务逻辑不受影响

## 实践要点

### 1. 依赖反转

Domain 层定义协议，Data 层实现：

```swift
// Domain 层定义
protocol ReviewItemRepository {
    func save(_ item: ReviewItem) async throws
}

// Data 层实现
final class SwiftDataReviewItemRepository: ReviewItemRepository {
    func save(_ item: ReviewItem) async throws {
        // SwiftData 实现
    }
}
```

### 2. Use Case 模式

每个业务操作封装为独立的 Use Case：

```swift
final class CreateReviewItemUseCase {
    private let repository: ReviewItemRepository
    
    func execute(_ input: Input) async throws -> ReviewItem {
        // 业务逻辑
    }
}
```

### 3. ViewModel 与 Use Case

ViewModel 组合多个 Use Case：

```swift
@Observable
final class ReviewListViewModel {
    private let fetchUseCase: FetchReviewItemsUseCase
    private let deleteUseCase: DeleteReviewItemUseCase
    
    func load() async {
        items = try await fetchUseCase.execute()
    }
}
```

## 目录结构

```
NotBad/
├── Domain/              # 领域层
│   ├── Entities/
│   ├── Repositories/
│   └── Errors/
├── Application/         # 应用层
│   ├── UseCases/
│   └── DTOs/
├── Data/                # 数据层
│   ├── SwiftData/
│   └── Repositories/
├── Infrastructure/      # 基础设施层
│   ├── DI/
│   └── Logging/
└── Presentation/        # 表现层
    ├── ViewModels/
    └── Views/
```

## See Also

- <doc:Architecture>
- <doc:UseCases>
- <doc:DependencyInjection>
