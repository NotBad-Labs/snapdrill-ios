# SnapDrill

**SnapDrill** 是一款个人智能学习助手 iOS 应用，旨在帮助用户通过间隔重复（Spaced Repetition）技术来采集、组织和复习知识。

## 架构设计

项目采用基于 Swift Package Manager (SPM) 的 **严格模块化架构 (Strict Modular Architecture)**。主 App Target 仅仅是一个薄层，负责将各功能模块组合在一起。

### 模块层级

#### 1. 基础层 (Foundation Layers)
这些模块为应用提供底层能力。

- **[SnapDrillCore](Packages/SnapDrillCore/README.md)**: 核心逻辑层。包含领域实体、业务引擎 (Engine)、基础服务 (Service) 和通用工具 (Utils)。
- **[SnapDrillData](Packages/SnapDrillData/README.md)**: 数据层。基于 SwiftData 的持久化和迁移管理。
- **[SnapDrillUI](Packages/SnapDrillUI/README.md)**: 表现层。包含设计系统、通用组件 (ImageCropper) 和基础路由协议。

#### 2. 功能层 (Feature Layer)
所有具体的业务功能都整合在一个统一的模块中，以简化开发体验。

- **[SnapDrillFeatures](Packages/SnapDrillFeatures/README.md)**: 
    - **Capture**: 智能扫描与 OCR。
    - **Library**: 题库管理与编辑。
    - **Dashboard**: 数据概览。
    - **Review**: 复习流程。
    - **Settings**: 设置与关于。

### 其他
- **Scripts**: 自动化脚本与开发者工具。
- **Composition**: 应用层的胶水代码与依赖注入占位符。

## 环境要求

- **Xcode**: 16.0+
- **iOS**: 18.0+
- **SwiftLint**: 必需 (用于代码风格检查) `brew install swiftlint`

## 快速开始

1.  克隆仓库: `git clone https://github.com/chramboliao/SnapDrill.git`
2.  安装依赖工具: 确保已安装 SwiftLint。
3.  打开项目: 双击 `SnapDrill.xcodeproj`。
4.  运行: 选择 `SnapDrill` Scheme，在模拟器或真机上运行。

## 贡献

请阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 了解如何参与项目开发、分支管理及代码规范。

## 测试

项目包含完整的测试套件，包括单元测试、集成测试和 UI 测试。

### 测试覆盖率

[![codecov](https://codecov.io/gh/chramboliao/SnapDrill/branch/main/graph/badge.svg)](https://codecov.io/gh/chramboliao/SnapDrill)

- **目标覆盖率**: 60%+
- **当前覆盖率**: 查看 CI 报告

### 运行测试

- **Xcode**: 按下 `Cmd+U`
- **命令行**:
  ```bash
  xcodebuild test -scheme SnapDrill -destination 'platform=iOS Simulator,name=iPhone 17'
  ```
- **带覆盖率报告**:
  ```bash
  xcodebuild test -scheme SnapDrill \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -enableCodeCoverage YES
  ```

### 测试结构

```
Tests/
├── SnapDrillCoreTests/          # Service 层测试
│   ├── OCRServiceTests
│   ├── PDFExportServiceTests
│   ├── CaptureServiceTests
│   └── AnalyticsServiceTests
├── SnapDrillDataTests/          # 数据层测试
│   ├── ReviewItemModelTests
│   ├── ModelTests
│   ├── ReviewRepositoryTests
│   └── TestHelpers
└── SnapDrillUITests/            # UI 测试（待添加）
```

## 文档

所有模块均提供 Apple **DocC** 文档。
查看方式：Xcode 菜单栏 **Product > Build Documentation**。
