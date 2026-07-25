# SnapDrill

SnapDrill 是一款 iPhone 通用效率工具，用于把纸张、照片和 PDF 变成可搜索、可整理、
可导出和可打印的个人资料库。

产品借鉴错题整理类 App 的高效工作流，但不提供题库、搜题、解题、课程、社区或儿童账号。
教育材料只是允许处理的内容之一，不是产品身份。

## 当前状态

- 尚未上线，没有外部用户或兼容性承诺。
- 当前代码仍有与目标产品不一致的历史实现；差异见
  [ARCHITECTURE.md](docs/ARCHITECTURE.md)。
- 产品目标只由 [PRD.md](docs/PRD.md) 定义，不能从现有代码、旧 issue、旧 PR 或 Git 历史反推。
- Git 历史保留全部旧文档，可用于追责和回滚，但不参与当前决策。

## 文档

仓库只维护五份当前文档，依赖方向保持单向：

| 文档 | 负责回答 |
|---|---|
| [PRD.md](docs/PRD.md) | 做什么、为谁做、明确不做什么 |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | 代码如何承载产品，以及当前有哪些实现偏差 |
| [DATA.md](docs/DATA.md) | 本地数据、图片、删除、备份和恢复必须满足什么 |
| [DEVELOPMENT.md](docs/DEVELOPMENT.md) | 人和 Agent 如何开发、验证、提交与合并 |
| [RELEASE.md](docs/RELEASE.md) | 候选构建如何验证、签名、分发与发布 |

新增长期文档前，优先更新上述 owner。临时调查、截图、日志和审计结果放在 PR、CI artifact
或本地临时目录，不进入当前文档树。

## 技术栈

- iOS 26.0+
- Swift 6.3 strict concurrency
- SwiftUI
- SwiftData
- 四个本地 Swift Package：Core、Data、UI、Features

## 本地验证

```bash
# 快速静态检查
swiftlint --strict
python3 Scripts/validate_docs.py --check

# 完整源码门禁，要求 clean committed checkout
bash Scripts/ci-local.sh
```

`swift test` 不适用于本仓库。Xcode 测试统一使用 `AllTests` scheme 与 `AllTests` test plan。
准确工具链版本见 `Configs/Toolchain.env`。

## 目录

```text
SnapDrill/                 App composition root
SnapDrillShare/            Share Extension
Packages/SnapDrillCore/    领域类型、服务协议、纯算法
Packages/SnapDrillData/    SwiftData、Repository、文件与备份
Packages/SnapDrillUI/      公共 SwiftUI 组件和路由协议
Packages/SnapDrillFeatures/用户工作流和界面
Scripts/                   本地与 CI 验证工具
docs/                      五份当前文档
```
