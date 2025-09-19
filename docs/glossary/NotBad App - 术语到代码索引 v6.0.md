# NotBad App - 术语到代码索引 v6.0 (Swift 6.2 + iOS 26)

## 文档定位：术语→代码映射索引 (Terms to Code Mapping Index)

本文档建立PRD/TDD业务术语到Swift代码实现的精确映射关系，为开发团队提供从概念到代码的直接跳转路径。基于Swift 6.2 + iOS 26技术栈，确保业务语言与技术实现的完美对齐。

## 文档治理与变更流程

- **同步更新**: 代码结构变更时，索引必须同步更新
- **命名一致**: 代码符号应优先采用术语表中的标准命名
- **单一事实来源**: 本索引为术语→代码映射的权威参考
- **开发指导**: 新功能开发前应查阅本索引确保命名一致性

## 速查：相关文档（快速跳转）

- 文档索引: [docs/README.md](../README.md)
- PRD: [docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.0.md](../prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.0.md)
- TDD: [docs/tdd/NotBad 错题本 App - 技术设计文档 (TDD) v6.0.md](../tdd/NotBad%20错题本%20App%20-%20技术设计文档%20(TDD)%20v6.0.md)
- RTM: [docs/rtm/NotBad App - 需求追踪矩阵 (RTM) v6.0.md](../rtm/NotBad%20App%20-%20需求追踪矩阵%20(RTM)%20v6.0.md)
- 业务术语表: [docs/glossary/NotBad App - 业务术语表 v6.0.md](NotBad%20App%20-%20业务术语表%20v6.0.md)
- 技术术语表: [docs/glossary/NotBad App - 技术术语表 v6.0.md](NotBad%20App%20-%20技术术语表%20v6.0.md)

| 版本 | 日期 | 作者 | 变更说明 | 状态 |
| :---- | :---- | :---- | :---- | :---- |
| v1.0 | 2025-09-04 | Tech Team | 基于PRD v4.0和TDD v4.0的基础代码映射 | 已归档 |
| **v6.0** | **2025-09-19** | **Tech Team** | **🚀 Swift 6.2 + iOS 26架构升级，完整代码映射体系** | ✅ **生效中** |

## 1. 核心领域实体映射 (Domain Entities Mapping)

### 1.1 错题管理实体

| 术语 (中文) | 建议代码符号 (Swift 6.2) | 文件路径 | 说明/特性 |
|-------------|--------------------------|----------|----------|
| **错题/复习项** | `struct ReviewItem: Sendable` | `Sources/Domain/Entities/ReviewItem.swift` | 核心领域实体，Swift 6.2 Sendable保证并发安全 |
| **错题内容** | `struct ReviewContent: Codable, Sendable` | `Sources/Domain/ValueObjects/ReviewContent.swift` | 题目文本/图片，Enhanced Pattern Matching支持 |
| **错题元数据** | `struct ReviewItemMetadata: Sendable` | `Sources/Domain/ValueObjects/ReviewItemMetadata.swift` | ownerId, privacyLevel, shareStatus等 |
| **学习记录** | `struct StudyRecord: Sendable` | `Sources/Domain/Entities/StudyRecord.swift` | 复习会话时间戳，支持并发写入 |
| **掌握度** | `enum MasteryLevel: Sendable, CaseIterable` | `Sources/Domain/ValueObjects/MasteryLevel.swift` | 未掌握/模糊/已掌握，Swift 6.2枚举增强 |
| **隐私级别** | `enum PrivacyLevel: String, Codable, Sendable` | `Sources/Domain/ValueObjects/PrivacyLevel.swift` | 高/中/低敏感度分级 |

### 1.2 用户管理实体

| 术语 (中文) | 建议代码符号 (Swift 6.2) | 文件路径 | 说明/特性 |
|-------------|--------------------------|----------|----------|
| **用户档案** | `struct UserProfile: Sendable` | `Sources/Domain/Entities/UserProfile.swift` | 用户基础信息，支持Actor隔离 |
| **隐私设置** | `struct UserPrivacySettings: Sendable` | `Sources/Domain/ValueObjects/UserPrivacySettings.swift` | 年龄分层，家长同意状态 |
| **年龄组** | `enum AgeGroup: String, Codable, Sendable` | `Sources/Domain/ValueObjects/AgeGroup.swift` | under13/teen13to17/adult18plus |
| **数据收集级别** | `enum DataCollectionLevel: Sendable` | `Sources/Domain/ValueObjects/DataCollectionLevel.swift` | minimal/standard/enhanced |

### 1.3 Discovery社区实体 🆕

| 术语 (中文) | 建议代码符号 (Swift 6.2) | 文件路径 | 说明/特性 |
|-------------|--------------------------|----------|----------|
| **社区帖子** | `struct DiscoveryPost: Sendable` | `Sources/Domain/Entities/DiscoveryPost.swift` | 匿名化社区内容，无个人标识 |
| **匿名内容** | `struct AnonymizedContent: Sendable` | `Sources/Domain/ValueObjects/AnonymizedContent.swift` | 完全匿名化的学习内容 |
| **审核状态** | `enum ModerationStatus: String, Sendable` | `Sources/Domain/ValueObjects/ModerationStatus.swift` | pending/approved/flagged/rejected |
| **社区互动** | `struct CommunityInteraction: Sendable` | `Sources/Domain/Entities/CommunityInteraction.swift` | 点赞、评论等匿名互动 |

## 2. Swift 6.2 服务层映射 (Service Layer Mapping)

### 2.1 并发安全服务

| 术语 (中文) | 建议代码符号 (Swift 6.2) | 文件路径 | 并发特性 |
|-------------|--------------------------|----------|----------|
| **OCR处理器** | `actor OCRProcessor` | `Sources/Infrastructure/OCR/OCRProcessor.swift` | Enhanced Actor Isolation，线程安全 |
| **数据同步协调器** | `actor SyncCoordinator` | `Sources/Infrastructure/Sync/SyncCoordinator.swift` | Actor重入性控制 |
| **批量处理器** | `actor BatchProcessor` | `Sources/Infrastructure/Processing/BatchProcessor.swift` | Improved TaskGroup批量处理 |
| **内存管理器** | `@MainActor class MemoryManager` | `Sources/Infrastructure/Memory/MemoryManager.swift` | MainActor UI更新协调 |

### 2.2 AI与识别服务

| 术语 (中文) | 建议代码符号 (Swift 6.2) | 文件路径 | iOS 26特性 |
|-------------|--------------------------|----------|------------|
| **增强Vision服务** | `class EnhancedVisionOCRService` | `Sources/Infrastructure/OCR/EnhancedVisionOCRService.swift` | iOS 26 Advanced Vision Framework |
| **设备端AI服务** | `actor LocalAIService` | `Sources/Infrastructure/AI/LocalAIService.swift` | iOS 26 Neural Engine优化 |
| **混合AI服务** | `class HybridAIService` | `Sources/Infrastructure/AI/HybridAIService.swift` | 本地+云端AI智能切换 |
| **内容审核服务** | `actor ContentModerationService` | `Sources/Infrastructure/Moderation/ContentModerationService.swift` | AI+人工双重审核 |

### 2.3 数据持久化服务

| 术语 (中文) | 建议代码符号 (Swift 6.2) | 文件路径 | SwiftData特性 |
|-------------|--------------------------|----------|---------------|
| **持久化控制器** | `@MainActor class PersistenceController` | `Sources/Infrastructure/Persistence/PersistenceController.swift` | iOS 26 Enhanced SwiftData |
| **CloudKit同步服务** | `actor EnhancedCloudKitService` | `Sources/Infrastructure/Sync/EnhancedCloudKitService.swift` | iOS 26 Advanced CloudKit |
| **数据备份管理器** | `class BackupManager` | `Sources/Infrastructure/Backup/BackupManager.swift` | 自动备份恢复 |
| **冲突解决器** | `actor ConflictResolver` | `Sources/Infrastructure/Sync/ConflictResolver.swift` | 智能冲突处理 |

## 3. 应用层用例映射 (Use Case Layer Mapping)

### 3.1 核心业务用例

| 术语 (中文) | 建议代码符号 (Swift 6.2) | 文件路径 | 业务逻辑 |
|-------------|--------------------------|----------|----------|
| **创建复习项用例** | `class CreateReviewItemUseCase` | `Sources/Application/UseCases/CreateReviewItemUseCase.swift` | OCR+分类+存储完整流程 |
| **智能复习用例** | `class IntelligentReviewUseCase` | `Sources/Application/UseCases/IntelligentReviewUseCase.swift` | 基于遗忘曲线的复习计划 |
| **批量处理用例** | `class BatchProcessingUseCase` | `Sources/Application/UseCases/BatchProcessingUseCase.swift` | Improved TaskGroup并发处理 |
| **错题搜索用例** | `class SearchReviewItemsUseCase` | `Sources/Application/UseCases/SearchReviewItemsUseCase.swift` | Enhanced Collections高性能搜索 |

### 3.2 Discovery社区用例 🆕

| 术语 (中文) | 建议代码符号 (Swift 6.2) | 文件路径 | 隐私保护 |
|-------------|--------------------------|----------|----------|
| **匿名分享用例** | `class AnonymousShareUseCase` | `Sources/Application/UseCases/AnonymousShareUseCase.swift` | 完全移除个人标识 |
| **内容审核用例** | `class ContentModerationUseCase` | `Sources/Application/UseCases/ContentModerationUseCase.swift` | AI+人工双重审核 |
| **社区发现用例** | `class CommunityDiscoveryUseCase` | `Sources/Application/UseCases/CommunityDiscoveryUseCase.swift` | 个性化内容推荐 |

### 3.3 Premium订阅用例

| 术语 (中文) | 建议代码符号 (Swift 6.2) | 文件路径 | 商业逻辑 |
|-------------|--------------------------|----------|----------|
| **订阅管理用例** | `class SubscriptionManagementUseCase` | `Sources/Application/UseCases/SubscriptionManagementUseCase.swift` | Premium功能控制 |
| **配额检查用例** | `class QuotaValidationUseCase` | `Sources/Application/UseCases/QuotaValidationUseCase.swift` | 1500题/月免费额度 |
| **功能降级用例** | `class FeatureDegradationUseCase` | `Sources/Application/UseCases/FeatureDegradationUseCase.swift` | 优雅的功能降级 |

## 4. 表现层组件映射 (Presentation Layer Mapping)

### 4.1 SwiftUI视图组件

| 术语 (中文) | 建议代码符号 (Swift 6.2) | 文件路径 | UI特性 |
|-------------|--------------------------|----------|--------|
| **主界面** | `struct MainTabView: View` | `Sources/Presentation/Views/MainTabView.swift` | iOS 26 SwiftUI增强 |
| **拍照录入界面** | `struct CameraCaptureyView: View` | `Sources/Presentation/Views/CameraCaptureView.swift` | ProMotion Max流畅体验 |
| **复习卡片界面** | `struct ReviewCardView: View` | `Sources/Presentation/Views/ReviewCardView.swift` | 120fps滚动优化 |
| **Discovery社区界面** | `struct DiscoveryFeedView: View` | `Sources/Presentation/Views/DiscoveryFeedView.swift` | 匿名社区内容展示 |

### 4.2 视图模型 (MVVM)

| 术语 (中文) | 建议代码符号 (Swift 6.2) | 文件路径 | 状态管理 |
|-------------|--------------------------|----------|----------|
| **主界面视图模型** | `@MainActor class MainTabViewModel: ObservableObject` | `Sources/Presentation/ViewModels/MainTabViewModel.swift` | MainActor UI状态管理 |
| **OCR视图模型** | `@MainActor class OCRViewModel: ObservableObject` | `Sources/Presentation/ViewModels/OCRViewModel.swift` | OCR处理状态协调 |
| **复习视图模型** | `@MainActor class ReviewViewModel: ObservableObject` | `Sources/Presentation/ViewModels/ReviewViewModel.swift` | 复习进度状态 |
| **社区视图模型** | `@MainActor class CommunityViewModel: ObservableObject` | `Sources/Presentation/ViewModels/CommunityViewModel.swift` | 社区内容状态 |

## 5. 安全隐私组件映射 (Security & Privacy Mapping)

### 5.1 加密安全服务

| 术语 (中文) | 建议代码符号 (Swift 6.2) | 文件路径 | 安全特性 |
|-------------|--------------------------|----------|----------|
| **加密服务** | `actor EncryptionService` | `Sources/Infrastructure/Security/EncryptionService.swift` | AES-256 + Keychain |
| **隐私保护服务** | `actor PrivacyProtectionService` | `Sources/Infrastructure/Privacy/PrivacyProtectionService.swift` | 数据分类保护 |
| **合规管理器** | `@MainActor class ComplianceManager` | `Sources/Infrastructure/Compliance/ComplianceManager.swift` | COPPA/GDPR合规 |
| **访问控制服务** | `actor AccessControlService` | `Sources/Infrastructure/Security/AccessControlService.swift` | 年龄分层访问控制 |

### 5.2 年龄保护组件

| 术语 (中文) | 建议代码符号 (Swift 6.2) | 文件路径 | 保护机制 |
|-------------|--------------------------|----------|----------|
| **年龄验证器** | `class AgeVerificationService` | `Sources/Infrastructure/Privacy/AgeVerificationService.swift` | 年龄闸门验证 |
| **家长同意管理器** | `class ParentalConsentManager` | `Sources/Infrastructure/Privacy/ParentalConsentManager.swift` | 13岁以下保护 |
| **数据匿名化器** | `actor DataAnonymizer` | `Sources/Infrastructure/Privacy/DataAnonymizer.swift` | Discovery内容匿名化 |

## 6. 性能监控组件映射 (Performance Monitoring Mapping)

### 6.1 性能监控服务

| 术语 (中文) | 建议代码符号 (Swift 6.2) | 文件路径 | 监控指标 |
|-------------|--------------------------|----------|----------|
| **性能监控器** | `actor PerformanceMonitor` | `Sources/Infrastructure/Monitoring/PerformanceMonitor.swift` | 启动时间、内存使用 |
| **分析服务** | `actor AnalyticsService` | `Sources/Infrastructure/Analytics/AnalyticsService.swift` | 结构化事件上报 |
| **崩溃报告器** | `class CrashReporter` | `Sources/Infrastructure/Monitoring/CrashReporter.swift` | 崩溃日志收集 |
| **指标计算器** | `actor MetricsCalculator` | `Sources/Domain/Services/MetricsCalculator.swift` | L1/L2/L3业务指标 |

### 6.2 分析事件定义

| 术语 (中文) | 建议代码符号 (Swift 6.2) | 文件路径 | 事件类型 |
|-------------|--------------------------|----------|----------|
| **分析事件** | `enum AnalyticsEvent: Sendable` | `Sources/Infrastructure/Analytics/AnalyticsEvent.swift` | 用户行为事件 |
| **性能指标** | `enum PerformanceMetric: Sendable` | `Sources/Infrastructure/Monitoring/PerformanceMetric.swift` | 性能监控指标 |
| **业务事件** | `enum BusinessEvent: Sendable` | `Sources/Domain/Events/BusinessEvent.swift` | 业务流程事件 |

## 7. 测试组件映射 (Testing Components Mapping)

### 7.1 Swift 6.2 测试框架

| 测试类型 | 建议代码符号 (Swift 6.2) | 文件路径 | 测试特性 |
|----------|--------------------------|----------|----------|
| **领域测试** | `@Test class ReviewItemTests` | `Tests/DomainTests/ReviewItemTests.swift` | Swift Testing新框架 |
| **用例测试** | `@Test class CreateReviewItemUseCaseTests` | `Tests/ApplicationTests/CreateReviewItemUseCaseTests.swift` | 业务逻辑测试 |
| **OCR测试** | `@Test class OCRPerformanceTests` | `Tests/InfrastructureTests/OCRPerformanceTests.swift` | 性能基准测试 |
| **UI测试** | `class MainFlowUITests: XCTestCase` | `UITests/MainFlowUITests.swift` | XCUITest端到端测试 |

### 7.2 测试工具类

| 测试工具 | 建议代码符号 (Swift 6.2) | 文件路径 | 工具功能 |
|----------|--------------------------|----------|----------|
| **模拟仓储** | `actor MockRepository` | `Tests/Mocks/MockRepository.swift` | 数据层模拟 |
| **测试工厂** | `struct TestDataFactory` | `Tests/Helpers/TestDataFactory.swift` | 测试数据生成 |
| **性能测试助手** | `class PerformanceTestHelper` | `Tests/Helpers/PerformanceTestHelper.swift` | 性能指标验证 |

## 8. 配置与工具映射 (Configuration & Tools Mapping)

### 8.1 项目配置

| 配置类型 | 建议代码符号/文件 | 文件路径 | 配置内容 |
|----------|------------------|----------|----------|
| **应用配置** | `struct AppConfiguration` | `Sources/Infrastructure/Config/AppConfiguration.swift` | 环境配置、功能开关 |
| **构建配置** | `Package.swift` | `Package.swift` | Swift 6.2包管理 |
| **CI/CD配置** | `.github/workflows/ios.yml` | `.github/workflows/ios.yml` | GitHub Actions |
| **代码质量** | `.swiftlint.yml` | `.swiftlint.yml` | SwiftLint规则 |

### 8.2 开发工具

| 工具类型 | 建议代码符号/脚本 | 文件路径 | 工具功能 |
|----------|------------------|----------|----------|
| **代码生成器** | `generate_stubs.py` | `Scripts/generate_stubs.py` | 代码模板生成 |
| **性能分析** | `performance_analyzer.py` | `Scripts/performance_analyzer.py` | 性能数据分析 |
| **测试覆盖率** | `coverage_report.sh` | `Scripts/coverage_report.sh` | 覆盖率报告 |

## 9. 文档映射 (Documentation Mapping)

### 9.1 技术文档

| 文档类型 | 文档路径 | 对应代码模块 |
|----------|----------|-------------|
| **架构决策记录** | `docs/adr/ADR-007-Swift6.2-并发架构升级.md` | Actor并发架构 |
| **API文档** | `docs/api/` | 所有Public接口 |
| **部署指南** | `docs/deployment/` | CI/CD配置 |

### 9.2 开发指南

| 指南类型 | 文档路径 | 使用场景 |
|----------|----------|----------|
| **Swift 6.2迁移指南** | `docs/guides/swift62-migration.md` | 代码升级参考 |
| **并发编程指南** | `docs/guides/concurrency-guide.md` | Actor使用规范 |
| **测试编写指南** | `docs/guides/testing-guide.md` | 测试最佳实践 |

## 10. 使用指南 (Usage Guidelines)

### 开发流程规范

1. **新功能开发**: 先查阅术语表确定概念，再查阅本索引确定代码结构
2. **命名规范**: 优先使用索引中的建议命名，保持术语一致性
3. **架构对齐**: 新代码必须符合Clean Architecture分层结构
4. **并发安全**: 所有新服务必须考虑Swift 6.2并发安全

### 代码维护规范

1. **索引更新**: 新增代码文件后及时更新本索引
2. **重构同步**: 代码重构时同步更新术语映射
3. **文档一致**: 确保代码注释与术语表保持一致
4. **版本同步**: 主要架构变更时更新索引版本

## 变更日志 (Change Log)

**v6.0 (2025-09-19)**: Swift 6.2 + iOS 26 完整代码映射体系

- **Swift 6.2架构**: Enhanced Actor、Improved TaskGroup、Enhanced Sendable全面映射
- **iOS 26特性**: Advanced Vision、Enhanced SwiftData、ProMotion Max代码映射
- **Discovery社区**: 匿名化架构、内容审核、社区互动完整代码结构
- **隐私保护**: COPPA/GDPR合规、数据分类、年龄分层代码实现映射
- **性能监控**: 结构化日志、指标计算、崩溃报告代码映射
- **测试架构**: Swift Testing新框架、性能测试、UI测试完整映射
- **开发工具**: CI/CD、代码质量、部署配置完整映射

**v1.0 (2025-09-04)**: 基于PRD v4.0和TDD v4.0的基础代码映射 (已归档)

---

**维护说明**: 本索引应与代码实现保持严格同步，任何代码结构变更都应及时反映到索引中
**使用建议**: 开发团队应将本索引作为代码导航的主要参考，确保业务概念与技术实现的一致性
**最后更新**: 2025年9月19日 - 术语代码索引v6.0完整映射体系建立完成
