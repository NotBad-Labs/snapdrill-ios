# ``SnapDrillCore``

零依赖核心库，提供 SM-2 调度算法、OCR 识别、图片存储、日志和通用工具。

## 概述

`SnapDrillCore` 是整个模块体系的最底层，不依赖任何本地包。
其他所有包（`SnapDrillData`、`SnapDrillUI`、`SnapDrillFeatures`）均可安全 import。

## 主要类型

### 复习调度引擎

- ``ReviewScheduler`` — SM-2 间隔重复算法的核心实现
- ``SM2State`` — 封装单道题目的复习状态（ease factor、interval、repetitions）
- ``ReviewRating`` — 用户评价（Again / Hard / Good / Easy）
- ``Difficulty`` — 题目难度等级（1–5 星）

### 服务

- ``OCRService`` — 基于 Vision 框架的图片文字识别
- ``ImageStorage`` — 图片本地持久化（存储在 `Documents/images/`）
- ``NetworkMonitor`` — 实时网络状态监控

### 日志

- ``SnapDrillLogger`` — 基于 `os.Logger` 的结构化日志，禁止使用 `print()`

### 依赖注入

- ``ServiceContainer`` — 所有服务的协议约定
- ``LiveServiceContainer`` — 生产环境实现

### 通知

- `Notification.Name.reviewDataDidChange` — 数据写操作后广播
- `Notification.Name.switchToCaptureTab` / `switchToLibraryTab` / `switchToSettingsTab` — Tab 切换

## 扩展工具

- `Collection[safe:]` — 安全数组下标访问，防止越界崩溃
- `Date.iso8601DateString` — ISO8601 日期字符串（YYYY-MM-DD）
- `Date.relativeDescription(relativeTo:)` — 中文相对时间描述
