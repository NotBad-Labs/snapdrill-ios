# ImageKit/OCRKit 架构说明（已归档）

> ⚠️ **本文档已过时** - 归档日期：2025-12-12  
> 
> **原因**：ImageKit 和 OCRKit 已整合为 **CaptureKit**，以更好地反映统一的录入链路。  
> 同时新增 **ProcessKit** 用于图像处理和增强。
> 
> **请参阅最新文档**：
> - [架构文档](../ARCHITECTURE.md) - 当前 3-Kit 架构说明
> - [扫描流程规范](../SCAN_FLOW.md) - C 混合模式扫描流程详细说明
> - [3Kit 验证报告](../3KIT_VALIDATION_REPORT.md) - CaptureKit/ProcessKit/ReviewKit 架构验证

---

## 历史架构：ImageKit/OCRKit（已废弃）

在 2025 年 12 月之前，NotBad 使用以下架构：

```
┌─────────────────────────────────────────────────────────────┐
│                    Swift Packages (旧版)                     │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │  ReviewKit │  │  ImageKit  │  │   OCRKit   │             │
│  │  ─────────  │  │  ─────────  │  │  ─────────  │             │
│  │  Model     │  │  Storage   │  │  Vision    │             │
│  │  ValueObj  │  │  Service   │  │  Service   │             │
│  │  Scheduler │  │            │  │            │             │
│  │  Persist   │  │            │  │            │             │
│  └────────────┘  └────────────┘  └────────────┘             │
└─────────────────────────────────────────────────────────────┘
```

### ImageKit（图片存储）- 已整合到 CaptureKit

位置：`Packages/ImageKit/`（已移除）

**职责**：图片文件的保存和读取。

| 文件 | 职责 | 迁移去向 |
|------|------|---------|
| `ImageStorageService.swift` | 图片存储服务，使用 App Groups 共享目录 | → `CaptureKit/Storage/ImageStorageService.swift` |
| `ImageKit.swift` | 模块入口 | → `CaptureKit.swift` |

### OCRKit（文字识别）- 已整合到 CaptureKit

位置：`Packages/OCRKit/`（已移除）

**职责**：基于 Vision 框架的 OCR 服务。

| 文件 | 职责 | 迁移去向 |
|------|------|---------|
| `OCRService.swift` | Vision OCR 封装 | → `CaptureKit/OCR/OCRService.swift` |
| `OCRTypes.swift` | OCR 结果类型定义 | → `CaptureKit/OCR/OCRTypes.swift` |
| `OCRKit.swift` | 模块入口 | → `CaptureKit.swift` |

---

## 为什么整合？

### 问题：职责分散

在旧架构中：
- **ImageKit** 只负责存储图片
- **OCRKit** 只负责识别文字
- 两者总是一起使用，但物理分离

### 缺点

1. **维护成本高**：需要维护 3 个 Package.swift
2. **职责不清晰**：扫描流程被切分到两个 Kit
3. **缺少防腐层**：没有 DraftScan 验证机制，容易污染数据库

### 解决方案：整合为 CaptureKit

新的 CaptureKit 整合了完整的录入链路：

```
CaptureKit（录入层）
├── Scanner/           # 扫描状态机
│   ├── ScanState.swift
│   ├── DraftScan.swift（防腐层）
│   └── LiveDocumentDetector.swift
├── OCR/               # 文字识别（来自 OCRKit）
│   ├── OCRService.swift
│   └── OCRTypes.swift
└── Storage/           # 图片存储（来自 ImageKit）
    └── ImageStorageService.swift
```

### 优势

1. ✅ **统一录入链路**：从扫描到存储一站式
2. ✅ **防腐层设计**：DraftScan 验证防止脏数据
3. ✅ **维护成本低**：只需维护一个 Package.swift
4. ✅ **职责清晰**：CaptureKit = 输入质量控制

---

## 迁移指南

### 代码迁移

**Before (旧代码):**
```swift
import ImageKit
import OCRKit

// 分别使用两个 Kit
let imageService = ImageStorageService.shared
let ocrService = OCRService.shared

// 拍照 → 识别 → 存储
let image = captureImage()
let text = try await ocrService.recognize(image)
let imagePath = try await imageService.save(image)
```

**After (新代码):**
```swift
import CaptureKit

// 使用统一的 CaptureKit
let scanner = DocumentScanner()

// 扫描 → 生成 DraftScan（防腐层）
let draft = try await scanner.capture()

// 验证
guard draft.isValid else {
    showError(draft.invalidReason)
    return
}

// 确认后再保存
confirmAndSave(draft)
```

### Package 依赖更新

**Before:**
```swift
// Package.swift (旧)
dependencies: [
    .package(path: "../Packages/ReviewKit"),
    .package(path: "../Packages/ImageKit"),
    .package(path: "../Packages/OCRKit"),
]
```

**After:**
```swift
// Package.swift (新)
dependencies: [
    .package(path: "../Packages/ReviewKit"),
    .package(path: "../Packages/CaptureKit"),  // 替代 ImageKit + OCRKit
    .package(path: "../Packages/ProcessKit"),  // 新增
]
```

---

## 相关文档

- [架构文档](../ARCHITECTURE.md) - 当前 3-Kit 架构
- [扫描流程规范](../SCAN_FLOW.md) - C 混合模式详细说明
- [3Kit 验证报告](../3KIT_VALIDATION_REPORT.md) - 架构验证报告
- [Swift 6 迁移计划](../SWIFT6_MIGRATION_PLAN.md) - 包含 Kit 整合进度

---

**归档原因**：反映当前架构的真实状态，避免新开发者被过时信息误导。  
**归档日期**：2025-12-12  
**最后使用版本**：~2025-12-11
