# Technical Debt Ledger（技术债分类账）

> **上游依赖**：`principles.md`（技术债标记）、`decisions/`（ADR 技术债节）
> **下游影响**：无
>
> 本文件是架构级技术债的**汇总索引**——只收录有决策上下文、不适合用 Issue 追踪的长期架构约束。
> 源头在 `principles.md` 和 ADR 中，本文件指向它们，不重复内容。
> 有明确修复动作的日常技术债 → 创建 GitHub Issue 并打 `tech-debt` label。

---

## 入选标准

同时满足以下两条才收录：

1. **有决策上下文**——不是简单的 TODO，而是「因为 X 原因选择了次优方案 Y，当 Z 时重新评估」
2. **不适合用 Issue 追踪**——长期架构约束或等待外部条件，无明确的单次 fix action

---

## 活跃技术债

### 等待外部条件

| ID | 描述 | 来源 | 偿还条件 |
|---|---|---|---|
| TD-1 | LibraryViewModel tags 过滤在内存端处理（SwiftData many-to-many `#Predicate` 不支持） | [ADR-006](decisions/ADR-006-swiftdata-over-coredata.md) 技术债节 | Apple 完善 SwiftData many-to-many Predicate 支持 |

### 等待内部里程碑

| ID | 描述 | 来源 | 偿还条件 |
|---|---|---|---|
| TD-2 | 6 个 `.shared` 单例（CaptureDraftService、PDFExportService、PerformanceMonitor、NetworkMonitor、AppConfiguration、OnboardingManager）待迁移到 DI 注入；部分具体实现暂留 Core 包 | [principles.md](principles.md) 技术债标记 + [ADR-003](decisions/ADR-003-five-package-structure.md) + [ADR-004](decisions/ADR-004-dependency-injection-pattern.md) 技术债节 | Core → Core + Services 拆包时统一清理 |

### 渐进消解

| ID | 描述 | 来源 | 偿还条件 |
|---|---|---|---|
| TD-3 | `NotificationCenter.reviewDataDidChange` 跨模块刷新通知 | [principles.md](principles.md) 技术债标记 | @Query 被引入到更多 View 后自然消解 |

---

## 已偿还（归档）

_暂无。偿还时从上方移至此处，注明日期和 PR。_
