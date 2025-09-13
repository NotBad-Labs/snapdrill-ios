# NotBad App - 术语 → 代码 索引 v4.2 (Swift6 + iOS18)

目的：把 PRD/TDD/RTM 中的核心术语映射到代码符号（Swift 协议/类型/函数名）和建议的文件路径，方便开发团队快速定位实现点与对齐命名。

说明：以下路径/符号为建议约定（与 TDD 中使用的名称保持一致）。如果代码实现路径不同，请把此文件作为单一事实来源并在需要时更新。

| 术语 (中文) | 建议代码符号 (Swift) | 建议文件/模块路径 | 说明/备注 |
| :---- | :---- | :---- | :---- |
| 复习项 | `struct ReviewItem` | `Sources/Domain/Entities/ReviewItem.swift` | 核心领域实体，包含 content/metadata/studyHistory/masteryLevel |
| ReviewContent | `struct ReviewContent` | `Sources/Domain/ValueObjects/ReviewContent.swift` | 题目文本/图片描述等 |
| ReviewMetadata | `struct ReviewItemMetadata` | `Sources/Domain/ValueObjects/ReviewItemMetadata.swift` | 包含 ownerId, parentShareStatus, parentAccessRevokedAt, sharedWithClassIds |
| StudyRecord | `struct StudyRecord` | `Sources/Domain/Entities/StudyRecord.swift` | 记录复习会话与时间戳 |
| MasteryLevel | `enum MasteryLevel` | `Sources/Domain/ValueObjects/MasteryLevel.swift` | 未掌握/模糊/已掌握 |
| 指标计算器（L1/L2/L3） | `protocol MetricsCalculator`<br>`func calculateMARU(...)` | `Sources/Domain/Services/MetricsCalculator.swift` | 计算 MARU/MRU/MMU 的契约（见 TDD） |
| 埋点事件 | `enum AnalyticsEvent` | `Sources/Infrastructure/Analytics/AnalyticsEvent.swift` | 列出 `reviewItemCreated`, `studySessionCompleted`, `itemMarkedMastered`, `parentAccessRevoked`, `teacherClassCreated` 等 |
| 家长访问服务 | `protocol ParentAccessService` | `Sources/Domain/Services/ParentAccessService.swift` | request/approve/revoke/getAccessLog，撤销需本地即时生效并异步同步 |
| 班级管理服务 | `protocol ClassManagementService` | `Sources/Domain/Services/ClassManagementService.swift` | createClass/generateInviteCode/assignHomework/getAnonymizedStats |
| ClassStats | `struct ClassStats` | `Sources/Domain/DTOs/ClassStats.swift` | 匿名聚合统计数据结构 |
| AccessRecord | `struct AccessRecord` | `Sources/Domain/DTOs/AccessRecord.swift` | 家长访问审计记录（who/when/action/itemId） |
| OCR 服务 | `protocol OCRService`<br>`func reprocess(image:)` | `Sources/Infrastructure/OCR/OCRService.swift`<br>`Sources/Infrastructure/OCR/VisionOCRService.swift` | 支持 reprocess/候选结果/置信度字段 |
| AI 分析服务 | `protocol AIAnalysisService` / `class HybridAIService` | `Sources/Infrastructure/AI/HybridAIService.swift` | 本地 CoreML 与云端混合选择策略（Pro 优先云端） |
| 同步服务 | `protocol SyncService` / `class CloudKitSyncService` | `Sources/Infrastructure/Sync/CloudKitSyncService.swift` | 包含 conflict resolution, quota monitoring hook |
| Subscription 管理 | `class SubscriptionManager` | `Sources/Infrastructure/Billing/SubscriptionManager.swift` | StoreKit 集成、优雅降级逻辑 |
| 配额服务 | `class QuotaService` | `Sources/Infrastructure/Quota/QuotaService.swift` | CloudKit 配额监控与本地限流逻辑 |
| Use Case: 创建复习项 | `class CreateReviewItemUseCase` | `Sources/Application/UseCases/CreateReviewItemUseCase.swift` | Use case 层实现复习项创建逻辑 |
| Use Case: 学习会话 | `class StudySessionUseCase` | `Sources/Application/UseCases/StudySessionUseCase.swift` | 管理 study session 的开始/结束/计数 |
| Redo 模板服务 | `class RedoTemplateService` | `Sources/Infrastructure/Redo/RedoTemplateService.swift` | 生成重做模板、遮蔽答案区域 |
| 批量导入服务 | `protocol BatchImportService` | `Sources/Infrastructure/Import/BatchImportService.swift` | 从相册批量导入图片，支持并发处理 |
| 遗忘曲线服务 | `protocol ForgettingCurveService` | `Sources/Domain/Services/ForgettingCurveService.swift` | 计算最佳复习时间，个性化学习提醒 |
| 性能监控服务 | `protocol PerformanceMonitoringService` | `Sources/Infrastructure/Monitoring/PerformanceMonitoringService.swift` | 追踪启动时间、OCR处理时间、同步延迟等 |
| 教师作业进度 | `struct AssignmentProgress` | `Sources/Domain/DTOs/AssignmentProgress.swift` | 作业完成统计、难点分析 |
| Feature Flag | `struct FeatureFlags` / `enum Feature` | `Sources/Infrastructure/Config/FeatureFlags.swift` | 在运行时切换云AI/教师功能/大容量历史版本等 |
| ADR 文件 | `docs/adr/ADR-005-导航协调器模式.md`<br>`docs/adr/ADR-006-底部Tab导航架构设计.md` | `docs/adr/` | 记录导航架构和协调器模式决策 |


## 如何使用
1. 开发者可在代码实现前检索本表，确保命名与 TDD/术语表一致。  
2. 若实际代码文件路径或名称不同，请在 PR 中更新本索引（始终以本文件为单一事实来源）。  
3. 我可以根据需要把这些建议符号生成为代码 stub（Swift 协议/structs）到 `Sources/` 下以便开发直接开始实现——如需要，请回复“生成 stubs”。

## 变更记录
- v1.2 (2025-09-13): 新增底部Tab导航架构相关的术语和代码映射
- v1.1 (2025-09-13): 补充批量导入、遗忘曲线、性能监控等新增服务的代码映射
- v1.0 (2025-09-04): 初始索引，基于 PRD v4.0 / TDD v4.0 / RTM v2.0

## 导航架构术语映射

| 术语 (中文) | 建议代码符号 (Swift) | 建议文件/模块路径 | 说明/备注 |
| :---- | :---- | :---- | :---- |
| 底部Tab导航 | `struct MainTabView` | `Sources/Shared/Views/MainTabView.swift` | 5个Tab的主界面导航容器 |
| 首页Tab | `struct HomeTabView` | `Sources/Features/Home/Views/HomeTabView.swift` | 学习总览和快速入口 |
| 题库Tab | `struct QuestionBankTabView` | `Sources/Features/QuestionBank/Views/QuestionBankTabView.swift` | ReviewItem管理和分类 |
| 录入Tab | `struct CaptureTabView` | `Sources/Features/Capture/Views/CaptureTabView.swift` | OCR拍照识别功能 |
| 发现Tab | `struct DiscoverTabView` | `Sources/Features/Discover/Views/DiscoverTabView.swift` | 学习社区和资源推荐 |
| 我的Tab | `struct ProfileTabView` | `Sources/Features/Profile/Views/ProfileTabView.swift` | 个人设置和账户管理 |

***

如果你同意，我会把该文件 commit 并 push 到 `cr/prd-adjust-subscription`。如果需要把索引扩展为“术语 -> 文档链接 -> 代码路径”的更大表格，我也可以扩展。
