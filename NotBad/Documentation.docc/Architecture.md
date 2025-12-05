# Architecture

NotBad 采用 Clean Architecture 分层架构设计。

## Overview

Clean Architecture 将应用分为多个同心圆层，每层有明确的职责，依赖方向从外向内。

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│      (SwiftUI Views, ViewModels)        │
├─────────────────────────────────────────┤
│           Application Layer             │
│           (Use Cases, DTOs)             │
├─────────────────────────────────────────┤
│             Domain Layer                │
│    (Entities, Repository Protocols)     │
├─────────────────────────────────────────┤
│         Infrastructure Layer            │
│        (DI, Logging, Analytics)         │
├─────────────────────────────────────────┤
│             Data Layer                  │
│   (SwiftData, Repository Implementations)│
└─────────────────────────────────────────┘
```

## 分层说明

### Domain 层

领域层是应用的核心，包含：

- **Entities**: 业务实体如 `ReviewItem`, `Subject`
- **Repository Protocols**: 数据访问协议
- **Domain Errors**: 领域错误类型

领域层不依赖任何外部框架。

### Application 层

应用层包含业务用例：

- **Use Cases**: 单一职责的业务操作
- **DTOs**: 数据传输对象

每个 Use Case 封装一个业务操作，如 `CreateReviewItemUseCase`。

### Data 层

数据层实现 Domain 层定义的协议：

- **SwiftData Repositories**: 使用 SwiftData 实现持久化
- **Mappers**: 数据模型转换

### Infrastructure 层

基础设施层提供技术支持：

- **DI Factory**: 依赖注入工厂
- **Logging**: 日志系统
- **Analytics**: 分析服务

### Presentation 层

表现层处理 UI：

- **ViewModels**: 使用 @Observable 的视图模型
- **Views**: SwiftUI 视图
- **Components**: 可复用 UI 组件

## 依赖规则

1. 依赖方向：外层 → 内层
2. Domain 层不依赖任何外层
3. Application 层只依赖 Domain
4. Data 层实现 Domain 层的协议

## See Also

- <doc:CleanArchitecture>
- <doc:DependencyInjection>
- <doc:UseCases>
