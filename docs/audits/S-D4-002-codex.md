---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D4-002 Codex 独立修复提案

## 结论

`LiveNotificationService` 当前把每日复习提醒当作全局单例通知处理，和 Multi-Profile 产品边界冲突。修复应把 notification identifier 变成 profile-scoped，并把普通业务路径从 `cancelAll()` 改成 `cancelDaily(for:)`。

代码证据：

- `LiveNotificationService.swift:40-41`：`scheduleDaily` 调用 `cancelAll()`。
- `LiveNotificationService.swift:54`：所有 Profile 共用 `"com.snapdrill.daily-review"`。
- `LiveNotificationService.swift:64-65`：`cancelAll()` 调 `removeAllPendingNotificationRequests()`，会移除 app 的全部 pending notification。
- `NotificationSettingsViewModel.swift:54/67/74`：设置页调用协议时没有 Profile 作用域。

## 6 项设计决策

| 决策点 | Codex 方案 |
|---|---|
| ID 拼接格式 | `com.snapdrill.notification.daily-review.profile.<lowercase-uuid>`。保留清晰 namespace：app / domain / notification type / profile scope。使用 suffix profileId，便于按 exact identifier 删除单个 Profile；prefix `com.snapdrill.notification.` 便于 admin reset 过滤 SnapDrill 管理的通知。 |
| Profile 上下文如何注入 | 协议参数显式传 `ProfileScope`：`scheduleDaily(..., for scope: ProfileScope)`、`cancelDaily(for scope:)`。不让 service 持有 `ProfileManager`，避免 Core 反向依赖 Data，也不改 `ProfileManager.swift` 主流程。 |
| 替代 cancelAll 的 scope 化 | 正常业务路径只删除 exact scoped identifier：`removePendingNotificationRequests(withIdentifiers: [identifier])`。同一 Profile 重复 schedule 只覆盖本 Profile；disable 只删除本 Profile。 |
| 升级路径 | 在下一次 `scheduleDaily(..., for:)` 时清理旧 legacy ID `"com.snapdrill.daily-review"`。不迁移到默认 Profile，因为旧通知无法可靠知道原 Profile；清理比误归属更安全。 |
| 是否保留 cancelAll | 从普通协议语义中移除 `cancelAll()`，改成 `cancelDaily(for:)`。如确需 reset/admin 能力，新增明确命名的 `cancelAllSnapDrillNotifications() async`，只删除 `com.snapdrill.notification.` prefix 和 legacy ID，不调用系统级 `removeAllPendingNotificationRequests()`。 |
| Multi-Profile 测试边界 | 引入 `UserNotificationScheduling` facade + fake center，在 Core 单元测试里断言 pending request identifier 集合。不要用真实 `UNUserNotificationCenter` 做单测，避免 simulator 权限/系统状态污染。 |

## 修复 patch

### `Packages/SnapDrillCore/Sources/SnapDrillCore/Service/NotificationServiceProtocol.swift`

```diff
@@
 public protocol NotificationServiceProtocol: Sendable {
@@
-    /// 安排每日复习提醒
+    /// 安排指定 Profile 的每日复习提醒
     ///
-    /// 以每日固定时间重复触发的本地通知替换所有现有提醒。
+    /// 以每日固定时间重复触发的本地通知替换同一 Profile 的现有提醒。
     /// - Parameters:
     ///   - hour: 触发小时（0-23）
     ///   - minute: 触发分钟（0-59）
-    func scheduleDaily(at hour: Int, minute: Int) async throws
+    ///   - scope: Profile 隔离作用域
+    func scheduleDaily(at hour: Int, minute: Int, for scope: ProfileScope) async throws
 
-    /// 取消所有已安排的通知
-    func cancelAll()
+    /// 取消指定 Profile 已安排的每日提醒
+    func cancelDaily(for scope: ProfileScope)
+
+    /// 管理员/重置语义：取消 SnapDrill 管理的所有通知，不触碰其他 app/local pending request。
+    func cancelAllSnapDrillNotifications() async
 }
```

### `Packages/SnapDrillCore/Sources/SnapDrillCore/Service/LiveNotificationService.swift`

```diff
@@
 import Foundation
 import UserNotifications
 
+protocol UserNotificationScheduling: Sendable {
+    func add(_ request: UNNotificationRequest) async throws
+    func pendingNotificationRequests() async -> [UNNotificationRequest]
+    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
+}
+
+extension UNUserNotificationCenter: UserNotificationScheduling {}
+
+enum SnapDrillNotificationID {
+    static let legacyDailyReview = "com.snapdrill.daily-review"
+    static let managedPrefix = "com.snapdrill.notification."
+    private static let dailyReviewPrefix = managedPrefix + "daily-review.profile."
+
+    static func dailyReview(for profileId: UUID) -> String {
+        dailyReviewPrefix + profileId.uuidString.lowercased()
+    }
+
+    static func isManaged(_ identifier: String) -> Bool {
+        identifier == legacyDailyReview || identifier.hasPrefix(managedPrefix)
+    }
+}
+
 /// 通知服务生产实现
@@
 public final class LiveNotificationService: NotificationServiceProtocol {
+    private let notificationCenter: any UserNotificationScheduling
 
     // MARK: - Initialization
 
     /// 创建通知服务生产实例
-    public init() {}
+    public init(notificationCenter: any UserNotificationScheduling = UNUserNotificationCenter.current()) {
+        self.notificationCenter = notificationCenter
+    }
@@
-    /// 安排每日固定时间的复习提醒
+    /// 安排指定 Profile 的每日固定时间复习提醒
     ///
-    /// 先取消所有现有提醒，再注册新的每日重复通知。
-    public func scheduleDaily(at hour: Int, minute: Int) async throws {
-        cancelAll()
+    /// 只替换同一 Profile 的每日提醒，不影响其他 Profile。
+    public func scheduleDaily(at hour: Int, minute: Int, for scope: ProfileScope) async throws {
+        let identifier = SnapDrillNotificationID.dailyReview(for: scope.id)
+        notificationCenter.removePendingNotificationRequests(
+            withIdentifiers: [identifier, SnapDrillNotificationID.legacyDailyReview]
+        )
@@
         let request = UNNotificationRequest(
-            identifier: "com.snapdrill.daily-review",
+            identifier: identifier,
             content: content,
             trigger: trigger
         )
 
-        try await UNUserNotificationCenter.current().add(request)
-        SnapDrillLogger.generic.info("已安排每日复习提醒：\(hour):\(String(format: "%02d", minute))")
+        try await notificationCenter.add(request)
+        SnapDrillLogger.generic.info(
+            "已安排每日复习提醒 profile=\(scope.id.uuidString) time=\(hour):\(String(format: "%02d", minute))"
+        )
     }
 
-    /// 取消所有已安排的本地通知
-    public func cancelAll() {
-        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
-        SnapDrillLogger.generic.info("已取消所有待发送通知")
+    /// 取消指定 Profile 的每日提醒
+    public func cancelDaily(for scope: ProfileScope) {
+        notificationCenter.removePendingNotificationRequests(
+            withIdentifiers: [SnapDrillNotificationID.dailyReview(for: scope.id)]
+        )
+        SnapDrillLogger.generic.info("已取消每日复习提醒 profile=\(scope.id.uuidString)")
+    }
+
+    /// 管理员/重置语义：仅取消 SnapDrill 管理的通知。
+    public func cancelAllSnapDrillNotifications() async {
+        let identifiers = await notificationCenter.pendingNotificationRequests()
+            .map(\.identifier)
+            .filter(SnapDrillNotificationID.isManaged)
+        guard !identifiers.isEmpty else { return }
+        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
+        SnapDrillLogger.generic.info("已取消 SnapDrill 管理的通知 count=\(identifiers.count)")
     }
 }
```

### `Packages/SnapDrillCore/Sources/SnapDrillCore/Service/NotificationServiceMock.swift`

```diff
@@
     /// `scheduleDaily(at:minute:)` 被调用时记录的参数
-    public private(set) var scheduledHours: [(hour: Int, minute: Int)] = []
+    public private(set) var scheduledHours: [(hour: Int, minute: Int, profileId: UUID)] = []
 
-    /// `cancelAll()` 被调用的次数
-    public private(set) var cancelAllCallCount = 0
+    public private(set) var cancelledProfileIds: [UUID] = []
+    public private(set) var cancelAllSnapDrillCallCount = 0
@@
-    public func scheduleDaily(at hour: Int, minute: Int) async throws {
+    public func scheduleDaily(at hour: Int, minute: Int, for scope: ProfileScope) async throws {
         if let error = simulatedError {
             throw error
         }
-        scheduledHours.append((hour, minute))
+        scheduledHours.append((hour, minute, scope.id))
     }
 
-    public func cancelAll() {
-        cancelAllCallCount += 1
+    public func cancelDaily(for scope: ProfileScope) {
+        cancelledProfileIds.append(scope.id)
+    }
+
+    public func cancelAllSnapDrillNotifications() async {
+        cancelAllSnapDrillCallCount += 1
     }
@@
-        cancelAllCallCount = 0
+        cancelledProfileIds.removeAll()
+        cancelAllSnapDrillCallCount = 0
```

### `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/NotificationSettingsViewModel.swift`

```diff
@@
     private let notificationService: NotificationServiceProtocol
+    private let profileScope: ProfileScope
@@
-    init(notificationService: NotificationServiceProtocol) {
+    init(notificationService: NotificationServiceProtocol, profileScope: ProfileScope) {
         self.notificationService = notificationService
+        self.profileScope = profileScope
     }
@@
-            try await notificationService.scheduleDaily(at: hour, minute: minute)
+            try await notificationService.scheduleDaily(at: hour, minute: minute, for: profileScope)
         } catch {
             SnapDrillLogger.generic.error("安排每日通知失败: \(error.localizedDescription)")
-            notificationService.cancelAll()
+            notificationService.cancelDaily(for: profileScope)
@@
-        notificationService.cancelAll()
+        notificationService.cancelDaily(for: profileScope)
@@
-            try await notificationService.scheduleDaily(at: hour, minute: minute)
+            try await notificationService.scheduleDaily(at: hour, minute: minute, for: profileScope)
```

### `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/NotificationSettingsView.swift`

```diff
@@
 import SwiftUI
 import SnapDrillCore
+import SnapDrillData
@@
     @Environment(\.services) private var services
+    @Environment(\.profileManager) private var profileManager
@@
         .onAppear {
             if viewModel == nil {
-                viewModel = NotificationSettingsViewModel(notificationService: services.notification)
+                guard let scope = profileManager.activeScope else {
+                    assertionFailure("ProfileScope missing while building NotificationSettingsViewModel")
+                    return
+                }
+                viewModel = NotificationSettingsViewModel(
+                    notificationService: services.notification,
+                    profileScope: scope
+                )
             }
         }
```

这里不改 `ProfileManager.swift` 主流程；`AppRootView` 已在 loaded content 注入 `.environment(\.profileManager, profileManager)`，Settings 层可直接读取当前 scope。

## 测试 patch

### Core 隔离测试

建议在 `Packages/SnapDrillCore/Tests/SnapDrillCoreTests/NotificationServiceTests.swift` 新增 fake center 与以下测试。

```swift
import UserNotifications

private final class FakeNotificationCenter: UserNotificationScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var pendingStorage: [String: UNNotificationRequest] = [:]
    private var removedStorage: [[String]] = []

    func add(_ request: UNNotificationRequest) async throws {
        lock.withLock {
            pendingStorage[request.identifier] = request
        }
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        lock.withLock {
            Array(pendingStorage.values)
        }
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        lock.withLock {
            removedStorage.append(identifiers)
            for identifier in identifiers {
                pendingStorage.removeValue(forKey: identifier)
            }
        }
    }

    func seed(_ request: UNNotificationRequest) {
        lock.withLock {
            pendingStorage[request.identifier] = request
        }
    }
}

private func scope(_ uuid: String) -> ProfileScope {
    ProfileScope(id: UUID(uuidString: uuid)!, name: uuid)
}

private func dummyRequest(id: String) -> UNNotificationRequest {
    UNNotificationRequest(
        identifier: id,
        content: UNMutableNotificationContent(),
        trigger: nil
    )
}
```

边界测试：

```swift
@Test("同一 Profile 重复 scheduleDaily 只覆盖自身通知")
func scheduleDailyReplacesOnlySameProfile() async throws {
    let center = FakeNotificationCenter()
    let service = LiveNotificationService(notificationCenter: center)
    let profileA = scope("00000000-0000-0000-0000-000000000001")
    let profileB = scope("00000000-0000-0000-0000-000000000002")

    try await service.scheduleDaily(at: 8, minute: 0, for: profileA)
    try await service.scheduleDaily(at: 19, minute: 0, for: profileB)
    try await service.scheduleDaily(at: 20, minute: 30, for: profileA)

    let pending = await center.pendingNotificationRequests()
    let identifiers = Set(pending.map(\.identifier))
    #expect(identifiers == [
        SnapDrillNotificationID.dailyReview(for: profileA.id),
        SnapDrillNotificationID.dailyReview(for: profileB.id)
    ])
}

@Test("Profile A 设置后切到 B 设置不会擦除 A")
func scheduleDailyForBPreservesA() async throws {
    let center = FakeNotificationCenter()
    let service = LiveNotificationService(notificationCenter: center)
    let profileA = scope("00000000-0000-0000-0000-000000000011")
    let profileB = scope("00000000-0000-0000-0000-000000000012")

    try await service.scheduleDaily(at: 20, minute: 0, for: profileA)
    try await service.scheduleDaily(at: 19, minute: 0, for: profileB)

    let identifiers = Set(await center.pendingNotificationRequests().map(\.identifier))
    #expect(identifiers.contains(SnapDrillNotificationID.dailyReview(for: profileA.id)))
    #expect(identifiers.contains(SnapDrillNotificationID.dailyReview(for: profileB.id)))
    #expect(identifiers.count == 2)
}

@Test("disable on Profile A 只擦 A 通知")
func cancelDailyRemovesOnlySelectedProfile() async throws {
    let center = FakeNotificationCenter()
    let service = LiveNotificationService(notificationCenter: center)
    let profileA = scope("00000000-0000-0000-0000-000000000021")
    let profileB = scope("00000000-0000-0000-0000-000000000022")

    try await service.scheduleDaily(at: 20, minute: 0, for: profileA)
    try await service.scheduleDaily(at: 19, minute: 0, for: profileB)
    service.cancelDaily(for: profileA)

    let identifiers = Set(await center.pendingNotificationRequests().map(\.identifier))
    #expect(!identifiers.contains(SnapDrillNotificationID.dailyReview(for: profileA.id)))
    #expect(identifiers.contains(SnapDrillNotificationID.dailyReview(for: profileB.id)))
}

@Test("cancelAllSnapDrillNotifications 只删除 SnapDrill managed namespace")
func cancelAllSnapDrillNotificationsKeepsExternalRequests() async throws {
    let center = FakeNotificationCenter()
    let service = LiveNotificationService(notificationCenter: center)
    let profileA = scope("00000000-0000-0000-0000-000000000031")
    let profileB = scope("00000000-0000-0000-0000-000000000032")
    await center.seed(dummyRequest(id: SnapDrillNotificationID.dailyReview(for: profileA.id)))
    await center.seed(dummyRequest(id: SnapDrillNotificationID.dailyReview(for: profileB.id)))
    await center.seed(dummyRequest(id: "com.other.local-notification"))

    await service.cancelAllSnapDrillNotifications()

    let identifiers = Set(await center.pendingNotificationRequests().map(\.identifier))
    #expect(identifiers == ["com.other.local-notification"])
}

@Test("通知 ID namespace 包含通知类型和 Profile ID")
func dailyReviewIdentifierIsProfileScoped() {
    let profileA = UUID(uuidString: "00000000-0000-0000-0000-000000000041")!
    let profileB = UUID(uuidString: "00000000-0000-0000-0000-000000000042")!

    let idA = SnapDrillNotificationID.dailyReview(for: profileA)
    let idB = SnapDrillNotificationID.dailyReview(for: profileB)

    #expect(idA.hasPrefix("com.snapdrill.notification.daily-review.profile."))
    #expect(idA.contains(profileA.uuidString.lowercased()))
    #expect(idA != idB)
    #expect(idA != SnapDrillNotificationID.legacyDailyReview)
}

@Test("scheduleDaily 触发 legacy daily-review ID 清理")
func scheduleDailyRemovesLegacyIdentifier() async throws {
    let center = FakeNotificationCenter()
    let service = LiveNotificationService(notificationCenter: center)
    let profileA = scope("00000000-0000-0000-0000-000000000051")
    await center.seed(dummyRequest(id: SnapDrillNotificationID.legacyDailyReview))

    try await service.scheduleDaily(at: 20, minute: 0, for: profileA)

    let identifiers = Set(await center.pendingNotificationRequests().map(\.identifier))
    #expect(!identifiers.contains(SnapDrillNotificationID.legacyDailyReview))
    #expect(identifiers.contains(SnapDrillNotificationID.dailyReview(for: profileA.id)))
}
```

说明：fake center 用同步 lock 而不是 actor，是为了让 `removePendingNotificationRequests(withIdentifiers:)` 的测试语义和生产 API 一样立即生效，避免 `Task {}` 桥接带来的断言竞态。

### Feature ViewModel 测试同步

`NotificationSettingsViewModelTests` 的 mock 应记录 profileId，并把旧 `cancelAllCallCount` 改成 `cancelledProfileIds`。

关键断言：

```swift
let scope = ProfileScope(id: UUID(), name: "A")
let vm = NotificationSettingsViewModel(notificationService: service, profileScope: scope)

let result = await vm.enable(hour: 9, minute: 0)

#expect(result == true)
#expect(service.lastScheduledProfileId == scope.id)
```

失败回滚与 disable：

```swift
#expect(service.cancelledProfileIds == [scope.id])
```

这可以防止 Settings 层在未来回退到无作用域通知 API。

## 验证命令

最终应用 patch 后应跑：

```bash
swiftlint --strict
xcodebuild build-for-testing \
  -scheme AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -testPlan AllTests
```

本任务只要求独立提案，且严禁直接修改生产文件；我未 apply patch，因此未执行 build-for-testing 验证修复后编译。

## 已知盲区

1. 本方案不修复通知设置 `@AppStorage(UDKey.notificationsEnabled/hour/minute)` 仍可能是全局偏好的问题。S-D4-002 的根因是系统 pending notification ID 共享；偏好是否也要 per Profile 存储应另行按产品语义裁决。
2. legacy `"com.snapdrill.daily-review"` 只在下一次 schedule 或 admin reset 时清理。若用户永远不再打开通知设置，旧 pending request 可能保留到系统触发或用户重装；我排除启动时自动清理，是为了避免在 app launch 做不可见的通知状态 mutation。
3. 本方案当前只覆盖 daily review 一种通知类型。未来如果新增错题到期提醒、备份提醒、家长周报等，应把 `SnapDrillNotificationID` 扩展成 typed namespace，并为每种通知补 profile-scoped ID 测试。
4. 本方案不设计跨设备同步通知。若未来 iCloud 同步通知设置，需要定义“每设备本地通知”与“跨设备偏好同步”的边界，避免多设备重复提醒。
5. 本方案不覆盖 Apple Watch 转发细节。Watch 通知镜像依赖 iOS 系统设置；如果未来做 watchOS app，应重新审查 identifier、category、threadIdentifier 是否也要 profile-scoped。
6. 本方案不修改 `ProfileManager.swift` 主流程。Profile 切换后 View tree 已通过 `.id(activeProfileId)` 重建；如果未来移除这个重建机制，`NotificationSettingsViewModel` 持有的 `ProfileScope` 生命周期需要重审。
