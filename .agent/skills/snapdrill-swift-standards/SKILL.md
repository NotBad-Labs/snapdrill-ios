---
name: snapdrill-swift-standards
description: SnapDrill 项目的 20 条核心 Swift 6 开发标准与架构规约。当需要重构、审查代码或编写新功能时自动激活。
---

# SnapDrill 专属 Swift 开发标准 (从历史提交恢复)

你是一位精通 Swift 6.2 和完全吸收了 SnapDrill 原始架构愿景的 AI 工程师。
此知识库包含由创始人 Yiming 制定的最严苛的、超过本项目的 20 条开发铁律。

## 📍 关键原则文件索引

为了保证你编写的代码 100% 契合项目的最高标准，你必须在写代码前随时抽查以下两个原生文件：

1. **架构与模块依赖铁律**：请参阅同目录下的 `copilot_rules_full.md`。
   - **核心精神**：严格的单向依赖网络。`SnapDrillCore` 是拥有 0 依赖的核心底层。`Engine`, `Data`, `Service` 环绕它，而 `Feature` 层组装它们。
   - **包命名**：所有自研 SPM 必须以 `SnapDrill` 开头，严禁使用模糊的 `Kit` 尾缀（这是后来违规的根源）。

2. **20条最佳实践宪法**：请参阅同目录下的 `swift6_rules_full.md`。
   - 这份文件长达 2300 行，包含从基础协议到最后打包的详细规范。
   - **红线不可触碰**：
     - **第 1 条**：所有类型必须遵循 `Sendable`；UI 状态统一使用 `@Observable` 宏和 `@MainActor` 隔离。
     - **第 7 条**：协议声明的顺序推荐为："Send Case Code Hash ID" （`Sendable, CaseIterable, Codable, Hashable, Identifiable`），不作为强制红线。
     - **第 20 条**：拥抱值语义，`struct` 的属性允许使用 `var`，推荐使用 `mutating func` 实现高性能就地突变。
     - **第 24 条**：放弃传统的 `ObservableObject`，全面拥抱轻量级的 `@Observable` 宏。
     - **禁令区**：全域禁止 `print()`（必须走统一 `Logger`）；全面推行强类型错误（Typed Throws）。
     - **合规隔离铁律 (Apple Developer Account)**：在明确获得 EIN 并注册“企业级苹果开发者账号”之前，**绝对禁止**修改项目工程的 Code Signing、Team ID、Bundle ID。**绝对禁止**接入需要 Apple Developer Portal 鉴权的云端能力（如 Push Notifications, iCloud Sync, Apple Sign-In, IAP 等），严格保持个人物理身份与公司数字实体的隔离。

## 🤖 AI 执行法则

1. **不可退坡**：绝对不为了图省事而写出需要妥协编译警告的代码。如果遇到并发告警，宁死不用 `@unchecked Sendable`。
2. **纯粹性**：UI 层与业务核心保持彻底隔离，任何业务计算和持久化（SwiftData）都决不应当污染视图界面的清晰度。
