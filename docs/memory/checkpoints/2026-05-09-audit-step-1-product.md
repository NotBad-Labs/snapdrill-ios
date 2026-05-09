---
last_verified: 2026-05-09
layer: snapshot
freshness:
  max_age_days: 90
  decay_trigger: [next_audit]
---
# Step 1: 产品运行体系审计

## Goal

审计全部 Swift 源码（~33,000 行）在 5 个维度上的健康度：并发安全、数据安全、错误处理、架构合规、隐私合规。

## Scope

201 文件：Swift 源码(177) + 资源/lproj/xcassets(12) + PrivacyInfo/entitlements/plist(12)

## Findings by Dimension

### A. 并发安全

**nonisolated(unsafe) 审计：5 处声明，4 个独立位置。**

| 位置 | 用途 | 正当性 |
|---|---|---|
| `DataExecutor.swift:40` | `nonisolated public let container: ModelContainer` | ✅ Apple SDK Sendable + init-once read-only |
| `PDFPagePickerView.swift:156-157` | PDFPage 跨隔离域传递 | ✅ 有注释说明 |
| `CameraSessionManager.swift:83` | `AVCaptureSession()` | ✅ Apple SDK + 专用串行队列 |
| `CameraSessionManager.swift:98` | `onRegionDetected` 闭包 | ✅ MainActor set / nonisolated read |
| `CameraSessionManager.swift:99` | `onCapture` 闭包 | ✅ 同上 |

**结论**：全部 5 处有 inline 注释说明正当理由，均为 Apple SDK 类型或明确的跨隔离域模式。**无滥用**。

**Warning (1): PersistenceController 类型未标记 @available(deprecated)**
- `Persistence.swift:19-24` — 声明了 `public final class PersistenceController` + `shared` 单例
- 生产调用路径已迁移到 DataExecutor（DependencyContainer 通过 RepositoryContainer → DataExecutor 访问 ModelContainer）
- PersistenceController.shared 无任何生产调用方（仅自身声明）
- 但类型本身无 `@available(*, deprecated, message: "Use DataExecutor")` 标记
- 风险：未来开发者可能引用 PersistenceController 而非 DataExecutor

### B. 数据安全

**✅ EXIF GPS 剥离**：ImageStorage.compressedJPEGData 使用 CGImageDestination 从 CGImage 编码，CGImage 不携带 EXIF 元数据（含 GPS）。文档详尽。

**✅ Share Extension 数据隔离**：Share Extension 通过 App Group 共享容器写入，ImageStorage 统一处理去 EXIF。

**✅ Firebase 默认不采集**：FirebaseBootstrap 依赖 GoogleService-Info.plist 预设 `FIREBASE_ANALYTICS_COLLECTION_DEACTIVATED=YES` + `FirebaseCrashlyticsCollectionEnabled=NO`。DependencyContainer 通过 `AppConfiguration.FeatureFlags.analyticsEnabled` 双重 opt-in 守卫。

**✅ 零注册、纯本地架构**：无用户账户系统、无数据外传路径。

**Warning (1): Share Extension 临时文件 EXIF 残留**
- 基线审计 X5 已记录：Share Extension 在 ImageStorage 处理前，原始文件短暂存在于共享容器
- 已记录为设计级考虑，后续排期处理
- 不做新发现

### C. 错误处理

**try? 审计：17 个文件，共计 46+ 处 try?。**

逐处检查：

| 状态 | 数量 | 说明 |
|---|---|---|
| ✅ 有 best-effort 注释 | 40+ | 合规 |
| ⚠️ 缺注释（非 Task.sleep） | 3 | AppRouter:128, ImageStorage:183, DataAndSyncSettingsView:319 |
| ℹ️ Task.sleep（低风险） | 3 | DashboardAnalytics:187, Dashboard:142, AppRouter:136 |

**Warning (2): 3 处 try? 缺少 best-effort 注释**

| 文件:行 | 内容 | 风险 |
|---|---|---|
| `AppRouter.swift:128` | `try? FileManager.default.removeItem(at: pendingURL)` | 低（pending URL 已过期，删不掉不影响） |
| `ImageStorage.swift:183` | `try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize` | 极低（获取文件大小失败返回 nil） |
| `DataAndSyncSettingsView.swift:319` | `try? fileURL.resourceValues(forKeys: [.fileSizeKey])` | 极低（同上） |

注：3 处 Task.sleep 的 try? 无需注释（Swift 并发语法要求 `try? await`，不是错误处理模式）。

### D. 架构合规

**✅ 依赖方向全部正确**（独立 grep 验证，与 CI 检查一致）：
- Core → 无下游 import ✅
- Data → 只有 Core ✅
- UI → 只有 Core ✅
- Infrastructure → 只有 Core ✅
- Features → 不 import Infrastructure ✅

**✅ DataExecutor 迁移完成**：
- 生产调用路径：DependencyContainer → RepositoryContainer(executor:) → DataExecutor.container.mainContext
- PersistenceController 仅作兼容类型声明保留，无生产调用方

**Info (1): ZIPFoundation 架构泄漏已于 PR #740 修复**
- `ZIPArchiver` 已抽到 Data 层
- 基线审计 X4 已闭合

### E. 隐私合规

**✅ PrivacyInfo.xcprivacy 声明完整**：
- NSPrivacyTracking: false
- 3 类收集数据：CrashData、OtherDiagnosticData、ProductInteraction — 全部 NOT linked、NOT tracking
- 4 类 Required Reason APIs 正确声明：UserDefaults(CA92.1)、FileTimestamp(C617.1)、DiskSpace(E174.1)、SystemBootTime(35F9.1)

**✅ Entitlements**：App Group + iCloud/CloudKit（SwiftData + Share Extension 必需）

**Warning (3): zh-Hans 本地化缺失 16 个 key**

| 缺失分组 | 数量 | 示例 key |
|---|---|---|
| library 相关 | 6 | `library.export_images`, `library.share_card_title` 等 |
| settings.import 相关 | 10 | `settings.import_csv`, `settings.import_complete` 等 |

风险：中文用户看到英文文本。CSV 导入功能的中文 UI 不完整。

## Score

| 维度 | 得分 | 说明 |
|---|---|---|
| 并发安全 | 8/10 | nonisolated(unsafe) 全部正当，PersistenceController 未标 deprecated |
| 数据安全 | 9/10 | 核心路径安全，Share Extension EXIF 已知待处理 |
| 错误处理 | 8/10 | 绝大多数 try? 有注释，3 处缺失 |
| 架构合规 | 9/10 | 依赖方向零违规，DataExecutor 迁移完成 |
| 隐私合规 | 7/10 | PrivacyInfo 完整，但 zh-Hans 缺失 16 个 key |
| **综合** | **8.2/10** | |

## Next

Step 7: 依赖与供应链审计
