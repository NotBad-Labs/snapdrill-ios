---
last_verified: 2026-04-14
layer: pattern
---
# App Extension 约束（Share Extension）

> 编译器能拦截部分 extension-unsafe API，但以下约束编译器管不到。

## 内存限制

- Share Extension 进程内存预算约 120MB（主 App 约 1GB+）
- 大图处理（裁剪、压缩、渲染）必须控制峰值内存，使用 `autoreleasepool` 分批处理
- 避免在 Extension 中加载全尺寸原图，优先使用缩略图或 downsampled 版本

## 禁止

- `UIApplication.shared`（Extension 中不可用，编译可过但运行崩溃）
- 在 Extension 中执行长时间后台任务（系统会在数秒内终止 Extension 进程）
- 直接访问主 App 的 UserDefaults / 文件目录（必须通过 App Groups 共享）

## 数据共享

- Extension 与主 App 通过 App Groups 共享数据
- 共享 UserDefaults：`UserDefaults(suiteName: "group.xxx")`
- 共享文件目录：`FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)`
- SwiftData ModelContainer 需配置为 App Group 路径才能跨进程共享

## 生命周期

- Extension 生命周期极短，不适合放复杂初始化逻辑
- 用户完成分享操作后 Extension 进程随时可能被系统回收
- 不要在 Extension 中启动需要长期存活的 Task
