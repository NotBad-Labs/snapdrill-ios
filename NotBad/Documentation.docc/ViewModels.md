# ViewModels

NotBad 的 ViewModel 设计模式。

## Overview

NotBad 使用 Swift 5.9 引入的 `@Observable` 宏实现响应式 ViewModel。

## ViewModel 设计

### 基本结构

```swift
@Observable
@MainActor
final class ReviewListViewModel {
    // MARK: - State
    var items: [ReviewItem] = []
    var isLoading = false
    var error: Error?
    
    // MARK: - Dependencies
    private let fetchUseCase: FetchReviewItemsUseCase
    private let deleteUseCase: DeleteReviewItemUseCase
    
    // MARK: - Init
    init(fetchUseCase: FetchReviewItemsUseCase,
         deleteUseCase: DeleteReviewItemUseCase) {
        self.fetchUseCase = fetchUseCase
        self.deleteUseCase = deleteUseCase
    }
    
    // MARK: - Actions
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await fetchUseCase.execute()
        } catch {
            self.error = error
        }
    }
}
```

### @MainActor

ViewModel 使用 `@MainActor` 确保 UI 状态更新在主线程：

```swift
@Observable
@MainActor
final class DashboardViewModel {
    var statistics: Statistics?  // UI 状态，主线程更新
}
```

### 依赖注入

ViewModel 通过构造器注入 Use Cases：

```swift
init(
    fetchUseCase: FetchReviewItemsUseCase,
    deleteUseCase: DeleteReviewItemUseCase
) {
    self.fetchUseCase = fetchUseCase
    self.deleteUseCase = deleteUseCase
}
```

## 在 View 中使用

```swift
struct ReviewListView: View {
    @State private var viewModel: ReviewListViewModel
    
    init(viewModel: ReviewListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        List(viewModel.items) { item in
            ReviewItemRow(item: item)
        }
        .task {
            await viewModel.load()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
```

## 状态管理

### 加载状态

```swift
@Observable
final class ViewModel {
    var isLoading = false
    
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        // 加载数据
    }
}
```

### 错误处理

```swift
@Observable
final class ViewModel {
    var error: Error?
    
    func performAction() async {
        do {
            try await useCase.execute()
        } catch {
            self.error = error
        }
    }
}
```

## 测试

```swift
@Test
func testLoadItems() async {
    // Given
    let mockFetch = MockFetchReviewItemsUseCase()
    mockFetch.result = [ReviewItem.sample]
    let viewModel = ReviewListViewModel(fetchUseCase: mockFetch, ...)
    
    // When
    await viewModel.load()
    
    // Then
    #expect(viewModel.items.count == 1)
    #expect(viewModel.isLoading == false)
}
```

## See Also

- <doc:Architecture>
- <doc:UseCases>
- <doc:Views>
