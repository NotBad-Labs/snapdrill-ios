# 审查请求：NotificationSettingsViewModel

**日期**：2026-03-05 15:42（北京时间）
**审查文件**：`Packages/SnapDrillFeatures/Sources/SnapDrillFeatures/Settings/NotificationSettingsViewModel.swift`
**审查人**：Google Antigravity（Gemini 3.1 Pro）
**状态**：已审查

---

## 项目背景

iOS 间隔重复学习 App（SnapDrill），Swift 6.2 + SwiftUI + SwiftData，iOS 18.0+，单用户本地优先，无后端。ViewModel 为 `@Observable @MainActor final class`。

### 关键设计

- `notificationService` 遵循 `NotificationServiceProtocol`（`@MainActor` 协议）
- `enable(hour:minute:)` 先请求权限，授权后再调度通知
- `disable()` 取消所有通知
- `reschedule(hour:minute:)` 重新调度

---

## 审查问题

1. **`enable()` 的权限与调度竞态**：`enable()` 先 `await requestPermission()` 再 `await scheduleDaily()`。若用户在权限弹窗期间快速多次点击 enable，是否会产生多个并发 Task 同时执行？每次 `scheduleDaily` 调用是否会累积多条通知而非覆盖？

2. **权限被拒时的状态一致性**：`requestPermission()` 返回 `false` 时，`enable()`直接 `return false`，但 ViewModel 中 `isEnabled` 等状态属性是否已经在调用前被 View 层乐观更新（即先改 UI 再等结果）？若权限被拒，UI 状态是否能正确回滚？

3. **`reschedule` 失败时的静默处理**：`reschedule()` 的 catch 只打 log。若调度失败（如系统通知权限在设置中被撤销），用户界面显示"已开启"但实际通知不会推送。是否需要将错误状态暴露给 View 层？

4. **`disable()` 是否需要异步**：`notificationService.cancelAll()` 是同步方法，在 `@MainActor` 上调用。若 `cancelAll()` 内部有耗时操作（如遍历大量 pending notifications），是否会阻塞主线程？

---

## 审查结果

> 请将审查结果直接写在下方，保留标题层级，每个问题单独一节。
> 使用以下标记：🔴 严重 / 🟡 警告 / 🟢 建议 / ✅ 无问题
> 每个问题末尾注明具体文件和行号（如可定位）。

### 问题 1：enable() 并发多次调用

🟡 **警告**。这是一个标准的重入并发隐患。由于系统层面的请求弹窗 `await requestPermission()` 会导致控制流长期挂起并在外处于不确定性闲置，如若用户在此期间缺乏耐心暴力连点控件，调用堆栈将会创建出复数的并行任务；从而在终于授权通过那一秒全部下垂倾注出重复的指令 `scheduleDaily`。
建议：使用内部标记变量例如 `isRequesting` 过滤，或直接把等待期间的触控按钮直接废弃锁死直到返回结果。
文件：`NotificationSettingsViewModel.swift`，行 40-51。

### 问题 2：权限被拒时的 UI 状态回滚

🟡 **警告**。尽管我们在后台拦截了 `false` 的返回，但在 SwiftUI 流行的双向数据绑定（典型的如 Switch/Toggle 开关）面前，如果视图仅通过一个本地 `@State` 并由自身的点击驱使向右变为已打开的样式，由于没有来自 ViewModel 侧强势推回原位的基础补偿，系统 UI 将会被“欺骗”地僵死在这个无法挽救的错误（拒绝）状态。
建议：需要确保在授权拒绝的负向链路中回推或通过统一的唯一事实来源（如 `isNotificationEnabled`）掌控组件外观，并强制撤销拨动行为。
文件：`NotificationSettingsViewModel.swift`，行 43。

### 问题 3：reschedule 失败静默处理

🟡 **警告**。更改时间的交互其实常常容易由于权限被收回、通知系统崩塌而被静默。ViewModel 只做出了微小的日志输出，而外部的界面时间转轮确实变换了新数字，这会让用户满怀希望等待明天的提醒，产生逻辑预期撕裂感。
建议：设计提供暴露出错误的标志属性能让 View 订阅，并在出现 Catch 时激活红圈 Toast，或借此机会引流用户向系统设置要回权限。
文件：`NotificationSettingsViewModel.swift`，行 63-65。

### 问题 4：disable() 主线程阻塞风险

🟢 **建议**。通常情况下，对底层 `UNUserNotificationCenter` 触发删除指令 `cancelAll()` 的耗时均在跨进程通信中被妥善处理在微秒内，这并不会真实触发可见的阻塞反馈。
但在完全追捧全局协程的大框架下，建议依然可以将系统级调令丢装至 `Task` 块。
文件：`NotificationSettingsViewModel.swift`，行 56。

### 综合评估

🟡 **中风险。**在这个局部内逻辑相对收敛清晰，比较明显的短板主要来自对使用者反复触控防错底层的轻敌（问题1）、因与前台响应缺失断连造成欺骗性的状态残留（问题2）。补齐数据流防线与向外的错误传递后，将非常健壮。
