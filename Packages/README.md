# NotBad Packages

NotBad 的核心业务逻辑模块，采用物理隔离架构。

## 架构理念

> **文件夹分层是"君子协定"，Package 隔离是"物理围墙"。**

通过 Swift Package 实现物理模块化，让编译器强制执行架构约束：

- Package 无法引用 App 代码（单向依赖）
- Package 被迫保持纯粹（无 UI 依赖）
- 改 UI 不触发核心库重编

## Package 列表

| Package | 职责 | 测试 |
|---------|------|------|
| [ReviewKit](ReviewKit/) | 复习算法（间隔重复） | 9 tests ✅ |
| [ImageKit](ImageKit/) | 图片存储（FileManager） | 16 tests ✅ |
| [OCRKit](OCRKit/) | 文字识别（Vision） | 10 tests ✅ |

## 目标架构

```
NotBad (App Target) - 只是一层薄薄的 UI
│
└── Packages/
    ├── ReviewKit    # 🧠 大脑：复习算法
    ├── ImageKit     # 📷 图片存储
    └── OCRKit       # 📝 文字识别
```

## 终极测试

如果能创建一个 macOS 命令行工具，只依赖 ReviewKit，成功运行复习算法——说明核心逻辑完全独立于 UI。

```bash
cd Packages/ReviewKit
swift run ReviewKitCLI
```

## 集成到主工程

1. 打开 `NotBad.xcodeproj`
2. File → Add Package Dependencies
3. 点击 "Add Local..."
4. 依次添加 `ReviewKit`、`ImageKit`、`OCRKit`

## 运行所有测试

```bash
# ReviewKit
cd Packages/ReviewKit && swift test

# ImageKit
cd Packages/ImageKit && swift test

# OCRKit
cd Packages/OCRKit && swift test
```

## 相关文档

- [ADR-007: 模块化架构演进方向](../docs/adr/ADR-007-modularization-direction.md)
