# 审查请求：LibraryViewModel

**日期**：2026-03-05 15:42（北京时间）
**审查文件**：`Packages/SnapDrillFeatures/Sources/SnapDrillFeatures/Library/LibraryViewModel.swift`
**审查人**：Google Antigravity（Gemini 3.1 Pro）
**状态**：已审查

---

## 项目背景

iOS 间隔重复学习 App（SnapDrill），Swift 6.2 + SwiftUI + SwiftData，iOS 18.0+，单用户本地优先，无后端。ViewModel 为 `@Observable @MainActor final class`。

### 已完成的相关修复（本次不重复审查）

PR #72（Issue #65）已修复以下问题：

- 分页并发无保护（`isLoadingMore` 防重入）
- `nonisolated(unsafe) var paginationTask` 相关问题
- 搜索防抖任务句柄管理

### 关键设计

- 题库列表使用 `fetchFilteredModels(searchText:subjects:tags:limit:offset:)` 手动分页，非 `@Query`
- `searchTask` 标注为 `nonisolated(unsafe)`，注释说明 `Task.cancel()` 是线程安全的
- `deleteItems(ids:)` 批量删除，循环内每次调用 `repositories.review.delete(id:)`（每次内部各自 save）

---

## 审查问题

1. **`nonisolated(unsafe) searchTask` 当前是否安全**：PR #72 修复后，`searchTask` 的使用模式（赋值、cancel、nil）是否仍有数据竞争风险？注释中声称"Task.cancel() 是线程安全的"——这个说法在 Swift 6 中是否准确？`deinit` 中对它的访问是否安全？

2. **`deleteItems(ids:)` 批量删除的原子性**：循环内逐条调用 `repositories.review.delete(id:)`，每次内部各自 `save()`。若中途某条删除失败，已删除的条目无法恢复。这在题库删除场景下风险有多大？是否需要批量原子删除？

3. **`deleteItem` / `deleteItems` 缺少图片文件清理**：删除题目时只调用 `repositories.review.delete(id:)`，若该题目有 `imagePath` 或 `answerImagePath`，对应图片文件是否被清理？还是永久残留为孤儿文件？

4. **`refreshData` 和 `loadMore` 的取消检查时机**：两个方法内部在 `fetchFilteredModels` 返回后才检查 `Task.isCancelled`。若 fetch 耗时较长（大量数据），用户已切走页面，Task 是否会正确退出？`guard !Task.isCancelled` 的位置是否足够早？

---

## 审查结果

> 请将审查结果直接写在下方，保留标题层级，每个问题单独一节。
> 使用以下标记：🔴 严重 / 🟡 警告 / 🟢 建议 / ✅ 无问题
> 每个问题末尾注明具体文件和行号（如可定位）。

### 问题 1：nonisolated(unsafe) searchTask 当前安全性

🔴 **严重**。虽有注释掩饰，但在 Swift 6 严格并发检查下，此模式存在明显的数据竞争。`searchTask` 的赋值发生在 `@MainActor`，而在类的 `deinit` 时（无任何隔离保护）去读取它并调用 `.cancel()`。因为 `Task` 本身为 class（引用类型），无同步机制保护的跨线程读写指针势必引发竞态条件甚至 Crash。
建议：将 `searchTask` 的清理交还系统，在 SwiftUI 中使用 `.task(id:)` 让生命周期随 View 自动取消，从而彻底消除手动的 deinit 清理；或将其封装入独立的 Actor。
文件：`LibraryViewModel.swift`，行 46 与 157。

### 问题 2：deleteItems 批量删除原子性

🟡 **警告**。当前依靠 `for` 循环逐个调用 `repositories.review.delete(id: id)`，并且内部各自隐式或显式 `save()`，这破坏了原子操作。如果在循环中途抛出异常，已删除的条目无法回滚，造成了题库列表"部分被删"的割裂状态。
建议：Repository 层应提供一个 `delete(ids: Set<UUID>)` 的专门接口，底层只调用一次 `save()`，在出现异常时统一 `rollback()`。
文件：`LibraryViewModel.swift`，行 137-145。

### 问题 3：删除题目时图片文件未清理

🔴 **严重**。删除题目时只清理了数据库实体，完全没有处理文件系统！若题目包含 `imagePath` 或 `answerImagePath`，对应的图片资源将成为永久无法访问的孤儿文件，最终导致 App 存储空间泄漏、体积不断膨胀。
建议：在 Repository delete 或由专门的层（如 MediaManager）拦截删除动作，同步清理相关联的沙盒磁盘文件资源。
文件：`LibraryViewModel.swift`，行 128 和 140。

### 问题 4：refreshData / loadMore 取消检查时机

🟡 **警告**。取消检查的时机太迟。由于 `repositories.review.fetchFilteredModels` 没有采用 `async` 修饰，这是一个同步查询方法！这意味着繁重的检索过滤查询全程阻塞 `@MainActor` 所在的主线程。就算在其后检查了 `!Task.isCancelled`，主线程的长时间卡顿（数百毫秒甚至秒级）已成定局。
建议：首要动作是将这些大批量数据拉取接口改成原生 `async` 并切到 Background Actor (`@ModelActor`)；并且在其执行长时间循环时更早调入 `Task.checkCancellation()` 作为安全打断点。
文件：`LibraryViewModel.swift`，行 92 和 117。

### 综合评估

🔴 **高风险。**当前文件不仅存在会导致 App 存储持续膨胀的未处理媒体文件泄漏（问题3），更包含隐匿的指针读取竞态（问题1），两者都会侵蚀应用最底线的稳定性与用户体验质量；附带大量数据同步查询（问题4）对主流程的蛮横阻断亦需优先重构至次要线程。
