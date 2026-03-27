# SnapDrill

**SnapDrill** 是一款面向学生和家长的练习题数字化存档与间隔重复复习工具，帮助用户以最低成本完成"看到题目 → 数字化存档"的过程。

**[项目状态看板](STATUS.md)**

## 文档

| 文档 | 用途 |
|---|---|
| [产品文档](docs/product/) | 愿景、设计、需求、用户旅程、商业化 |
| [开发流程](docs/workflow.md) | 看板、Git、Code Review、优先级 |
| [DocC API 文档](Packages/) | Xcode: Product > Build Documentation |

## 架构设计

项目采用基于 Swift Package Manager (SPM) 的 **严格模块化架构 (Strict Modular Architecture)**。主 App Target 仅仅是一个薄层，负责将各功能模块组合在一起。

### 模块层级

#### 1. 基础层 (Foundation Layers)

这些模块为应用提供底层能力。

- **[SnapDrillCore](Packages/SnapDrillCore/README.md)**: 核心逻辑层。包含 SM-2 调度引擎 (ReviewScheduler)、OCR/ImageStorage 服务、Difficulty/ReviewRating 枚举和通用工具。
- **[SnapDrillData](Packages/SnapDrillData/README.md)**: 数据层。基于 SwiftData 的 `@Model` 类（直接作领域对象）、具体 Repository 类、持久化控制器和迁移计划。
- **[SnapDrillUI](Packages/SnapDrillUI/README.md)**: 表现层。包含设计系统、通用组件 (ImageCropper) 和基础路由协议。

- **[SnapDrillInfrastructure](Packages/SnapDrillInfrastructure/)**: 基础设施层。Firebase 实现（Analytics/Crashlytics/RemoteConfig），仅 `SnapDrill/App` 可 import。

#### 2. 功能层 (Feature Layer)

业务功能拆分为 5 个独立 SPM target，编译器强制模块边界。

- **[SnapDrillFeatures](Packages/SnapDrillFeatures/README.md)**:
  - **SnapDrillFeatureCapture**: 智能扫描与 OCR。
  - **SnapDrillFeatureLibrary**: 题库管理、编辑与分类管理（学科/来源/年级）。
  - **SnapDrillFeatureDashboard**: 数据概览。
  - **SnapDrillFeatureReview**: 复习流程。
  - **SnapDrillFeatureSettings**: 设置与关于。

### 其他

- **Scripts**: 自动化脚本与开发者工具。
- **SnapDrill/App**: 薄壳组合根（DependencyContainer + AppRouter）。

## 环境要求

- **Xcode**: 26.0+
- **iOS**: 26.0+
- **SwiftLint**: 必需 (用于代码风格检查) `brew install swiftlint`

## 快速开始

1. 克隆仓库: `git clone https://github.com/NotBad-Labs/snapdrill-ios.git`
2. 安装依赖工具: 确保已安装 SwiftLint。
3. 打开项目: 双击 `SnapDrill.xcodeproj`。
4. 运行: 选择 `SnapDrill` Scheme，在模拟器或真机上运行。

## 测试

- **Xcode**: `Cmd+U`
- **命令行**: `xcodebuild test -scheme SnapDrill -destination 'platform=iOS Simulator,name=iPhone 17'`

