---
last_verified: 2026-05-20
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# SnapDrill 文档体系语义层审计报告【维度 4：技术↔产品对齐】

> **版本**：2026-05-20 | **审计员**：Antigravity (Gemini 3.5 Flash (High)) 独立审计
> **审计范围**：
> - `docs/tech/architecture.md` (核心架构文档)
> - `docs/tech/non-functional-requirements.md` (NFR 指标)
> - `docs/tech/apple-limits.md` (Apple 平台能力边界)
> - `docs/tech/api-pitfalls.md` (API 踩坑)
> - `docs/tech/compliance.md` (隐私合规)
> - `docs/tech/deployment.md` (CI/CD 发布)
> - `Packages/SnapDrillCore/Sources/` (核心服务代码)
> - `Packages/SnapDrillData/Sources/` (数据层代码)
>
> **审计目的**：核对技术设计和实际代码实现是否真正服务于 Vision 核心价值链「采集 → 管理 → 导出/打印」，寻找在 DI、数据流并发、多 Profile、以及通知系统上的底层实现与产品原意漂移点。
>
> **审计纪律**：基于 F-008 纪律，全量扫描，不切片，不分工。严格避开维度 1-3 已有的 findings，保持独立性的单家原始 findings 产出。本报告不使用任何标记“维度 4 已终结/已收官”的结论词，保持持续审计状态。

---

## 维度 4 语义对齐审计总览

通过对核心服务代码、数据层核心逻辑以及技术文档的系统级核对，发现技术决策与产品愿景之间存在 **5 项关键漂移点**，包含严重的 DI 装饰性设计、影响多 Profile 核心主张的系统通知物理死锁、以及并发数据流的重大概念认知偏差：
- **HIGH 严重度**：2 项
- **MEDIUM 严重度**：2 项
- **LOW 严重度**：1 项

---

## 维度 4 Finding 清单

| Finding ID | 技术决策 (具体文件位置 + 决策内容) | 服务的价值链阶段 | 严重度 | 类型 | 推荐处理方向 |
|---|---|---|---|---|---|
| **F-D4-001** | **ProEntitlementProvider 泄露**<br>`SnapDrillCore/Service/ProEntitlementProvider.swift` 声明协议，在 ViewModel/View 构造中直接硬编码 `DefaultProEntitlementProvider()`。 | 导出/打印（智能组卷）及管理（高级统计） | **HIGH** | **实现遗漏 / 装饰性服务** | **DI 容器补齐注册 + 移除硬编码**<br>在 `ServiceContainer` 和 `LiveServiceContainer` 中补充注册；View 层通过 DI 获取，移除构造器默认硬编码参数。 |
| **F-D4-002** | **DataExecutor 并发流认知偏差**<br>`docs/tech/architecture.md` 描述通过非主线程 DataExecutor 进行并发操作，但实际 Repository 直接使用 `mainContext` 在 `MainActor` 主线程同步 CRUD。 | 管理 (全量/分页数据读写、保存与回滚) | **MEDIUM** | **真漂移 (概念认知漂移)** | **Arch 架构文档纠正 + many-to-many 性能防护**<br>在 Arch 纠正数据流图示与文字，明确主线程同步读写事实，在 many-to-many 内存过滤中提供防 UI 卡顿与防 XPC 阻塞防护。 |
| **F-D4-003** | **通知系统物理覆盖死锁**<br>`ProfileManager.swift` 将通知项列为 `perProfileKeys` 隔离，但 `LiveNotificationService.swift` 使用唯一硬编码 identifier `"com.snapdrill.daily-review"`。 | 复习 / 管理 (每日复习提醒) | **HIGH** | **半漂移 (物理覆盖死锁 / 愿景失效)** | **拼接 Profile ID 区分实例**<br>在本地推送 Request 标识符中拼接当前 `profileId`，支持多 Profile 通知并存；移除全局 `cancelAll()`，避免切换时覆盖其他孩子。 |
| **F-D4-004** | **CaptureDraftService 绕过 DI**<br>`CaptureViewModel` & `DashboardViewModel` 绕过 `CaptureDraftServiceProtocol`，直接硬引用 `CaptureDraftService.shared` 静态单例。 | 采集 (异常退出草稿恢复) | **MEDIUM** | **实现遗漏 / 真漂移** | **DI 容器统一暴露 + 移除静态依赖**<br>在 `ServiceContainer` 暴露并注册该服务，ViewModel 改为通过 DI 容器获取以保障单元测试和 Preview 可 Mock 性。 |
| **F-D4-005** | **NFR 高频场景漏设与过度规划**<br>`non-functional-requirements.md` 性能指标仅限 200 题常规场景及印刷体 OCR，缺乏海量数据 most-to-many 查询以及手写 OCR 的性能防护。 | 采集 / 管理 / 导出 | **LOW** | **过度规划 / 漏掉高频场景** | **NFR 补齐指标与退级要求**<br>在 NFR 补充“手写 OCR 混合识别”的退级响应指标，并在 many-to-many 大数据内存过滤中添加主线程防卡顿指标。 |

---

## 详细 Finding 描述与对齐隐患剖析

### 🔍 F-D4-001 [HIGH] — ProEntitlementProvider 僵尸服务与装饰性 DI（主链堵死）
*   **技术决策**：在 `SnapDrillCore/Service/ProEntitlementProvider.swift` 中声明了 `ProEntitlementProvider` 协议及默认返回 `false` 的 `DefaultProEntitlementProvider` 结构体，用于实现 Pro 付费特性门控。
*   **服务的价值链阶段**：导出/打印（智能组卷的 Pro 锁）及管理（Dashboard 高级统计的 Pro 锁）。
*   **严重度**：HIGH
*   **类型**：实现遗漏 / 装饰性服务
*   **语义与对齐分析**：
    1.  **组合根注册遗漏**：虽然设计了 `ProEntitlementProvider`，但是此服务被彻底遗忘在 `ServiceContainer` 和 `LiveServiceContainer` 之外。
    2.  **硬编码默认参数漏洞**：在 `SmartPaperView.swift` 和 `DashboardAnalyticsViewModel.swift` 的构造器中，开发者直接绕过了组合根，采用 `proEntitlementProvider: any ProEntitlementProvider = DefaultProEntitlementProvider()` 的硬编码参数进行规避。
    3.  **产品主链彻底锁死**：由于 `DefaultProEntitlementProvider` 的 `isProUser` 永远返回 `false`，这把所有用户的智能组卷（导出/打印主价值链）和高级统计通道彻底锁死在免费界面中，且完全破坏了架构文档声称的“全服务采用 Protocol-based DI 进行隔离，以便未来替换 StoreKit 实现”的设计。
*   **推荐处理方向**：
    *   在 `ServiceContainer` 协议和 `LiveServiceContainer` 中补齐 `proEntitlementProvider: any ProEntitlementProvider` 属性；
    *   在 `DependencyContainer` 初始化时将其注入；
    *   移除 `SmartPaperView` 和 `DashboardAnalyticsViewModel` 的构造默认值，统一由 Environment DI 容器注入。

---

### 🔍 F-D4-002 [MEDIUM] — DataExecutor 并发数据流文档描述与实际主线程同步 CRUD 的认知偏差
*   **技术决策**：`docs/tech/architecture.md` 中数据流图示描述为“Repository 封装 ModelContext，通过 DataExecutor (actor) 访问”，暗示数据持久化与 CRUD 操作是由 actor 异步接管以隔离并发。
*   **服务的价值链阶段**：管理 (全表查询、分页、many-to-many 过滤及数据保存/回滚)。
*   **严重度**：MEDIUM
*   **类型**：真漂移 (概念认知漂移)
*   **语义与对齐分析**：
    1.  **模型暴露的实质**：实际代码表明，`DataExecutor` 本质上是一个“非 MainActor 容器创建器（消除了 #599 XPC 主线程死锁）”，在其初始化之后，内部的 `container` 是以 `nonisolated` 暴露的。
    2.  **主线程同步瓶颈**：所有子 Repository（如 `ReviewRepository`）都是在初始化时通过 `executor.container.mainContext` 直接拿到了绑定在 `MainActor`（UI 主隔离域）上的 `ModelContext`。后续在主线程上同步执行了所有的 `fetch`、`insert` 和 `saveContext`。这与文档描述中“通过 actor 数据访问”的意图严重错位。
    3.  **大数据量隐藏危机**：由于 SwiftData 在 many-to-many（如 tag 关联查询）上不支持 `#Predicate` 运行时过滤，代码采用了“内存读取 model.tags 遍历过滤”的折中方案。在 2000+ 条错题（NFR 指标上限）的高频大数据场景下，这会导致主线程在循环中触发成百上千次 SwiftData 懒加载小 SQL 查询（N+1 查询问题），直接在 `MainActor` 上卡死数秒，彻底违背了 NFR 对“60fps 滚动无掉帧”与“性能耗时控制”的规定。
*   **推荐处理方向**：
    *   修正 `docs/tech/architecture.md` 中的数据流图示和文字，诚实承认 CRUD 目前同步在 `MainActor` 上的设计；
    *   在 `ReviewRepository` 过滤 many-to-many时，引入轻量缓冲与防主线程卡死机制，或者对大数据量的 tag 查询采用 fetch ID 后过滤的优化方案。

---

### 🔍 F-D4-003 [HIGH] — 推送系统物理覆盖死锁与多 Profile UserDefaults 隔离冲突
*   **技术决策**：在 `SnapDrillData/ProfileManager.swift` 中，将 `notificationHour` and `notificationMinute` 列为了 `perProfileKeys` 隔离存储，实现了多 Profile（代表多孩家庭）独立的每日复习提醒时间偏好。
*   **服务的价值链阶段**：复习 / 管理 (每日复习提醒驱动)。
*   **严重度**：HIGH
*   **类型**：半漂移 (物理 API 覆盖死锁)
*   **语义与对齐分析**：
    1.  **物理与逻辑的断裂**：虽然在产品逻辑上通过 Vault 模式将每个孩子的通知设置在各自的数据库与偏好中做了完好的隔离；但是，在底层 `LiveNotificationService.swift` 中，本地 `UNNotificationRequest` 调度时，将 `identifier` 硬编码为唯一的 `"com.snapdrill.daily-review"`，且每次安排新通知前都会调用全局 `cancelAll()`！
    2.  **非活跃孩子提醒物理抹除**：当家长把 Profile 从老大切换到老二时，老二的通知被注册到系统，但是使用同一 ID 且伴有 `cancelAll()` 会导致在 iOS 系统底层，老大原本生效的每日 8 点通知被**静默擦除**。由于后台无法频繁自动切换 Profile 重新安排，最终导致处于后台的另一个孩子的复习提醒完全失效。这完全击穿了 P5（家长友好、多孩时间隔离）的 Vision 价值链。
*   **推荐处理方向**：
    *   在 `UNNotificationRequest` 的 identifier 构造中，拼接当前 Scope 的 Profile ID：`"com.snapdrill.daily-review.\(profileId.uuidString)"`；
    *   移除 `scheduleDaily` 内部粗暴的 `cancelAll()`，改为针对当前活跃 Profile 进行取消，确保多孩通知在系统底层完美共存。

---

### 🔍 F-D4-004 [MEDIUM] — CaptureDraftService 绕过 DI 直连静态单例的语义退化
*   **技术决策**：`docs/tech/architecture.md` 规定 `CaptureDraftService` 属于 `SnapDrillCore` 核心服务，需服务于异常退出下的草稿恢复（采集阶段）。
*   **服务的价值链阶段**：采集 (暂存草稿、异常状态恢复)。
*   **严重度**：MEDIUM
*   **类型**：实现遗漏 / 真漂移
*   **语义与对齐分析**：
    1.  **协议形同虚设**：项目虽然定义了 `CaptureDraftServiceProtocol`，但该服务并未在 DI 注入容器 `ServiceContainer` 中进行声明和整合。
    2.  **强引用破坏解耦**：在 `CaptureViewModel.swift`、`CaptureResultViewModel.swift` 和 `DashboardViewModel.swift` 中，逻辑代码直接绕过协议，强行调用 `CaptureDraftService.shared` 全局静态单例。这不仅破坏了 Architecture 文档声称的“零依赖核心层”以及“全服务 Protocol-based DI 注入降低耦合”的目标，也导致了测试和 Preview 时难以在内存中隔离草稿磁盘文件。
*   **推荐处理方向**：
    *   在 `ServiceContainer` 协议和 `LiveServiceContainer` 补上 `captureDraft: any CaptureDraftServiceProtocol`；
    *   ViewModel 的 init 或 `@Environment` 中引用此协议，解耦静态单例，使得单元测试可以通过 Mock 模拟草稿恢复流程。

---

### 🔍 F-D4-005 [LOW] — NFR 非功能性指标对海量数据与手写体 OCR 的定义盲区
*   **技术决策**：在 `docs/tech/non-functional-requirements.md` 中假定了常规的 200 题常规场景（40MB 存储，150MB 内存）和印刷体 OCR（< 2秒）。
*   **服务的价值链阶段**：采集 / 管理 / 导出。
*   **严重度**：LOW
*   **类型**：过度规划 / 漏掉高频场景
*   **语义与对齐分析**：
    1.  **手写场景指标缺失**：练习册/卷整理的绝对高频场景是“手写体 OCR 识别（混合手写答案与红色批改）”，而 `apple-limits.md` 已经指明“Vision OCR 无独立中文手写识别模型”。但 NFR 只为印刷体设定了 `< 2秒` 响应指标，未对手写识别在复杂环境下的退级指标和提示做任何性能指引，给下游开发造成了体验真空。
    2.  **大数据防崩溃防卡顿指标缺失**：NFR 仅规划了 200 题的加载（< 500ms），但在 2000+ 题（甚至是 P5 多孩多 Profile 累加后）的海量复杂 tag 联合查询下，由于 many-to-many 导致主线程严重 N+1 同步卡顿，NFR 没有设定任何性能和内存防崩、防卡死指标，构成了指标设计的过度规划（过度详尽于常规）与核心异常场景的缺失。
*   **推荐处理方向**：
    *   在 NFR 中追加“手写/印刷混合 OCR”在弱光等物理环境下的响应退级时间标准；
    *   增加 many-to-many 关联标签内存查询的主线程限时指标（例如在 `1000+` 题目场景下，加载与搜索主线程单次阻塞时间不得超过 `100ms`，必要时采用异步预加载或 Fetch ID 后过滤机制）。
