# SnapDrillCore

**核心逻辑层 (Core Logic Layer)**

`SnapDrillCore` 包含应用共享的业务模型、基础服务、算法引擎和通用工具。不依赖任何本地包。部分服务因处理图片/颜色而 import UIKit/SwiftUI。

## 组成部分

### 1. Model (业务模型)
- `Difficulty`: 难度枚举（1-5 星）
- `Profile`: 用户 Profile 值类型（Multi-Profile 支持）

### 2. Engine (算法引擎)
- `ReviewScheduler`: SM-2 间隔重复调度器
- `SM2State`: 调度状态值类型
- `ReviewRating`: 用户评分枚举

### 3. Service (基础服务)
- `OCRService` / `OCRServiceProtocol`: 文本识别（基于 Apple Vision）
- `ImageStorage`: 图片文件管理（保存/加载/删除）
- `PDFExportService`: PDF 导出服务
- `PDFExportOptions`: PDF 导出配置（去答案、留白、页眉等）
- `CaptureDraftService` / `CaptureDraftServiceProtocol`: 采集草稿缓存
- `AnalyticsServiceProtocol` / `AnalyticsEvent`: 分析服务协议与事件枚举
- `NotificationServiceProtocol`: 通知服务协议
- `PrivacyConsentService`: 隐私授权管理
- `PDFExportable`: PDF 导出能力协议

### 4. DI (依赖注入)
- `ServiceContainer`: 服务容器协议
- `LiveServiceContainer`: 生产环境服务容器
- `MockServiceContainer`: 测试用 Mock 容器

### 5. Support (支撑类型)
- `AppConfiguration` / `RemoteConfigurable`: 应用配置与远程配置协议
- `Notification.Name` 扩展: 跨模块通知名（reviewDataDidChange 等）
- `SnapDrillLogger`: 日志系统（基于 os.Logger）
- `SnapDrillError` / `OCRError` / `ImageStorageError`: 错误类型
- `ReviewSwipeTip` / `FieldConfigTip`: TipKit 提示定义

### 6. Utils (通用工具)
- `Date+Extensions`, `Collection+Safe`, `Color+Hex` 等基础扩展

## 依赖
- *无本地包依赖*（纯 Swift + Apple 框架）
