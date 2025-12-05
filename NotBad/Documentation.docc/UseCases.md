# Use Cases

理解 NotBad 的 Use Case 模式。

## Overview

Use Case 是 Clean Architecture 中应用层的核心，每个 Use Case 封装单一业务操作。

## Use Case 设计原则

### 单一职责

每个 Use Case 只做一件事：

```swift
// ✅ 好：单一职责
CreateReviewItemUseCase
FetchReviewItemsUseCase
DeleteReviewItemUseCase

// ❌ 不好：职责过多
ReviewItemService.create()
ReviewItemService.fetch()
ReviewItemService.delete()
```

### 依赖注入

Use Case 通过构造器注入依赖：

```swift
final class CreateReviewItemUseCase {
    private let repository: ReviewItemRepository
    
    init(repository: ReviewItemRepository) {
        self.repository = repository
    }
}
```

### 异步执行

Use Case 方法使用 async/await：

```swift
func execute(_ input: Input) async throws -> Output {
    // 业务逻辑
}
```

## 当前 Use Cases

### 错题管理

| Use Case | 功能 |
|----------|------|
| `CreateReviewItemUseCase` | 创建错题 |
| `FetchReviewItemsUseCase` | 获取错题列表 |
| `UpdateReviewItemUseCase` | 更新错题 |
| `DeleteReviewItemUseCase` | 删除错题 |

### 复习流程

| Use Case | 功能 |
|----------|------|
| `GetDueReviewItemsUseCase` | 获取待复习错题 |
| `RecordReviewResultUseCase` | 记录复习结果 (SM-2) |
| `StartReviewSessionUseCase` | 开始复习会话 |
| `CompleteReviewSessionUseCase` | 完成复习会话 |

### 统计分析

| Use Case | 功能 |
|----------|------|
| `GetStatisticsUseCase` | 获取学习统计 |

## 使用示例

### 在 ViewModel 中使用

```swift
@Observable
final class ReviewListViewModel {
    private let fetchUseCase: FetchReviewItemsUseCase
    private let deleteUseCase: DeleteReviewItemUseCase
    
    var items: [ReviewItem] = []
    var isLoading = false
    var error: Error?
    
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await fetchUseCase.execute()
        } catch {
            self.error = error
        }
    }
    
    func delete(_ item: ReviewItem) async {
        do {
            try await deleteUseCase.execute(item.id)
            items.removeAll { $0.id == item.id }
        } catch {
            self.error = error
        }
    }
}
```

### 测试 Use Case

```swift
@Test
func testCreateReviewItem() async throws {
    // Given
    let mockRepo = MockReviewItemRepository()
    let useCase = CreateReviewItemUseCase(repository: mockRepo)
    let input = CreateReviewItemInput(question: "1+1=?", answer: "2")
    
    // When
    let item = try await useCase.execute(input)
    
    // Then
    #expect(item.question == "1+1=?")
    #expect(mockRepo.savedItems.count == 1)
}
```

## See Also

- <doc:Architecture>
- <doc:CleanArchitecture>
