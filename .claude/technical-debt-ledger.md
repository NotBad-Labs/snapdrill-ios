# Technical Debt Ledger（技术债分类账）

> 架构级技术债汇总。日常技术债用 GitHub Issue + `tech-debt` label 追踪。

---

## 活跃技术债

| ID | 描述 | 偿还条件 |
|---|---|---|
| TD-1 | LibraryViewModel tags 过滤在内存端处理（SwiftData many-to-many `#Predicate` 不支持） | Apple 完善 SwiftData many-to-many Predicate 支持 |
| TD-2 | 5 个 `.shared` 单例待迁移到 DI 注入（CaptureDraftService、PDFExportService、AppConfiguration、OnboardingManager、PrivacyConsentService） | Core → Core + Services 拆包时统一清理 |
| TD-3 | `NotificationCenter.reviewDataDidChange` 跨模块刷新通知 | @Query 被引入到更多 View 后自然消解 |
