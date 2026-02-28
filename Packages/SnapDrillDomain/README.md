# SnapDrillDomain

**领域用例层 (The Domain Use Case Layer)**

`SnapDrillDomain` 是 Clean Architecture 中的用例层，定义了应用的核心业务操作协议，并持有 Repository 抽象接口。它将业务逻辑从数据实现（`SnapDrillData`）和功能视图（`SnapDrillFeatures`）中解耦出来。

## 组成部分

### UseCase（业务用例）
- `ReviewUseCase` / `ReviewUseCaseProtocol`: 复习流程调度，封装 SM-2 算法调用。
- `TaxonomyUseCase` / `TaxonomyUseCaseProtocol`: 学科、来源、标签的分类管理。
- `UseCaseContainer` / `DefaultUseCaseContainer`: 统一的用例容器，通过 SwiftUI `@Environment(\.useCases)` 注入。

### Repository 协议（存储抽象）
- `ReviewRepositoryProtocol`: 复习条目 CRUD 抽象。
- `TaxonomyRepositoryProtocols`: Subject / Source / Tag 的仓库协议。

## 依赖
- `SnapDrillCore`: 使用核心领域实体（`ReviewItem`, `Subject` 等）。

## 注意
- 此模块**只定义协议和用例**，不包含任何 SwiftData 代码。
- 具体的 Repository 实现位于 `SnapDrillData`。
