# Scripts & Tools

包含用于通过自动化改善**开发者体验 (DX)** 的脚本。

## 脚本说明

| 脚本 | 用途 |
|---|---|
| `lint.sh` | 调用 SwiftLint strict；工具缺失时 fail closed |
| `ci-local.sh` | canonical local source gate：精确工具身份 + lint/docs/static + AllTests CI build/test；要求 clean committed checkout |
| `ci_github.py` | GitHub Actions fail-closed helper：精确工具 / runtime 身份、结构化 exact simulator 选择与唯一 `.xctestrun` |
| `setup.sh` | 新开发者入职的一键环境配置（待完善） |
| `pre-commit` | Git pre-commit hook（提交前自动检查） |
| `generate_feature_status.py` | 由各 feature spec frontmatter 生成 `docs/reference/feature-status.md`（实现状态单写；不表示 Release 合同符合；产物勿手改，pre-commit/CI 校验） |
| `generate_intent_traceability.py` | 由各 feature spec `intent_refs` / `release_refs` 生成 durable intent 与 Release 1 双向追溯索引；Release ID 从 effective contract 读取，ratified decision 无 Feature / operations owner 时失败（产物勿手改，pre-commit/CI 校验） |
| `test_doc_generators.py` | 文档生成器单元测试（覆盖意图追溯索引与功能状态看板的成功与失败路径，pre-commit/CI 校验） |
| `validate_document_control.py` | 检查所有 repository Markdown 的角色 / 生命周期唯一归属、历史降级标识、本地链接 / anchor 与 alias |
| `validate_docs.py` | 检查高风险文档漂移：历史 ADR 状态、过时 Firebase 路线陈述、产品定位回退、feature spec 意图追溯、`intent_refs` 目标存在性与验收证据行 |
| `validate_capture_contract.py` | 递归检查 Capture 契约文案边界：Capture 暴露 L10n、权限用途串和 Capture View 用户可见字符串，避免回退到旧错题本 / 儿童教育定位 |
| `tests/` | 脚本回归测试；覆盖文档 / Capture、local/GitHub CI failure oracles、workflow contract 和弱 lint 入口 |
| `check_headers.py` | 检查 Swift 文件头部版权声明是否规范（手动工具，无 CI 调用） |
| `add_assets.rb` | 向 Asset Catalog 批量添加资源（一次性 Xcode 工具） |
| `add_swiftlint_phase.rb` | 为 Xcode Target 自动添加 SwiftLint Build Phase（一次性） |
| `fix_duplicate_assets.rb` | 清理 Asset Catalog 中的重复资源（一次性） |
| `inspect_project.rb` | 检查 `.xcodeproj` 项目文件结构（诊断用） |
| `hooks/` | 本地 hook 脚本目录 |
| `migrations-completed/` | 已完成的一次性 migration 脚本归档（保留供历史溯源） |

此目录不包含任何生产环境代码。

`ci-local.sh` 与 GitHub Actions 的两个 job 均读取 [`../Configs/Toolchain.env`](../Configs/Toolchain.env) 的 Xcode / SwiftLint 身份。GitHub job 额外消费 pinned simulator runtime，并由 `ci_github.py` 要求该 runtime 下唯一 exact iPhone 17（名称 + device type）和唯一 `.xctestrun`；本地 gate 仍只记录 name-based requested destination。两者均不覆盖 archive / install、隐私 / 网络或 Release candidate 证据。
