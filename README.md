# SnapDrill

**SnapDrill** 是一款简洁、私有、原生的成人效率工具：以最低摩擦，把纸张、照片和 PDF 变成可搜索、可整理、可打印的个人资料库。首个切口是处理结构化纸张 / PDF 的成年人，试卷与题目只是擅长处理的内容类型。（最高产品权威见 [Product Constitution v1](docs/explanations/vision.md)。）

## 文档

| 文档 | 用途 |
|---|---|
| [文档总导航](docs/README.md) | 完整文档索引（Diátaxis 分层）|
| [功能规格](docs/features/) | 各功能 Why/What/How/Verify（一元化，每功能一文件）|
| [设计解释](docs/explanations/) | 愿景、设计原则、架构、商业化、待验证假设、竞品、用户旅程、隐私合规 |
| [查阅参考](docs/reference/) | 功能状态(SSOT)、术语、埋点、平台边界、NFR、范围路线、ASO |
| [操作指南](docs/how-to/) | 发布与 CI |
| [架构决策](docs/decisions/) | ADR-001~005 |
| [AGENTS.md](AGENTS.md) | Agent 最小启动契约：权威路由、执行边界与完成证据（CLAUDE.md 软链至此）|
| [DocC API 文档](Packages/) | Xcode: Product > Build Documentation |

## 当前状态（2026-07-12）

> 当前生产与发布事实的入口。历史区域路线见 [ADR-003](docs/decisions/ADR-003-dual-region-release.md) / [ADR-004](docs/decisions/ADR-004-china-build-firebase-free.md)；现行分析与隐私策略见 [ADR-005](docs/decisions/ADR-005-analytics-privacy-strategy.md)。实现状态以当前代码、构建、签名和发布实证为准。

- **阶段**：美国 NotBad Labs L.L.C.（Team `J58U72W335`）全球版，工程标识为 `com.snapdrill.global`。Release 1 为 iPhone-only、英文 + 简体中文、免费、无广告、无 IAP；iPad 与中国大陆专项发行只有新裁决后才能重入。
- **产品定位**（PO 2026-07-12 Gate B）：通用受众的成人效率工具；当前首个切口是结构化纸张 / PDF 的采集、整理 / 找回、导出 / 打印。SSOT 见 [Product Constitution v1](docs/explanations/vision.md) 与 [positioning-and-audience.md](docs/explanations/positioning-and-audience.md)。
- **分析 / 隐私**（ADR-005 D6=A）：**零采集 / 本地优先**——Apple ASC 聚合 + 端侧 MetricKit（#799 已合，`ServiceContainer` 14 服务），无后端、无 Firebase。
- **发布就绪**：流程与检查项见 [release-and-ci.md](docs/how-to/release-and-ci.md)；是否可发布必须以当次代码、依赖、签名、隐私清单、构建和 App Store Connect 实证重新判定，不使用固定 RC 快照替代实时检查。
- **决策 · 商业**：Release 1 不接 StoreKit，所有 Pro、CloudKit、Word、价格与 IAP 只是未来候选；不可用入口必须隐藏，不保留“敬请期待”承诺。
- **决策 · Firebase**：**已编译层彻底剔除（#803）**——删除整个 `SnapDrillInfrastructure` 包 + 切断 pbxproj 引用 + 清理 GoogleService 示例，二进制不再链接任何 Firebase SDK；生产端零采集（注入 `NoOpAnalyticsService`、ATT 已移除）。同步根治了 SwiftPM protobuf 子模块 clone 卡顿。

**阻塞真相**（旧文档 issue 编号有漂移，以下以本地为准）：

| 项 | 真相 |
|---|---|
| 公司 Apple 账号 | 美国 NotBad Labs L.L.C.（Team `J58U72W335`）**已 active**（pivot 后）；旧国内 #163 Organization/DUNS 路线随大陆路线挂起 |
| StoreKit / Pro | #479 —— 不属于 Release 1；未来重入候选 |
| CloudKit 同步 | #485 —— 当前 `cloudKitDatabase: .none`；未来 Apple 私有同步假设 |
| Word 导出 | #486 —— 不属于 Release 1；未来高级输出假设 |

**发布路径**：美国全球版生产基线（`com.snapdrill.global`，自动签名）；routine source gate 为 `bash Scripts/ci-local.sh`，更高风险改动继续补 targeted UI / AX、真机或发布证据。Archive 与开发签名真机安装已有本机实证，TestFlight / App Store 上传仍需当次 distribution signing、export/upload 与 App Store Connect 实证。shipping target 为 iPhone-only（`UIDeviceFamily = [1]`）；iPad 与中国大陆专项发行均须明确重入，不是默认后续步骤。

## 架构设计

项目采用基于 Swift Package Manager (SPM) 的 **严格模块化架构 (Strict Modular Architecture)**。主 App Target 仅仅是一个薄层，负责将各功能模块组合在一起。

### 模块层级

#### 1. 基础层 (Foundation Layers)

这些模块为应用提供底层能力。

- **[SnapDrillCore](Packages/SnapDrillCore/README.md)**: 核心逻辑层。包含 SM-2 调度引擎 (ReviewScheduler)、OCR/ImageStorage 服务、ReviewRating 枚举和通用工具。
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

- **Xcode**: 26.6 (`17F113`)
- **iOS**: 26.0+
- **SwiftLint**: 0.63.2

routine source gate 的精确工具身份只维护在 [`Configs/Toolchain.env`](Configs/Toolchain.env)；本段是便于阅读的当前快照。

## 快速开始

1. 克隆仓库: `git clone https://github.com/NotBad-Labs/snapdrill-ios.git`
2. 安装依赖工具: 确保已安装 SwiftLint。
3. 打开项目: 双击 `SnapDrill.xcodeproj`。
4. 运行: 选择 `SnapDrill` Scheme，在模拟器或真机上运行。

## 测试

在 clean committed checkout 上运行 canonical local source gate：

```bash
bash Scripts/ci-local.sh
```

该入口固定工具身份，依次执行 SwiftLint、脚本与文档门禁、依赖方向检查、`AllTests` CI configuration 的 `build-for-testing` 和 `test-without-building`，并要求唯一 `.xctestrun`。它不运行 app XCUITest / AX，也不证明 archive、安装、隐私 / 网络或候选发布状态；高风险改动仍按 [`docs/how-to/parallel-lanes.md`](docs/how-to/parallel-lanes.md) 补对应证据。

### 快照重录

`SnapshotRecord` 只用于明确选择的 snapshot test，不属于默认测试路径。重录前必须限定具体测试，重录后人工审查每一处 baseline diff；禁止用全量重录让当前实现反向改写测试 oracle。
