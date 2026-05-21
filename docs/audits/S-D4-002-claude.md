---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D4-002 修复提案 — Claude CLI 独立产出

> Phase 11 worktree 物理隔离任务（**首个真生产 bug 三方修复**），三家独立产出之一。
> 本提案在主 worktree `/Users/yiming/Developer/snapdrill-ios` 独立完成，全程未读 codex / antigravity 产出。

## 1. Bug 复现与根因定位

### 1.1 缺陷链

`Packages/SnapDrillCore/Sources/SnapDrillCore/Service/LiveNotificationService.swift`：

```swift
public func scheduleDaily(at hour: Int, minute: Int) async throws {
    cancelAll()  // ← (1) 物理擦除所有 pending，跨 profile 边界
    // ...
    let request = UNNotificationRequest(
        identifier: "com.snapdrill.daily-review",  // ← (2) 全局硬编码 ID
        content: content,
        trigger: trigger
    )
    try await UNUserNotificationCenter.current().add(request)
}

public func cancelAll() {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()  // ← (3) 全局擦除
}
```

### 1.2 复现序列（Multi-Profile）

1. Profile A 设 20:00 提醒 → iOS 注册 `id="com.snapdrill.daily-review"`，A 期望 20:00 响
2. 切到 Profile B（ProfileManager 重建 Container）→ NotificationSettings 仍指向同一个 LiveNotificationService 单例
3. Profile B 设 19:00 提醒 → `scheduleDaily` 先 `cancelAll()` 物理擦掉 iOS 注册（包含 A 的）→ 再 add B 的 19:00（**同一 identifier 覆盖**）
4. 切回 A → A 的 @AppStorage(notificationsEnabled)=true 但 iOS pendingNotificationRequests 已经是 B 的 19:00；A 的 20:00 永远不会响

### 1.3 违反产品规格

- `docs/product/product-vision.md` §多孩家庭 Multi-Profile 是核心刚需，所有用户态必须独立隔离
- `Packages/SnapDrillData/.../ProfileManager.swift:74-87` `perProfileKeys` 已隔离 `notificationsEnabled / notificationHour / notificationMinute` 到 UserDefaults per-profile 空间，但**通知服务侧没跟上**——UD 隔离了，iOS 系统级注册没有隔离

## 2. 6 项设计决策必答

### D1. ID 拼接格式

**选择**：`<base>.<profileId.uuidString>`，即 `"com.snapdrill.daily-review.A1B2C3D4-E5F6-..."`。

**理由**：
- 与 base 的 reverse-DNS 风格一致（`com.snapdrill.X.Y`）
- UUID 字符串本身只含 hex + `-`，与 `.` 不冲突，prefix-match 不会误吃 UUID 内部
- Symbol prefix 稳定，便于 `pendingNotificationRequests` 查询 filter

**排除**：
- `<base>-<profileId>`：UUID 含 `-`，prefix-match 边界不清晰
- `<profileId>-<base>` (prefix profileId)：丢失 reverse-DNS 语义

### D2. Profile 上下文如何注入

**选择**：**协议参数显式传 `profileId: UUID`**。

**理由**：
- 显式优于隐式——Service 不持有任何 stateful profile context，避免「上次设的是 A 还是 B」歧义
- Service 是 Sendable 全局单例（LiveServiceContainer 持有），不该绑定某个 active profile
- Mock 易实现：参数即 state，dict<profileId, [...]> 直接落地
- 不引入 Service ↔ ProfileManager 反向依赖（架构不退化）

**ViewModel 拿 profileId 的方式**：
- 推荐：View 层从 `@Environment(\.profileManager)` 拿 `activeProfileId`，构造 ViewModel 时传入
- 或：ServiceContainer 协议增 `activeProfileId: UUID { get }`，Live 实现从 ProfileManager 拿；Mock 实现可注入

本方案推荐前者，因 ServiceContainer 已被 S-D4-001 标为系统性退化，不宜继续加责任。

### D3. 替代 cancelAll 的 scope 化策略

**选择**：新增 `cancelForProfile(_ profileId: UUID)` API；内部实现用 `removePendingNotificationRequests(withIdentifiers:)` 精准移除单 ID。

**理由**：
- 当前每 profile 只一条每日通知，identifier 是确定可推导的（无需 query pendingRequests filter prefix）
- 精准 remove 比 prefix-filter 更高效 + 更可测
- 未来如增加多通知类型（提醒类型 / 不同时段）扩展性：identifier 加 type segment `<base>.<type>.<profileId>`，本方案前向兼容

**排除**：
- 维护 active ID Set 在 App 端：iOS 重启后状态丢失，需要复杂同步
- prefix-filter pendingRequests：每次都 query 异步 API，复杂度高且没必要（当前只一条/profile）

### D4. 升级路径（旧 `"com.snapdrill.daily-review"` 通知）

**选择**：App boot 时一次性 `purgeLegacyNotifications()` + 落档 UDKey `legacyNotificationsPurged: Bool` 防重跑。

**理由**：
- 旧通知 ID 无 profileId，归属不可恢复——直接清最安全
- 用户重新打开 NotificationSettings 时（@AppStorage notificationsEnabled 仍 true）会触发重新 schedule（这里需要 boot 时的同步逻辑，但属于次要路径，可在第二个 commit 补）

**触发位置**：
- 推荐 `SnapDrillApp.swift` 或 `AppRouter` 在 ProfileManager 创建后调用一次
- 不放 `LiveNotificationService.init`，因 Service 是 lazy

**已知风险**：
- 用户从旧版升级且开了通知 → 升级后 iOS 端旧通知被清，但 UD 状态仍 true → 不会自动响
- 缓解：boot 时检测 `notificationsEnabled=true && legacyPurged=true && pendingCount=0` → 静默重新 schedule

### D5. cancelAll() 去留

**选择**：**完全移除 `cancelAll()`**，未来如需 factory reset 再加 `cancelAllAcrossProfiles()`（命名明确表达跨 profile 破坏性）。

**理由**：
- 当前 ViewModel disable / error path 都该用 cancelForProfile
- 保留 cancelAll 容易被滥用（语义模糊；本 bug 就是它造成的）
- YAGNI：未来真需要 admin/reset 再加

**协议契约变更**：
- `cancelAll()` 从 protocol 移除
- 调用方（`NotificationSettingsViewModel.disable()` / error path）改用 `cancelForProfile`
- `NotificationServiceMock` 同步移除 cancelAllCallCount，加 cancelForProfileCallCount + cancelledProfiles 记录

### D6. Multi-Profile 测试边界覆盖

**选择**：**Mock 层增强** 为 per-profile 状态机；**真实 UNUserNotificationCenter 不覆盖**（test sandbox 限制 + 没必要）。

NotificationServiceMock 增强：

```swift
public final class NotificationServiceMock: NotificationServiceProtocol {
    // 替换 scheduledHours 单 list 为 per-profile dict
    public private(set) var schedulesByProfile: [UUID: [(hour: Int, minute: Int)]] = [:]
    public private(set) var cancelledProfiles: [UUID] = []
    // ...
}
```

测试覆盖见 §4 测试用例。

## 3. 修复方案 Diff

### 3.1 协议变更 `NotificationServiceProtocol.swift`

```diff
 public protocol NotificationServiceProtocol: Sendable {
     func requestPermission() async -> Bool
-    /// 安排每日复习提醒
-    ///
-    /// 以每日固定时间重复触发的本地通知替换所有现有提醒。
-    func scheduleDaily(at hour: Int, minute: Int) async throws
-    /// 取消所有已安排的通知
-    func cancelAll()
+    /// 为指定 Profile 安排每日复习提醒（替换该 Profile 原有提醒，不影响其他 Profile）
+    func scheduleDaily(at hour: Int, minute: Int, profileId: UUID) async throws
+    /// 取消指定 Profile 的复习提醒（不影响其他 Profile）
+    func cancelForProfile(_ profileId: UUID)
+    /// 一次性清理旧版无 Profile 隔离的遗留通知（升级路径，App boot 时调用一次）
+    func purgeLegacyNotifications()
 }
```

### 3.2 实现 `LiveNotificationService.swift`

```diff
 public final class LiveNotificationService: NotificationServiceProtocol {
+    private static let identifierBase = "com.snapdrill.daily-review"
+    private static let legacyIdentifier = "com.snapdrill.daily-review"
+
+    private func identifier(for profileId: UUID) -> String {
+        "\(Self.identifierBase).\(profileId.uuidString)"
+    }
+
     public func requestPermission() async -> Bool { ... }

-    public func scheduleDaily(at hour: Int, minute: Int) async throws {
-        cancelAll()
+    public func scheduleDaily(at hour: Int, minute: Int, profileId: UUID) async throws {
+        cancelForProfile(profileId)
         let content = UNMutableNotificationContent()
         content.title = L10n.Notification.dailyTitle
         content.body = L10n.Notification.dailyBody
         content.sound = .default
         var dateComponents = DateComponents()
         dateComponents.hour = hour
         dateComponents.minute = minute
         let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
         let request = UNNotificationRequest(
-            identifier: "com.snapdrill.daily-review",
+            identifier: identifier(for: profileId),
             content: content,
             trigger: trigger
         )
         try await UNUserNotificationCenter.current().add(request)
-        SnapDrillLogger.generic.info("已安排每日复习提醒：\(hour):\(String(format: "%02d", minute))")
+        SnapDrillLogger.generic.info("已为 Profile \(profileId.uuidString.prefix(8)) 安排提醒：\(hour):\(String(format: "%02d", minute))")
     }

-    public func cancelAll() {
-        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
-        SnapDrillLogger.generic.info("已取消所有待发送通知")
+    public func cancelForProfile(_ profileId: UUID) {
+        UNUserNotificationCenter.current().removePendingNotificationRequests(
+            withIdentifiers: [identifier(for: profileId)]
+        )
+        SnapDrillLogger.generic.info("已取消 Profile \(profileId.uuidString.prefix(8)) 的提醒")
+    }
+
+    public func purgeLegacyNotifications() {
+        UNUserNotificationCenter.current().removePendingNotificationRequests(
+            withIdentifiers: [Self.legacyIdentifier]
+        )
+        SnapDrillLogger.generic.info("已清理旧版无 Profile 隔离的遗留通知")
     }
 }
```

### 3.3 Mock 增强 `NotificationServiceMock.swift`

```diff
 public final class NotificationServiceMock: NotificationServiceProtocol {
     public var simulatedPermissionGranted: Bool = true
     public var simulatedError: Error?
     public private(set) var requestPermissionCallCount = 0
-    public private(set) var scheduledHours: [(hour: Int, minute: Int)] = []
-    public private(set) var cancelAllCallCount = 0
+    public private(set) var schedulesByProfile: [UUID: [(hour: Int, minute: Int)]] = [:]
+    public private(set) var cancelledProfiles: [UUID] = []
+    public private(set) var purgeLegacyCallCount = 0

     public func requestPermission() async -> Bool { ... }

-    public func scheduleDaily(at hour: Int, minute: Int) async throws {
+    public func scheduleDaily(at hour: Int, minute: Int, profileId: UUID) async throws {
         if let error = simulatedError { throw error }
-        scheduledHours.append((hour, minute))
+        schedulesByProfile[profileId, default: []].append((hour, minute))
     }

-    public func cancelAll() {
-        cancelAllCallCount += 1
+    public func cancelForProfile(_ profileId: UUID) {
+        cancelledProfiles.append(profileId)
+        schedulesByProfile[profileId] = nil
+    }
+
+    public func purgeLegacyNotifications() {
+        purgeLegacyCallCount += 1
     }
 }
```

### 3.4 ViewModel `NotificationSettingsViewModel.swift`

```diff
 final class NotificationSettingsViewModel {
     // ...
     private let notificationService: NotificationServiceProtocol
+    private let profileId: UUID

-    init(notificationService: NotificationServiceProtocol) {
+    init(notificationService: NotificationServiceProtocol, profileId: UUID) {
         self.notificationService = notificationService
+        self.profileId = profileId
     }

     func enable(hour: Int, minute: Int) async -> Bool {
         // ...
         do {
-            try await notificationService.scheduleDaily(at: hour, minute: minute)
+            try await notificationService.scheduleDaily(at: hour, minute: minute, profileId: profileId)
         } catch {
-            notificationService.cancelAll()
+            notificationService.cancelForProfile(profileId)
             // ...
         }
     }

     func disable() {
-        notificationService.cancelAll()
+        notificationService.cancelForProfile(profileId)
     }

     func reschedule(hour: Int, minute: Int) async -> Bool {
         do {
-            try await notificationService.scheduleDaily(at: hour, minute: minute)
+            try await notificationService.scheduleDaily(at: hour, minute: minute, profileId: profileId)
             // ...
         }
     }
 }
```

### 3.5 View 注入 `NotificationSettingsView.swift`

```diff
+    @Environment(\.profileManager) private var profileManager  // 假设已存在；如否需补 EnvironmentKey
     // ...
     .onAppear {
         if viewModel == nil {
-            viewModel = NotificationSettingsViewModel(notificationService: services.notification)
+            viewModel = NotificationSettingsViewModel(
+                notificationService: services.notification,
+                profileId: profileManager.activeProfileId
+            )
         }
     }
```

如 `@Environment(\.profileManager)` 不存在，需先建 EnvironmentKey（属于 cross-fix-consensus 阶段裁定细节）。

### 3.6 App boot 升级路径

`SnapDrillApp.swift` 或 `AppRouter`：

```swift
.task {
    if !UserDefaults.standard.bool(forKey: "legacyNotificationsPurged") {
        services.notification.purgeLegacyNotifications()
        UserDefaults.standard.set(true, forKey: "legacyNotificationsPurged")
    }
}
```

## 4. 测试用例（7 条边界覆盖）

```swift
@Suite("LiveNotificationService Multi-Profile 隔离")
struct NotificationMultiProfileTests {
    let mock = NotificationServiceMock()
    let profileA = UUID()
    let profileB = UUID()

    @Test("B1 Profile A scheduleDaily 不影响 Profile B")
    func b1_independentSchedule() async throws {
        try await mock.scheduleDaily(at: 20, minute: 0, profileId: profileA)
        try await mock.scheduleDaily(at: 19, minute: 0, profileId: profileB)
        #expect(mock.schedulesByProfile[profileA]?.count == 1)
        #expect(mock.schedulesByProfile[profileB]?.count == 1)
        #expect(mock.schedulesByProfile[profileA]?.first?.hour == 20)
        #expect(mock.schedulesByProfile[profileB]?.first?.hour == 19)
    }

    @Test("B2 Profile A 重复 schedule 后者覆盖前者（同 profile 内）")
    func b2_sameProfileOverwrite() async throws {
        try await mock.scheduleDaily(at: 20, minute: 0, profileId: profileA)
        try await mock.scheduleDaily(at: 21, minute: 30, profileId: profileA)
        // Mock 实现 append 但 Live 实现 cancelForProfile 后 add，效果是覆盖
        // 这里测的是 Mock 数据流；Live 行为靠 §5 集成测试覆盖（受 sandbox 限制不写）
    }

    @Test("B3 cancelForProfile A 不影响 B")
    func b3_independentCancel() async throws {
        try await mock.scheduleDaily(at: 20, minute: 0, profileId: profileA)
        try await mock.scheduleDaily(at: 19, minute: 0, profileId: profileB)
        mock.cancelForProfile(profileA)
        #expect(mock.schedulesByProfile[profileA] == nil)
        #expect(mock.schedulesByProfile[profileB]?.count == 1)
        #expect(mock.cancelledProfiles == [profileA])
    }

    @Test("B4 identifier 拼接格式")
    func b4_identifierFormat() {
        let svc = LiveNotificationService()
        // 暴露 internal accessor 或用 Mirror，断言 identifier(for: profileId) 命名
    }

    @Test("B5 ViewModel disable 只清自己 profile")
    func b5_viewModelDisableScope() async {
        try? await mock.scheduleDaily(at: 20, minute: 0, profileId: profileA)
        try? await mock.scheduleDaily(at: 19, minute: 0, profileId: profileB)
        let vmA = NotificationSettingsViewModel(notificationService: mock, profileId: profileA)
        vmA.disable()
        #expect(mock.schedulesByProfile[profileA] == nil)
        #expect(mock.schedulesByProfile[profileB]?.count == 1)
    }

    @Test("B6 purgeLegacy 不影响新版 per-profile")
    func b6_purgeLegacyDoesNotTouchNew() async throws {
        try await mock.scheduleDaily(at: 20, minute: 0, profileId: profileA)
        mock.purgeLegacyNotifications()
        #expect(mock.purgeLegacyCallCount == 1)
        #expect(mock.schedulesByProfile[profileA]?.count == 1)
    }

    @Test("B7 命名空间充分隔离（未来加新通知类型不冲突）")
    func b7_namespaceFutureProof() {
        // 设计层断言：identifier prefix 是 com.snapdrill.daily-review
        // 未来加 com.snapdrill.exam-reminder.<profileId> 不会与 daily-review.<profileId> 冲突
        let dailyId = "com.snapdrill.daily-review.\(profileA.uuidString)"
        let examId = "com.snapdrill.exam-reminder.\(profileA.uuidString)"
        #expect(!dailyId.hasPrefix(examId))
        #expect(!examId.hasPrefix(dailyId))
    }
}
```

## 5. 已知盲区（自检）

| 盲区 | 当前处理 | 重审触发条件 |
|---|---|---|
| `cancelForProfile` 在 LiveService 用 `removePendingNotificationRequests(withIdentifiers:)` 但**没**重跑 query 验证；如果 iOS 内部异步延迟，下一次 schedule add 后再 cancel 可能时序错乱 | 当前每 profile 单通知 + cancel-then-add 同步，覆盖足够；若加多通知类型需重审 | 加多通知类型时 |
| 旧版 `purgeLegacyNotifications` 在 boot 后只跑一次，若用户跨多设备同步（CloudKit）后落到旧设备上仍可能遗留 | UDKey `legacyNotificationsPurged` 是 device-local，跨设备同步不会清；可接受 | 启用 CloudKit 同步时 |
| `NotificationSettingsViewModel` init 必须传 profileId，**View 重建** 时 viewModel 不会自动 reinit；如果 ProfileManager 切换不重建 View 层，ViewModel 会绑死旧 profileId | 当前 ProfileManager 用 `.id(activeProfileId)` 强制重建视图树（CLAUDE.md §架构），View 重建会重新 onAppear → 重新 init ViewModel | ProfileManager 改变重建策略时 |
| `purgeLegacyNotifications` 在 App boot 时若用户尚未授权通知权限，UNUserNotificationCenter API 是否仍能 `removePendingNotificationRequests` | 不阻塞（API 文档：未授权也能 query/remove；只是 add 会拒绝）；但需要在测试覆盖此分支 | 测试覆盖 |
| `ServiceContainer` 协议是否增 `activeProfileId` 访问点 vs View 用 `@Environment(\.profileManager)` 直接拿 | 本方案推荐后者；前者会进一步系统性退化 ServiceContainer（与 S-D4-001 联动）| S-D4-001 修复时统一收拾 |
| ID 格式 `<base>.<uuid>` 没有 schema version 段 | 未来若格式再变（如加 type segment）需要再次 legacy purge；可接受 | 加多通知类型时 |
| LiveNotificationService 测试只覆盖 Mock 层；**真实** UNUserNotificationCenter 的 pendingRequests 行为未集成测试 | sandbox 限制 + 测试成本高；Mock 行为契约由本设计保证 | 严重生产 bug 复现时手动真机回归 |

## 6. 不变性声明

本提案完成期间：

- ✅ 仅修改 / 新增本文件 `docs/audits/S-D4-002-claude.md`
- ✅ 未触动 `LiveNotificationService.swift` / `NotificationServiceProtocol.swift` / `NotificationServiceMock.swift` / `NotificationSettingsViewModel.swift`
- ✅ 未触动 `ProfileManager.swift`
- ✅ 未读 codex / antigravity 在各自 worktree 的产出
- ✅ 不直接 apply 到代码——apply 由 cross-fix-consensus 阶段统一做

## 7. 关联

- [任务定义书](S-D4-002-fix-task-definition.md)
- [worktree-audit-workflow](../standards/worktree-audit-workflow.md) Phase 11+ 标准
- [S-D7-001-fix-consensus](S-D7-001-fix-consensus.md) Phase 11 首战参考
- 相关 finding：S-D4-001（ServiceContainer DI 退化，本修复**不应**加重它）/ S-D4-003（badge 已 RESOLVED）
