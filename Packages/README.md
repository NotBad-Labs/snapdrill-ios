# NotBad Packages

NotBad 的核心业务逻辑模块，采用物理隔离架构。

## 架构理念

> **文件夹分层是"君子协定"，Package 隔离是"物理围墙"。**

通过 Swift Package 实现物理模块化，让编译器强制执行架构约束：

- Package 无法引用 App 代码（单向依赖）
- Package 被迫保持纯粹（无 UI 依赖）
- 改 UI 不触发核心库重编
- **App 和 Widget 共享同一个 Model 定义**，避免 SwiftData 命名空间陷阱

## Package 列表

| Package | 职责 | 内容 | 测试 |
|---------|------|------|------|
| [ReviewKit](ReviewKit/) | 领域层核心 | Model + 算法 + 持久化 | 9 tests ✅ |
| [CaptureKit](CaptureKit/) | 录入链路 (图片存储 + OCR + 实时扫描) | ImageStorage + OCR + LiveText/Scanner + CaptureService | TBD |

## ReviewKit - 领域层核心

ReviewKit 是 NotBad 的**领域层（Domain Layer）**，包含：

```
ReviewKit/
├── Models/
│   └── ReviewItemModel.swift    # SwiftData @Model（充血模型）
├── ValueObjects/
│   └── ValueObjects.swift       # Subject, Grade, Difficulty 等
├── Data/
│   └── PersistenceController.swift  # App Groups 共享数据库
├── ReviewScheduler.swift        # 间隔重复算法
└── ReviewKit.swift              # 公开 API 入口
```

### 为什么 Model 放在 ReviewKit？

**SwiftData 命名空间陷阱**：SwiftData 使用完全限定类名作为标识符。

- 如果 Model 在主 App：存储为 `NotBad.ReviewItemModel`
- 如果 Widget 复制一份：存储为 `NotBadWidget.ReviewItemModel`
- **结果**：Widget 无法读取主 App 的数据！

**解决方案**：将 Model 放入 Package，统一为 `ReviewKit.ReviewItemModel`。

## 目标架构（单一 CaptureKit 版本）

```
NotBad (App Target)           NotBadWidget (Widget Target)
         │                              │
         └──────────┬───────────────────┘
                    │
                    ▼
              ReviewKit (Package)
              ┌─────────────────────────┐
              │ ReviewItemModel         │  ← 统一的 Model
              │ PersistenceController   │  ← 共享数据库
              │ ReviewScheduler         │  ← 复习算法
              └─────────────────────────┘
                    │
                    ▼
              CaptureKit (Package)
              ┌─────────────────────────┐
              │ ImageStorageService     │  ← App Group 图片存储
              │ OCRService/LiveText/    │  ← Vision & VisionKit
              │ Scanner/CaptureService  │  ← 统一录入入口
              └─────────────────────────┘
```

## 终极测试

如果能创建一个 macOS 命令行工具，只依赖 ReviewKit，成功运行复习算法——说明核心逻辑完全独立于 UI。

```bash
cd Packages/ReviewKit
swift run ReviewKitCLI
```

## 集成到主工程

### 步骤 1：添加 Package 依赖

1. 打开 `NotBad.xcodeproj`
2. File → Add Package Dependencies
3. 点击 "Add Local..."
4. 选择 `Packages/ReviewKit`

### 步骤 2：添加到 Target

1. 选择 NotBad target
2. General → Frameworks, Libraries...
3. 添加 `ReviewKit`

### 步骤 3：删除或停用旧文件

以下文件已迁移到 Packages，请删除或停用以避免双份定义：
- `NotBad/Models/ReviewItemModel.swift`
- `NotBad/Models/ValueObjects.swift`
- `NotBad/Data/PersistenceController.swift`
- 任何旧的 OCR/Image 入口（已合并进 CaptureKit）

### 步骤 4：添加 import

在需要的文件顶部添加：
```swift
import ReviewKit
```

## 运行所有测试

```bash
# ReviewKit
cd Packages/ReviewKit && swift test

# CaptureKit
cd Packages/CaptureKit && swift test
```

## 相关文档

- [ADR-007: 模块化架构演进方向](../docs/adr/ADR-007-modularization-direction.md)
