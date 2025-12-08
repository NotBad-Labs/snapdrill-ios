# ADR-001: 采用 Clean Architecture

## 状态
**已废弃** — 被 [ADR-006](../../adr/ADR-006-pragmatic-architecture.md) 取代

> ⚠️ 本决策已于 2025年12月6日废弃。项目转向实用主义架构，详见 ADR-006。

## 日期
2025年12月

## 上下文

NotBad 是一个错题本 iOS 应用，需要：
- 长期可维护性：作为学习工具，需要持续迭代
- 高可测试性：确保复习算法等核心逻辑正确
- 技术栈独立性：UI 框架和数据层可能随 Apple 更新而变化
- 团队协作友好：清晰的边界便于分工

传统 MVC/MVVM 在应用规模增长时容易出现：
- ViewController/ViewModel 膨胀
- 业务逻辑与 UI 耦合
- 难以单元测试
- 数据层变更影响全局

## 决策

采用 **Clean Architecture** 分层架构，将应用划分为以下层次：

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│    (SwiftUI Views, ViewModels)          │
├─────────────────────────────────────────┤
│           Application Layer             │
│         (Use Cases, DTOs)               │
├─────────────────────────────────────────┤
│             Domain Layer                │
│   (Entities, Repository Protocols)      │
├─────────────────────────────────────────┤
│         Infrastructure Layer            │
│      (DI, Logging, Analytics)           │
├─────────────────────────────────────────┤
│             Data Layer                  │
│  (SwiftData, Repository Implementations)│
└─────────────────────────────────────────┘
```

### 依赖规则
- 依赖方向：外层 → 内层
- Domain 层不依赖任何外层
- Application 层只依赖 Domain
- Data 层实现 Domain 层定义的协议

## 选项考虑

### 选项 A: 传统 MVVM
- ✅ 简单直接，Swift/SwiftUI 生态常见
- ✅ 学习成本低
- ❌ ViewModel 容易膨胀
- ❌ 业务逻辑复用困难
- ❌ 测试需要 mock UI 相关依赖

### 选项 B: Clean Architecture
- ✅ 清晰的职责分离
- ✅ 高度可测试（纯业务逻辑层）
- ✅ 便于技术栈迁移
- ✅ 支持复杂业务场景
- ❌ 初期设置成本较高
- ❌ 小功能也需要多层代码

### 选项 C: TCA (The Composable Architecture)
- ✅ 状态管理优秀
- ✅ 可组合性强
- ❌ 学习曲线陡峭
- ❌ 额外依赖 (Point-Free 库)
- ❌ 与 SwiftUI 原生模式差异大

## 后果

### 正面
1. **高测试覆盖率**：489 个测试覆盖核心逻辑
2. **技术栈独立**：成功从 Core Data 迁移到 SwiftData
3. **职责清晰**：每层边界明确，代码易于定位
4. **复用性好**：Use Cases 可在不同 UI 场景复用

### 负面
1. **代码量增加**：简单功能也需要多层代码
2. **学习成本**：新成员需要理解分层规则
3. **过度设计风险**：小项目可能显得繁重

## 目录结构

```
NotBad/
├── Domain/              # 领域层
│   ├── Entities/        # 业务实体
│   ├── Repositories/    # Repository 协议
│   └── Errors/          # 领域错误
├── Application/         # 应用层
│   ├── UseCases/        # 用例
│   └── DTOs/            # 数据传输对象
├── Data/                # 数据层
│   ├── SwiftData/       # 持久化实现
│   └── Repositories/    # Repository 实现
├── Infrastructure/      # 基础设施层
│   ├── DI/              # 依赖注入
│   └── Logging/         # 日志
└── Presentation/        # 表现层
    ├── Views/           # SwiftUI 视图
    └── ViewModels/      # ViewModel
```

## 参考

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- iOS Clean Architecture with SwiftUI（参考链接待更新）
