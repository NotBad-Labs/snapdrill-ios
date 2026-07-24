# SnapDrill

**SnapDrill** 是一款简洁、私有、原生的成人效率工具：以最低摩擦，把纸张、照片和 PDF
变成可搜索、可整理、可打印的个人资料库。试卷与题目是擅长处理的内容类型，但产品不是
教辅内容平台。

## 文档

| 文档 | 用途 |
|---|---|
| [Product Vision & Principles](docs/product/vision.md) | 长期产品方向、定位、原则和耐久边界 |
| [Release 1 PRD](docs/product/release-1-prd.md) | 当前发布的目标、范围、非目标和验收结果 |
| [Feature Specs](docs/features/) | 单功能的 Why / What / How / Verify |
| [文档导航](docs/README.md) | 架构、数据契约、设计、操作、ADR 和生成索引 |
| [AGENTS.md](AGENTS.md) | 编码 Agent 的执行边界与完成证据；不是产品文档 |

根 README 是人和 Agent 的唯一冷启动入口。产品要求沿
`Product Vision & Principles -> Release PRD -> Feature Spec -> 验收标准` 读取；当前实现以
`origin/develop` 的代码、测试、构建、设备和发布证据为准。两者不一致时记录偏差，不能用
当前代码反向改写产品要求。

## 当前工作与发布事实

- **当前执行**：[Pull requests](https://github.com/NotBad-Labs/snapdrill-ios/pulls) /
  [Issues](https://github.com/NotBad-Labs/snapdrill-ios/issues)；旧 PR、issue 和报告默认只是历史证据。
- **实现状态**：[自动生成的功能状态](docs/reference/feature-status.md) + 当前代码和验证结果。
- **发布流程**：[release-and-ci.md](docs/how-to/release-and-ci.md)；每个候选都必须重新验证签名、
  隐私、构建、安装和 App Store Connect 事实。
- **当前发行边界**：美国 NotBad Labs L.L.C. 全球版，iPhone-only，英文 + 简体中文，免费、
  无广告、无 IAP。精确约束由 [Release 1 PRD](docs/product/release-1-prd.md) 维护。

## 架构设计

App target 是薄 composition root，功能和基础能力由 Swift Package Manager 模块隔离。
依赖必须朝 Core 收敛，Core 保持零第三方依赖。完整拓扑、依赖规则和当前偏差见
[architecture.md](docs/explanations/architecture.md)；各包的公开职责见 [Packages](Packages/)。

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
