# ``SnapDrillCore``

零依赖核心库，提供 SM-2 调度算法、OCR 服务、图片存储、采集草稿、日志和通用工具。

## 概述

`SnapDrillCore` 是整个模块体系的最底层，不依赖任何本地包。
所有其他包（`SnapDrillData`、`SnapDrillUI`、五个 Feature 包）均可安全 import。

依赖方向：`SnapDrillFeature*` / `SnapDrillData` / `SnapDrillUI` ──► `SnapDrillCore`

## 主要类型

### 复习调度引擎

- ``ReviewScheduler`` — SM-2 间隔重复算法的核心实现
- ``SM2State`` — 封装单道题目的复习状态（ease factor、interval、repetitions）
- ``ReviewRating`` — 用户评价（Again / Hard / Good / Easy）
- ``Difficulty`` — 题目难度等级（1–5 星）

### 采集能力（`Capture/` 子目录）

- ``OCRService`` — 基于 Vision 框架的图片文字识别（遵循 `OCRServiceProtocol`）
- ``ImageStorage`` — 图片本地持久化（存储在 `Documents/images/`）

### 服务（`Service/` 子目录）

- ``CaptureDraftService`` — 跨域草稿缓存（Dashboard 检测 / Capture 消费），`@MainActor` 单例
- ``PDFExportService`` — 从 `[any PDFExportable]` 生成 PDF Data

### 协议

- ``OCRServiceProtocol`` — OCR 服务协议，供 ViewModel 注入和测试替换
- ``PDFExportable`` — PDF 导出协议，`ReviewExportSnapshot` 遵循
- ``ServiceContainer`` — 所有应用服务的协议约定
- ``AnalyticsServiceProtocol`` — Analytics 事件上报协议
- ``CaptureDraftServiceProtocol`` — 采集草稿服务协议
- ``NotificationServiceProtocol`` — 本地通知调度协议
- ``RemoteConfigurable`` — 远程配置读取协议

### 枚举

- ``AnalyticsEvent`` — Analytics 事件类型定义

### 服务

- ``PrivacyConsentService`` — ATT 隐私授权请求与状态查询
- ``LiveNotificationService`` — 本地推送通知调度

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
- `Date.relativeDescription(relativeTo:)` — 中文相对时间描述
