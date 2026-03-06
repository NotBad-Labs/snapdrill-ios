# 审查请求：DashboardViewModel

**日期**：2026-03-05 15:42（北京时间）
**审查文件**：`Packages/SnapDrillFeatures/Sources/SnapDrillFeatures/Dashboard/DashboardViewModel.swift`
**审查人**：Google Antigravity（Gemini 3.1 Pro）
**状态**：已审查

---

## 项目背景

iOS 间隔重复学习 App（SnapDrill），Swift 6.2 + SwiftUI + SwiftData，iOS 18.0+，单用户本地优先，无后端。ViewModel 为 `@Observable @MainActor final class`。

### 已完成的相关修复（本次不重复审查）

PR #76（Issue #68）已修复以下问题：

- `loadData()` 改为原子更新（先计算所有值再一次性赋给属性，避免 UI 中间状态撕裂）

### 关键设计

- `dataChangeObserver` 标注为 `nonisolated(unsafe) private var`，类型为 `Any?`
- 监听 `NotificationCenter.reviewDataDidChange`，收到后在 `Task { @MainActor in }` 内调用 `loadData()`
- `loadData()` 是同步方法，一次性读取 4 个统计值

---

## 审查问题

1. **`nonisolated(unsafe) var dataChangeObserver` 安全性**：`deinit` 中读取此属性并调用 `removeObserver`。Swift 6 中 `@MainActor` 类的 `deinit` 是 nonisolated，是否存在与主线程读写同一属性的数据竞争？与 `ReviewViewModel` 中同样模式的 `dataChangeObserver` 相比，有何差异？

2. **NotificationCenter 监听触发的 Task 无句柄**：收到通知后创建 `Task { @MainActor in ... }`，但此 Task 没有保存句柄。若短时间内收到多条通知，多个 Task 并发执行 `loadData()`，在 `@MainActor` 单线程下是否会产生问题？若 ViewModel 已释放，Task 是否会安全退出（注意 `[weak self]` 的使用）？

3. **`loadData()` 同步执行 4 次 Repository 查询**：当前实现在主线程同步执行 4 次数据库查询。在题库数据量较大时，是否会阻塞主线程导致 UI 卡顿？与 PR #76 改为原子赋值后，这个问题是否有所缓解还是依然存在？

4. **`checkDraftAndCapture` 的 `CaptureDraftService.shared` 依赖**：此方法直接访问 `CaptureDraftService.shared` 单例。在 `@MainActor` 环境下，这个访问是否线程安全？`CaptureDraftService` 是否也是 `@MainActor` 隔离的？

---

## 审查结果

> 请将审查结果直接写在下方，保留标题层级，每个问题单独一节。
> 使用以下标记：🔴 严重 / 🟡 警告 / 🟢 建议 / ✅ 无问题
> 每个问题末尾注明具体文件和行号（如可定位）。

### 问题 1：nonisolated(unsafe) dataChangeObserver 安全性

🔴 **严重**。此模式和 Library 犯了同样的数据竞争隐患。`setupDataRetention` 在主线程存储 `NotificationCenter` 返回的监听标识，而任意系统线程执行的 `deinit` 中却被用来做移除释放。对于句柄实例对象的指针在缺乏同步护栏的情况存在重叠读写并发崩溃的潜在危险。
建议：使用具备自动生命周期的 AsyncStream 形式：`for await _ in NotificationCenter.default.notifications(named: .reviewDataDidChange)` 替换掉闭包与手动对象拆卸；或依赖 Combine。
文件：`DashboardViewModel.swift`，行 37 与 67。

### 问题 2：通知触发的 Task 无句柄

🟡 **警告**。目前的通知监听没有防抖/限流保护！若 `reviewDataDidChange` 在短时间内由于底层循环删除或批量写库而被触发了 N 次，主线程会无脑推挤新建 N 个繁重的 `loadData()`。即便有 `@MainActor` 序列保障不会发生同时错写，巨大的冗余查询也必定导致 UI 被锁死。同时即便 ViewModel 此刻释放，这些进入主队列的待命中 Task 依旧会挣扎消费完毕。
建议：通过专属的 `cancelable` 任务句柄实现简单的去抖（Debounce）处理。
文件：`DashboardViewModel.swift`，行 58-62。

### 问题 3：loadData 同步 4 次查询的主线程阻塞风险

🔴 **严重**。之前的 PR #76 仅处理完表面撕裂状态，四重暴力查询仍是同步深查（无 `await`）。面对稍微有些体积的历史积累及卡片基础量，在主线程四连下达 `Repository.fetch...` 会导致界面的刷新被大幅度拖拽与丢帧。
建议：必须抽离成 `@ModelActor` (基于 SwiftData 发散后台查询) 或脱离 MainActor。所有计算工作全在底层 Actor 运算终结后，再一次性跳回 `@MainActor` 向这些统计属性派发结果。
文件：`DashboardViewModel.swift`，行 80-83。

### 问题 4：CaptureDraftService.shared 访问安全性

🟡 **警告**。方法内部的确是透过注入的 `draftService` 调用的协议方法（尽管它是以 `.shared` 兜底）。问题在于 `CaptureDraftService` 协议自身或者实现类并没有声明为 `Sendable`，如果是存在共享磁盘缓存的单例在并发环境供 `@MainActor` 读取是极其容易爆出状态不一的隐忧缝隙。
建议：不仅要要求不直接呼叫 `CaptureDraftService.shared` 实体，更应彻底改组 Service 的并发模型使其自身成为标准的隔离 Actor 统合磁盘调度。
文件：`DashboardViewModel.swift`，行 94。

### 综合评估

🔴 **高风险。**这里作为 App 首屏面板不仅堆砌着没有任何阻截阀的异步通知响应（问题2），更是以暴力的串联排队方法把全部计算交给了主线程（问题3）。这样的合集必定会让界面的每一步刷新卡得令人皱眉。推荐加急将数据汇总查询模块外包给并行后台。
