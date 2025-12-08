# Code Review 指南 — NotBad 项目

**版本**: 5.0 (Pragmatic Edition)  
**适用范围**: NotBad (iOS K12 错题本)

本文档为团队统一的代码审查（Code Review）准则。我们的目标是在保持**开发效率**（实用主义）的同时，交付符合 **Apple Design Awards** 标准的高质量教育应用。

> 说明：风格细节以 `docs/CODING_STANDARDS.md` 为准，本指南聚焦评审检查项；如有冲突，优先级为 ADR → CODING_STANDARDS → 本指南。

> **🎯 愿景**：通过原生架构发挥平台优势，在创新、包容性、用户体验上追求卓越。

请在每次 PR 评审时参考下列 **15 个核心维度** 逐项核对。

---

## 目录

1. [命名与代码风格](#1-命名与代码风格)
2. [架构与依赖 (实用主义版)](#2-架构与依赖-实用主义版)
3. [SOLID 原则](#3-solid-原则)
4. [并发与安全 (Swift 6)](#4-并发与安全-swift-6)
5. [领域驱动设计 (Rich Model)](#5-领域驱动设计-rich-model)
6. [性能与资源管理 (图片特规)](#6-性能与资源管理-图片特规)
7. [隐私与数据安全](#7-隐私与数据安全)
8. [无障碍与包容性](#8-无障碍与包容性)
9. [本地化与国际化](#9-本地化与国际化)
10. [SwiftUI 最佳实践](#10-swiftui-最佳实践)
11. [用户体验与交互](#11-用户体验与交互)
12. [错误处理与日志](#12-错误处理与日志)
13. [测试策略](#13-测试策略)
14. [文档与可维护性](#14-文档与可维护性)
15. [网络层规范 (预留)](#15-网络层规范-预留)

---

## 1. 命名与代码风格

> 详细风格规范已汇总于 `docs/CODING_STANDARDS.md`，评审时仅需确认是否遵循该文档；如需具体规则（命名、协议顺序、Design Tokens），请直接参阅 CODING_STANDARDS。

---

## 2. 架构与依赖 (实用主义版)

我们放弃严格的分层（Domain/Data/Presentation），采用 **SwiftData 原生驱动** 架构。

### 2.1 核心组件职责

| 组件 | 职责 | 允许依赖 | 禁止依赖 |
|------|------|---------|---------|
| **Models** (`@Model`) | 数据库定义、简单的业务计算 | Foundation, SwiftData | SwiftUI Views |
| **Services** (Struct) | **核心逻辑**、算法、IO操作 | Foundation, UIKit (仅限图片处理) | SwiftUI Views |
| **Views** (SwiftUI) | UI 布局、状态展示 | Models, Services, SwiftData | - |

### 2.2 数据流向

```text
Database (@Model) → @Query (自动刷新) → View
         ↑                                |
         └──────── Service (逻辑/IO) ──────┘
```

- **读取**：View 使用 `@Query` 直接驱动 UI。
- **写入**：View 调用 `modelContext` 或 `Service`（如图片保存）。
- **逻辑**：无状态的复杂逻辑（如复习算法）下沉至 `Service`。

### 2.3 关键检查点

- [ ] **拒绝中间商**：不应存在 `Entity` ↔ `Mapper` ↔ `Model` 的转换代码。
- [ ] **View 直连**：列表页应直接使用 `@Query`，禁止通过 ViewModel 手动 Fetch。
- [ ] **逻辑隔离**：复杂的算法（如计算下次复习时间）必须在 `Service` 中。

### 2.4 未来演进：物理模块化

> **核心洞察**：只要代码还在同一个 Target 里，混乱就会像引力一样不可避免。文件夹分层是"君子协定"，Package 隔离是"物理围墙"。

**物理隔离 vs 逻辑分层**：

| 方式 | 约束 | 违反代价 |
|------|------|---------|
| 逻辑分层 | "Domain 层不能引用 UIKit" | 只是代码审查时被说一句 |
| 物理隔离 | Package.swift 里没有 UIKit | **编译不过** |

**目标结构**：

```
NotBad (App Target) - 只是一层薄薄的 UI
└── Packages/
    ├── ReviewKit    # 🧠 大脑：数据、算法、逻辑
    ├── ImageKit     # 图片处理
    └── OCRKit       # 文字识别
```

**终极测试**：创建一个 macOS 命令行工具 Target，依赖 ReviewKit，能直接跑通复习算法——如果做到了，架构就超越了 90% 的独立开发者。

> 详见 [ADR-007: 模块化演进方向](adr/ADR-007-modularization-direction.md)

---

## 3. SOLID 原则

在实用主义架构下，重点关注 **单一职责 (SRP)**。

- **View**: 只负责渲染。如果 `body` 超过 200 行，拆分 Subview。
- **Model**: 包含数据和与其紧密相关的业务属性（如 `isMastered`）。
- **Service**: 包含独立于数据的逻辑（如 `OCRService`, `ImageStorageService`）。

---

## 4. 并发与安全 (Swift 6)

### 4.1 Actor 隔离

- **UI & Model**: 均运行在 `@MainActor`。
- **后台任务**: 图片压缩、OCR 解析必须在后台 Task 执行，避免阻塞 UI。

### 4.2 结构化并发

```swift
// ✅ 正确：支持取消
func processImage(_ data: Data) async throws -> String {
    try await Task.detached {
        try Task.checkCancellation()
        return try ImageProcessor.save(data)
    }.value
}
```

---

## 5. 领域驱动设计 (Rich Model)

### 5.1 充血模型

直接在 `@Model` 类中实现业务属性，不再创建额外的 Domain Entity。

```swift
@Model
final class ReviewItem {
    var wrongCount: Int
    var lastReviewDate: Date
    
    // ✅ 业务逻辑直接写在 Model
    var isHardQuestion: Bool {
        wrongCount > 5
    }
    
    // ✅ 简单的状态变更
    func markAsReviewed() {
        self.wrongCount -= 1
        self.lastReviewDate = Date()
    }
}
```

### 5.2 核心逻辑分离 (The Brain)

不依赖状态的纯数学/逻辑计算，放入纯 Swift Service。

```swift
struct ReviewAlgorithm {
    // 纯函数：易于测试
    static func nextReviewDate(current: Date, history: [ReviewLog]) -> Date {
        // ... 艾宾浩斯算法实现 ...
    }
}
```

---

## 6. 性能与资源管理 (图片特规)

### 6.1 🚨 图片存储铁律

**严禁将图片二进制数据 (`Data`) 直接存入 SwiftData。**

| 存储位置 | 内容 | 访问方式 |
|---------|------|---------|
| **SwiftData** | 图片路径字符串 | `item.imagePath` (String) |
| **FileManager** | 图片文件 (`.jpg`) | `ImageStorageService` |

**检查点**：

- [ ] Model 中**没有** `Data` 类型的图片字段。
- [ ] 图片保存必须通过 `ImageStorageService` 写入磁盘，仅返回文件名存库。
- [ ] 删除 Model 时，必须同步调用 Service 删除对应的磁盘文件。

### 6.2 查询优化

- [ ] 使用 `#Predicate` 在数据库层过滤，禁止在内存中 `.filter()` 大数组。
- [ ] 使用 `@Query` 时尽可能指定 `FetchDescriptor` 的 `fetchLimit`（如适用）。

---

## 7. 隐私与数据安全

### 7.1 儿童隐私 (COPPA)

- [ ] **不收集**任何个人身份信息 (PII)。
- [ ] **不包含**第三方广告 SDK。
- [ ] 图片数据仅存储在本地（或用户个人的 iCloud），不上传至我们服务器。

### 7.2 权限管理

- [ ] 相机/相册权限仅在用户点击相关按钮时请求，并提供清晰用途说明。

---

## 8. 无障碍与包容性

### 8.1 基础标准

- [ ] **VoiceOver**: 所有交互元素必须有 `accessibilityLabel`。
- [ ] **Dynamic Type**: 文字必须随系统字体大小缩放（使用 `.font(.body)` 等语义字体）。
- [ ] **对比度**: 颜色对比度需符合 WCAG AA 标准。

```swift
// ✅ 良好的无障碍实践
Button(action: scan) {
    Image(systemName: "camera")
}
.accessibilityLabel("扫描题目")
.accessibilityHint("双击打开相机拍摄错题")
```

---

## 9. 本地化与国际化

- [ ] 所有用户可见文本必须使用 `LocalizedStringKey`。
- [ ] 日期/数字使用系统格式化器（`.formatted(.dateTime)`）。
- [ ] 支持简体中文与英文。

---

## 10. SwiftUI 最佳实践

### 10.1 状态管理

- **View 私有状态**: 使用 `@State`。
- **数据模型**: 使用 `@Bindable` (iOS 17+) 或 `@ObservedObject`。
- **列表渲染**: 使用 `List` 或 `LazyVStack`，且 Model 必须遵循 `Identifiable`。

### 10.2 避免过度计算

```swift
// ✅ 提取复杂计算到属性
var formattedDate: String {
    item.date.formatted()
}

var body: some View {
    Text(formattedDate) // 不要在 body 里直接调 formatter
}
```

---

## 11. 用户体验与交互

- [ ] **状态反馈**: 加载中显示 `ProgressView`，空数据使用 `ContentUnavailableView`。
- [ ] **触觉反馈**: 重要操作（如保存、删除）触发 `HapticFeedback`。
- [ ] **动画**: 列表增删需有 `.animation`，并尊重 `reduceMotion` 设置。
- [ ] **错误恢复**: 遇到 IO 错误时，提供"重试"按钮。

---

## 12. 错误处理与日志

### 12.1 简化策略

不再使用复杂的分层错误，统一使用 `AppError` 和 `Logger`。

```swift
enum AppError: LocalizedError {
    case imageSaveFailed
    case ocrUnavailable
    
    var errorDescription: String? {
        switch self {
        case .imageSaveFailed: return String(localized: "图片保存失败，请检查存储空间")
        case .ocrUnavailable: return String(localized: "OCR 服务不可用")
        }
    }
}
```

### 12.2 日志规范

- [ ] 使用 `Logger` 分类（如 `Logger.ui`, `Logger.data`）。
- [ ] **禁止**使用 `print()`。
- [ ] **禁止**在日志中打印用户输入的原文（隐私合规）。

---

## 13. 测试策略

### 13.1 测试重点

由于采用实用主义架构，测试重心转移：

1. **Services (Unit Test)**: 重点覆盖 `ReviewAlgorithm`（复习算法）和 `ImageStorageService`（文件逻辑）。
2. **UI Flows (UI Test)**: 覆盖"拍照 -> 生成题目 -> 列表显示"的核心链路。
3. **Models**: 测试充血模型中的业务计算属性。

### 13.2 规范

- [ ] 新算法必须有单元测试。
- [ ] UI 测试使用 `waitForExistence` 而非 `sleep`。

---

## 14. 文档与可维护性

- [ ] **TODO**: 必须关联 Issue 编号。
- [ ] **注释**: 复杂的算法逻辑（如复习间隔计算）必须写明数学原理。
- [ ] **Commit Message**: 遵循 `<type>(<scope>): <subject>` 格式。

---

## 15. 网络层规范 (预留)

> *当前为纯本地应用。未来引入云同步时，将采用 Repository 模式封装网络请求，保持上层架构不变。*

---

## 📋 Pull Request 审查清单

在提交 PR 前，请确保：

**架构与质量**

- [ ] View 直连 SwiftData，无冗余中间层。
- [ ] 图片通过文件系统存储，数据库仅存路径。
- [ ] 复杂算法已抽离至 Service 并包含测试。

**用户体验**

- [ ] 包含无障碍标签。
- [ ] 支持动态字体。
- [ ] 错误状态有 UI 提示。

**安全与合规**

- [ ] 未引入隐私泄露风险。
- [ ] 未在主线程执行耗时 IO。

---

## 版本历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|---------|------|
| 1.0 | 2025-12-05 | 初始版本：7 个核心维度 | Team |
| 2.0 | 2025-12-05 | 扩展至 12 个维度（隐私、无障碍、本地化、SwiftUI、UX） | Team |
| 3.0 | 2025-12-05 | 扩展至 14 个维度，合并 CODING_STANDARDS | Team |
| 4.0 | 2025-12-05 | 企业级架构增强，新增 Use Cases 层、分层错误体系 | Team |
| **5.0** | **2025-12-06** | **🔥 实用主义架构重构 (Pragmatic Edition)** | **Team** |
| | | - 废弃 Clean Architecture，采用 SwiftData 原生驱动 | |
| | | - 简化为 3 层：Models → Services → Views | |
| | | - 废弃分层 DDD，采用充血模型 | |
| | | - 图片存储分离（FileManager + imagePath） | |
| | | - 简化错误处理（单一 AppError） | |
| | | - 代码量减少 45%（100+ 文件 → 55 文件） | |
| | | - 参见 [ADR-006](adr/ADR-006-pragmatic-architecture.md) | |

---

> **💡 结语**：架构是为产品服务的。通过简化架构，我们把精力从"维护代码结构"转移到"打磨核心功能（OCR准确率、复习算法体验）"上。这就是 NotBad 项目的新方向。
