---
id: ADR-005
status: Accepted
date: 2026-03-04
---

# ADR-005: SnapDrillInfrastructure 包隔离（Firebase 封装）

## 背景

项目需要集成 Firebase（Analytics、Crashlytics、RemoteConfig）用于匿名行为分析和崩溃报告。Firebase SDK 体积大、依赖多，且不遵循 Swift 严格并发。需要决定如何组织 Firebase 相关代码。

## 决策

**创建独立的 SnapDrillInfrastructure 包，持有所有 Firebase 实现。仅 SnapDrill/App target 可 import 此包，其他所有包（Core、Data、UI、Features）禁止 import。**

Core 包定义服务协议（AnalyticsServiceProtocol、CrashReportingProtocol 等），Infrastructure 包提供具体实现（FirebaseAnalyticsService、CrashReportingService 等），DependencyContainer 在 App 层完成组装。

## 被否决的方案

### 方案 A：Firebase 代码直接放在 App target

- **为什么否决**：App target 是薄壳组合根，不应该持有业务逻辑或服务实现。Firebase 的配置、事件映射、错误处理都是实现细节，应该被封装
- **补充**：App target 直接持有 Firebase 代码会导致 Firebase import 污染组合根的可读性

### 方案 B：Firebase 代码放在 Core 包

- **为什么否决**：Core 包是零外部依赖的纯逻辑包，可以在 macOS 上 `swift test`。引入 Firebase SDK 后 Core 包的独立可测试性被破坏，且所有依赖 Core 的包都会间接依赖 Firebase

### 方案 C：不用独立包，通过 SPM 条件编译隔离

- **为什么否决**：条件编译（`#if canImport(FirebaseAnalytics)`）分散在代码库各处，难以维护且无法通过包结构强制隔离。独立包通过 import 规则在编译器层面禁止越权访问

## 后果

**正面**：
- Core 包保持零外部依赖，`swift test` 24/24 通过
- Firebase SDK 的更新、替换、移除只影响 Infrastructure 包
- 编译器强制：Features/Data/UI 包无法意外 import Firebase

**负面**：
- 新增 Firebase 功能需要在 Core（协议）和 Infrastructure（实现）两处修改
- Gemini Review 使用 `ubuntu-latest` runner，不占用 Mac mini 资源，但 Infrastructure 包的编译仍需 macOS

**技术债**：无。
