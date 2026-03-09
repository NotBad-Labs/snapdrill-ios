# SnapDrillCore

**零依赖内核 (Zero-Dependency Kernel)**

`SnapDrillCore` 包含应用共享的业务模型、基础服务、算法引擎和通用工具。不依赖任何本地包或 UI 框架。

## 组成部分

### 1. Model (业务模型)
- `Difficulty`: 难度枚举（1-5 星）
- `SubscriptionProduct` / `SubscriptionStatus`: 订阅相关类型

### 2. Engine (算法引擎)
- `ReviewScheduler`: SM-2 间隔重复调度器
- `SM2State`: 调度状态值类型
- `ReviewRating`: 用户评分枚举

### 3. Service (基础服务)
- `OCRService` / `OCRServiceProtocol`: 文本识别（基于 Apple Vision）
- `ImageStorage`: 图片文件管理（保存/加载/删除）
- `PDFExportService`: PDF 导出服务
- `CaptureDraftService` / `CaptureDraftServiceProtocol`: 采集草稿缓存
- `AnalyticsServiceProtocol` / `CrashReportingProtocol`: 分析与崩溃上报协议
- `NotificationServiceProtocol`: 通知服务协议
- `SubscriptionServiceProtocol`: 订阅服务协议
- `NetworkMonitor`: 网络状态监控
- `PrivacyConsentService`: 隐私授权管理
- `AppConfiguration`: 应用配置（含 FeatureFlags）

### 4. Support (支撑类型)
- `ReviewDataNotification`: 跨模块通知名定义
- `SnapDrillLogger`: 日志系统（基于 os.Logger）
- `ServiceContainer` / `LiveServiceContainer`: 服务容器协议与实现

### 5. Utils (通用工具)
- `Date+Extension`, `Collection+Safe`, `Color+Hex` 等基础扩展

## 依赖
- *无依赖*（纯 Swift）
