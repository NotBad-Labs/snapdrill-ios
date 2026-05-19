# Scripts & Tools

包含用于通过自动化改善**开发者体验 (DX)** 的脚本。

## 脚本说明

| 脚本 | 用途 |
|---|---|
| `lint.sh` | 调用 SwiftLint 进行代码风格检查 |
| `setup.sh` | 新开发者入职的一键环境配置（待完善） |
| `pre-commit` | Git pre-commit hook，自动触发 lint |
| `check_headers.py` | 检查 Swift 文件头部版权声明是否规范（manual tool；无 CI 调用） |
| `add_assets.rb` | 向 Asset Catalog 批量添加资源（一次性 Xcode 工具） |
| `add_swiftlint_phase.rb` | 为 Xcode Target 自动添加 SwiftLint Build Phase（一次性） |
| `fix_duplicate_assets.rb` | 清理 Asset Catalog 中的重复资源（一次性） |
| `inspect_project.rb` | 检查 `.xcodeproj` 项目文件结构（诊断用） |
| `ci-local.sh` | 本地模拟 CI 流程（lint + build + test） |
| `post_review.sh` | 将 Review 结果发布到 GitHub PR |
| `gemini_project_review.py` | 调用 Gemini API 项目级审计（手动；主流是 cross-audit skill 的 `gemini -p`） |
| `gemini_review.py` | 调用 Gemini API 代码审查（同上） |
| `gemini_utils.py` | Gemini 脚本共享工具函数 |
| `validate_frontmatter.py` | YAML frontmatter schema 校验（CI Build & Test job 调用） |
| `recall-index.sh` | 知识/记忆快速召回（手动 CLI） |
| `anti-pattern-scan.sh` | PR 合并后启发式反模式扫描（post-merge-checkpoint.sh 调用） |
| `audit/docaudit.py` | 文档审计引擎（CI Docs Audit job 调用 + 多处 hook 调用） |
| `audit/skill_refresh_report.py` | Vendored skill 上游对比报告（手动） |
| `audit/tests/` | docaudit 单元测试（CI Docs Audit job 调用） |
| `migrations-completed/` | 已完成的一次性 migration 脚本归档（保留供历史溯源） |

此目录不包含任何生产环境代码。
