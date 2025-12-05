# ADR-004: 分层错误体系设计

## 状态
已采纳

## 日期
2025年12月

## 上下文

应用需要处理多种错误场景：
- 数据层：SwiftData 持久化错误
- 业务层：验证失败、业务规则违反
- 表现层：用户友好的错误提示

问题：
- 底层错误直接暴露给 UI 导致信息泄露
- 错误类型不统一，处理逻辑分散
- 难以提供一致的用户体验

## 决策

采用 **分层错误体系**，每层定义自己的错误类型，向上转换时映射为更抽象的错误。

```
┌─────────────────────────────┐
│     PresentationError       │  ← 用户友好消息
├─────────────────────────────┤
│      ApplicationError       │  ← 业务级错误
├─────────────────────────────┤
│       DomainError           │  ← 领域规则错误
├─────────────────────────────┤
│     RepositoryError         │  ← 数据访问错误
└─────────────────────────────┘
```

## 错误定义

### RepositoryError
```swift
enum RepositoryError: Error {
    case notFound(id: UUID)
    case saveFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case fetchFailed(underlying: Error)
}
```

### DomainError
```swift
enum DomainError: Error {
    case validationFailed(reason: String)
    case businessRuleViolation(rule: String)
    case invalidState(expected: String, actual: String)
}
```

### ApplicationError
```swift
enum ApplicationError: Error {
    case itemNotFound
    case invalidInput(field: String, reason: String)
    case operationFailed(operation: String)
    case unauthorized
}
```

## 错误转换

```swift
extension RepositoryError {
    func toApplicationError() -> ApplicationError {
        switch self {
        case .notFound:
            return .itemNotFound
        case .saveFailed, .deleteFailed, .fetchFailed:
            return .operationFailed(operation: "数据操作")
        }
    }
}
```

## 选项考虑

### 选项 A: 统一错误类型
```swift
enum AppError: Error {
    case notFound
    case saveFailed
    case networkError
    // ... 所有错误
}
```
- ✅ 简单，一个类型
- ❌ 类型臃肿
- ❌ 层级信息丢失
- ❌ 难以针对性处理

### 选项 B: 分层错误体系
- ✅ 职责分离
- ✅ 每层关注自己的错误
- ✅ 向上转换时可过滤敏感信息
- ❌ 需要定义转换逻辑
- ❌ 类型数量增加

### 选项 C: 仅使用 Swift Error
```swift
throw NSError(domain: "...", code: 1, userInfo: [...])
```
- ✅ 无需定义类型
- ❌ 类型不安全
- ❌ 处理逻辑分散

## 后果

### 正面
1. **关注点分离**：每层处理自己关心的错误
2. **安全性**：底层错误细节不暴露给用户
3. **可测试性**：可以针对特定错误类型编写测试
4. **一致性**：统一的错误处理模式

### 负面
1. **样板代码**：需要定义转换方法
2. **调试复杂**：需要追踪错误转换链
3. **学习成本**：团队需要理解分层规则

## 用户友好消息

```swift
extension ApplicationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "找不到该项目"
        case .invalidInput(let field, let reason):
            return "\(field)输入有误：\(reason)"
        case .operationFailed(let operation):
            return "\(operation)失败，请重试"
        case .unauthorized:
            return "没有权限执行此操作"
        }
    }
}
```

## 参考

- [Error Handling in Swift](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/errorhandling/)
- [Result Type and Error Handling](https://www.swiftbysundell.com/articles/the-power-of-result-types-in-swift/)
