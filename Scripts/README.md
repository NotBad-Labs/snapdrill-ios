# Scripts & Tools

包含用于通过自动化改善**开发者体验 (DX)** 的脚本。

## 脚本说明

| 脚本 | 用途 |
|---|---|
| `lint.sh` | 调用 SwiftLint 进行代码风格检查 |
| `ci-local.sh` | 本地模拟 CI 流程（lint + build + test） |
| `setup.sh` | 新开发者入职的一键环境配置（待完善） |
| `pre-commit` | Git pre-commit hook（提交前自动检查） |
| `generate_feature_status.py` | 由各 feature spec frontmatter 生成 `docs/reference/feature-status.md`（功能状态 SSOT；校验必填字段、枚举、日期格式与阻塞 issue；产物勿手改，pre-commit/CI 校验） |
| `generate_intent_traceability.py` | 由各 feature spec `intent_refs` 生成 `docs/reference/intent-traceability.md`（意图追溯索引；产物勿手改，pre-commit/CI 校验） |
| `test_doc_generators.py` | 文档生成器单元测试（覆盖意图追溯索引与功能状态看板的成功与失败路径，pre-commit/CI 校验） |
| `validate_docs.py` | 检查高风险文档漂移：历史 ADR 状态、过时 Firebase 路线陈述、产品定位回退、feature spec 意图追溯、`intent_refs` 目标存在性与验收证据行 |
| `tests/` | 脚本回归测试；当前覆盖文档健康检查的引用解析、验收证据行和 fail-closed 行为 |
| `check_headers.py` | 检查 Swift 文件头部版权声明是否规范（手动工具，无 CI 调用） |
| `add_assets.rb` | 向 Asset Catalog 批量添加资源（一次性 Xcode 工具） |
| `add_swiftlint_phase.rb` | 为 Xcode Target 自动添加 SwiftLint Build Phase（一次性） |
| `fix_duplicate_assets.rb` | 清理 Asset Catalog 中的重复资源（一次性） |
| `inspect_project.rb` | 检查 `.xcodeproj` 项目文件结构（诊断用） |
| `hooks/` | 本地 hook 脚本目录 |
| `migrations-completed/` | 已完成的一次性 migration 脚本归档（保留供历史溯源） |

此目录不包含任何生产环境代码。
