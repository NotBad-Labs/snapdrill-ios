# ``SnapDrillCore``

> 当前实现 API 参考，不定义 Release 1 可见能力。`Profile` 与 Review 类型仍在 live code 中，
> 但单资料库和公开能力边界由上游产品 / 数据合同决定。

核心逻辑层，提供 SM-2 调度算法、OCR 服务、图片存储、采集草稿、日志和通用工具。

## 概述

`SnapDrillCore` 是整个模块体系的最底层，不依赖任何本地包（部分服务因处理图片/颜色而 import UIKit/SwiftUI）。
所有其他包（`SnapDrillData`、`SnapDrillUI`、五个 Feature 包）均可安全 import。

依赖方向：`SnapDrillFeature*` / `SnapDrillData` / `SnapDrillUI` ──► `SnapDrillCore`

## 主要类型

### 业务模型

- ``Profile`` — 当前 Multi-Profile 实现遗留的值类型

### 回顾调度引擎

- ``ReviewScheduler`` — SM-2 间隔重复算法的核心实现
- ``SM2State`` — 封装单份资料的回顾调度状态（ease factor、interval、repetitions）
- ``ReviewRating`` — 用户评价（Again / Hard / Good / Easy）

### 采集能力（`Capture/` 子目录）

- ``OCRService`` — 基于 Vision 框架的图片文字识别（遵循 `OCRServiceProtocol`）
- ``ImageStorage`` — 图片本地持久化（存储在 `Documents/images/`）

### 服务（`Service/` 子目录）

- ``CaptureDraftService`` — 跨域草稿缓存（Dashboard 检测 / Capture 消费），`@MainActor` 单例
- ``PDFExportService`` — 从 `[any PDFExportable]` 生成 PDF Data
- ``PDFExportOptions`` — PDF 导出配置（去答案、留白答题区、页眉页码等）
- ``PrivacyConsentService`` — 隐私授权服务（ATT 已移除，ADR-002）
- ``LiveNotificationService`` — 本地推送通知调度

### 协议

- ``OCRServiceProtocol`` — OCR 服务协议，供 ViewModel 注入和测试替换
- ``PDFExportable`` — PDF 导出协议，`ArchiveExportSnapshot` 遵循
- ``ServiceContainer`` — 所有应用服务的协议约定
- ``AnalyticsServiceProtocol`` — Analytics 事件上报协议
- ``CaptureDraftServiceProtocol`` — 采集草稿服务协议
- ``NotificationServiceProtocol`` — 本地通知调度协议
- ``RemoteConfigurable`` — 远程配置读取协议

### 枚举与错误

- ``AnalyticsEvent`` — Analytics 事件类型定义
- ``SnapDrillError`` — 应用级通用错误
- ``OCRError`` — OCR 识别错误
- ``ImageStorageError`` — 图片存储错误

### 配置

- ``AppConfiguration`` — 应用环境信息和功能开关

### DI 容器

- ``LiveServiceContainer`` — 生产环境服务容器实现
- ``MockServiceContainer`` — 测试和 Preview 用 Mock 服务容器

### 日志

- ``SnapDrillLogger`` — 基于 `os.Logger` 的结构化日志，禁止使用 `print()`

### 通知

- `Notification.Name.reviewDataDidChange` — 数据写操作后广播，驱动非 `@Query` 视图刷新
- `Notification.Name.switchToCaptureTab` / `switchToLibraryTab` / `switchToSettingsTab` — Tab 切换

## 扩展工具

- `Collection[safe:]` — 安全数组下标访问，防止越界崩溃
- `Date.iso8601DateString` — ISO8601 日期字符串（YYYY-MM-DD）
- `Date.relativeDescription(relativeTo:)` — 相对时间描述（L10n 本地化）
