# NotBad 彻底重构执行计划

> 版本: 1.0  
> 创建日期: 2025-12-06  
> 预计工期: 2-3 周（按优先级分阶段）

---

## 📋 目录

1. [重构目标与原则](#1-重构目标与原则)
2. [当前架构评估](#2-当前架构评估)
3. [目标架构](#3-目标架构)
4. [阶段划分与优先级](#4-阶段划分与优先级)
5. [详细任务清单](#5-详细任务清单)
6. [风险与缓解措施](#6-风险与缓解措施)
7. [验收标准](#7-验收标准)

---

## 1. 重构目标与原则

### 1.1 核心目标

| 目标 | 描述 |
|-----|-----|
| **架构合规** | 严格遵循 Clean Architecture + DDD 分层 |
| **Swift 6 Ready** | 完全兼容 Swift 6 并发模型（@MainActor、Sendable） |
| **可测试性** | 所有业务逻辑 100% 可单元测试 |
| **性能优化** | 消除不必要的重渲染、优化内存使用 |
| **代码质量** | 遵循 CODE_REVIEW_GUIDELINES.md 15 维度标准 |

### 1.2 重构原则

```
1. 增量重构：小步前进，每步可验证
2. 保持可编译：每次提交都能通过编译
3. 测试先行：修改前确保有测试覆盖
4. 向后兼容：Legacy 代码标记 @deprecated 逐步移除
5. 文档同步：代码变更同步更新文档
```

### 1.3 禁止事项（来自 CODE_REVIEW_GUIDELINES）

- ❌ 在 View 中直接访问 Repository
- ❌ View 直接使用 ModelContext（应通过 Use Case）
- ❌ ViewModel 直接操作 SwiftData Model
- ❌ Domain 层依赖 Data/Infrastructure
- ❌ Use Case 返回 Data Model
- ❌ 硬编码字符串（使用 Localizable.xcstrings）
- ❌ 命名使用拼音或中英混合
- ❌ 公开 API 缺少文档注释

---

## 2. 当前架构评估

### 2.1 架构层次现状

```
┌─────────────────────────────────────────────────────────────────┐
│                     Presentation 层                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ Views       │  │ ViewModels  │  │ Coordinators│              │
│  │ (直接@Query)│  │ (混合依赖) │  │ (已完成)    │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
├─────────────────────────────────────────────────────────────────┤
│                     Domain 层 (Application)                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ Entities    │  │ Use Cases   │  │ Value Objects│             │
│  │ (完善)      │  │ (待集成)    │  │ (完善)       │             │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
├─────────────────────────────────────────────────────────────────┤
│                     Data 层                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ Models      │  │ Repository  │  │ Mappers     │              │
│  │ (SwiftData) │  │ (已实现)    │  │ (已实现)    │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
├─────────────────────────────────────────────────────────────────┤
│                     Infrastructure 层                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ OCR Service │  │ AI Service  │  │ DI Factory  │              │
│  │ (完善)      │  │ (完善)      │  │ (已实现)    │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 问题诊断

| 类别 | 问题 | 严重程度 | 影响范围 |
|-----|------|---------|---------|
| **View 层** | 直接使用 `@Query` 访问 SwiftData | 🔴 高 | 4 个 View |
| **View 层** | 混用 `@StateObject` 和 `@State` | 🟡 中 | 部分 View |
| **ViewModel 层** | 未完全集成 Use Cases | 🔴 高 | 所有 ViewModel |
| **ViewModel 层** | 仍使用 DataProvider | 🟡 中 | 多数 ViewModel |
| **依赖注入** | View 未统一使用 DependencyFactory | 🟡 中 | 多数 View |
| **错误处理** | 未使用分层错误体系 | 🟡 中 | 全局 |
| **测试覆盖** | ViewModel 测试覆盖不足 | 🟡 中 | 测试层 |

### 2.3 已完成的基础设施

✅ Domain 层实体（ReviewItem + Extensions）  
✅ Value Objects 完整定义  
✅ Use Case Protocols（Library/Review/Statistics）  
✅ Use Case Implementations  
✅ Repository 实现（ReviewItemRepository）  
✅ DependencyFactory 协议和生产实现  
✅ 协调器层次结构（AppCoordinator → Feature Coordinators）  
✅ 分层错误类型（DomainError/RepositoryError/InfrastructureError）  

---

## 3. 目标架构

### 3.1 数据流架构

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER                                     │
│                          │                                       │
│                          ▼                                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    View (SwiftUI)                           │ │
│  │  • 纯 UI 渲染                                               │ │
│  │  • @Bindable ViewModel                                      │ │
│  │  • 无业务逻辑                                               │ │
│  └────────────────────────────────────────────────────────────┘ │
│                          │ User Action                           │
│                          ▼                                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                 ViewModel (@Observable)                     │ │
│  │  • UI 状态管理                                              │ │
│  │  • 调用 Use Cases                                           │ │
│  │  • 错误转换 → 用户友好消息                                  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                          │ Use Case Call                         │
│                          ▼                                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Use Cases (Application Layer)                  │ │
│  │  • 业务流程编排                                             │ │
│  │  • 领域规则验证                                             │ │
│  │  • 返回 Domain Entities                                     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                          │ Repository Call                       │
│                          ▼                                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                 Repository (Data Layer)                     │ │
│  │  • 数据持久化抽象                                           │ │
│  │  • Model ↔ Entity 转换                                      │ │
│  │  • 封装 SwiftData                                           │ │
│  └────────────────────────────────────────────────────────────┘ │
│                          │                                       │
│                          ▼                                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              SwiftData (ReviewItemModel)                    │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 依赖注入流

```swift
// 目标：所有 View 通过 Environment 获取依赖

// App 入口
@main
struct NotBadApp: App {
    let container = try! ModelContainer(...)
    let factory: DependencyFactory = ProductionDependencyFactory(modelContainer: container)
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.dependencyFactory, factory)
        }
    }
}

// View 使用
struct LibraryView: View {
    @Environment(\.dependencyFactory) private var factory
    @State private var viewModel: LibraryViewModel?
    
    var body: some View {
        content
            .task {
                viewModel = factory.makeLibraryViewModel()
            }
    }
}
```

---

## 4. 阶段划分与优先级

### Phase 1: 核心架构对齐 (优先级 P0)

**目标**: 消除 View 直接访问数据层的问题

| 任务 | 预计耗时 | 依赖 |
|-----|---------|-----|
| 1.1 DependencyFactory 增加 ViewModel 工厂方法 | 2h | - |
| 1.2 LibraryView 移除 @Query，改用 ViewModel | 4h | 1.1 |
| 1.3 DashboardView 移除 @Query | 3h | 1.1 |
| 1.4 ReviewView 移除 @Query | 3h | 1.1 |
| 1.5 ProfileView 移除 @Query | 2h | 1.1 |

**验收**: 所有 View 中无 `@Query`，数据通过 ViewModel 获取

---

### Phase 2: ViewModel Use Case 集成 (优先级 P0)

**目标**: ViewModel 完全通过 Use Cases 操作业务

| 任务 | 预计耗时 | 依赖 |
|-----|---------|-----|
| 2.1 LibraryViewModel 集成 CRUD Use Cases | 4h | Phase 1 |
| 2.2 DashboardViewModel 集成 Statistics Use Case | 3h | Phase 1 |
| 2.3 ReviewViewModel 完善 Use Case 调用 | 3h | Phase 1 |
| 2.4 CaptureViewModel 集成 Create Use Case | 3h | Phase 1 |
| 2.5 移除 DataProvider，统一使用 Use Cases | 2h | 2.1-2.4 |

**验收**: ViewModel 中无直接 Repository 调用

---

### Phase 3: 错误处理统一 (优先级 P1)

**目标**: 实现分层错误处理和用户友好提示

| 任务 | 预计耗时 | 依赖 |
|-----|---------|-----|
| 3.1 完善 NotBadError 统一错误封装 | 2h | - |
| 3.2 Use Cases 返回 Result<T, DomainError> | 3h | 3.1 |
| 3.3 ViewModel 错误转换为用户消息 | 3h | 3.2 |
| 3.4 View 统一错误展示组件 | 2h | 3.3 |
| 3.5 补充 Analytics 错误上报 | 1h | 3.4 |

**验收**: 所有错误有明确分类和用户友好提示

---

### Phase 4: 测试补充 (优先级 P1)

**目标**: 核心业务逻辑测试覆盖率 > 80%

| 任务 | 预计耗时 | 依赖 |
|-----|---------|-----|
| 4.1 补充 Use Case 单元测试 | 4h | Phase 2 |
| 4.2 ViewModel 测试用 Mock 工厂 | 2h | 4.1 |
| 4.3 补充 ViewModel 单元测试 | 4h | 4.2 |
| 4.4 集成测试验证完整流程 | 3h | 4.3 |
| 4.5 性能测试基准建立 | 2h | - |

**验收**: 测试覆盖率报告 > 80%

---

### Phase 5: 性能与代码质量 (优先级 P2)

**目标**: 消除性能问题，提升代码质量

| 任务 | 预计耗时 | 依赖 |
|-----|---------|-----|
| 5.1 View 拆分优化重渲染 | 4h | Phase 2 |
| 5.2 大列表懒加载优化 | 3h | 5.1 |
| 5.3 图片缓存策略优化 | 2h | - |
| 5.4 SwiftFormat 统一代码风格 | 1h | - |
| 5.5 移除 @deprecated 代码 | 2h | Phase 2 |
| 5.6 补充缺失的文档注释 | 3h | - |

**验收**: Instruments 分析无明显性能问题

---

### Phase 6: 本地化与无障碍 (优先级 P2)

**目标**: 完善多语言支持和无障碍体验

| 任务 | 预计耗时 | 依赖 |
|-----|---------|-----|
| 6.1 检查所有硬编码字符串 | 2h | - |
| 6.2 补充缺失的本地化 key | 2h | 6.1 |
| 6.3 检查日期/数字格式化 | 1h | - |
| 6.4 VoiceOver 无障碍审计 | 3h | - |
| 6.5 动态字体支持检查 | 2h | - |

**验收**: 中英文切换正常，VoiceOver 可完整操作

---

## 5. 详细任务清单

### 5.1 Phase 1 详细任务

#### 1.1 DependencyFactory 增加 ViewModel 工厂方法

```swift
// DependencyFactory.swift 增加
protocol DependencyFactory: Sendable {
    // ... existing ...
    
    // MARK: - ViewModels
    
    /// 创建 LibraryViewModel
    func makeLibraryViewModel() -> LibraryViewModel
    
    /// 创建 DashboardViewModel  
    func makeDashboardViewModel() -> DashboardViewModel
    
    /// 创建 ReviewViewModel
    func makeReviewViewModel() -> ReviewViewModel
    
    /// 创建 CaptureViewModel
    func makeCaptureViewModel() -> CaptureViewModel
}
```

#### 1.2 LibraryView 改造

**改造前（问题代码）**:
```swift
struct LibraryView: View {
    @Query(sort: \ReviewItemModel.createdAt, order: .reverse)
    private var models: [ReviewItemModel]  // ❌ 直接依赖 SwiftData
    
    private var items: [ReviewItem] {
        models.map { ReviewItemMapper.toEntity(from: $0) }  // ❌ View 做转换
    }
}
```

**改造后**:
```swift
struct LibraryView: View {
    @Environment(\.dependencyFactory) private var factory
    @State private var viewModel: LibraryViewModel?
    
    var body: some View {
        Group {
            if let viewModel {
                LibraryContentView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .task {
            viewModel = await factory.makeLibraryViewModel()
            await viewModel?.loadItems()
        }
    }
}

struct LibraryContentView: View {
    @Bindable var viewModel: LibraryViewModel
    
    var body: some View {
        List(viewModel.filteredItems) { item in
            // ...
        }
    }
}
```

### 5.2 Phase 2 详细任务

#### 2.1 LibraryViewModel Use Case 集成

**改造后**:
```swift
@MainActor
@Observable
final class LibraryViewModel {
    
    // MARK: - Use Cases
    
    private let fetchItemsUseCase: FetchReviewItemsUseCaseProtocol
    private let deleteItemUseCase: DeleteReviewItemUseCaseProtocol
    private let updateItemUseCase: UpdateReviewItemUseCaseProtocol
    
    // MARK: - State
    
    private(set) var items: [ReviewItem] = []
    private(set) var isLoading = false
    private(set) var error: DomainError?
    
    // MARK: - Init
    
    init(
        fetchItemsUseCase: FetchReviewItemsUseCaseProtocol,
        deleteItemUseCase: DeleteReviewItemUseCaseProtocol,
        updateItemUseCase: UpdateReviewItemUseCaseProtocol
    ) {
        self.fetchItemsUseCase = fetchItemsUseCase
        self.deleteItemUseCase = deleteItemUseCase
        self.updateItemUseCase = updateItemUseCase
    }
    
    // MARK: - Actions
    
    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        
        items = await fetchItemsUseCase.execute(filter: currentFilter)
    }
    
    func deleteItem(_ item: ReviewItem) async throws {
        try await deleteItemUseCase.execute(item)
        await loadItems()
    }
}
```

### 5.3 Phase 3 详细任务

#### 3.1 统一错误处理示例

```swift
// ViewModel 错误处理
func loadItems() async {
    isLoading = true
    defer { isLoading = false }
    
    do {
        items = try await fetchItemsUseCase.execute()
    } catch let error as DomainError {
        self.error = error
        Analytics.track(.error, properties: [
            "type": "domain",
            "code": error.errorCode
        ])
    } catch let error as RepositoryError {
        self.error = .repositoryError(error)
    } catch {
        self.error = .unknown(error)
    }
}

// View 错误展示
struct LibraryContentView: View {
    @Bindable var viewModel: LibraryViewModel
    
    var body: some View {
        content
            .overlay {
                if let error = viewModel.error {
                    ErrorView(error: error) {
                        viewModel.dismissError()
                    }
                }
            }
    }
}
```

---

## 6. 风险与缓解措施

| 风险 | 概率 | 影响 | 缓解措施 |
|-----|-----|-----|---------|
| 重构引入回归 Bug | 高 | 高 | 每步有测试覆盖，增量提交 |
| 性能下降 | 中 | 中 | Phase 5 专项优化，建立基准 |
| 进度延期 | 中 | 中 | P0 任务优先，P2 可延后 |
| SwiftData 兼容问题 | 低 | 高 | 保留 @Query 回退方案 |
| 团队学习成本 | 中 | 低 | 充分文档 + 代码注释 |

---

## 7. 验收标准

### 7.1 架构合规检查

- [ ] 所有 View 中无 `@Query` 直接使用
- [ ] ViewModel 只依赖 Use Case Protocol
- [ ] Use Case 只依赖 Repository Protocol
- [ ] Domain 层无外层依赖
- [ ] DependencyFactory 创建所有依赖

### 7.2 代码质量检查

- [ ] 所有公开 API 有文档注释
- [ ] 无硬编码字符串
- [ ] 无编译警告
- [ ] SwiftLint 零违规
- [ ] 所有 async 方法有 @MainActor 或明确线程标注

### 7.3 测试覆盖检查

- [ ] Use Case 测试覆盖率 > 90%
- [ ] ViewModel 测试覆盖率 > 80%
- [ ] Repository 测试覆盖率 > 80%
- [ ] 集成测试覆盖关键流程

### 7.4 性能检查

- [ ] 启动时间 < 1s（冷启动）
- [ ] 列表滚动 60fps
- [ ] 内存占用合理（< 100MB 常规使用）
- [ ] 无内存泄漏

### 7.5 用户体验检查

- [ ] VoiceOver 完整可用
- [ ] 动态字体支持
- [ ] 中英文切换正常
- [ ] 深色模式适配

---

## 📅 执行时间线

```
Week 1:
├── Day 1-2: Phase 1（核心架构对齐）
├── Day 3-4: Phase 2（Use Case 集成）
└── Day 5: 代码审查 + Bug 修复

Week 2:
├── Day 1-2: Phase 3（错误处理）
├── Day 3-4: Phase 4（测试补充）
└── Day 5: 集成测试 + 性能基准

Week 3:
├── Day 1-2: Phase 5（性能优化）
├── Day 3-4: Phase 6（本地化 + 无障碍）
└── Day 5: 最终验收 + 文档更新
```

---

## 🚀 开始执行

准备好开始了吗？建议按以下顺序执行：

1. **首先执行 Phase 1.1**: 完善 DependencyFactory
2. **然后并行执行 Phase 1.2-1.5**: 各 View 移除 @Query
3. **最后执行 Phase 2**: ViewModel 集成 Use Cases

是否现在开始执行 Phase 1？
