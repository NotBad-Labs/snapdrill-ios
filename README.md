# SnapDrill

**SnapDrill** 是一款通用的简洁、私有、原生效率工具：扫描、归档、整理任何题目与文档，帮助用户以最低成本完成"看到内容 → 数字化存档 → 导出打印"的闭环。（产品定位见 [positioning-and-audience.md](docs/explanations/positioning-and-audience.md)；铁律「定位≠产品」，内核仍可为试卷 / 错题场景优化。）

## 文档

| 文档 | 用途 |
|---|---|
| [文档总导航](docs/README.md) | 完整文档索引（Diátaxis 分层）|
| [功能规格](docs/features/) | 各功能 Why/What/How/Verify（一元化，每功能一文件）|
| [设计解释](docs/explanations/) | 愿景、设计原则、架构、商业化、待验证假设、竞品、用户旅程、隐私合规 |
| [查阅参考](docs/reference/) | 功能状态(SSOT)、术语、埋点、平台边界、NFR、范围路线、ASO |
| [操作指南](docs/how-to/) | 发布与 CI |
| [架构决策](docs/decisions/) | ADR-001~005 |
| [AGENTS.md](AGENTS.md) | 智能体协作行为约束 + 架构 + 编码（CLAUDE.md 软链至此）|
| [DocC API 文档](Packages/) | Xcode: Product > Build Documentation |

## 当前状态（2026-06-11）

> 上架/运营状态锚点（供跨会话 / 跨 agent 追溯）。决策细节见 [ADR-003 双地区发布](docs/decisions/ADR-003-dual-region-release.md) / [ADR-004 国内 Firebase-Free](docs/decisions/ADR-004-china-build-firebase-free.md) / [ADR-005 分析与隐私遥测策略](docs/decisions/ADR-005-analytics-privacy-strategy.md)。事实源以本地 code/docs/git 为准（GitHub issue/PR 可能滞后）。

- **阶段**（🔁 2026-06-09 pivot）：**改用美国公司账号 NotBad Labs L.L.C.（Team `J58U72W335`）做全球版生产**，工程已切 `com.snapdrill.global`（真机签名验证通过，#795 已合）；**国内大陆路线暂时挂起**（资源保留可复活）。核心免费闭环约 90% build-complete；Pro / 同步为外部阻塞，非闭环本身。
- **产品定位**（PO 2026-06-11 决策）：**通用效率工具——扫描、归档、整理任何题目与文档**（试卷 / 竞赛 / 证书 / 培训 / 票据），非儿童教育工具；COPPA general-audience 目标。铁律「定位≠产品」。SSOT 见 [positioning-and-audience.md](docs/explanations/positioning-and-audience.md)。
- **分析 / 隐私**（ADR-005 D6=A）：**零采集 / 本地优先**——Apple ASC 聚合 + 端侧 MetricKit（#799 已合，`ServiceContainer` 14 服务），无后端、无 Firebase。
- **发布阻塞清单 RC-1~RC-12**（见 [development-process.md](docs/explanations/development-process.md) §5）：**Firebase 编译剔除（#803 已合，整个 `SnapDrillInfrastructure` 包删除）+ MetricKit（#799 已合）已完成**；剩余公开上架待办 = 未成年人法律定性（律师 gated，已被 general-audience 重定位稀释）+ 官网政策文案对齐零采集。**TestFlight 内测不被这些阻塞**。
- **决策 · Pro**：免费优先，本期**不接 StoreKit**；Pro 入口保留（待改"敬请期待"占位）。
- **决策 · Firebase**：**已编译层彻底剔除（#803）**——删除整个 `SnapDrillInfrastructure` 包 + 切断 pbxproj 引用 + 清理 GoogleService 示例，二进制不再链接任何 Firebase SDK；生产端零采集（注入 `NoOpAnalyticsService`、ATT 已移除）。同步根治了 SwiftPM protobuf 子模块 clone 卡顿。

**阻塞真相**（旧文档 issue 编号有漂移，以下以本地为准）：

| 项 | 真相 |
|---|---|
| 公司 Apple 账号 | 美国 NotBad Labs L.L.C.（Team `J58U72W335`）**已 active**（pivot 后）；旧国内 #163 Organization/DUNS 路线随大陆路线挂起 |
| StoreKit / Pro | #479 —— 延后（免费优先）|
| CloudKit 同步 | #485 —— 已 `cloudKitDatabase: .none` 禁用，延后 |
| Word 导出 | **#486**（旧文档误标为"Apple 账号"）—— Pro，延后 |

**发布路径**：美国全球版生产基线（`com.snapdrill.global`，自动签名）；DoD 门禁 = `swiftlint --strict` + `build-for-testing`(AllTests)；上架 / CI / Archive 上传操作见 [release-and-ci](docs/how-to/release-and-ci.md)。（旧"国内家长内测 + Firebase 运行时止血"路径随大陆路线挂起。）

## 架构设计

项目采用基于 Swift Package Manager (SPM) 的 **严格模块化架构 (Strict Modular Architecture)**。主 App Target 仅仅是一个薄层，负责将各功能模块组合在一起。

### 模块层级

#### 1. 基础层 (Foundation Layers)

这些模块为应用提供底层能力。

- **[SnapDrillCore](Packages/SnapDrillCore/README.md)**: 核心逻辑层。包含 SM-2 调度引擎 (ReviewScheduler)、OCR/ImageStorage 服务、Difficulty/ReviewRating 枚举和通用工具。
- **[SnapDrillData](Packages/SnapDrillData/README.md)**: 数据层。基于 SwiftData 的 `@Model` 类（直接作领域对象）、具体 Repository 类、持久化控制器和迁移计划。
- **[SnapDrillUI](Packages/SnapDrillUI/README.md)**: 表现层。包含设计系统、通用组件 (ImageCropper) 和基础路由协议。

> **Firebase / `SnapDrillInfrastructure` 已退役（#803）**：分析改为**零采集**——生产注入 `NoOpAnalyticsService` + 端侧 MetricKit（在 `SnapDrillCore`），见 [ADR-005](docs/decisions/ADR-005-analytics-privacy-strategy.md) D6=A。已无 Infrastructure 包，二进制不链接 Firebase。

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

- **Xcode**: 26.5+
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
