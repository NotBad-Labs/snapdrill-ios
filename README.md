# SnapDrill

**SnapDrill** 是一款面向家庭教育场景的练习题数字化存档效率工具，帮助用户以最低成本完成"看到题目 → 数字化存档 → 导出打印"的闭环。

## 文档

| 文档 | 用途 |
|---|---|
| [文档总导航](docs/README.md) | 完整文档索引（Diátaxis 分层）|
| [功能规格](docs/features/) | 各功能 Why/What/How/Verify（一元化，每功能一文件）|
| [设计解释](docs/explanations/) | 愿景、设计原则、架构、商业化、待验证假设、竞品、用户旅程、隐私合规 |
| [查阅参考](docs/reference/) | 功能状态(SSOT)、术语、埋点、平台边界、NFR、范围路线、ASO |
| [操作指南](docs/how-to/) | 发布与 CI |
| [架构决策](docs/decisions/) | ADR-001~004 |
| [AGENTS.md](AGENTS.md) | 智能体协作行为约束 + 架构 + 编码（CLAUDE.md 软链至此）|
| [DocC API 文档](Packages/) | Xcode: Product > Build Documentation |

## 当前状态（2026-05-29）

> 上架/运营状态锚点（供跨会话 / 跨 agent 追溯）。决策细节见 [ADR-003 双地区发布](docs/decisions/ADR-003-dual-region-release.md) / [ADR-004 国内 Firebase-Free](docs/decisions/ADR-004-china-build-firebase-free.md)。事实源以本地 code/docs/git 为准（GitHub issue/PR 可能滞后）。

- **阶段**：国内内测 TestFlight 准备（路径 A：个人账号 Team `W5A8THDKW8` 已 active，**内测无账号阻塞**）。核心免费闭环约 90% build-complete；Pro / 同步为外部阻塞，非闭环本身。
- **决策 · Pro**：免费优先，本期**不接 StoreKit**；Pro 入口保留（待改"敬请期待"占位）。
- **决策 · Firebase（PIPL）**：国内 build 先**运行时止血**（不调 `FirebaseBootstrap.configure()` + 注入 NoOp + 移除 `GoogleService-Info.plist`）→ **抓包复验零出境** → 公开上架前随 C 路径做**编译层剔除**。

**阻塞真相**（旧文档 issue 编号有漂移，以下以本地为准）：

| 项 | 真相 |
|---|---|
| 公司 Apple 账号 | **#163**（Organization，DUNS 处理中）—— 仅**外部 TestFlight / 公开上架**需要，不卡内测 |
| StoreKit / Pro | #479 —— 延后（免费优先）|
| CloudKit 同步 | #485 —— 已 `cloudKitDatabase: .none` 禁用，延后 |
| Word 导出 | **#486**（旧文档误标为"Apple 账号"）—— Pro，延后 |

**内测关键路径**：① Firebase 运行时止血 + 抓包复验 → ② 共享 `SnapDrill` scheme → ③ bump `CURRENT_PROJECT_VERSION` 5→6 → ④ 加 `ITSAppUsesNonExemptEncryption=NO` → ⑤ DoD 门禁（swiftlint + build-for-testing）→ ⑥ Xcode Organizer 手动 Archive 上传（fastlane / `upload_testflight.sh` 待修）→ ⑦ 内测仅邀国内家长 Apple ID。

## 架构设计

项目采用基于 Swift Package Manager (SPM) 的 **严格模块化架构 (Strict Modular Architecture)**。主 App Target 仅仅是一个薄层，负责将各功能模块组合在一起。

### 模块层级

#### 1. 基础层 (Foundation Layers)

这些模块为应用提供底层能力。

- **[SnapDrillCore](Packages/SnapDrillCore/README.md)**: 核心逻辑层。包含 SM-2 调度引擎 (ReviewScheduler)、OCR/ImageStorage 服务、Difficulty/ReviewRating 枚举和通用工具。
- **[SnapDrillData](Packages/SnapDrillData/README.md)**: 数据层。基于 SwiftData 的 `@Model` 类（直接作领域对象）、具体 Repository 类、持久化控制器和迁移计划。
- **[SnapDrillUI](Packages/SnapDrillUI/README.md)**: 表现层。包含设计系统、通用组件 (ImageCropper) 和基础路由协议。

- **[SnapDrillInfrastructure](Packages/SnapDrillInfrastructure/)**: 基础设施层。Firebase 实现（Analytics/Crashlytics；RemoteConfig 已移除），仅 `SnapDrill/App` 可 import。

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

- **Xcode**: 26.4+
- **iOS**: 26.0+
- **SwiftLint**: 必需 (用于代码风格检查) `brew install swiftlint`

## 快速开始

1. 克隆仓库: `git clone https://github.com/NotBad-Labs/snapdrill-ios.git`
2. 安装依赖工具: 确保已安装 SwiftLint。
3. 打开项目: 双击 `SnapDrill.xcodeproj`。
4. 运行: 选择 `SnapDrill` Scheme，在模拟器或真机上运行。

## 测试

- **Xcode**: `Cmd+U`
- **命令行 AllTests 两步法**（禁止单步 `xcodebuild test`）：

```bash
xcodebuild build-for-testing -scheme AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -testPlan AllTests

xcodebuild test-without-building -scheme AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -testPlan AllTests
```
