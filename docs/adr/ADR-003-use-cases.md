# ADR-003: Use Cases 模式

## 状态
已采纳

## 日期
2025年12月

## 上下文

在 Clean Architecture 中，Application 层需要组织业务逻辑。常见模式：
- Service 类（多方法）
- Use Case 类（单一职责）
- Interactor 模式

问题：
- ViewModel 容易变得臃肿
- 业务逻辑难以复用
- 测试需要大量 mock

## 决策

采用 **Use Case 模式**，每个用例封装单一业务操作。

```swift
protocol UseCase {
    associatedtype Input
    associatedtype Output
    func execute(_ input: Input) async throws -> Output
}

final class AddReviewItemUseCase: UseCase {
    private let repository: ReviewItemRepository
    
    init(repository: ReviewItemRepository) {
        self.repository = repository
    }
    
    func execute(_ input: AddReviewItemInput) async throws -> ReviewItem {
        // 业务逻辑
    }
}
```

## 选项考虑

### 选项 A: Service 类
```swift
class ReviewService {
    func add(_ item: ReviewItem) { }
    func update(_ item: ReviewItem) { }
    func delete(_ item: ReviewItem) { }
    func getStatistics() -> Statistics { }
}
```
- ✅ 代码集中，易于查找
- ❌ 类容易膨胀
- ❌ 违反单一职责原则
- ❌ 测试需要 mock 整个服务

### 选项 B: Use Case 模式
```swift
class AddReviewItemUseCase { }
class UpdateReviewItemUseCase { }
class GetStatisticsUseCase { }
```
- ✅ 单一职责，易于理解
- ✅ 便于测试（mock 最小依赖）
- ✅ 支持复杂业务编排
- ❌ 文件数量增加
- ❌ 简单操作显得繁重

### 选项 C: Repository 直接调用
- ✅ 简单直接
- ❌ 业务逻辑泄露到 ViewModel
- ❌ 无法复用跨层逻辑

## 后果

### 正面
1. **职责清晰**：每个 Use Case 只做一件事
2. **高可测试性**：依赖最小化，易于 mock
3. **业务文档化**：Use Case 名称即业务描述
4. **复用性**：多个 ViewModel 可共享 Use Case

### 负面
1. **文件数量多**：每个操作一个文件
2. **样板代码**：简单 CRUD 也需要完整结构
3. **命名挑战**：需要清晰的命名规范

## 当前 Use Cases

```
Application/UseCases/
├── ReviewItem/
│   ├── AddReviewItemUseCase.swift
│   ├── UpdateReviewItemUseCase.swift
│   ├── DeleteReviewItemUseCase.swift
│   ├── FetchReviewItemsUseCase.swift
│   └── SearchReviewItemsUseCase.swift
├── Review/
│   ├── GetDueReviewItemsUseCase.swift
│   └── RecordReviewResultUseCase.swift
├── Subject/
│   ├── AddSubjectUseCase.swift
│   └── FetchSubjectsUseCase.swift
└── Statistics/
    └── GetStatisticsUseCase.swift
```

## ViewModel 集成

```swift
@Observable
final class ReviewListViewModel {
    private let fetchUseCase: FetchReviewItemsUseCase
    private let deleteUseCase: DeleteReviewItemUseCase
    
    var items: [ReviewItem] = []
    
    func load() async {
        items = try await fetchUseCase.execute()
    }
    
    func delete(_ item: ReviewItem) async {
        try await deleteUseCase.execute(item.id)
    }
}
```

## 参考

- [Clean Architecture Use Cases](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Use Case Driven Development](https://www.ivarjacobson.com/publications/books/use-case-20-2016)
